//
//  KDSClearGesturePwdVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/3/19.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSClearGesturePwdVC.h"
#import "KDSDBManager.h"
#import "KDSHttpManager+Login.h"
#import "MBProgressHUD+MJ.h"
#import "UIView+Extension.h"

@interface KDSClearGesturePwdVC ()

///
@property (nonatomic, weak) UITextField *textField;

@end

@implementation KDSClearGesturePwdVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationTitleLabel.text = Localized(@"clearGesturePwd");
    UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(20, 20, kScreenWidth - 40, 35)];
    tf.placeholder = Localized(@"inputLoginPwd");
    tf.secureTextEntry = YES;
    tf.backgroundColor = UIColor.whiteColor;
    tf.layer.cornerRadius = 5;
    [tf addTarget:self action:@selector(textFieldTextChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:tf];
    self.textField = tf;
    
    NSString *title = Localized(@"verify");
    UIFont *font = [UIFont systemFontOfSize:15];
    UIButton *verifyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [verifyBtn setTitle:title forState:UIControlStateNormal];
    [verifyBtn setTitleColor:KDSRGBColor(0x5f, 0xd7, 0xb9) forState:UIControlStateNormal];
    verifyBtn.titleLabel.font = font;
    [verifyBtn addTarget:self action:@selector(verifyBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    CGFloat width = ceil([title sizeWithAttributes:@{NSFontAttributeName : font}].width);
    verifyBtn.frame = CGRectMake((kScreenWidth - width) / 2, CGRectGetMaxY(tf.frame) + 50, width, 35);
    [self.view addSubview:verifyBtn];
}

- (void)textFieldTextChanged:(UITextField *)sender
{
    [sender trimTextToLength:-1];
}

- (void)verifyBtnAction:(UIButton *)sender
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.removeFromSuperViewOnHide = YES;
    [[KDSHttpManager sharedManager] login:1 username:[KDSUserManager sharedManager].user.name password:self.textField.text success:^(KDSUser * _Nonnull user) {
        [hud hide:NO];
        [KDSUserManager sharedManager].user = user;
        [[KDSDBManager sharedManager] updateUser:user];
        [KDSHttpManager sharedManager].token = user.token;
        [[KDSDBManager sharedManager] updateUserGesturePwd:nil];
        NSInteger count = self.navigationController.viewControllers.count;
        if (count > 3)
        {
            [self.navigationController popToViewController:self.navigationController.viewControllers[count - 3] animated:YES];
        }
        else
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
        [MBProgressHUD showSuccess:Localized(@"clearGesturePwdSuccess")];
    } error:^(NSError * _Nonnull error) {
        [hud hide:NO];
        [MBProgressHUD showSuccess:Localized(@"clearGesturePwdFailed")];
    } failure:^(NSError * _Nonnull error) {
        [hud hide:NO];
        [MBProgressHUD showSuccess:Localized(@"clearGesturePwdFailed")];
    }];
}

@end
