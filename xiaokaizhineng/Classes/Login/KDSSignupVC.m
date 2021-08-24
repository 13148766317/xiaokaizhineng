//
//  KDSSignupVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/1/15.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSSignupVC.h"
#import "XWCountryCodeController.h"
#import "Masonry.h"
#import "NSTimer+KDSBlock.h"
#import "KDSHttpManager+Login.h"
#import "MBProgressHUD+MJ.h"
#import "KDSNavigationController.h"
#import "KDSUserAgreementVC.h"

@interface KDSSignupVC ()

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
///验证码文本框的父视图，显示白色背景、阴影和圆角。
@property (nonatomic, strong) UIView *captchaView;
///验证码文本框。
@property (nonatomic, strong) UITextField *captchaTextField;
///验证码按钮。
@property (nonatomic, strong) UIButton *captchaBtn;
///密码文本框的父视图，显示白色背景、阴影和圆角。
@property (nonatomic, strong) UIView *pwdView;
///密码文本框。
@property (nonatomic, strong) UITextField *pwdTextField;
///注册/完成按钮。
@property (nonatomic, strong) UIButton *signupOrDoneBtn;
///用户协议(诸城时显示)同意状态按钮。
@property (nonatomic, strong) UIButton *agreementStateBtn;
///用户协议(注册时显示)按钮。
@property (nonatomic, strong) UIButton *agreementBtn;
///验证码倒计时秒数。初始化时为59
@property (nonatomic, assign) NSInteger countdown;

@end

@implementation KDSSignupVC

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.type = 0;
        self.countdown = 59;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.bgIV = [[UIImageView alloc] initWithImage:[self imageWithName:@"loginBg"]];
    [self.view insertSubview:self.bgIV atIndex:0];
    [self.bgIV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.bottom.right.equalTo(self.view);
    }];
    
    UIView *navView = [[UIView alloc] init];
    navView.backgroundColor = UIColor.clearColor;
    [self.view addSubview:navView];
    [navView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(kStatusBarHeight + kNavBarHeight);
    }];
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [navView addSubview:closeBtn];
    [closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(navView).offset(kStatusBarHeight);
        make.left.equalTo(navView).offset(3);
        make.width.height.mas_equalTo(44);
    }];
    [closeBtn setImage:[UIImage imageNamed:@"loginClose"] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeBtnClickDismissController:) forControlEvents:UIControlEventTouchUpInside];
    UILabel *titleLabel = [[UILabel alloc] init];
    [navView addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(navView).offset(kStatusBarHeight);
        make.left.equalTo(closeBtn.mas_right);
        make.bottom.equalTo(navView);
        make.right.equalTo(navView).offset(-34);
    }];
    titleLabel.font = [UIFont fontWithName:@"SourceHanSansCN-Bold" size:18];
    titleLabel.textColor = KDSRGBColor(0x2b, 0x2f, 0x50);
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = self.title;
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight - kStatusBarHeight - kNavBarHeight)];
    headerView.backgroundColor = UIColor.clearColor;
    self.tableView.backgroundColor = UIColor.clearColor;
    [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(navView.mas_bottom);
        make.left.bottom.right.equalTo(self.view);
    }];
    self.tableView.tableHeaderView = headerView;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.bounces = NO;
    
    self.logoIV = [[UIImageView alloc] initWithImage:[self imageWithName:@"loginLogo"]];
    [headerView addSubview:self.logoIV];
    [self.logoIV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(headerView).offset(40);
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
    self.countryOrRegionBtn.enabled = NO;
    NSString *title = KDSTool.crc;
    if (!title)
    {
        NSLocale *locale = [NSLocale autoupdatingCurrentLocale];
        NSString *code = [locale objectForKey:NSLocaleCountryCode];
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"CRCCODE" ofType:@"plist"];
        NSDictionary *codeDict = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
        title = codeDict[code] ?: @"+86";
    }
    title = @"+86";
    [self.countryOrRegionBtn setTitle:title forState:UIControlStateNormal];
    [self.countryOrRegionBtn setTitleColor:KDSRGBColor(0xc3, 0xc4, 0xcb) forState:UIControlStateNormal];
    [self.countryOrRegionBtn addTarget:self action:@selector(clickCountryOrRegionBtnSelectCountryOrRegion:) forControlEvents:UIControlEventTouchUpInside];
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
    
    self.captchaView = [[UIView alloc] init];
    self.captchaView.backgroundColor = UIColor.whiteColor;
    self.captchaView.layer.cornerRadius = 25;
    self.captchaView.layer.shadowColor = KDSRGBColor(0xdd, 0xdd, 0xdd).CGColor;
    self.captchaView.layer.shadowOffset = CGSizeMake(3, 3);
    self.captchaView.layer.shadowOpacity = 1.0;
    self.captchaView.clipsToBounds = NO;
    [headerView addSubview:self.captchaView];
    [self.captchaView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.usernameView.mas_bottom).offset(20);
        make.left.equalTo(self.usernameView);
        make.width.mas_equalTo(205);
        make.height.mas_equalTo(50);
    }];
    self.captchaTextField = [[UITextField alloc] init];
