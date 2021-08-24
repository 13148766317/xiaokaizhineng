//
//  KDSLockLanguageAlterVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/16.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSLockLanguageAlterVC.h"
#import "MBProgressHUD+MJ.h"

@interface KDSLockLanguageAlterVC ()

///中文选择按钮。
@property (nonatomic, strong) UIButton *zhBtn;
///英文选择按钮。
@property (nonatomic, strong) UIButton *enBtn;

@end

@implementation KDSLockLanguageAlterVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationTitleLabel.text = Localized(@"language");
    
    UIView *cornerView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, kScreenWidth - 20, 121)];
    cornerView.layer.cornerRadius = 5;
    cornerView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:cornerView];
    
    UIFont *font = [UIFont systemFontOfSize:12];
    UIColor *color = KDSRGBColor(0x2b, 0x2f, 0x50);
    UIImage *normalImg = [UIImage imageNamed:@"deviceLanguageNormal"];
    UIImage *selectedImg = [UIImage imageNamed:@"deviceLanguageSelected"];
    
    NSString *zh = Localized(@"languageChinese");
    UILabel *zhLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 0, 200, 60)];
    zhLabel.text = zh;
    zhLabel.textColor = color;
    zhLabel.font = font;
    [cornerView addSubview:zhLabel];
    
    self.zhBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.zhBtn setImage:normalImg forState:UIControlStateNormal];
    [self.zhBtn setImage:selectedImg forState:UIControlStateSelected];
    self.zhBtn.frame = CGRectMake(cornerView.bounds.size.width - 13 - 24, 18, 24, 24);
    self.zhBtn.selected = [self.language isEqualToString:zh];
    [self.zhBtn addTarget:self action:@selector(selectLockLanguage:) forControlEvents:UIControlEventTouchUpInside];
    [cornerView addSubview:self.zhBtn];
    
    UIView *separactor = [[UIView alloc] initWithFrame:CGRectMake(13, CGRectGetMaxY(zhLabel.frame), cornerView.bounds.size.width - 26, 1)];
    separactor.backgroundColor = KDSRGBColor(0xf0, 0xf0, 0xf0);
    [cornerView addSubview:separactor];
    
    NSString *en = Localized(@"languageEnglish");
    UILabel *enLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, CGRectGetMaxY(separactor.frame), 200, 60)];
    enLabel.text = en;
    enLabel.textColor = color;
    enLabel.font = font;
    [cornerView addSubview:enLabel];
    
    self.enBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.enBtn setImage:normalImg forState:UIControlStateNormal];
    [self.enBtn setImage:selectedImg forState:UIControlStateSelected];
    self.enBtn.frame = CGRectMake(cornerView.bounds.size.width - 13 - 24, 79, 24, 24);
    self.enBtn.selected = [self.language isEqualToString:en];
    [self.enBtn addTarget:self action:@selector(selectLockLanguage:) forControlEvents:UIControlEventTouchUpInside];
    [cornerView addSubview:self.enBtn];
    
    //确认按钮
    UIButton *doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    doneBtn.layer.cornerRadius = 30;
    doneBtn.backgroundColor = KDSRGBColor(0x2d, 0xd9, 0xba);
    [doneBtn setTitle:Localized(@"ok") forState:UIControlStateNormal];
    [doneBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    doneBtn.frame = CGRectMake((kScreenWidth - 300) / 2, kScreenHeight - kStatusBarHeight - kNavBarHeight - 60 - 80, 300, 60);
    [doneBtn addTarget:self action:@selector(setLockLanguage:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:doneBtn];
}

#pragma mark - 控件等事件方法。
///中文/英文按钮选择切换语言
- (void)selectLockLanguage:(UIButton *)sender
{
    self.zhBtn.selected = self.enBtn.selected = NO;
    sender.selected = YES;
}

///点击完成按钮设置锁语言。
- (void)setLockLanguage:(UIButton *)sender
{
    NSString *language = self.zhBtn.selected ? Localized(@"languageChinese") : Localized(@"languageEnglish");
    if (![language isEqualToString:self.language])
    {
        __weak typeof(self) weakSelf = self;
        MBProgressHUD *hud = [MBProgressHUD showMessage:Localized(@"settingLockLanguage")];
        [self.lock.bleTool setLockLanguage:self.zhBtn.selected ? @"zh" : @"en" completion:^(KDSBleError error) {
            [hud hide:YES];
            if (error == KDSBleErrorSuccess)
            {
                weakSelf.lock.bleTool.connectedPeripheral.language = self.zhBtn.selected ? @"zh" : @"en";
                [MBProgressHUD showSuccess:Localized(@"setLockLanguageSuccess")];
                !weakSelf.lockLanguageDidAlterBlock ?: weakSelf.lockLanguageDidAlterBlock(language);
                [weakSelf.navigationController popViewControllerAnimated:YES];
            }
            else
            {
                [MBProgressHUD showError:[Localized(@"setLockLanguageFailed") stringByAppendingFormat:@": %ld", (long)error]];
            }
        }];
    }
}

@end
