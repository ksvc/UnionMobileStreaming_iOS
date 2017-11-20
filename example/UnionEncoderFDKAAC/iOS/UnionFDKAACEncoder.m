//
//  UnionFDKAACEncoder.h
//  UnionStreamer
//
//  Created by pengbin on 10/28/17.
//  Copyright © 2017 ksyun. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "UnionFDKAACEncoder.h"
#include <CoreMedia/CoreMedia.h>
#include "fdkAACEncoder.h"

/**
 音视频编码模块接口定义
 
 */
@interface UnionFDKAACEncoder() {
    FdkAACEncoder* _encoder;   // encoder handle
    dispatch_queue_t _a_enc_q; // serial queue
    NSLock* _aEncLock;
    int _frameEncoded;
    BOOL _initConfig;
}
@end

static void aacEncCallback(UnionAVPacket* pkt, void* opaque ) {
    UnionFDKAACEncoder * enc = (__bridge UnionFDKAACEncoder*)opaque;
    if (enc && enc.encodedPacketCallback) {
        enc.encodedPacketCallback(pkt);
    }
}

@implementation UnionFDKAACEncoder

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
    _a_enc_q = dispatch_queue_create( "com.union.fdkaac_enc_q", DISPATCH_QUEUE_SERIAL);
    _aEncLock = [[NSLock alloc] init];
    return self;
}

- (void) dealloc {
    [self stop];
}

/**
 * 开始编码.
 */
- (BOOL) start {
    if (_encoder) {
        NSLog(@"encoder is running");
        return NO;
    }
    [_aEncLock lock];
    [self startEncoder];
    _initConfig = NO;
    [_aEncLock unlock];
    return YES;
}

- (void) startEncoder {
    UnionAudioEncCfg * cfg = &(self.encoderCfg->a);
    _encoder = fdkAACEncInit();
    fdkAACEncSetCallback(_encoder, aacEncCallback, (__bridge void *)self, NULL);
    if (cfg->channels < 2 && cfg->profile == UNION_CODEC_PROFILE_AAC_HE_V2) {
        cfg->profile = UNION_CODEC_PROFILE_AAC_HE;
    }
    int ret = fdkAACEncOpen(_encoder, cfg);
    if ( ret ) { // open failed
        [super newError:ret info:@"fdk-aac encoder open failed"];
    }
}

/**
 * 停止编码.
 */
- (void) stop{
    [_aEncLock lock];
    [self stopEncoder];
    [_aEncLock unlock];
}
- (void) stopEncoder{
    if (_encoder) {
        fdkAACEncClose(_encoder);
        fdkAACEncRelease(_encoder);
        _encoder = NULL;
    }
}

/**
 * flush当前编码器.
 */
- (void) flush{
    [_aEncLock lock];
    if ( _encoder ) {
        int ret = fdkAACEncEncode( _encoder, NULL);
        if ( ret ) {
            [super newError:ret info:@"fdk-aac flush error"];
        }
    }
    [_aEncLock unlock];
}

/**
 编码数据输入函数
 
 @param frame 送入的数据
 @param completion 完成回调
 */
- (void)processAVFrame:(UnionAVFrame*)frame
            onComplete:(void (^)(BOOL))completion{
    [_aEncLock lock];
    if (frame == NULL || _encoder == NULL) {
        [_aEncLock unlock];
        return;
    }
    int ret = fdkAACEncEncode(_encoder, frame);
    if (ret) {
        [super newError:ret info:@"encode frame failed"];
    }
    if (completion) {
        completion( ret == UNION_ENC_ERR_NONE );
    }
    [_aEncLock unlock];
}

/**
 编码过程中动态设置目标码率
 
 @param bitrate 新的目标码率
 */
- (void) adjustBitrate:(int) bitrate {
    NSLog(@"fdk-aac can't adjust bitrate");
}

@end
