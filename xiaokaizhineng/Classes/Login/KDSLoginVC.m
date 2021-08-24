//
//  KDSLoginVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/1/15.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSLoginVC.h"
#import "Masonry.h"
#import "XWCountryCodeController.h"
#import "KDSSignupVC.h"
#import "KDSTabBarController.h"
#import "KDSHttpManager+Login.h"
#import "MBProgressHUD+MJ.h"
#import "KDSDBManager.h"
#import "KDSNavigationController.h"

@interface KDSLoginVC ()

///背景图片视图。
@property (nonatomic, strong) UIImageView *bgIV;
///凯迪仕logo视图
@property (nonatomic, strong) UIImageView *logoIV;
///用户名文本框的父视图，显示白色背景、阴影和圆角。
@property (nonatomic, strong) UIView *usernameView;
///选择和显示国家/地区按钮
@property (nonatomic, strong) UIButton *countryOrRegionBtn;
///用户名文本框。
@property (nonatomic, strong) UITextField *usernameTextField;
///密码文本框的父视图，显示白色背景、阴影和圆角。
@property (nonatomic, strong) UIView *pwdView;
///密码文本框。
@property (nonatomic, strong) UITextField *pwdTextField;
///登录按钮。
@property (nonatomic, strong) UIButton *loginBtn;
///注册按钮。
@property (nonatomic, strong) UIButton *signupBtn;
///忘记密码按钮。
@property (nonatomic, strong) UIButton *forgotBtn;

@end

