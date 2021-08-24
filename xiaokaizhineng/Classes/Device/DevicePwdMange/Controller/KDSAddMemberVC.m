//
//  KDSAddMemberVC.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/18.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSAddMemberVC.h"
#import "XWCountryCodeController.h"
#import "MBProgressHUD+MJ.h"
#import "KDSHttpManager+User.h"
#import "Masonry.h"

@interface KDSAddMemberVC ()
@property (weak, nonatomic) IBOutlet UIView *numberView;
///国家/区域电话代码按钮。
@property (weak, nonatomic) IBOutlet UIButton *crcBtn;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIImageView *tipsIV;
@property (weak, nonatomic) IBOutlet UILabel *tipsLabel;
@property (weak, nonatomic) IBOutlet UIButton *okBtn;

@end

@implementation KDSAddMemberVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationTitleLabel.text = Localized(@"addMember");
    self.textField.placeholder = Localized(@"inputOne'sPhoneNumberOrEmailAccount");
    [self.textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    ///手机号码输入框键盘类型
    self.textField.keyboardType = UIKeyboardTypeNumberPad;
    [self.okBtn setTitle:Localized(@"ok") forState:UIControlStateNormal];
    [self setUI];
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
    [self.crcBtn setTitle:title forState:UIControlStateNormal];
    self.crcBtn.enabled = NO;
    NSString *tips = Localized(@"memberAuthTips");
    self.tipsLabel.text = tips;
    NSDictionary *attr = @{NSFontAttributeName : self.tipsLabel.font};
    CGSize size = [tips sizeWithAttributes:attr];
    if (size.width > kScreenWidth - 40 - self.tipsIV.image.size.width - 5)
    {
        size = [tips boundingRectWithSize:CGSizeMake(kScreenWidth - 80, ceil(size.height) * 2) options:NSStringDrawingUsesLineFragmentOrigin attributes:attr context:nil].size;
        
    }
    [self.tipsLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.numberView.mas_bottom).offset(11);
        make.centerX.equalTo(self.view).offset((self.tipsIV.image.size.width + 5) / 2.0);
        make.size.mas_equalTo((CGSize){ceil(size.width), ceil(size.height)});
    }];
    [self.tipsIV mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.tipsLabel);
        make.right.equalTo(self.tipsLabel.mas_left).offset(-5);
        make.size.mas_equalTo(self.tipsIV.image.size);
    }];
}

-(void)setUI{
    self.numberView.layer.shadowColor = KDSRGBColor(0xdd, 0xdd, 0xdd).CGColor;
    self.numberView.layer.shadowOffset = CGSizeMake(3, 3);
    self.numberView.layer.shadowOpacity = 1.0;
    self.numberView.clipsToBounds = NO;
    
}
-(void)textFieldDidChange:(UITextField *)sender
{
    if (sender.text.length > 11)
    {
        sender.text = [sender.text substringToIndex:11];
    }
}
#pragma mark - 控件等事件方法。
- (IBAction)saveClick:(id)sender {
    
    NSString *username = self.textField.text;
    NSArray<NSString *> *comps = [self.crcBtn.currentTitle componentsSeparatedByString:@"+"];
    ///如果用户名是邮箱地址
    /*if ([KDSTool isValidateEmail:username])
    {
        
    }
    ///如果用户名是中国区手机号码
    else */if (comps.lastObject.intValue != 86 || [KDSTool isValidatePhoneNumber:self.textField.text])
    {
        username = [comps.lastObject stringByAppendingString:username];
    }
    else///不是邮箱且不是手机号码
    {
        [MBProgressHUD showError:Localized(@"inputValidEmailOrPhoneNumber")];
        return;
    }
    ///如果输入的手机号码或者邮箱是本人的则提示不能添加自己
    if ([username isEqualToString:[KDSUserManager sharedManager].user.name])
    {
        [MBProgressHUD showError:Localized(@"can'tAddSelf")];
        return;
    }
    KDSAuthMember *member = [KDSAuthMember new];
    member.jurisdiction = @"3";
    member.beginDate = @"2000-01-01 00:00:00";
    member.endDate = @"2099-01-01 00:00:00";
    member.uname = username;
    member.adminname = [KDSUserManager sharedManager].user.name;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.removeFromSuperViewOnHide = YES;
    [[KDSHttpManager sharedManager] addAuthorizedUser:member withUid:[KDSUserManager sharedManager].user.uid device:self.lock.device success:^{
        [hud hide:NO];
        [MBProgressHUD showSuccess:Localized(@"addSuccess")];
        !self.memberDidAddBlock ?: self.memberDidAddBlock(member);
        [self.navigationController popViewControllerAnimated:YES];
    } error:^(NSError * _Nonnull error) {
        [hud hide:NO];
        [MBProgressHUD showError:error.localizedDescription];
    } failure:^(NSError * _Nonnull error) {
        [hud hide:NO];
        [MBProgressHUD showError:error.localizedDescription];
    }];
}

///点击国家/区域码按钮选择国家/区域码。
- (IBAction)crcBtnClickSelectCode:(UIButton *)sender
{
    XWCountryCodeController *countryCodeVC = [[XWCountryCodeController alloc] init];
    countryCodeVC.returnCountryCodeBlock = ^(NSString *countryCodeStr) {
        NSArray<NSString *> *comps = [countryCodeStr componentsSeparatedByString:@"+"];
        [self.crcBtn setTitle:[@"+" stringByAppendingString:comps.lastObject] forState:UIControlStateNormal];
    };
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:countryCodeVC];
    [self presentViewController:navi animated:YES completion:nil];
}

///被授权的账号限制输入长度
- (IBAction)textFieldTextDidChange:(UITextField *)sender
{
    if (sender.text.length > 25)
    {
        sender.text = [sender.text substringToIndex:25];
    }
}


@end
