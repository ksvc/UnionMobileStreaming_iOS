//  UnionLibrtmpPublisher.m
//  UnionPublisher
//
//  Created by shixuemei on 10/28/17.
//  Copyright © 2017 ksyun. All rights reserved.
//
#import "UnionLibrtmpPublisher.h"
#import "UnionPublisherDef.h"
#import "UnionLibrtmp.h"

#define CASE_RETURN( ENU ) case ENU : {return @#ENU;}
NSString *const UnionPublisherStateDidChangeNotification =@"UnionPublisherStateDidChangeNotification";

@interface UnionLibrtmpPublisher(){
    UnionLibrtmp_t  *_publisher;
}

@property (nonatomic, readwrite) UnionPublisherState publisherState;
@property (nonatomic, readwrite) NSError* error;

@end

#pragma mark - UnionLibrtmpPublisher implementation
@implementation UnionLibrtmpPublisher

#pragma mark - initialization
-(instancetype)init
{
    self =[super init];
    
    _publisher = union_librtmp_open();
    if(NULL == _publisher)
        return nil;
    
    _publisherState = UnionPublisherState_Idle;
    return self;
}

-(void)dealloc
{
    if(_publisher)
    {
        union_librtmp_close(_publisher);
        _publisher = NULL;
    }
}

#pragma mark - av format
/**
 @abstract 设置video format
 */
- (void)setVideoEncCfg:(UnionVideoEncCfg *)videoEncCfg
{
    if(NULL == _publisher)
        return ;
    
    union_librtmp_set_videocfg(_publisher, videoEncCfg);
    return ;
}

/**
 @abstract 设置audio format
 */
- (void)setAudioEncCfg:(UnionAudioEncCfg *)audioEncCfg
{
    if(NULL == _publisher)
        return ;
    
    union_librtmp_set_videocfg(_publisher, audioEncCfg);
    return ;
}

/**
 @abstract 设置metadata
 @param metadata 自定义的meta，视频宽高等内部会按照videoFmt和audioFmt信息来填充
 */
- (void) setMetaData:(NSDictionary *)metadata
{
    UnionDict metaDict = {0, NULL};
    if(metadata)
    {
        for (NSString *key in [metadata allKeys]) {
            id val = [metadata objectForKey:key];
            const char *name = [key UTF8String];
            if ([val isKindOfClass:[NSString class]]) {
                const char *str = [(NSString*)val UTF8String];
                union_librtmp_set_userMetadata(_publisher, name, 0, str);
            }
            else if ([val isKindOfClass:[NSNumber class]]) {
                double number = [(NSNumber*)val doubleValue];
                union_librtmp_set_userMetadata(_publisher, name, number, nil);
            }
            else
                continue;
        }
    }
}

#pragma mark - publish
/**
 @abstract 启动推流
 @param url 目标地址
 @return  成功返回0，失败返回负数
 */
- (int)startStream: (NSURL* __nonnull) url
{
    char *rtmpUrl = [[url absoluteString] UTF8String];
    int errorCode = UnionPublisherErrorCode_Unknown;
    int ret = UnionPublisher_Error_Unknown;
    
    if(NULL == _publisher)
        goto FAIL;
    
    if(NULL == url || ![[url scheme] isEqualToString:@"rtmp"])
    {
        ret = UnionPublisher_Error_Invalid_Address;
        goto FAIL;
    }
    
    if(UnionPublisherState_Started != _publisherState)
    {
        ret = union_librtmp_start(_publisher, rtmpUrl, NULL);
        if(ret < 0)
            goto FAIL;
        
        [self newStreamState:UnionPublisherState_Started errorCode:0 info:nil];
    }

    return 0;
    
FAIL:
    errorCode = (UnionPublisherErrorCode)ret;
    [self newStreamState:UnionPublisher_Status_Error errorCode:errorCode info:[self getStreamStateName:errorCode]];
    return -1;
}

/**
 @abstract 停止推流
 */
- (void)stopStream
{
    if(UnionPublisherState_Idle == _publisherState)
        return ;
    
    if(_publisher)
        union_librtmp_stop(_publisher);
    
    [self newStreamState:UnionPublisherState_Stopped errorCode:0 info:nil];
    return ;
}

/**
 @abstract 发送数据包
 */
- (int) sendPacket:(UnionAVPacket *)packet
{
    if(NULL == _publisher  || UnionPublisherState_Started != _publisherState)
        return -1;
    
    int ret = union_librtmp_send(_publisher, packet);
    
    if(ret < 0)
    {
        int errorCode = (UnionPublisherErrorCode)ret;
        [self newStreamState:UnionPublisher_Status_Error errorCode:errorCode info:[self getStreamStateName:errorCode]];
    }

    return ret;
}

#pragma mark - state

/**
 @abstract 状态变化
 */
- (void) newStreamState:(UnionPublisherState)state errorCode:(UnionPublisherErrorCode)errorCode info:(NSString*)info
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(_publisherState != state)
        {
            _publisherState = state;
            if(UnionPublisherState_Error == state)
            {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: info};
                _error = [[NSError alloc] initWithDomain:@"UnionLibrtmpPublisher"
                                                    code:errorCode
                                                userInfo:userInfo];
            }
            else
                _error = nil;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:UnionPublisherStateDidChangeNotification
                                                                object:self];
        }
    });
}

- (NSString *)getStreamStateName:(UnionPublisherErrorCode)code
{
    switch (code){
            CASE_RETURN (UnionPublisherErrorCode_Unknown)
            CASE_RETURN (UnionPublisherErrorCode_Invalid_Address)
            CASE_RETURN (UnionPublisherErrorCode_ConnectServer_Failed)
            CASE_RETURN (UnionPublisherErrorCode_ConnectStream_Failed)
            CASE_RETURN (UnionPublisherErroCode_Send_Failed)
        default:
            return nil;
    }
}

@end