@implementation KDSLoginVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.bgIV = [[UIImageView alloc] initWithImage:[self imageWithName:@"loginBg"]];
    [self.view insertSubview:self.bgIV atIndex:0];
    [self.bgIV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(self.view);
    }];
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
    headerView.backgroundColor = UIColor.clearColor;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.tableHeaderView = headerView;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.bounces = NO;
    
    self.logoIV = [[UIImageView alloc] initWithImage:[self imageWithName:@"loginLogo"]];
    [headerView addSubview:self.logoIV];
    [self.logoIV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(headerView).offset(104);
        make.centerX.equalTo(headerView);
        make.width.mas_equalTo(200);
        make.height.mas_equalTo(19);
    }];
    
    self.usernameView = [[UIView alloc] init];
    self.usernameView.backgroundColor = UIColor.whiteColor;
    self.usernameView.layer.cornerRadius = 25;
    self.usernameView.layer.shadowColor = KDSRGBColor(0xdd, 0xdd, 0xdd).CGColor;
    self.usernameView.layer.shadowOffset = CGSizeMake(3, 3);
    self.usernameView.layer.shadowOpacity = 1.0;
    self.usernameView.clipsToBounds = NO;
    [headerView addSubview:self.usernameView];
    [self.usernameView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.logoIV.mas_bottom).offset(80);
        make.centerX.equalTo(headerView);
        make.width.mas_equalTo(300);
        make.height.mas_equalTo(50);
    }];
    self.usernameTextField = [[UITextField alloc] init];
    self.usernameTextField.placeholder = Localized(@"inputPhoneNumberOrEMail");
    [self.usernameTextField addTarget:self action:@selector(usernameTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    self.usernameTextField.font = [UIFont systemFontOfSize:14];
    self.usernameTextField.keyboardType = UIKeyboardTypeNumberPad;
    CGFloat height = 50.0;
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 63, height)];
    UIImageView *leftIV = [[UIImageView alloc] initWithImage:[self imageWithName:@"loginUsernameAccessory"]];
    leftIV.frame = CGRectMake(0, (height - 15) / 2.0, 15, 15);
    [leftView addSubview:leftIV];
    self.countryOrRegionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.countryOrRegionBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    NSString *title = KDSTool.crc;
    if (!title)
    {
        NSLocale *locale = [NSLocale autoupdatingCurrentLocale];
        NSString *code = [locale objectForKey:NSLocaleCountryCode];
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"CRCCODE" ofType:@"plist"];
        NSDictionary *codeDict = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
        title = codeDict[code] ?: @"+86";
    }
    else
    {
        title = [@"+" stringByAppendingString:title];
    }
    title = @"+86";
    [self.countryOrRegionBtn setTitle:title forState:UIControlStateNormal];
    [self.countryOrRegionBtn setTitleColor:KDSRGBColor(0xc3, 0xc4, 0xcb) forState:UIControlStateNormal];
    [self.countryOrRegionBtn addTarget:self action:@selector(clickCountryOrRegionBtnSelectCountryOrRegion:) forControlEvents:UIControlEventTouchUpInside];
    self.countryOrRegionBtn.enabled = NO;
    self.countryOrRegionBtn.frame = CGRectMake(CGRectGetMaxX(leftIV.frame), 0, 43, height);
    [leftView addSubview:self.countryOrRegionBtn];
    //竖线
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.countryOrRegionBtn.frame), 10, 1, height - 10 * 2)];
    lineView.backgroundColor = KDSRGBColor(0xec, 0xec, 0xec);
    [leftView addSubview:lineView];
    self.usernameTextField.leftView = leftView;
    self.usernameTextField.leftViewMode = UITextFieldViewModeAlways;
    [self.usernameView addSubview:self.usernameTextField];
    [self.usernameTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self.usernameView);
        make.left.equalTo(self.usernameView).offset(27);
        make.right.equalTo(self.usernameView).offset(-27);
    }];
    
    self.pwdView = [[UIView alloc] init];
    self.pwdView.backgroundColor = UIColor.whiteColor;
    self.pwdView.layer.cornerRadius = 25;
    self.pwdView.layer.shadowColor = KDSRGBColor(0xdd, 0xdd, 0xdd).CGColor;
    self.pwdView.layer.shadowOffset = CGSizeMake(3, 3);
    self.pwdView.layer.shadowOpacity = 1.0;
    self.pwdView.clipsToBounds = NO;
    [headerView addSubview:self.pwdView];
    [self.pwdView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.usernameView.mas_bottom).offset(20);
        make.centerX.equalTo(headerView);
        make.width.mas_equalTo(300);
        make.height.mas_equalTo(50);
    }];
    self.pwdTextField = [[UITextField alloc] init];
    self.pwdTextField.placeholder = Localized(@"inputPassword");
    [self.pwdTextField addTarget:self action:@selector(pwdTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    self.pwdTextField.font = [UIFont systemFontOfSize:14];
    self.pwdTextField.keyboardType = UIKeyboardTypeASCIICapable;
    self.pwdTextField.secureTextEntry = YES;
    UIView *lv = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 18, height)];
    UIImageView *liv = [[UIImageView alloc] initWithImage:[self imageWithName:@"loginPwdLeftAccessory"]];
    liv.frame = CGRectMake(0, (height - 15) / 2, 15, 15);
    liv.contentMode = UIViewContentModeScaleAspectFit;
    [lv addSubview:liv];
    self.pwdTextField.leftView = lv;
    self.pwdTextField.leftViewMode = UITextFieldViewModeAlways;
    UIView *rv = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, height)];
    UIButton *rBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, (height - 10) / 2, 16, 10)];
    [rBtn setImage:[self imageWithName:@"loginPwdRightAccessoryNormal"] forState:UIControlStateNormal];
    [rBtn setImage:[self imageWithName:@"loginPwdRightAccessorySelected"] forState:UIControlStateSelected];
    [rBtn addTarget:self action:@selector(showOrHidePwd:) forControlEvents:UIControlEventTouchUpInside];
    [rv addSubview:rBtn];
    self.pwdTextField.rightView = rv;
    self.pwdTextField.rightViewMode = UITextFieldViewModeAlways;
    [self.pwdView addSubview:self.pwdTextField];
    [self.pwdTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self.pwdView);
        make.left.equalTo(self.pwdView).offset(27);
        make.right.equalTo(self.pwdView).offset(-27);
    }];
    
    self.loginBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.loginBtn.layer.cornerRadius = 30;
    self.loginBtn.layer.shadowColor = KDSRGBColor(0x53, 0xd3, 0xbc).CGColor;
    self.loginBtn.layer.shadowOffset = CGSizeMake(3, 3);
    self.loginBtn.layer.shadowOpacity = 1.0;
    self.loginBtn.clipsToBounds = NO;
    [self.loginBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.loginBtn.backgroundColor = KDSRGBColor(0x2d, 0xd9, 0xba);
    self.loginBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.loginBtn setTitle:Localized(@"signIn") forState:UIControlStateNormal];
    [self.loginBtn addTarget:self action:@selector(loginBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:self.loginBtn];
    [self.loginBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.pwdView.mas_bottom).offset(50);
        make.left.right.equalTo(self.pwdView);
        make.height.mas_equalTo(60);
    }];
    
    self.signupBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.signupBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.signupBtn setTitle:Localized(@"signUp") forState:UIControlStateNormal];
    [self.signupBtn setTitleColor:KDSRGBColor(0x2b, 0x2f, 0x50) forState:UIControlStateNormal];
    [self.signupBtn addTarget:self action:@selector(clickSignupBtnSignup:) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:self.signupBtn];
    [self.signupBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.loginBtn.mas_bottom).offset(15);
        make.left.equalTo(self.loginBtn.mas_left).offset(22);
        make.width.mas_lessThanOrEqualTo(80);
        make.height.mas_equalTo(20);
    }];
    
    self.forgotBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.forgotBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.forgotBtn setTitle:Localized(@"forgotPassword") forState:UIControlStateNormal];
    [self.forgotBtn setTitleColor:KDSRGBColor(0x2b, 0x2f, 0x50) forState:UIControlStateNormal];
    [self.forgotBtn addTarget:self action:@selector(clickForgotBtnRetrievePwd:) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:self.forgotBtn];
    [self.forgotBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self.signupBtn);
        make.right.equalTo(self.loginBtn.mas_right).offset(-22);
        make.width.mas_lessThanOrEqualTo(200);
    }];
    
    NSArray<NSString *> *comps = [self.countryOrRegionBtn.currentTitle componentsSeparatedByString:@"+"];
    NSString *account = [KDSTool getDefaultLoginAccount];
    if (comps.lastObject && [account hasPrefix:comps.lastObject])
    {
        account = [account substringFromIndex:comps.lastObject.length];
    }
    self.usernameTextField.text = account;
}

