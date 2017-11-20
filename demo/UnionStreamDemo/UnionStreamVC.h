//
//  UnionStreamVC.h
//  UnionSteamDemo
//
//  Created by ksyun on 2017/2/7.
//  Copyright © 2017年 ksyun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GPUImage/GPUImage.h>
#import "UnionUIVC.h"
#import "UnionUIView.h"
#import "UnionStreamKit.h"

@class UnionStreamKit;

@interface UnionStreamVC : UnionUIVC

@property UnionStreamKit *kit;

@property GPUImageOutput<GPUImageInput>* curFilter;

@property (nonatomic, readonly) UnionUIView   * ctrlView;

- (id)initWithUrl:(NSURL *)rtmpUrl andPreset:(UnionPreset) preset;

@property NSInteger audioCodecIdx;
@property NSInteger videoCodecIdx;

// 重写此方法，调整UI布局
- (void)setupUI;
- (void)onBtn:(UIButton *)btn;
- (void)onQuit;
@end

#define SEL_VALUE(SEL_NAME) [NSValue valueWithPointer:@selector(SEL_NAME)]
