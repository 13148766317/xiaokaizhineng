//
//  KDSSecuritySettingVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/23.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSSecuritySettingVC.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "KDSDBManager.h"
#import "KDSGesturePwdVC.h"

@interface KDSSecuritySettingVC ()

///手势密码状态标签。
@property (nonatomic, strong) UILabel *gesturePwdStateLabel;
///手势状态选择开关。
@property (nonatomic, weak) UISwitch *gesSwi;
///手势密码标签。
@property (nonatomic, strong) UILabel *gesturePwdLabel;
///touch ID状态标签。
@property (nonatomic, strong) UILabel *touchIDStateLabel;
///touch ID状态选择开关。
@property (nonatomic, weak) UISwitch *touchIDSwi;
///数据库管理对象。
@property (nonatomic, strong, readonly) KDSDBManager *dbMgr;

@end

@implementation KDSSecuritySettingVC

- (KDSDBManager *)dbMgr
{
    return [KDSDBManager sharedManager];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationTitleLabel.text = Localized(@"securitySetting");
    CGFloat height = 60;
    UIView *cornerView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, kScreenWidth - 20, height * 3 + 2)];
    cornerView.layer.cornerRadius = 5;
    cornerView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:cornerView];
    
    self.gesturePwdStateLabel = [self createLabelWithText:nil originY:0];
    [cornerView addSubview:self.gesturePwdStateLabel];
    UISwitch *gesSwi = [self createSwitchWithCenterY:self.gesturePwdStateLabel.center.y];
    [cornerView addSubview:gesSwi];
    self.gesSwi = gesSwi;
    
    UIView *separator1 = [self createSeparatorViewWithOriginY:CGRectGetMaxY(self.gesturePwdStateLabel.frame)];
    [cornerView addSubview:separator1];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(separator1.frame), kScreenWidth - 20, height)];
    self.gesturePwdLabel = [self createLabelWithText:nil originY:0];
    [view addSubview:self.gesturePwdLabel];
    UIImage *arrow = [UIImage imageNamed:@"right"];
    UIImageView *arrowIV = [[UIImageView alloc] initWithImage:arrow];
    arrowIV.frame = (CGRect){kScreenWidth - 20 - 13 - arrow.size.width, (60 - arrow.size.height) / 2, arrow.size};
    [view addSubview:arrowIV];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToSetOrModifyGesturePwd:)];
    [view addGestureRecognizer:tap];
    [cornerView addSubview:view];
    
    UIView *separator2 = [self createSeparatorViewWithOriginY:CGRectGetMaxY(view.frame)];
    [cornerView addSubview:separator2];
    
    self.touchIDStateLabel = [self createLabelWithText:nil originY:CGRectGetMaxY(separator2.frame)];
    [cornerView addSubview:self.touchIDStateLabel];
    UISwitch *idSwi = [self createSwitchWithCenterY:self.touchIDStateLabel.center.y];
    idSwi.tag = 1;
    [cornerView addSubview:idSwi];
    self.touchIDSwi = idSwi;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    BOOL gesOn = self.dbMgr.queryUserGesturePwdState;

    NSString *gesPwd = self.dbMgr.queryUserGesturePwd;

    NSString *gesState = Localized(gesOn&&gesPwd ? @"closeGesturePwd" : @"openGesturePwd");
    NSLog(@"--{Kaadas}--%@",gesState);
    if (!gesOn&&gesPwd ) {
         [[KDSDBManager sharedManager] updateUserGesturePwd:nil];
    }

    self.gesturePwdStateLabel.text = gesState;
    self.gesSwi.on = gesOn && gesPwd;
    self.gesturePwdLabel.text = Localized(gesPwd ? @"modifyGesturePwd" : @"setGesturePwd");
    NSLog(@"--{Kaadas}--%@",self.gesturePwdLabel.text);

    BOOL idOn = self.dbMgr.queryUserTouchIDState;
    LAContext *ctx = [[LAContext alloc] init];
    [ctx canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
    self.touchIDStateLabel.text = Localized(idOn ? @"closeTouchID" : @"openTouchID");
    if (@available(iOS 11.0, *))
    {
        if (ctx.biometryType == LABiometryTypeFaceID)
        {
            self.touchIDStateLabel.text = Localized(idOn ? @"closeFaceID" : @"openFaceID");
        }
    }
    self.touchIDSwi.on = idOn;
}

///根据文字、y原点创建一个标签，有默认的颜色和字体。创建的标签已设置好frame属性。
- (UILabel *)createLabelWithText:(nullable NSString *)text originY:(CGFloat)y
{
    UIFont *font = [UIFont systemFontOfSize:12];
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = font;
    label.textColor = KDSRGBColor(0x2b, 0x2f, 0x50);
    label.frame = (CGRect){13, y, kScreenWidth - 20 - 26 - 26 - 13, 60};
    return label;
}

///根据中心点y创建一个开关。创建的开关已设置好frame属性。
- (UISwitch *)createSwitchWithCenterY:(CGFloat)y
{
    UISwitch *swi = [[UISwitch alloc] initWithFrame:CGRectZero];
    CGSize size = swi.bounds.size;
    swi.transform = CGAffineTransformMakeScale(sqrt(0.5), sqrt(0.5));
    swi.center = CGPointMake(kScreenWidth - 20 - 13 - size.width * sqrt(0.5) / 2, y);
    [swi addTarget:self action:@selector(switchGesturePwdOrTouchIDState:) forControlEvents:UIControlEventTouchUpInside];
    return swi;
}