//    self.captchaTextField.keyboardType = UIKeyboardTypeASCIICapable;
    ///验证码输入框键盘类型
    self.captchaTextField.keyboardType = UIKeyboardTypeNumberPad;
    self.captchaTextField.placeholder = Localized(@"inputCaptcha");
    [self.captchaTextField addTarget:self action:@selector(captchaTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    self.captchaTextField.font = [UIFont systemFontOfSize:14];
    UIView *captchaLv = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 18, height)];
    UIImageView *cliv = [[UIImageView alloc] initWithImage:[self imageWithName:@"loginCaptchaAccessory"]];
    cliv.frame = CGRectMake(0, (height - 15) / 2, 15, 15);
    [captchaLv addSubview:cliv];
    self.captchaTextField.leftView = captchaLv;
    self.captchaTextField.leftViewMode = UITextFieldViewModeAlways;
    [self.captchaView addSubview:self.captchaTextField];
    [self.captchaTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(self.captchaView);
        make.left.equalTo(self.captchaView).offset(27);
        make.right.equalTo(self.captchaView).offset(-27);
    }];
    
    self.captchaBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.captchaBtn.layer.masksToBounds = YES;
    self.captchaBtn.layer.cornerRadius = 25;
    self.captchaBtn.backgroundColor = KDSRGBColor(0x2d, 0xd9, 0xba);
    self.captchaBtn.layer.shadowColor = KDSRGBColor(0x53, 0xd3, 0xbc).CGColor;
    self.captchaBtn.layer.shadowOffset = CGSizeMake(3, 3);
    self.captchaBtn.layer.shadowOpacity = 1.0;
    self.captchaBtn.clipsToBounds = NO;
    self.captchaBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.captchaBtn setTitle:Localized(@"getVerificatonCode") forState:UIControlStateNormal];
    [self.captchaBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.captchaBtn addTarget:self action:@selector(clickCodeBtnGetVerificationCode:) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:self.captchaBtn];
    [self.captchaBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.captchaView);
        make.left.equalTo(self.captchaView.mas_right).offset(5);
        make.width.mas_equalTo(90);
        make.height.mas_equalTo(50);
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
        make.top.equalTo(self.captchaView.mas_bottom).offset(20);
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
    
    self.signupOrDoneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.signupOrDoneBtn.layer.masksToBounds = YES;
    self.signupOrDoneBtn.layer.cornerRadius = 30;
    self.signupOrDoneBtn.backgroundColor = KDSRGBColor(0x2d, 0xd9, 0xba);
    self.signupOrDoneBtn.layer.shadowColor = KDSRGBColor(0x53, 0xd3, 0xbc).CGColor;
    self.signupOrDoneBtn.layer.shadowOffset = CGSizeMake(3, 3);
    self.signupOrDoneBtn.layer.shadowOpacity = 1.0;
    self.signupOrDoneBtn.clipsToBounds = NO;
    [self.signupOrDoneBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.signupOrDoneBtn setTitle:self.type ? Localized(@"done") : Localized(@"signUp") forState:UIControlStateNormal];
    [self.signupOrDoneBtn addTarget:self action:@selector(clickSignupOrDoneBtnSignupOrResetPwd:) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:self.signupOrDoneBtn];
    [self.signupOrDoneBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.pwdView.mas_bottom).offset(50);
        make.left.right.equalTo(self.pwdView);
        make.height.mas_equalTo(60);
    }];
    
    if (@available(iOS 12.0, *))
    {
        self.usernameTextField.textContentType = nil;
        self.captchaTextField.textContentType = UITextContentTypeOneTimeCode;
        self.pwdTextField.textContentType = nil;
    }
    
    if (self.type == 0)
    {
        NSString *agreement = Localized(@"agreement");
        UIFont *font = [UIFont systemFontOfSize:12];
        CGFloat width = ceil([agreement sizeWithAttributes:@{NSFontAttributeName : font}].width);
        self.agreementStateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.agreementStateBtn addTarget:self action:@selector(agreementStateBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.agreementStateBtn setImage:[self imageWithName:@"loginAgreement"] forState:UIControlStateNormal];
        [self.agreementStateBtn setImage:[self imageWithName:@"loginNoAgreement"] forState:UIControlStateSelected];
        [headerView addSubview:self.agreementStateBtn];
        [self.agreementStateBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.signupOrDoneBtn.mas_bottom).offset(22);
            make.left.equalTo(self.view).offset((kScreenWidth - 15 - 5 - width) / 2);
            make.width.height.mas_equalTo(15);
        }];
        self.agreementBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.agreementBtn.titleLabel.font = font;
        [self.agreementBtn setTitle:agreement forState:UIControlStateNormal];
        [self.agreementBtn setTitleColor:KDSRGBColor(0xb0, 0xb0, 0xb0) forState:UIControlStateNormal];
        [self.agreementBtn addTarget:self action:@selector(clickAgreementBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [headerView addSubview:self.agreementBtn];
        [self.agreementBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self.agreementStateBtn);
            make.left.equalTo(self.agreementStateBtn.mas_right).offset(5);
            make.width.mas_equalTo(width);
        }];
    }
}

