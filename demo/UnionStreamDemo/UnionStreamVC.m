//
//  UnionStreamVC.m
//  UnionStreamVC
//
//  Created by ksyun on 2017/2/7.
//  Copyright © 2017年 ksyun. All rights reserved.
//

#import "UnionStreamVC.h"
#import "UnionFileSelector.h"

#import "UnionVT264Encoder.h"
#import "UnionATAACEncoder.h"
#import "UnionX264Encoder.h"
#import "UnionFDKAACEncoder.h"

@interface UnionStreamVC () {
    UnionFileSelector * _fSel;
    NSMutableDictionary *_obsDict;
}

@property UIButton *captureBtn;//预览按钮
@property UIButton *streamBtn;//开始推流
@property UIButton *cameraBtn;//前后摄像头
@property UIButton *quitBtn;//返回按钮
@property NSInteger         curProfileIdx;
@property NSURL             *url;
@property UILabel           *streamState;//推流状态
@property UILabel           *lblUrl;//推流状态
@property UnionPreset       preset;

@end

@implementation UnionStreamVC
- (id)initWithUrl:(NSURL *)rtmpUrl andPreset:(UnionPreset) preset {
    if (self = [super init]) {
        _url = rtmpUrl;
        _preset = preset;
    }
    
    [self initObservers];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _kit = [[UnionStreamKit alloc] initWithPreset:_preset];
    _curFilter = [[GPUImageFilter alloc] init];
    //摄像头位置
    _kit.cameraPosition = AVCaptureDevicePositionFront;
    self.view.backgroundColor = [UIColor whiteColor];
    if (_audioCodecIdx == 1) { // 0 is defalut ataac
        _kit.aEncoder = [[UnionFDKAACEncoder alloc] initWithConfig:_kit.audioEncCfg];
    }
    if (_videoCodecIdx == 1) { // 0 is defalut vt264
        _kit.vEncoder = [[UnionX264Encoder alloc] initWithConfig:_kit.videoEncCfg];
    }
    [self setupUI];
    [self setupLogo];
    [self onCapture];
}

- (void)setupUI{
    _ctrlView = [[UnionUIView alloc] initWithFrame:self.view.bounds];
    @WeakObj(self);
    _ctrlView.onBtnBlock = ^(id sender){
        [selfWeak  onBtn:sender];
    };
    // top view
    _quitBtn = [_ctrlView addButton:@"退出"];
    _streamState = [_ctrlView addLable:@"空闲状态"];
    _streamState.textColor = [UIColor redColor];
    _streamState.textAlignment = NSTextAlignmentCenter;
    _cameraBtn = [_ctrlView addButton:@"前后摄像头"];
    _lblUrl = [_ctrlView addLable:_url.absoluteString];
    // bottom view
    _captureBtn = [_ctrlView addButton:@"开始预览"];
    _streamBtn = [_ctrlView addButton:@"开始推流"];
    [self.view addSubview:_ctrlView];
    [self layoutUI];
}

- (void)layoutUI{
    _ctrlView.frame = self.view.frame;
    [_ctrlView layoutUI];
    [_ctrlView putRow:@[_quitBtn, _streamState, _cameraBtn]];
    [_ctrlView putRow:@[_lblUrl]];
    _ctrlView.yPos = self.view.frame.size.height - 30;
    [_ctrlView putRow:@[_captureBtn, [UIView new], _streamBtn]];
}

- (void) setupLogo {
    _fSel = [[UnionFileSelector alloc] initWithDir:@"/Documents/logo/" andSuffix:@[@".png"]];
    if (_fSel.filePath) {
        NSURL * url = [NSURL fileURLWithPath:_fSel.filePath];
        _kit.logoPic = [[GPUImagePicture alloc] initWithURL:url];
    }
    else {
        [_fSel downloadFile:@"https://avatars3.githubusercontent.com/u/16359966?s=200&v=4" name:@"logo.png"];
    }
}

- (void)onBtn:(UIButton *)btn{
    if (btn == _captureBtn) {
        [self onCapture]; //启停预览
    }else if (btn == _streamBtn){
        [self onStream]; //启停推流
    }else if (btn == _cameraBtn){
        [self onCamera]; //切换前后摄像头
    }else if (btn == _quitBtn){
        [self onQuit]; //退出
    }
}

