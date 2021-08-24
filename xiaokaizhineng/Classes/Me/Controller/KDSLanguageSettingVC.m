//
//  KDSLanguageSettingVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/22.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSLanguageSettingVC.h"
#import "MBProgressHUD+MJ.h"

@interface KDSLanguageSettingVC ()

///简体中文选择按钮。
@property (nonatomic, strong) UIButton *zhsBtn;
///繁体中文选择按钮。
@property (nonatomic, strong) UIButton *zhtBtn;
///英文选择按钮。
@property (nonatomic, strong) UIButton *enBtn;
///泰文选择按钮。
@property (nonatomic, strong) UIButton *thBtn;

@end

@implementation KDSLanguageSettingVC

#pragma mark - 生命周期和UI方法。
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationTitleLabel.text = Localized(@"languageSetting");
    CGFloat height = 60;
    UIView *cornerView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, kScreenWidth - 20, height * 4 + 3)];
    cornerView.layer.cornerRadius = 5;
    cornerView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:cornerView];
    
    CGFloat top = (height - 33) / 2.0;//选择语言按钮顶/底部离最近视图的距离。
    
    NSString *zhs = @"简体中文";//Localized(@"languageChineseSimple");
    UILabel *zhsLabel = [self createLabelWithText:zhs originY:0];
    [cornerView addSubview:zhsLabel];
    self.zhsBtn = [self createLanguageSelectButtonWithOriginY:top];
    [cornerView addSubview:self.zhsBtn];
    
    UIView *separactor1 = [self createSeparatorViewWithOriginY:CGRectGetMaxY(zhsLabel.frame)];
    [cornerView addSubview:separactor1];
    
    NSString *zht = @"繁體中文";//Localized(@"languageChineseTraditional");
    UILabel *zhtLabel = [self createLabelWithText:zht originY:CGRectGetMaxY(separactor1.frame)];
    [cornerView addSubview:zhtLabel];
    self.zhtBtn = [self createLanguageSelectButtonWithOriginY:CGRectGetMaxY(separactor1.frame) + top];
    [cornerView addSubview:self.zhtBtn];
    
    UIView *separactor2 = [self createSeparatorViewWithOriginY:CGRectGetMaxY(zhtLabel.frame)];
    [cornerView addSubview:separactor2];
    
    NSString *en = @"English";//Localized(@"languageEnglish");
    UILabel *enLabel = [self createLabelWithText:en originY:CGRectGetMaxY(separactor2.frame)];
    [cornerView addSubview:enLabel];
    self.enBtn = [self createLanguageSelectButtonWithOriginY:CGRectGetMaxY(separactor2.frame) + top];
    UIView *maskViewE = [[UIView alloc] initWithFrame:self.enBtn.bounds];
    maskViewE.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
    //[self.enBtn addSubview:maskViewE];
    //self.enBtn.enabled = NO;
    [cornerView addSubview:self.enBtn];
    
    UIView *separactor3 = [self createSeparatorViewWithOriginY:CGRectGetMaxY(enLabel.frame)];
    [cornerView addSubview:separactor3];
    
    NSString *th = @"ภาษาไทย";//Localized(@"languageThailand");
    UILabel *thLabel = [self createLabelWithText:th originY:CGRectGetMaxY(separactor3.frame)];
    [cornerView addSubview:thLabel];
    self.thBtn = [self createLanguageSelectButtonWithOriginY:CGRectGetMaxY(separactor3.frame) + top];
    UIView *maskViewT = [[UIView alloc] initWithFrame:self.thBtn.bounds];
    maskViewT.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
    [self.thBtn addSubview:maskViewT];
    self.thBtn.enabled = NO;
    [cornerView addSubview:self.thBtn];
    
    NSString *language = [KDSTool getLanguage];
    if ([language hasPrefix:JianTiZhongWen])
    {//开头匹配简体中文
        self.zhsBtn.selected = YES;
    }
    else if ([language hasPrefix:FanTiZhongWen])
    {//开头匹配繁体中文
        self.zhtBtn.selected = YES;
    }
    else if ([language hasPrefix:@"th"])
    {
        self.thBtn.selected = YES;
    }
    else
    {//其他一律设置为英文
        self.enBtn.selected = YES;
    }
    
    //确认按钮
    UIButton *doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    doneBtn.layer.cornerRadius = 30;
    doneBtn.backgroundColor = KDSRGBColor(0x2d, 0xd9, 0xba);
    [doneBtn setTitle:Localized(@"ok") forState:UIControlStateNormal];
    [doneBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    CGFloat width = kScreenWidth < 375 ? (kScreenWidth - 76) : 300;
    doneBtn.frame = CGRectMake((kScreenWidth - width) / 2, kScreenHeight - kStatusBarHeight - kNavBarHeight - 60 - 80, width, 60);
    [doneBtn addTarget:self action:@selector(setSystemLanguage:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:doneBtn];
}

///根据文字、y原点创建一个语言标签，有默认的颜色和字体。创建的标签已设置好frame属性。
- (UILabel *)createLabelWithText:(NSString *)text originY:(CGFloat)y
{
    UIFont *font = [UIFont systemFontOfSize:12];
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = font;
    label.textColor = KDSRGBColor(0x2b, 0x2f, 0x50);
    label.frame = (CGRect){13, y, ceil([text sizeWithAttributes:@{NSFontAttributeName : font}].width), 60};
    return label;
}

///根据原点y创建一个语言选择按钮，有默认的图片。创建的按钮已设置好frame属性。
- (UIButton *)createLanguageSelectButtonWithOriginY:(CGFloat)y
{
    UIImage *normalImg = [UIImage imageNamed:@"deviceLanguageNormal"];
    UIImage *selectedImg = [UIImage imageNamed:@"deviceLanguageSelected"];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:normalImg forState:UIControlStateNormal];
    [btn setImage:selectedImg forState:UIControlStateSelected];
    btn.imageView.contentMode = UIViewContentModeScaleAspectFill;
    btn.frame = (CGRect){kScreenWidth - 20 - 13 - 33, y, 33, 33};
    [btn addTarget:self action:@selector(selectSystemLanguage:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

///根据原点y创建一条分隔线视图，有默认的颜色。创建的分隔线已设置好frame属性。
- (UIView *)createSeparatorViewWithOriginY:(CGFloat)y
{
    UIView *separactor = [[UIView alloc] initWithFrame:(CGRect){13, y, kScreenWidth - 46, 1}];
    separactor.backgroundColor = KDSRGBColor(0xf0, 0xf0, 0xf0);
    return separactor;
}

#pragma mark - 控件等事件方法。
///选择语言
- (void)selectSystemLanguage:(UIButton *)sender
{
    self.zhsBtn.selected = self.zhtBtn.selected = self.enBtn.selected = self.thBtn.selected = NO;
    sender.selected = YES;
}

///设置语言
- (void)setSystemLanguage:(UIButton *)sender
{
    if (self.zhsBtn.selected)
    {
        [KDSTool setLanguage:JianTiZhongWen];
    }
    else if (self.zhtBtn.selected)
    {
        [KDSTool setLanguage:FanTiZhongWen];
    }
    else if (self.zhtBtn.selected)
    {
        [KDSTool setLanguage:Thailand];
    }
    else
    {
        [KDSTool setLanguage:English];
    }
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.removeFromSuperViewOnHide = YES;
    self.navigationTitleLabel.text = Localized(@"languageSetting");
    [sender setTitle:Localized(@"ok") forState:UIControlStateNormal];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [hud hide:YES];
        [MBProgressHUD showSuccess:Localized(@"done")];
    });
}

@end
