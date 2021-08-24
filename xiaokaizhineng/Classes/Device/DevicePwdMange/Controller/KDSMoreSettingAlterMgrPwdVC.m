//
//  KDSMoreSettingAlterMgrPwdVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/15.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSMoreSettingAlterMgrPwdVC.h"
#import "MBProgressHUD+MJ.h"

@interface KDSMoreSettingAlterMgrPwdVC ()

///管理密码输入文本框。
@property (nonatomic, strong) UITextField *pwdTextField;
///下一步按钮。
@property (nonatomic, strong) UIButton *nextStepBtn;
///发送修改命令时弹出的半透层视图，添加到key window中。
@property (nonatomic, strong) UIView *alteringMaskView;
///发送修改命令时弹出的提示视图，添加到key window中。
@property (nonatomic, strong) UIView *alteringTipsView;

@end

@implementation KDSMoreSettingAlterMgrPwdVC

- (UIView *)alteringMaskView
{
    if (!_alteringMaskView)
    {
        _alteringMaskView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _alteringMaskView.backgroundColor = UIColor.blackColor;
        _alteringMaskView.alpha = 0.35;
    }
    return _alteringMaskView;
}

- (UIView *)alteringTipsView
{
    if (!_alteringTipsView)
    {
        _alteringTipsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 220, 105)];
        _alteringTipsView.center = CGPointMake(kScreenWidth / 2, kScreenHeight / 2);
        _alteringTipsView.backgroundColor = [UIColor whiteColor];
        _alteringTipsView.layer.cornerRadius = 5;
        //生效中
        UILabel *label1 = [[UILabel alloc] init];
        NSString *text = Localized(@"alteringManagementPwd");
        UIFont *font = [UIFont systemFontOfSize:14];
        label1.text = text;
        label1.font = font;
        label1.textColor = KDSRGBColor(0x10, 0x10, 0x10);
        CGFloat height1 = ceil([text sizeWithAttributes:@{NSFontAttributeName : font}].height);
        label1.textAlignment = NSTextAlignmentCenter;
        ///提示语
        UILabel *label2 = [[UILabel alloc] init];
        text = Localized(@"alteringManagementPwdTips");
        font = [UIFont systemFontOfSize:13];
        label2.text = text;
        label2.font = font;
        label2.numberOfLines = 0;
        label2.textColor = KDSRGBColor(0x10, 0x10, 0x10);
        CGFloat height2 = ceil([text boundingRectWithSize:CGSizeMake(200, 105) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : font} context:nil].size.height);
        label2.textAlignment = NSTextAlignmentCenter;
        
        CGFloat top = (105 - height1 - height2) / 8.0 * 3.0;
        label1.frame = CGRectMake(0, top, 220, height1);
        label2.frame = CGRectMake(10, CGRectGetMaxY(label1.frame) + top / 3.0 * 2.0, 200, height2);
        
        [_alteringTipsView addSubview:label1];
        [_alteringTipsView addSubview:label2];
    }
    return _alteringTipsView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationTitleLabel.text = Localized(@"alterManagementPwd");
    
    CGFloat width = 300, height = 50;
    UIView *cornerView = [[UIView alloc] initWithFrame:CGRectMake((kScreenWidth - width) / 2.0, 30, width, height)];
    cornerView.backgroundColor = UIColor.whiteColor;
    cornerView.layer.cornerRadius = height / 2.0;
    cornerView.layer.shadowColor = KDSRGBColor(0xdd, 0xdd, 0xdd).CGColor;
    cornerView.layer.shadowOffset = CGSizeMake(3, 3);
    cornerView.layer.shadowOpacity = 1.0;
    cornerView.clipsToBounds = NO;
    [self.view addSubview:cornerView];
    
    UIImage *image = [self imageWithName:@"loginPwdLeftAccessory"];
    UIImageView *lockIV = [[UIImageView alloc] initWithImage:image];
    lockIV.contentMode = UIViewContentModeScaleAspectFit;
    lockIV.frame = CGRectMake(23, (height - 15) / 2, 15, 15);
    [cornerView addSubview:lockIV];

    self.pwdTextField = [[UITextField alloc] initWithFrame:CGRectMake(54, 0, width - 108, height)];
    self.pwdTextField.placeholder = Localized(@"inputNewManagementPassword");
    [self.pwdTextField addTarget:self action:@selector(textFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
    self.pwdTextField.font = [UIFont systemFontOfSize:14];
    self.pwdTextField.keyboardType = UIKeyboardTypeNumberPad;
    self.pwdTextField.secureTextEntry = YES;
    [cornerView addSubview:self.pwdTextField];
    
    UIButton *rBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.pwdTextField.frame) + 20, (height - 10) / 2, 16, 10)];
    [rBtn setImage:[self imageWithName:@"loginPwdRightAccessoryNormal"] forState:UIControlStateNormal];
    [rBtn setImage:[self imageWithName:@"loginPwdRightAccessorySelected"] forState:UIControlStateSelected];
    [rBtn addTarget:self action:@selector(showOrHidePwd:) forControlEvents:UIControlEventTouchUpInside];
    [cornerView addSubview:rBtn];
    
    //提示界面，没有考虑换行的情况
    image = [UIImage imageNamed:@"deviceExclamationMark"];
    UIImageView *exclamationMarkIV = [[UIImageView alloc] initWithImage:image];
    exclamationMarkIV.frame = CGRectMake(23, (height - image.size.height) / 2, image.size.width, image.size.height);
    [self.view addSubview:exclamationMarkIV];
    UILabel *tipsLabel = [[UILabel alloc] init];
    UIFont *font = [UIFont systemFontOfSize:12];
    tipsLabel.font = font;
    tipsLabel.textColor = KDSRGBColor(0xc2, 0xc2, 0xc2);
    tipsLabel.text = Localized(@"alterManagementPwdTips");
    CGSize size = [tipsLabel.text sizeWithAttributes:@{NSFontAttributeName : font}];
    tipsLabel.bounds = (CGRect){0, 0, ceil(size.width), ceil(size.height)};
    [self.view addSubview:tipsLabel];
    exclamationMarkIV.frame = (CGRect){(kScreenWidth - image.size.width - 5 - ceil(size.width)) / 2, CGRectGetMaxY(cornerView.frame) + 16, image.size};
    tipsLabel.center = CGPointMake(CGRectGetMaxX(exclamationMarkIV.frame) + 5 + size.width / 2, exclamationMarkIV.center.y);
    
    //下一步按钮
    self.nextStepBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.nextStepBtn setTitle:Localized(@"nextStep") forState:UIControlStateNormal];
    [self.nextStepBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.nextStepBtn setTitle:Localized(@"nextStep") forState:UIControlStateDisabled];
    [self.nextStepBtn setTitleColor:UIColor.lightTextColor forState:UIControlStateDisabled];
    self.nextStepBtn.backgroundColor = KDSRGBColor(0x2d, 0xd9, 0xba);
    self.nextStepBtn.frame = (CGRect){(kScreenWidth - 300) / 2.0, CGRectGetMaxY(tipsLabel.frame) + 55, width, 60};
    self.nextStepBtn.layer.cornerRadius = 30;
    [self.nextStepBtn addTarget:self action:@selector(clickNextStepBtnAlterManagementPassword:) forControlEvents:UIControlEventTouchUpInside];
    self.nextStepBtn.enabled = NO;
    [self.view addSubview:self.nextStepBtn];
}

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

