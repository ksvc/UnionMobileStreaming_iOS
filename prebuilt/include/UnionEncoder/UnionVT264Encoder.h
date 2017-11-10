//
//  UnionEncoder.h
//  UnionStreamer
//
//  Created by pengbin on 10/28/17.
//  Copyright © 2017 ksyun. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "UnionEncoderBase.h"

/**
 videotoolbox视频编码器 H.264
 
 能接受的输入像素格式为 UnionPixFmt_NV12 和 UnionPixFmt_I420,
 */
@interface UnionVt264Encoder: UnionEncoderBase

/**
 编码数据输入函数
 
 @param frame 送入的数据
 @param completion 完成回调
 */
- (void)processSampleBuffer:(CMSampleBufferRef)frame
                 onComplete:(void (^)(BOOL))completion;


/**
 编码数据输入函数
 
 @param frame 送入的数据
 @param time  时间戳
 @param completion 完成回调
 */
- (void)processPixelBuffer:(CVPixelBufferRef)frame
                  timeInfo:(CMTime)time
                 onComplete:(void (^)(BOOL))completion;

@end
