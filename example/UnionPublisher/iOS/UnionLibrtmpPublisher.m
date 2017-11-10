//  UnionLibrtmpPublisher.m
//  UnionPublisher
//
//  Created by shixuemei on 10/28/17.
//  Copyright © 2017 ksyun. All rights reserved.
//
#import "UnionLibrtmpPublisher.h"
#import "UnionPublisherDef.h"
#import "UnionLibrtmp.h"

@interface UnionLibrtmpPublisher(){
    UnionLibrtmp_t  *_publisher;
    NSDictionary    *_streamMetadata;
}

@property (nonatomic, readwrite) UnionPublisherState publisherState;

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
    
   _streamMetadata = nil;
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
    
    UnionVideoEncCfg *vEncCfg = union_librtmp_get_videocfg(_publisher);
    if(vEncCfg)
        memcpy(vEncCfg, videoEncCfg, sizeof(UnionVideoEncCfg));
    return ;
}

/**
 @abstract 设置audio format
 */
- (void)setAudioEncCfg:(UnionAudioEncCfg *)audioEncCfg
{
    if(NULL == _publisher)
        return ;
    
    UnionAudioEncCfg *aEncCfg = union_librtmp_get_audiocfg(_publisher);
    if(aEncCfg)
        memcpy(aEncCfg, audioEncCfg, sizeof(UnionVideoEncCfg));
    return ;
}

/**
 @abstract 设置metadata
 @param metadata 自定义的meta，视频宽高等内部会按照videoFmt和audioFmt信息来填充
 */
- (void) setMetaData:(NSDictionary *)metadata
{
    _streamMetadata = metadata;
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
    int ret = -1;
    
    if(NULL == _publisher || NULL == url || ![[url scheme] isEqualToString:@"rtmp"])
        goto FAIL;
    
    if(UnionPublisherState_Started != _publisherState)
    {
        UnionDict metaDict = {0, NULL};
        if(_streamMetadata)
        {
            metaDict.elems = (UnionDictElem *)malloc([_streamMetadata count] * sizeof(UnionDictElem));
            if(metaDict.elems)
            {
                memset(metaDict.elems, 0, sizeof([_streamMetadata count] * sizeof(UnionDictElem)));
                
                for (NSString *key in [_streamMetadata allKeys]) {
                    id val = [_streamMetadata objectForKey:key];
                    const char *name = [key UTF8String];
                    if ([val isKindOfClass:[NSString class]]) {
                        const char *str = [(NSString*)val UTF8String];
                        metaDict.elems[metaDict.number].type = UnionDataType_String;
                        metaDict.elems[metaDict.number].val.string = str;
                    }
                    else if ([val isKindOfClass:[NSNumber class]]) {
                        double number = [(NSNumber*)val doubleValue];
                        metaDict.elems[metaDict.number].type = UnionDataType_Number;
                        metaDict.elems[metaDict.number].val.number = number;
                    }
                    else
                        continue;
                    metaDict.elems[metaDict.number].name = name;
                    metaDict.number++;
                }
            }
        }
            
        ret = union_librtmp_start(_publisher, rtmpUrl, &metaDict);

        if(metaDict.elems)
            free(metaDict.elems);
            
        if(ret < 0)
            goto FAIL;
    }
    
    _publisherState = UnionPublisherState_Started;
    return 0;
    
FAIL:

    _publisherState = UnionPublisherState_Error;
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
    
    _publisherState = UnionPublisherState_Stopped;
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
        _publisherState = UnionPublisher_Status_Error;
    return ret;
}

@end