#pragma mark - 控件等事件
///点击关闭按钮dismiss控制器。
- (void)closeBtnClickDismissController:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

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

///点击获取验证码按钮调用获取验证码接口
- (void)clickCodeBtnGetVerificationCode:(UIButton *)sender
{
    
    if (self.usernameTextField.text.length == 0)
    {
        [MBProgressHUD showError:Localized(@"usernameCan'tBeNull")];
        return;
    }
    if (![[KDSUserManager sharedManager] netWorkIsAvailable]) {
        [MBProgressHUD showError:@"似乎已断开与互联网的连接"];
        return;
    }
    NSArray<NSString *> *comps = [self.countryOrRegionBtn.currentTitle componentsSeparatedByString:@"+"];
    NSString *username = self.usernameTextField.text;
    /*if ([KDSTool isValidateEmail:username])
    {
        [[KDSHttpManager sharedManager] getCaptchaWithEmail:username success:^{
            [MBProgressHUD showSuccess:Localized(@"captchaSendSuccess")];
        } error:^(NSError * _Nonnull error) {
            if (error.code == 704)
            {
                [MBProgressHUD showError:@"getCaptchaTooOfter"];
            }
            else
            {
                [MBProgressHUD showError:[NSString stringWithFormat:@"error: %ld", (long)error.code]];
            }
        } failure:^(NSError * _Nonnull error) {
            [MBProgressHUD showError:error.localizedDescription];
        }];
    }
    else */
    if (comps.lastObject.intValue != 86 || [KDSTool isValidatePhoneNumber:username])
    {
        [[KDSHttpManager sharedManager] getCaptchaWithTel:username crc:comps.lastObject success:^{
            [MBProgressHUD showSuccess:Localized(@"captchaSendSuccess")];
        } error:^(NSError * _Nonnull error) {
            //服务器返回的说明
            [MBProgressHUD showError:[NSString stringWithFormat:@"error: %@", error.localizedDescription]];
//            [MBProgressHUD showError:[NSString stringWithFormat:@"error: %ld", (long)error.localizedDescription]];
        } failure:^(NSError * _Nonnull error) {
            KDSLog(@"--{Kaadas}--22==%ld",(long)error.localizedDescription);
            [MBProgressHUD showError:error.localizedDescription];
        }];
    }
    else
    {
        [MBProgressHUD showError:Localized(@"inputValidEmailOrPhoneNumber")];
        return;
    }
    sender.enabled = NO;
    __weak typeof(self) weakSelf = self;
    NSTimer *timer = [NSTimer kdsScheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (weakSelf.countdown < 0 || !weakSelf)
        {
            [timer invalidate];
            weakSelf.countdown = 59;
            sender.enabled = YES;
            return;
        }
        [sender setTitle:[NSString stringWithFormat:@"%lds", (long)weakSelf.countdown] forState:UIControlStateDisabled];
        weakSelf.countdown--;
//        NSLog(@"--{Kaadas}--countdown=%ld",(long)weakSelf.countdown);
    }];
    [timer fire];
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
///验证码输入框约束
- (void)captchaTextFieldDidChange:(UITextField *)sender
{
    if (sender.text.length > 6)
    {
        sender.text = [sender.text substringToIndex:6];
    }
}
//MARK:点击注册按钮调用注册接口，如果是忘记密码调用忘记密码接口重置密码。
- (void)clickSignupOrDoneBtnSignupOrResetPwd:(UIButton *)sender
{
    if (self.type == 0 && self.agreementStateBtn.selected){
        [MBProgressHUD showError:@"请同意用户协议"];
        return;
    }
    
    ///用户名为空
    if (self.usernameTextField.text.length == 0)
    {
        [MBProgressHUD showError:Localized(@"usernameCan'tBeNull")];
        return;
    }
    
    NSString *captcha = [self.captchaTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//    NSString *expr = @"^\\d+$";
     NSString *expr = @"^\\d{6}$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", expr];
    ///验证码错误
    if (![predicate evaluateWithObject:captcha])
    {
        [MBProgressHUD showError:Localized(@"inputValidCaptcha")];
        return;
    }
    ///非6-16位数字+字母
    if (![KDSTool isValidPassword:self.pwdTextField.text])
    {
        [MBProgressHUD showError:Localized(@"requireValidPwd")];
        return;
    }
    
    NSString *username = [self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray<NSString *> *comps = [self.countryOrRegionBtn.currentTitle componentsSeparatedByString:@"+"];
    int source = 1;
    ///用户名是否是邮箱，source=2代表邮箱，source=1代表手机号码
    if ([KDSTool isValidateEmail:username])
    {
        source = 2;
    }
    ///手机号码是否是中国区的号码
    else if (comps.lastObject.intValue != 86 || [KDSTool isValidatePhoneNumber:self.usernameTextField.text])
    {
        username = [comps.lastObject stringByAppendingString:username];
    }
    else
    {
        [MBProgressHUD showError:Localized(@"inputValidEmailOrPhoneNumber")];
        return;
    }
    NSString *msg = self.type ? Localized(@"requestingResetPwd") : Localized(@"signingup");
    MBProgressHUD *hud = [MBProgressHUD showMessage:msg toView:self.view];
//    NSLog(@"comps==%@",comps);
    if (self.type == 0)///注册
    {
        [[KDSHttpManager sharedManager] signup:source username:username captcha:captcha password:self.pwdTextField.text success:^{
            [hud hide:YES];
            [MBProgressHUD showSuccess:Localized(@"signupSuccess")];
            [self dismissViewControllerAnimated:YES completion:^{
                !self.signupSuccess ?: self.signupSuccess(self.countryOrRegionBtn.currentTitle , source==2 ? username : [username substringFromIndex:comps.lastObject.length], self.pwdTextField.text);
            }];
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
    else///找回密码
    {
        [[KDSHttpManager sharedManager] forgotPwd:source name:username captcha:captcha newPwd:self.pwdTextField.text success:^{
            [hud hide:YES];
            [MBProgressHUD showSuccess:Localized(@"resetPwdSuccess")];
            [self dismissViewControllerAnimated:YES completion:nil];
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
}

///点击同意/不同意协议
- (void)agreementStateBtnAction:(UIButton *)sender
{
    sender.selected = !sender.selected;
}

///点击用户协议按钮，跳转用户协议界面。
- (void)clickAgreementBtnAction:(UIButton *)sender
{
    KDSUserAgreementVC *vc = [KDSUserAgreementVC new];
    [self.navigationController pushViewController:vc animated:YES];
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
