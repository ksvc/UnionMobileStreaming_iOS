//
//  UnionStreamVC.m
//  UnionStreamVC
//
//  Created by ksyun on 2017/2/7.
//  Copyright © 2017年 ksyun. All rights reserved.
//

#import "UnionSettingVC.h"
#import "UnionStreamVC.h"

@interface UnionSettingVC ()<UIPickerViewDataSource,
UIPickerViewDelegate>{
    NSArray * _profileNames;//存放各个清晰度标签
}
@property UnionUIView        * ctrlView;
@property UITextField        * hostUrlUI;   // host URL
@property UIButton           * doneBtn;


@property UIPickerView *profilePicker; // 选择参数
@property UIButton     *startBtn;      //开始推流

@property NSInteger         curProfileIdx;
@property NSURL             *url;

@end

@implementation UnionSettingVC

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString * uuidStr =[[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString *devCode  = [[uuidStr substringToIndex:3] lowercaseString];
    //推流地址
    NSString *streamSrv  = @"rtmp://test.uplive.ks-cdn.com/live";
    NSString *streamUrl      = [ NSString stringWithFormat:@"%@/%@", streamSrv, devCode];
    _url = [[NSURL alloc] initWithString:streamUrl];
    
    self.view.backgroundColor = [UIColor whiteColor];
    _profileNames = @[@"360p_auto",@"360p_1",@"360p_2",@"360p_3",
                      @"540p_auto",@"540p_1",@"540p_2",@"540p_3",
                      @"720p_auto",@"720p_1",@"720p_2",@"720p_3"];
    [self setupUI];
}

- (void)setupUI{
    _ctrlView = [[UnionUIView alloc] initWithFrame:self.view.bounds];
    @WeakObj(self);
    _ctrlView.onBtnBlock = ^(id sender){
        [selfWeak  onBtn:sender];
    };
    _hostUrlUI = [_ctrlView addTextField:_url.absoluteString];
    _doneBtn =  [_ctrlView  addButton:@"ok"];
    
    // profile picker
    _profilePicker = [[UIPickerView alloc] init];
    _profilePicker.delegate   = self;
    _profilePicker.dataSource = self;
    _profilePicker.showsSelectionIndicator= YES;
    _profilePicker.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.3];
    [_profilePicker selectRow:7 inComponent:0 animated:YES];
    [self pickerView:_profilePicker didSelectRow:7 inComponent:0];
    
    _startBtn = [_ctrlView addButton:@"开始"];

    [self.view addSubview:_ctrlView];
    [_ctrlView addSubview:_profilePicker];
    [self layoutUI];
}

- (void)layoutUI{
    _ctrlView.frame = self.view.frame;
    [_ctrlView layoutUI];
    [_ctrlView putWide:_hostUrlUI andNarrow:_doneBtn];
    _ctrlView.yPos +=_ctrlView.btnH;
    _ctrlView.btnH = 216;
    [_ctrlView putRow1:_profilePicker];
    _ctrlView.btnH = _ctrlView.height - _ctrlView.yPos;
    [_ctrlView putRow:@[_startBtn]];
}

- (void)onBtn:(UIButton *)btn{
    if (btn == _doneBtn) {
        [_hostUrlUI resignFirstResponder];
    }
    else if (btn ==  _startBtn) {
        _url = [[NSURL alloc] initWithString:_hostUrlUI.text];
        UnionStreamVC * vc = [[UnionStreamVC alloc] initWithUrl:_url andPreset:_curProfileIdx];
        [self presentViewController:vc animated:true completion:nil];
    }
}


#pragma mark - profile picker
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView*)pickerView {
    return 1; // 单列
}
- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component {
    return _profileNames.count;//
}
- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component{
    return [_profileNames objectAtIndex:row];
}
- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component {
    if (row >= 0 && row <= 3){
        _curProfileIdx = row;
    }else if (row >= 4 && row <= 7){
        _curProfileIdx = 100 + (row - 4);
    }else if (row >= 8 && row <= 11){
        _curProfileIdx = 200 + (row - 8);
    }else{
        _curProfileIdx = 103;
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - view rotate
- (void)onViewRotate{
    [self layoutUI];
}
- (BOOL)shouldAutorotate {
    return NO;
}

@end
