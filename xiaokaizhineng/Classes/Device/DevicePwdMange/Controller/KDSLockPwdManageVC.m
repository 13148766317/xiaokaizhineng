//
//  KDSLockPwdManageVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/15.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSLockPwdManageVC.h"
#import "KDSMoreSettingAlterMgrPwdVC.h"

@interface KDSLockPwdManageVC ()

@end

@implementation KDSLockPwdManageVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationTitleLabel.text = Localized(@"managePwd");
    UILabel *tipsLabel = [[UILabel alloc] init];
    tipsLabel.numberOfLines = 0;
    UIFont *font = [UIFont systemFontOfSize:12];
    tipsLabel.font = font;
    ///FIXME:managePwdTips这个本地化请使用英文的:冒号分隔"提示"2字(包括其它文字的也要这样)。
    NSString *tips = Localized(@"managePwdTips");
    NSArray<NSString *> *tipsComp = [tips componentsSeparatedByString:@":"];
    NSMutableAttributedString *attriStr = [[NSMutableAttributedString alloc] initWithString:tips attributes:@{NSForegroundColorAttributeName : KDSRGBColor(0xc2, 0xc2, 0xc2)}];
    [attriStr addAttribute:NSForegroundColorAttributeName value:KDSRGBColor(0x2d, 0xd9, 0xba) range:NSMakeRange(0, tipsComp.firstObject.length)];
    [attriStr addAttribute:NSForegroundColorAttributeName value:KDSRGBColor(0x2d, 0xd9, 0xba) range:[tips rangeOfString:@"12345678"]];
    tipsLabel.attributedText = attriStr;
    CGFloat height = ceil([tips sizeWithAttributes:@{NSFontAttributeName : font}].height);
    tipsLabel.frame = CGRectMake(10, 15, kScreenWidth - 20, height);
    [self.view addSubview:tipsLabel];
    
    UIView *cornerView = [[UIView alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(tipsLabel.frame) + 15, kScreenWidth - 20, 60)];
    cornerView.layer.cornerRadius = 5;
    cornerView.backgroundColor = UIColor.whiteColor;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToJumpToAlterManagementPassword:)];
    [cornerView addGestureRecognizer:tap];
    [self.view addSubview:cornerView];
    
    UILabel *alterPwdLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, kScreenWidth - 35, 60)];
    alterPwdLabel.font = font;
    alterPwdLabel.textColor = KDSRGBColor(0x2b, 0x2f, 0x50);
    alterPwdLabel.text = Localized(@"alterManagementPwd");
    [cornerView addSubview:alterPwdLabel];
    
    UIImage *arrow = [UIImage imageNamed:@"right"];
    UIImageView *arrowIV = [[UIImageView alloc] initWithImage:arrow];
    arrowIV.bounds = (CGRect){0, 0, arrow.size};
    arrowIV.center = (CGPoint){cornerView.bounds.size.width - 13 - arrow.size.width / 2, 30};
    [cornerView addSubview:arrowIV];
}

///点击跳转修改密码页面。
- (void)tapToJumpToAlterManagementPassword:(UITapGestureRecognizer *)sender
{
    KDSMoreSettingAlterMgrPwdVC *vc = [KDSMoreSettingAlterMgrPwdVC new];
    vc.lock = self.lock;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
