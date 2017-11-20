//
//  UnionEncoder.h
//  UnionStreamer
//
//  Created by pengbin on 10/28/17.
//  Copyright © 2017 ksyun. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "UnionX264Encoder.h"
#include "x264Encoder.h"
#include <sys/time.h>

#define UNION_FRAMERATE_ESTIMATE_WIN 5

int64_t union_gettime(void)
{
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (int64_t)tv.tv_sec * 1000000 + tv.tv_usec;
}

/**
 音视频编码模块接口定义
 
 */
@interface UnionX264Encoder() {
    X264Encoder* _encoder; // encoder handle
    dispatch_queue_t _v_enc_q; // serial queue
    NSLock* _vEncLock;
    int curBitRate;
    int _frameEncoded;
    BOOL _initConfig;
    uint8_t * _pParameterSet;
    int _parameterSetSize;
    OSType _pixFmt;
    int _width;
    int _height;
    int64_t _initVpts;
    float _frameRate;
    int64_t _lastVdts;
    int  _vFrameCnt;
    int _encVTime[UNION_FRAMERATE_ESTIMATE_WIN];
    int64_t _totalEncVTime; // total time for all frames in window
}
@end

static void x264EncCallback(UnionAVPacket* pkt, void* opaque ) {
    UnionX264Encoder * enc = (__bridge UnionX264Encoder*)opaque;
    if (enc && enc.encodedPacketCallback) {
        enc.encodedPacketCallback(pkt);
    }
}

@implementation UnionX264Encoder

- (id) init {
    if ( !(self = [super initWithConfig:NULL]) ) {
        return nil;
    }
    return self;
}

/**
 配置编码参数.
 */
- (id)initWithConfig:(UnionEncoderCfg*)cfg {
    if ( !(self = [super initWithConfig:cfg]) ) {
        return nil;
    }
    _v_enc_q = dispatch_queue_create( "com.union.x264_enc_q", DISPATCH_QUEUE_SERIAL);
    _vEncLock = [[NSLock alloc] init];
    _parameterSetSize = 0;
    _initVpts = -1;
    return self;
}

- (void) dealloc {
    [self stop];
    if (_pParameterSet) {
        free(_pParameterSet);
    }
    _pParameterSet = NULL;
    _parameterSetSize = 0;
}

/**
 * 开始编码.
 */
- (BOOL) start {
    if (_encoder) {
        NSLog(@"encoder is running");
        return NO;
    }
    [_vEncLock lock];
    [self startEncoder];
    _initConfig = NO;
    [_vEncLock unlock];
    return YES;
}

- (void) startEncoder {
    UnionVideoEncCfg * cfg = &(self.encoderCfg->v);
    _encoder = x264EncInit();
    x264EncSetCallback(_encoder, x264EncCallback, (__bridge void *)self, NULL);
    int ret = x264EncOpen(_encoder, cfg);
    if ( ret ) { // open failed
        [super newError:ret info:@"x264 encoder open failed"];
    }
    _width = cfg->width;
    _height = cfg->height;
    _frameRate = cfg->frameRate;
    _lastVdts = -1;
    _vFrameCnt = 0;
    
    for(int i = 0; i < UNION_FRAMERATE_ESTIMATE_WIN; i++)
        _encVTime[i] = 1000000 / _frameRate;
    _totalEncVTime  =  1000000 / _frameRate * UNION_FRAMERATE_ESTIMATE_WIN;
}

/**
 * 停止编码.
 */
- (void) stop{
    [_vEncLock lock];
    [self stopEncoder];
    [_vEncLock unlock];
}
- (void) stopEncoder{
    if (_encoder) {
        x264EncClose(_encoder);
        x264EncRelease(_encoder);
        _encoder = NULL;
    }
}

- (void) restartEncoder{
    [_vEncLock lock];
    [self stopEncoder];
    [self startEncoder];
    [_vEncLock unlock];
}

/**
 * flush当前编码器.
 */
