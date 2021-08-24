//
//  KDSModifyNicknameVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/22.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSModifyNicknameVC.h"
#import "KDSDBManager.h"
#import "KDSHttpManager+User.h"
#import "MBProgressHUD+MJ.h"

@interface KDSModifyNicknameVC ()

///输入新昵称的文本框。
@property (nonatomic, weak) UITextField *nicknameTF;
///保存按钮。
@property (nonatomic, strong) UIButton *saveBtn;
///记录输入框设备名字的上一次名字
@property (nonatomic,copy)NSString  *lastDeviceInputeName;

@end

@implementation KDSModifyNicknameVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationTitleLabel.text = Localized(@"modifyNickname");
    CGFloat height = 60;
    UIView *cornerView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, kScreenWidth - 20, height)];
    cornerView.backgroundColor = UIColor.whiteColor;
    cornerView.layer.cornerRadius = 5;
    [self.view addSubview:cornerView];
    
    UIFont *font = [UIFont systemFontOfSize:12];
    NSString *nickname = Localized(@"nickname");
    UILabel *nicknameLabel = [[UILabel alloc] initWithFrame:CGRectMake(13, 0, ceil([nickname sizeWithAttributes:@{NSFontAttributeName : font}].width), height)];
    nicknameLabel.text = nickname;
    nicknameLabel.font = font;
    nicknameLabel.textColor = KDSRGBColor(0x2b, 0x2f, 0x50);
    [cornerView addSubview:nicknameLabel];
    
    UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(nicknameLabel.frame) + 14, 0, CGRectGetWidth(cornerView.bounds) - CGRectGetMaxX(nicknameLabel.frame) - 14 - 8, height)];
    tf.font = [UIFont systemFontOfSize:14];
    tf.placeholder = Localized(@"inputNewNickname");//[KDSUserManager sharedManager].user.name;
    tf.clearButtonMode = UITextFieldViewModeWhileEditing;
    [tf addTarget:self action:@selector(textFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
    [cornerView addSubview:tf];
    self.nicknameTF = tf;
    
    self.saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.saveBtn setTitle:Localized(@"save") forState:UIControlStateNormal];
    [self.saveBtn setTitle:Localized(@"save") forState:UIControlStateHighlighted];
    [self.saveBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.saveBtn setTitleColor:UIColor.lightTextColor forState:UIControlStateDisabled];
    self.saveBtn.backgroundColor = KDSRGBColor(0x2d, 0xd9, 0xba);
    self.saveBtn.layer.cornerRadius = height / 2;
    self.saveBtn.enabled = NO;
    self.saveBtn.layer.shadowColor = [UIColor colorWithRed:0x53/255.0 green:0xd3/255.0 blue:0xbc/255.0 alpha:0.5].CGColor;
    self.saveBtn.layer.shadowOffset = CGSizeMake(3, 3);
    self.saveBtn.layer.shadowOpacity = 1;
    [self.saveBtn addTarget:self action:@selector(saveBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    self.saveBtn.bounds = CGRectMake(0, 0, kScreenWidth < 375 ? (kScreenWidth - 76) : 300, height);
    [self.view addSubview:self.saveBtn];
}

- (void)viewWillLayoutSubviews
{
    self.saveBtn.center = CGPointMake(kScreenWidth / 2, self.view.bounds.size.height - 164 - self.saveBtn.bounds.size.height / 2);
}

///个人信息昵称文本框文字改变后，限制长度不超过16。
- (void)textFieldTextDidChange:(UITextField *)sender
{
    NSData *data = [KDSTool getTranscodingStringDataWithString:sender.text];
    if ([data length] > 16) {
        sender.text = self.lastDeviceInputeName;
    }else{
        self.lastDeviceInputeName = sender.text;
    }
    self.saveBtn.enabled = sender.text.length != 0;
}

///点击保存按钮，保存新昵称。
- (void)saveBtnAction:(UIButton *)sender
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.removeFromSuperViewOnHide = YES;
    [[KDSHttpManager sharedManager] setUserNickname:self.nicknameTF.text withUid:[KDSUserManager sharedManager].user.uid success:^{
        [[KDSDBManager sharedManager] updateUserNickname:self.nicknameTF.text];
        [KDSUserManager sharedManager].userNickname = self.nicknameTF.text;
        [hud hide:YES];
        [self.navigationController popViewControllerAnimated:YES];
        [MBProgressHUD showSuccess:Localized(@"modifyNicknameSuccess")];
    } error:^(NSError * _Nonnull error) {
        [hud hide:YES];
        [MBProgressHUD showError:[Localized(@"modifyNicknameFailed") stringByAppendingFormat:@": %ld", (long)error.localizedDescription]];
    } failure:^(NSError * _Nonnull error) {
        [hud hide:YES];
        [MBProgressHUD showError:[Localized(@"modifyNicknameFailed") stringByAppendingFormat:@"，%@", error.localizedDescription]];
    }];
}

@end