///根据原点y创建一条分隔线视图，有默认的颜色。创建的分隔线已设置好frame属性。
- (UIView *)createSeparatorViewWithOriginY:(CGFloat)y
{
    UIView *separactor = [[UIView alloc] initWithFrame:(CGRect){13, y, kScreenWidth - 46, 1}];
    separactor.backgroundColor = KDSRGBColor(0xf0, 0xf0, 0xf0);
    return separactor;
}

#pragma mark - 控件等事件方法。
///选择手势密码或者touch ID状态，0是手势开关，1是touch ID开关。
-(void)switchGesturePwdOrTouchIDState:(UISwitch *)swi
{
    if (swi.tag == 0)
    {
        NSString *gesPwd = self.dbMgr.queryUserGesturePwd;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            KDSGesturePwdVC *vc = [KDSGesturePwdVC new];
            vc.type = !gesPwd ? 0 : 2;
            [self.navigationController pushViewController:vc animated:YES];
        });
        /*if (!gesPwd.length)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                KDSGesturePwdVC *vc = [KDSGesturePwdVC new];
                [self.navigationController pushViewController:vc animated:YES];
            });
            return;
        }
        BOOL res = [self.dbMgr updateUserGesturePwdState:swi.on];
        if (!res)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [swi setOn:!swi.on animated:YES];
            });
        }
        !res ?: (void)(self.gesturePwdStateLabel.text = Localized(swi.on ? @"closeGesturePwd" : @"openGesturePwd"));*/
    }else{
        LAContext *ctx = [[LAContext alloc] init];
        NSError * __autoreleasing error;
        if (![ctx canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error])
        {
            NSString *title = nil;
            if (@available(iOS 11.0, *))
            {
                BOOL fid = ctx.biometryType == LABiometryTypeFaceID;
                switch (error.code)
                {
                    case LAErrorBiometryLockout:
                        title = Localized((fid ? @"There were too many failed Face ID attempts and Face ID is now locked" : @"There were too many failed Touch ID attempts and Touch ID is now locked"));
                        break;
                        
                    case LAErrorBiometryNotAvailable:
                        title = Localized((fid ? @"deviceNotSupportOrCan'tUseFaceID" : @"deviceNotSupportOrCan'tUseTouchID"));
                        break;
                        
                    case LAErrorBiometryNotEnrolled:
                        title = Localized((fid ? @"The user has no enrolled Face ID" : @"The user has no enrolled Touch ID fingers"));
                        break;
                        
                    default:
                        break;
                }
            }
            else
            {
                switch (error.code)
                {
                    case LAErrorTouchIDNotAvailable:
                        title = Localized(@"deviceNotSupportOrCan'tUseTouchID");
                        break;
                        
                    case LAErrorTouchIDNotEnrolled:
                        title = Localized(@"The user has no enrolled Touch ID fingers");
                        break;
                        
                    case LAErrorTouchIDLockout:
                        title = Localized(@"There were too many failed Touch ID attempts and Touch ID is now locked");
                        break;
                        
                    default:
                        break;
                }
            }
            if (title)
            {
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [swi setOn:!swi.on animated:YES];
                }];
                [ac addAction:ok];
                [self presentViewController:ac animated:YES completion:nil];
            }
        }
        else
        {
            NSString *reason = Localized(swi.on ? @"authAndOpenTouchID" : @"authAndCloseTouchID");
            BOOL isFaceID = NO;
            if (@available(iOS 11.0, *))
            {
                if (ctx.biometryType == LABiometryTypeFaceID)
                {
                    reason = Localized(swi.on ? @"authAndOpenFaceID" : @"authAndCloseFaceID");
                    isFaceID = YES;
                }
            }
            ctx.localizedFallbackTitle = @"";
            [ctx evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:reason reply:^(BOOL success, NSError * _Nullable error) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    BOOL res = NO;
                    if (success)
                    {
                        res = [self.dbMgr updateUserTouchIDState:swi.on];
                    }
                    if (res)
                    {
                        self.touchIDStateLabel.text = Localized(swi.on ? (isFaceID ? @"closeFaceID" : @"closeTouchID") : (isFaceID ? @"openFaceID" : @"openTouchID"));
                    }
                    else
                    {
                        [swi setOn:!swi.on animated:YES];
                    }
                });
                
            }];
        }
    }
    
}

//MARK:点击跳转设置或修改手势密码。
- (void)tapToSetOrModifyGesturePwd:(UITapGestureRecognizer *)sender
{
    if (!self.dbMgr.queryUserGesturePwdState)//要先开启才能设置。
    {
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:Localized(@"pleaseOpenGesturePwdFirst") message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:nil];
        [ac addAction:ok];
        [self presentViewController:ac animated:YES completion:nil];

        return;
    }
    ///首次开启手势密码前需要先设置手势密码。因此基本不可能直接设置手势密码了。
    if ([self.gesturePwdLabel.text isEqualToString:Localized(@"setGesturePwd")])
    {
        
    }
    else
    {
        KDSGesturePwdVC *vc = [KDSGesturePwdVC new];
        vc.type = 1;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
