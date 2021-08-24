//
//  KDSLockAlterTimeVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/16.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSLockAlterTimeVC.h"
#import "MBProgressHUD+MJ.h"

@interface KDSLockAlterTimeVC ()

///动画视图。
@property (nonatomic, strong) UIImageView *animationIV;
///校准按钮，在动画视图的中间。
@property (nonatomic, strong) UIButton *calibrationBtn;
///提示标签。
@property (nonatomic, strong) UILabel *tipsLabel;
///动画定时器。
@property (nonatomic, strong) NSTimer *animationTimer;
///时间校准成功的对号图标
@property (nonatomic, strong) UIImageView * timeSuccessIcon;

@end

@implementation KDSLockAlterTimeVC

- (NSTimer *)animationTimer
{
    if (!_animationTimer)
    {
        _animationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 30 target:self selector:@selector(animationTimerActionChangeAnimationIVTransform:) userInfo:nil repeats:YES];
    }
    return _animationTimer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationTitleLabel.text = Localized(@"time");
    
    self.animationIV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"deviceAlteringLockTime"]];
    self.animationIV.frame = CGRectMake((kScreenWidth - 200) / 2.0, 124, 200, 200);
    [self.view addSubview:self.animationIV];
    
    self.calibrationBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    //self.calibrationBtn.backgroundColor = UIColor.clearColor;
    NSString *calibration = Localized(@"lockTimeCalibration");
    UIFont *font = [UIFont systemFontOfSize:13];
    [self.calibrationBtn setTitle:calibration forState:UIControlStateNormal];
    [self.calibrationBtn setTitleColor:KDSRGBColor(0x72, 0xdb, 0xfb) forState:UIControlStateNormal];
    self.calibrationBtn.titleLabel.font = font;
    self.calibrationBtn.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    CGFloat calibrationWidth = ceil([calibration sizeWithAttributes:@{NSFontAttributeName : font}].width);
    self.calibrationBtn.bounds = CGRectMake(0, 0, calibrationWidth, 30);
    self.calibrationBtn.center = self.animationIV.center;
    self.calibrationBtn.clipsToBounds = NO;
    [self.calibrationBtn addTarget:self action:@selector(clickCalibrationBtnBeginAnimationAndSetLockTime:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.calibrationBtn];
    
    self.timeSuccessIcon = [UIImageView new];
    self.timeSuccessIcon.backgroundColor = UIColor.clearColor;
    self.timeSuccessIcon.image = [UIImage imageNamed:@"deviceAlterLockTimeSuccseeIcon"];
    self.timeSuccessIcon.frame = CGRectMake((kScreenWidth-19) / 2.0, 185, 19, 13);
    //    self.timeSuccessIcon.center = self.animationIV.center;
    self.timeSuccessIcon.hidden = YES;
    [self.view addSubview:self.timeSuccessIcon];
    
    self.tipsLabel = [[UILabel alloc] init];
    self.tipsLabel.textColor = KDSRGBColor(0x14, 0x14, 0x14);
    self.tipsLabel.font = [UIFont systemFontOfSize:12];
    self.tipsLabel.textAlignment = NSTextAlignmentCenter;
    self.tipsLabel.numberOfLines = 0;
    self.tipsLabel.text = Localized(@"alteringManagementPwdTips");
    CGSize size = [self.tipsLabel.text boundingRectWithSize:CGSizeMake(kScreenWidth - 20, kScreenHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : self.tipsLabel.font} context:nil].size;
    self.tipsLabel.frame = CGRectMake(10, CGRectGetMaxY(self.animationIV.frame) + 36, kScreenWidth - 20, ceil(size.height));
    [self.view addSubview:self.tipsLabel];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_animationTimer invalidate];
    _animationTimer = nil;
}

#pragma mark - 控件等事件方法。
///点击校准按钮启动动画并发送同步时间命令。
- (void)clickCalibrationBtnBeginAnimationAndSetLockTime:(UIButton *)sender
{
    NSString *calibration = Localized(@"lockTimeCalibration");
    NSString *takingEffect = Localized(@"takingEffect");
    NSString *syncFailed = Localized(@"syncFailed");
    [sender setTitleColor:KDSRGBColor(0x72, 0xdb, 0xfb) forState:UIControlStateNormal];
    if ([sender.currentTitle isEqualToString:takingEffect]) return;
    self.animationTimer.fireDate = NSDate.date;
    [sender setTitle:takingEffect forState:UIControlStateNormal];
    self.animationIV.image = [UIImage imageNamed:@"deviceAlteringLockTime"];
    sender.bounds = (CGRect){0, 0, ceil([sender.currentTitle sizeWithAttributes:@{NSFontAttributeName : sender.titleLabel.font}].width), sender.bounds.size.height};
    __weak typeof(self) weakSelf = self;
    [self. lock.bleTool updateLockClock:^(KDSBleError error) {
        weakSelf.animationTimer.fireDate = NSDate.distantFuture;
        if (error == KDSBleErrorSuccess)
        {
            [MBProgressHUD showSuccess:Localized(@"syncSuccess")];
            [sender setTitle:calibration forState:UIControlStateNormal];
            weakSelf.animationIV.image = [UIImage imageNamed:@"deviceAlterLockTimeSussess"];
            weakSelf.animationIV.transform = CGAffineTransformIdentity;
            weakSelf.animationIV.transform = CGAffineTransformMakeRotation(-M_PI_4 * 1.37);
            self.timeSuccessIcon.hidden = NO;
        }
        else
        {
            [sender setTitle:syncFailed forState:UIControlStateNormal];
            [sender setTitleColor:KDSRGBColor(0xff, 0x90, 0x00) forState:UIControlStateNormal];
            weakSelf.animationIV.image = [UIImage imageNamed:@"deviceAlterLockTimeFailed"];
            weakSelf.animationIV.transform = CGAffineTransformIdentity;
            weakSelf.animationIV.transform = CGAffineTransformMakeRotation(-M_PI_4 * 1.37);
            self.timeSuccessIcon.hidden = YES;
        }
        sender.bounds = (CGRect){0, 0, ceil([sender.currentTitle sizeWithAttributes:@{NSFontAttributeName : sender.titleLabel.font}].width), sender.bounds.size.height};
    }];
}

///启动定时器时改变动画视图的转置矩阵。
- (void)animationTimerActionChangeAnimationIVTransform:(NSTimer *)timer
{
    self.animationIV.transform = CGAffineTransformRotate(self.animationIV.transform, M_PI / 30);
}

@end