- (void)onCamera{ //切换前后摄像头
    [_kit switchCamera];
}

- (void)onCapture{
    if (!_kit.vCapDev.isRunning){
        _kit.videoOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        [_kit setupFilter:_curFilter];
        [_kit startPreview:self.view]; //启动预览
    }
    else {
        [_kit stopPreview];
    }
}
- (void)onStream{
    if (!_kit.vCapDev.isRunning) {
        return;
    }
    _streamBtn.selected = !_streamBtn.selected;
    if (_streamBtn.selected) {
        NSLog(@"%@", self.url.absoluteString);
        _streamBtn.enabled = NO;
        _quitBtn.enabled = NO;
        dispatch_async(dispatch_get_global_queue(0,0), ^(){
            [_kit startStream:self.url];
            dispatch_async(dispatch_get_main_queue(), ^(){
                _streamBtn.enabled = YES;
                _quitBtn.enabled = YES;
            });
        });
    }
    else {
        _streamBtn.enabled = NO;
        _quitBtn.enabled = NO;
        dispatch_async(dispatch_get_global_queue(0,0), ^(){
            [_kit stopStream];
            dispatch_async(dispatch_get_main_queue(), ^(){
                _streamBtn.enabled = YES;
                _quitBtn.enabled = YES;
            });
        });
    }
}
- (void)onQuit{
    [_kit stopPreview];
    [self rmObservers];
    _kit = nil;

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - view rotate
- (void)onViewRotate{
    [self layoutUI];
    if (_kit == nil) {
        return;
    }
    UIInterfaceOrientation orie = [[UIApplication sharedApplication] statusBarOrientation];
    [_kit rotateStreamTo:orie];
}
- (BOOL)shouldAutorotate {
    return YES;
}
- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    self.kit.preview.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
}

#pragma mark - 旋转预览 iOS > 8.0
// 旋转处理，通过旋转bgView来做到画面相对手机静止不动
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        CGAffineTransform deltaTransform = coordinator.targetTransform;
        CGFloat deltaAngle = atan2f(deltaTransform.b, deltaTransform.a);
        
        CGFloat currentRotation = [[self.kit.preview.layer valueForKeyPath:@"transform.rotation.z"] floatValue];
        // Adding a small value to the rotation angle forces the animation to occur in a the desired direction, preventing an issue where the view would appear to rotate 2PI radians during a rotation from LandscapeRight -> LandscapeLeft.
        currentRotation += -1 * deltaAngle + 0.0001;
        [self.kit.preview.layer setValue:@(currentRotation) forKeyPath:@"transform.rotation.z"];
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // Integralize the transform to undo the extra 0.0001 added to the rotation angle.
        CGAffineTransform currentTransform = self.kit.preview.transform;
        currentTransform.a = round(currentTransform.a);
        currentTransform.b = round(currentTransform.b);
        currentTransform.c = round(currentTransform.c);
        currentTransform.d = round(currentTransform.d);
        self.kit.preview.transform = currentTransform;
    }];
}

#pragma mark - notification
- (void) initObservers{
    _obsDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                SEL_VALUE(onPublisherStateChange:) ,  UnionPublisherStateDidChangeNotification,
                nil];
}

- (void) rmObservers {
    [super rmObservers];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) addObservers {
    [super addObservers];
    
    NSNotificationCenter* dc = [NSNotificationCenter defaultCenter];
    for (NSString* key in _obsDict) {
        SEL aSel = [[_obsDict objectForKey:key] pointerValue];
        [dc addObserver:self
               selector:aSel
                   name:key
                 object:nil];
    }
}

#pragma mark -  state change
- (void) onPublisherStateChange:(NSNotification *)notification{
    if(UnionPublisherStateDidChangeNotification ==  notification.name)
    {
        if(UnionPublisherState_Idle == _kit.publisher.publisherState)
            _streamState.text = @"空闲状态";
        else if(UnionPublisherState_Started == _kit.publisher.publisherState)
            _streamState.text = @"开始推流";
        else if(UnionPublisherState_Stopped == _kit.publisher.publisherState)
            _streamState.text = @"推流结束";
        else if(UnionPublisherState_Error == _kit.publisher.publisherState)
        {
            _streamState.text = @"推流错误";
            NSLog(@"%@", _kit.publisher.error);
        }
    }
}


@end