#pragma mark - 控件等事件。
///限制数字之外的输入，长度不能超过12(6~12).
- (void)textFieldTextDidChange:(UITextField *)sender
{
    char pwd[13] = {0};
    int index = 0;
    NSString *text = sender.text.length > 12 ? [sender.text substringToIndex:12] : sender.text;
    for (NSInteger i = 0; i < text.length; ++i)
    {
        unichar c = [text characterAtIndex:i];
        if (c < '0' || c > '9') continue;
        pwd[index++] = c;
    }
    sender.text = @(pwd);
    self.nextStepBtn.enabled = sender.text.length > 5;
}

///点击密码输入框右边的按钮显示/隐藏密码
- (void)showOrHidePwd:(UIButton *)sender
{
    sender.selected = !sender.selected;
    self.pwdTextField.secureTextEntry = !sender.selected;
}

///点击下一步按钮，修改管理密码。
- (void)clickNextStepBtnAlterManagementPassword:(UIButton *)sender
{
    [[UIApplication sharedApplication].keyWindow addSubview:self.alteringMaskView];
    [[UIApplication sharedApplication].keyWindow addSubview:self.alteringTipsView];
    __weak typeof(self) weakSelf = self;
    [self.lock.bleTool manageKeyWithPwd:self.pwdTextField.text userId:@"00" action:KDSBleKeyManageActionSet keyType:KDSBleKeyTypeAdmin completion:^(KDSBleError error) {
        [weakSelf.alteringTipsView removeFromSuperview];
        [weakSelf.alteringMaskView removeFromSuperview];
        if (error == KDSBleErrorSuccess)
        {
            [MBProgressHUD showSuccess:Localized(@"alterManagementPwdSuccess")];
            [weakSelf.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            [MBProgressHUD showError:Localized(@"alterManagementPwdFailed")];
        }
    }];
}

@end