#pragma mark - 控件等事件
///点击国家/地区按钮选择国家/地区
- (void)clickCountryOrRegionBtnSelectCountryOrRegion:(UIButton *)sender
{
    XWCountryCodeController *countryCodeVC = [[XWCountryCodeController alloc] init];
    countryCodeVC.returnCountryCodeBlock = ^(NSString *countryCodeStr) {
        NSArray<NSString *> *comps = [countryCodeStr componentsSeparatedByString:@"+"];
        [self.countryOrRegionBtn setTitle:[@"+" stringByAppendingString:comps.lastObject] forState:UIControlStateNormal];
    };
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:countryCodeVC];
    [self presentViewController:navi animated:YES completion:nil];
}

///点击密码输入框右边的按钮显示/隐藏密码
- (void)showOrHidePwd:(UIButton *)sender
{
    sender.selected = !sender.selected;
    self.pwdTextField.secureTextEntry = !sender.selected;
}
///同时支持数字、字母大小写6-12的密码
- (void)pwdTextFieldDidChange:(UITextField *)sender
{
    if (sender.text.length > 12)
    {
        sender.text = [sender.text substringToIndex:12];
    }
}
///手机号码作为用户名
- (void)usernameTextFieldDidChange:(UITextField *)sender
{
    if (sender.text.length > 11)
    {
        sender.text = [sender.text substringToIndex:11];
    }
}
///点击登录按钮登录。
- (void)loginBtnAction:(UIButton *)sender
{
    if (self.usernameTextField.text.length == 0)
    {
        [MBProgressHUD showError:Localized(@"usernameCan'tBeNull")];
        return;
    }
    
    if (![KDSTool isValidPassword:self.pwdTextField.text])
    {
        [MBProgressHUD showError:Localized(@"requireValidPwd")];
        return;
    }
    int source = 1;
    NSString *username = self.usernameTextField.text;
    NSArray<NSString *> *comps = [self.countryOrRegionBtn.currentTitle componentsSeparatedByString:@"+"];
    /*if ([KDSTool isValidateEmail:username])
    {
        source = 2;
    }
    else */if (comps.lastObject.intValue != 86 || [KDSTool isValidatePhoneNumber:self.usernameTextField.text])
    {
        username = [comps.lastObject stringByAppendingString:username];
    }
    else
    {
        [MBProgressHUD showError:Localized(@"inputValidEmailOrPhoneNumber")];
        return;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showMessage:Localized(@"logining") toView:self.view];
    [[KDSHttpManager sharedManager] login:source username:username password:self.pwdTextField.text success:^(KDSUser * _Nonnull user) {
        NSString *account = [KDSTool getDefaultLoginAccount];
        if (![account isEqualToString:username])
        {
            [[KDSDBManager sharedManager] resetDatabase];
        }
        [KDSTool setDefaultLoginAccount:username];
        KDSTool.crc = comps.lastObject;
        [KDSUserManager sharedManager].user = user;
        [[KDSDBManager sharedManager] updateUser:user];
        [KDSUserManager sharedManager].userNickname = [[KDSDBManager sharedManager] queryUserNickname];
        [KDSHttpManager sharedManager].token = user.token;
        [hud hide:YES];
        KDSTabBarController *tab = [KDSTabBarController new];
        [UIApplication sharedApplication].keyWindow.rootViewController = tab;
    } error:^(NSError * _Nonnull error) {

        [hud hide:YES];
        NSString *msg;
        msg = error.localizedDescription;
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:Localized(@"tips") message:msg preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:nil];
        [ac addAction:action];
        [self presentViewController:ac animated:YES completion:nil];

    } failure:^(NSError * _Nonnull error) {
        [hud hide:YES];
        [MBProgressHUD showError:error.localizedDescription];
    }];
}