- (void) flush{
    [_vEncLock lock];
    if ( _encoder ) {
        int ret = x264EncEncode( _encoder, NULL);
        if ( ret ) {
            [super newError:ret info:@"X264 flush error"];
        }
    }
    [_vEncLock unlock];
}

/**
 编码数据输入函数
 
 @param frame 送入的数据
 @param completion 完成回调
 */
- (void)processAVFrame:(UnionAVFrame*)frame
            onComplete:(void (^)(BOOL))completion{
    int ret = 0;
    [_vEncLock lock];
    if (frame == NULL || _encoder == NULL) {
        [_vEncLock unlock];
        return;
    }
    if (frame->flags == UNION_AV_FLAG_OPAQUE) {
        CVPixelBufferRef buf = frame->plane[0];
        CMTime pts = CMTimeMake(frame->pts, 1000);
        [self processPixelBuffer:buf timeInfo:pts onComplete:completion];
        [_vEncLock unlock];
        return;
    }
    
    ++_vFrameCnt;
    int encTimeIdx = _vFrameCnt % UNION_FRAMERATE_ESTIMATE_WIN;
    double estFPS = (UNION_FRAMERATE_ESTIMATE_WIN * 1000000.0) / _totalEncVTime;
    _totalEncVTime -= _encVTime[encTimeIdx]; // 减掉老的
    
    int64_t encVStart = union_gettime();
    if (estFPS >= _frameRate)
    {
        ret = x264EncEncode(_encoder, frame);
        _encVTime[encTimeIdx] = (int)(union_gettime() - encVStart);
    }
    else
        _encVTime[encTimeIdx] =  1000000.0 / _frameRate;
    
    if (ret) {
        [super newError:ret info:@"encode frame failed"];
    }

    _totalEncVTime += _encVTime[encTimeIdx];
    
    if (completion) {
        completion( ret == UNION_ENC_ERR_NONE );
    }
    [_vEncLock unlock];
}

- (void)processPixelBuffer:(CVPixelBufferRef)frame
                  timeInfo:(CMTime)time
                onComplete:(void (^)(BOOL))completion {
    if(_encoder == NULL){
        return;
    }
    CFRetain(frame);
    dispatch_async(_v_enc_q, ^() {
        int64_t pts = (time.value * 1000 / time.timescale);
        if (_initVpts < 0){
            _initVpts = pts;
        }
        const int step  = (1000/_frameRate);
        bool bNeedDrop =  ( pts < (_initVpts - (step>>2)));
        if (bNeedDrop){
            return;
        }
        _initVpts += step;
        
        size_t wdt = CVPixelBufferGetWidth(frame);
        size_t hgt = CVPixelBufferGetHeight(frame);
        if ( wdt != _width || hgt != _height ) {
            UnionVideoEncCfg * cfg = &(self.encoderCfg->v);
            cfg->width = wdt;
            cfg->height = hgt;
            if (self.encoderConfigUpdateCallback) {
                self.encoderConfigUpdateCallback(self.encoderCfg);
            }
            [self restartEncoder];
        }
        UnionAVFrame  buf = {0};
        buf.pts = time.value*1000/time.timescale;
        buf.planeNum = CVPixelBufferGetPlaneCount(frame);
        CVPixelBufferLockBaseAddress(frame, 0);
        for (int i = 0; i < buf.planeNum; ++i ) {
            buf.plane[i] = CVPixelBufferGetBaseAddressOfPlane(frame, i);
            buf.stride[i] = CVPixelBufferGetBytesPerRowOfPlane(frame, i);
        }
        [self processAVFrame:&buf onComplete:completion];
        CVPixelBufferLockBaseAddress(frame, 0);
        CFRelease(frame);
    });
}



/**
 编码过程中动态设置目标码率
 
 @param bitrate 新的目标码率
 */
- (void) adjustBitrate:(int) bitrate {
    int delta =abs( bitrate - curBitRate); // update bitrate cfg
    if ( _encoder &&bitrate && curBitRate && delta > 5*1000 ) { // 5k step
        curBitRate = x264EncAdjustBitrate(_encoder, bitrate);
    }
}

@end
