//  UnionAdaptor.h
//  UnionAdaptor
//
//  Created by shixuemei on 10/28/17.
//  Copyright © 2017 ksyun. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "UnionAVCommon.h"

/**
 * 网络自适应模式
 */
typedef NS_ENUM(NSUInteger, UnionBWEstimateMode) {
    /// 禁用网络自适应
    UnionBWEstimateMode_None = 0,
    /// 综合模式, 较为平稳, 兼顾画面质量和流畅度
    UnionBWEstimateMode_Default,
    /// 流畅优先模式, 优先考虑流畅度，其实是画面质量
    UnionBWEstimateMode_Negtive,
};

/**
 * 网络自适应事件
 */
typedef NS_ENUM(NSUInteger, UnionBWEstimateEvent) {
    /// 未知事件
    UnionBWEstimateEvent_None = 0,
    /// 数据包发送较慢
    UnionBWEstimateEvent_SendSlow,
    /// 视频码率上调
    UnionBWEstimateEvent_BWRaise,
    /// 视频码率下调
    UnionBWEstimateEvent_BWDrop,
};

@interface UnionAdaptor : NSObject

#pragma mark - configuration
/**
  @abstract 是否处理视频数据 (默认YES)
  @discussion 推荐在启动本模块前设置，过程中不再改动
  */
@property (nonatomic, assign) BOOL  bWithVideo;

/**
 @abstract 是否处理音频数据 (默认YES)
 @discussion 推荐在启动本模块前设置，过程中不再改动
 */
@property (nonatomic, assign) BOOL  bWithAudio;

#pragma mark - network adaptive

/**
 @abstract   音频编码码率（单位:kbps, 默认64）
 @discussion 推荐在启动本模块前设置，过程中不再改动
 @discussion 该参数会影响码率自适应效果，请务必按照真实码率进行配置
 */
@property (nonatomic, assign) int   audioBitrate;

/**
 @abstract   视频编码起始码率（单位:kbps, 默认:500）
 @discussion 开始推流时的视频码率，开始推流后，根据网络情况在Min~Max范围内调节
 @discussion 视频码率上调则画面更清晰，下调则画面更模糊
 @discussion 推荐在启动本模块前设置，过程中不再改动
 @see videoMaxBitrate, videoMinBitrate
 */
@property (nonatomic, assign) int   videoInitBitrate;

/**
 @abstract   视频编码最高码率（单位:kbps, 默认:800）
 @discussion 视频码率自适应调整的上限, 为目标码率
 @discussion 推荐在启动本模块前设置，过程中不再改动
 @see videoInitBitrate, videoMinBitrate
 */
@property (nonatomic, assign) int   videoMaxBitrate;

/**
 @abstract   视频编码最低码率（单位:kbps, 默认:200）
 @discussion 视频码率自适应调整的下限
 @discussion 推荐在启动本模块前设置，过程中不再改动
 @see videoInitBitrate, videoMaxBitrate
 */
@property (nonatomic, assign) int   videoMinBitrate;

/**
 @abstract   带宽估计模式
 @discussion 带宽估计的策略选择 (开始推流前设置有效)
 */
@property (nonatomic, assign) UnionBWEstimateMode bwEstimateMode;

/**
 @abstract 网络自适应事件
 */
@property(nonatomic, copy) void(^bwEstimateEventCallback)(UnionBWEstimateEvent event, int64_t value);

#pragma mark - process

/**
 @abstract 启动网络自适应模块
 @return  成功返回0，失败返回负数
 */
- (int) start;

/**
 @abstract 写入数据包
 @param packet 待写入数据
 @return  成功返回0，失败返回负数
 */
- (int) writePacket:(UnionAVPacket *)packet;

/**
 @abstract 停止网络自适应模块
 */
- (void) stop;

/**
 @abstract 停止网络自适应模块
 */
@property(nonatomic, copy) void(^adaptedPacketCallback)(UnionAVPacket * pkt);

@end