///点击注册按钮跳转注册页面
- (void)clickSignupBtnSignup:(UIButton *)sender
{
    KDSSignupVC *vc = [KDSSignupVC new];
    vc.title = sender.currentTitle;
    vc.signupSuccess = ^(NSString * _Nullable crc, NSString * _Nonnull username, NSString * _Nonnull password) {
        if ([KDSTool getDefaultLoginAccount].length == 0)
        {
            [self.countryOrRegionBtn setTitle:crc forState:UIControlStateNormal];
            self.usernameTextField.text = username;
            self.pwdTextField.text = password;
        }
    };
    KDSNavigationController *nav = [[KDSNavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

///点击忘记密码按钮找回密码
- (void)clickForgotBtnRetrievePwd:(UIButton *)sender
{
    KDSSignupVC *vc = [KDSSignupVC new];
    vc.type = 1;
    vc.title = sender.currentTitle;
    [self presentViewController:vc animated:YES completion:nil];
}
                                                   
#pragma mark - 其它方法
/**
 *@abstract 根据图片名称在main bundle中创建UIImage.
 *@param name 图片名称，不带png后缀。
 *@return image。
 */
- (UIImage *)imageWithName:(NSString *)name
{
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"png"];
    UIImage *img = [[UIImage alloc] initWithContentsOfFile:path];
    return img;
}

@end
