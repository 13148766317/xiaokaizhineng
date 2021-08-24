//
//  KDSLockSecurityModeVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/18.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSLockSecurityModeVC.h"
#import "MBProgressHUD+MJ.h"
#import "Masonry.h"

@interface KDSLockSecurityModeVC ()

///开关
@property (nonatomic, weak) UISwitch *swi;

@end

@implementation KDSLockSecurityModeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationTitleLabel.text = self.title;
    
    UIView * supView = [UIView new];
    supView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:supView];
    [supView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(55);
        make.left.right.bottom.equalTo(self.view).offset(0);
    }];
    //安全模式标签+开关按钮
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 40)];
    view.backgroundColor = UIColor.whiteColor;
    UILabel *modelLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 200, 40)];
    modelLabel.text = self.title;
    modelLabel.font = [UIFont systemFontOfSize:14];
    modelLabel.textColor = KDSRGBColor(0x89, 0x89, 0x89);
    [view addSubview:modelLabel];
    
    UISwitch *switchControl = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 26, 15)];
    switchControl.transform = CGAffineTransformMakeScale(sqrt(0.5), sqrt(0.5));
    switchControl.on = self.lock.bleTool.connectedPeripheral.isAutoMode;
    switchControl.center = CGPointMake(kScreenWidth - 33, 20);
    [switchControl addTarget:self action:@selector(switchStateDidChange:) forControlEvents:UIControlEventValueChanged];
    [view addSubview:switchControl];
    [self.view addSubview:view];
    self.swi = switchControl;
    
    //锁图片
    UIImageView *iv = [[UIImageView alloc] init];

    if ([self.lock.device.model containsString:@"X5"] || [self.lock.device.model containsString:@"X5S"]) {
        //X5
        [iv setImage:[UIImage imageNamed:@"deviceSecurityModeX5"]];
    }
    else{
        //T5
        [iv setImage:[UIImage imageNamed:@"deviceSecurityModeT5"]];

    }
    CGFloat width = kScreenHeight < 667 ? 234 * 0.9 : 234;
    CGFloat heitht = kScreenHeight < 667 ? 284 * 0.9 : 284;
    iv.frame = CGRectMake((kScreenWidth - width) / 2, CGRectGetMaxY(view.frame) + (kScreenHeight < 667 ? 10 : 30), width, heitht);
    [self.view addSubview:iv];
    
    //提示标签+提示内容。
    UILabel *tipsLabel = [[UILabel alloc] init];
    tipsLabel.text = Localized(@"securityModeSettingTips");
    tipsLabel.textAlignment = NSTextAlignmentCenter;
    tipsLabel.numberOfLines = 0;
    tipsLabel.font = [UIFont systemFontOfSize:15];
    tipsLabel.textColor = KDSRGBColor(0x44, 0x44, 0x44);
    CGRect bounds = [tipsLabel.text boundingRectWithSize:CGSizeMake(kScreenWidth - 20, kScreenHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : tipsLabel.font} context:nil];
    tipsLabel.frame = CGRectMake(10, CGRectGetMaxY(iv.frame) + (kScreenHeight < 667 ? 20 : 40), kScreenWidth - 20, ceil(bounds.size.height));
    [self.view addSubview:tipsLabel];
    UIView *tipsContentView = [self createTipsContentViewWithMode:[self.lock.device.model containsString:@"X5"] ? 0 : 1];
    tipsContentView.center = CGPointMake(kScreenWidth / 2, CGRectGetMaxY(tipsLabel.frame) + 22 + tipsContentView.bounds.size.height / 2);
    [self.view addSubview:tipsContentView];
    
    [self.lock.bleTool getLockInfo:^(KDSBleError error, KDSBleLockInfoModel * _Nullable infoModel) {
        if (infoModel)
        {
            switchControl.on = (infoModel.lockState >> 5) & 0x1;
        }
    }];
}

