//
//  UnionEncoder.h
//  UnionStreamer
//
//  Created by pengbin on 10/28/17.
//  Copyright © 2017 ksyun. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "UnionAVCommon.h"
#import "UnionEncoder.h"
/**
 音视频编码模块接口定义
 
 UnionEncoderBase为基类, 只实现一些公共的基础功能
 要实现特定编码器的功能, 请继承本类来实现
 
 */
@interface UnionEncoderBase:NSObject <UnionEncoder>

#pragma mark - init
/**
 配置编码参数.
 */
- (id)initWithConfig:(UnionEncoderCfg*)cfg;

#pragma mark - operations

/**
 * 开始编码.
 */
- (BOOL) start;

/**
 * 停止编码.
 */
- (void) stop;

/**
 * flush当前编码器.
 */
- (void) flush;

/**
 编码过程中动态设置目标码率
 
 @param bitrate 新的目标码率
 */
- (void) adjustBitrate:(int) bitrate;

/**
 请求关键帧
 */
- (void) requestKeyFrame;

#pragma mark - data I/O
/**
 编码数据输入函数

 @param frame 送入的数据
 @param completion 完成回调
 */
- (void)processAVFrame:(UnionAVFrame*)frame
            onComplete:(void (^)(BOOL))completion;

/// 输出编码后的压缩数据
@property(nonatomic, copy) void(^encodedPacketCallback)(UnionAVPacket * pkt);

#pragma mark - informations

/** 当前的编码参数 */
@property (nonatomic, readonly) UnionEncoderCfg* encoderCfg;

/** 错误信息 */
@property (nonatomic, readonly) NSError* error;

/**
 * 获取当次编码过程中丢掉的frame数量.
 */
@property (nonatomic, readonly) int frameDropped;

/**
 * 获取当次编码过程中已编码的frame数量.
 */
@property (nonatomic, readonly) int frameEncoded;

@end

/// 新建编码器内部错误的工具函数
@interface UnionEncoderBase(error)
/**
 新建错误

 @param code 错误码
 @param info 错误信息
 */
- (void) newError:( NSInteger) code info:( NSString*) info ;
@end

