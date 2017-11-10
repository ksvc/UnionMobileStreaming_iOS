//
//  UnionEncoder.h
//  UnionStreamer
//
//  Created by pengbin on 10/28/17.
//  Copyright © 2017 ksyun. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "UnionAVCommon.h"

/**
 音视频编码模块接口定义
 
 UnionEncoder 只定义了编码器的接口协议
 
 */
@protocol UnionEncoder<NSObject>

#pragma mark - init
/**
 配置编码器参数
 
 @param cfg 编码器参数
 @return 构造的对象
 */
@required
- (id)initWithConfig:(UnionEncoderCfg*)cfg;

#pragma mark - operations

/**
 * 开始编码.
 */
@required
- (BOOL) start;

/**
 * 停止编码.
 */
@required
- (void) stop;

/**
 * flush当前编码器.
 */
@required
- (void) flush;

/**
 编码过程中动态设置目标码率
 
 @param bitrate 新的目标码率
 */
@required
- (void) adjustBitrate:(int) bitrate;

#pragma mark - data I/O
/**
 编码数据输入函数

 @param frame 送入的数据
 @param completion 完成回调
 */
@required
- (void)processAVFrame:(UnionAVFrame*)frame
            onComplete:(void (^)(BOOL))completion;

/// 输出编码后的压缩数据
@required
@property(nonatomic, copy) void(^encodedPacketCallback)(UnionAVPacket * pkt);

#pragma mark - informations

/** 当前的编码参数 */
@optional
@property (nonatomic, readonly) UnionEncoderCfg* encoderCfg;

/** 错误信息 */
@optional
@property (nonatomic, readonly) NSError* error;

/**
 * 获取当次编码过程中丢掉的frame数量.
 */
@optional
@property (nonatomic, readonly) int frameDropped;

/**
 * 获取当次编码过程中已编码的frame数量.
 */
@optional
@property (nonatomic, readonly) int frameEncoded;

@end