///根据锁类型创建一个提示内容视图，包含前面的绿竖线|+（开锁方式1+开锁方式2），返回的视图已设置bounds。mode（0: X5，1: T5)
- (UIView *)createTipsContentViewWithMode:(int)mode
{
    UIView *view = [[UIView alloc] init];
    if (mode == 0)
    {
        UILabel *pfLabel = [self createTipsLabelWithTitle:Localized(@"PIN+fingerprint")];
        UILabel *pcLabel = [self createTipsLabelWithTitle:Localized(@"PIN+card")];
        UILabel *fcLabel = [self createTipsLabelWithTitle:Localized(@"fingerprint+card")];
        
        UIView *pfLineView = [[UIView alloc] init];
        UIView *pcLineView = [[UIView alloc] init];
        UIView *fcLineView = [[UIView alloc] init];
        pfLineView.backgroundColor = pcLineView.backgroundColor = fcLineView.backgroundColor = KDSRGBColor(0x2d, 0xd9, 0xba);;
        pfLineView.layer.cornerRadius = 1;
        pcLineView.layer.cornerRadius = 1;
        fcLineView.layer.cornerRadius = 1;
        
        CGFloat width = MAX(MAX(pfLabel.bounds.size.width, pcLabel.bounds.size.width), fcLabel.bounds.size.width);
        CGFloat height = pfLabel.bounds.size.height;
        
        pfLineView.frame = (CGRect){(kScreenWidth - 2 - 11 - width) / 2, 0, 2, height};
        pfLabel.frame = (CGRect){CGRectGetMaxX(pfLineView.frame) + 11, 0, width, height};
        
        pcLineView.frame = (CGRect){(kScreenWidth - 2 - 11 - width) / 2, CGRectGetMaxY(pfLineView.frame) + height, 2, height};
        pcLabel.frame = (CGRect){CGRectGetMaxX(pcLineView.frame) + 11, CGRectGetMaxY(pfLineView.frame) + height, width, height};
        
        fcLineView.frame = (CGRect){(kScreenWidth - 2 - 11 - width) / 2, CGRectGetMaxY(pcLineView.frame) + height, 2, height};
        fcLabel.frame = (CGRect){CGRectGetMaxX(fcLineView.frame) + 11, CGRectGetMaxY(pcLineView.frame) + height, width, height};
        
        [view addSubview:pfLineView];
        [view addSubview:pfLabel];
        [view addSubview:pcLineView];
        [view addSubview:pcLabel];
        [view addSubview:fcLineView];
        [view addSubview:fcLabel];
        view.bounds = (CGRect){0, 0, kScreenWidth, height * 5};
    }
    else
    {
        UILabel *label = [self createTipsLabelWithTitle:Localized(@"PIN+fingerprint")];
        UIView *lineView = [[UIView alloc] init];
        lineView.frame = CGRectMake((kScreenWidth - 2 - 11 - label.bounds.size.width) / 2, 0, 2, label.bounds.size.height);
        lineView.layer.cornerRadius = 1;
        lineView.backgroundColor = KDSRGBColor(0x2d, 0xd9, 0xba);
        [view addSubview:lineView];
        label.frame = (CGRect){CGRectGetMaxX(lineView.frame) + 11, 0, label.bounds.size};
        [view addSubview:label];
        view.bounds = (CGRect){0, 0, kScreenWidth, label.bounds.size.height};
    }
    return view;
}

///根据内容创建一个提示内容标签，创建的标签已设置bounds。
- (UILabel *)createTipsLabelWithTitle:(NSString *)title
{
    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.textColor = KDSRGBColor(0x14, 0x14, 0x14);
    label.font = [UIFont systemFontOfSize:15];
    CGSize size = [title sizeWithAttributes:@{NSFontAttributeName : label.font}];
    label.bounds = CGRectMake(0, 0, ceil(size.width), ceil(size.height));
    return label;
}

//MARK:点击安全模式开关启动或关闭安全模式。
- (void)switchStateDidChange:(UISwitch *)sender
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.removeFromSuperViewOnHide = YES;
    __weak typeof(self) weakSelf = self;
    [weakSelf.lock.bleTool setLockSecurityModeStatus:sender.on ? 1 : 0 completion:^(KDSBleError error) {
        [hud hide:NO];
        if (error == KDSBleErrorSuccess)
        {
            weakSelf.lock.bleTool.connectedPeripheral.isAutoMode = sender.isOn;
            [MBProgressHUD showSuccess:Localized(@"setSuccess")];
        }
        else
        {
            [sender setOn:!sender.isOn animated:YES];
            [MBProgressHUD showError:Localized(@"setFailed")];
        }
    }];
}

@end
