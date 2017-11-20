//  UnionPublisher.h
//  UnionPublisher
//
//  Created by shixuemei on 10/28/17.
//  Copyright © 2017 ksyun. All rights reserved.
//

#import "UnionAVCommon.h"

/**
 * 发送端状态
 */
typedef NS_ENUM(NSUInteger, UnionPublisherState) {
    /// 初始化状态
    UnionPublisherState_Idle    = 0,
    /// 推流中
    UnionPublisherState_Started = 1,
    /// 推流结束
    UnionPublisherState_Stopped = 2,
    /// 推流错误
    UnionPublisherState_Error   = 3,
};

/**
 * 错误码
 */
typedef NS_ENUM(NSInteger, UnionPublisherErrorCode) {
    /// 未知错误
    UnionPublisherErrorCode_Unknown                 = -10000,
    /// 无效的地址
    UnionPublisherErrorCode_Invalid_Address         = -10001,
    /// 链接服务器失败
    UnionPublisherErrorCode_ConnectServer_Failed    = -10002,
    /// 推流失败
    UnionPublisherErrorCode_ConnectStream_Failed     = -10003,
    /// 发送数据失败
    UnionPublisherErroCode_Send_Failed              = -10004,
};

FOUNDATION_EXPORT NSString *const UnionPublisherStateDidChangeNotification;

/**
 发送模块接口协议定义
 */
@protocol UnionPublisher <NSObject>

@required

/**
 @abstract 设置视频格式
 @param videoFmt 视频格式
 @discussion 调用startStream方法前设置
 */
- (void) setVideoEncCfg:(UnionVideoEncCfg *) videoEncCfg;

/**
 @abstract 设置音频格式
 @param audioFmt 音频格式
 @discussion 调用startStream方法前设置
 */
- (void) setAudioEncCfg:(UnionAudioEncCfg *) audioEncCfg;

/**
 @abstract 设置metadata
 @param metadata 自定义的meta，视频宽高等内部会按照videoFmt和audioFmt信息来填充
 @discussion 调用startStream方法前设置
 */
- (void) setMetaData:(NSDictionary *)metadata;

/**
 @abstract 启动推流
 @param url 目标地址
 @return  成功返回0，失败返回负数
 */
- (int) startStream: (NSURL* __nonnull) url;

/**
 @abstract 发送数据包
 @param packet 待发送数据
 @return  成功返回0，失败返回负数
 */
- (int) sendPacket:(UnionAVPacket *)packet;

/**
 @abstract 停止推流
 */
- (void) stopStream;

/**
 @abstract 当前推流状况
 @discussion 可以通过该属性获取推流会话的工作状态
 */
@property (nonatomic, readonly) UnionPublisherState publisherState;

/**
 @abstract 错误信息
 @discussion 当状态为UnionPublisherState_Error时可获取相应的错误信息
 */
@property (nonatomic, readonly) NSError* error;

@end
