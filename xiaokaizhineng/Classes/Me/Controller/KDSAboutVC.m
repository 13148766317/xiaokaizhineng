//
//  KDSAboutVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/22.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSAboutVC.h"
#import "Masonry.h"

@interface KDSAboutVC ()

@end

@implementation KDSAboutVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationTitleLabel.text = Localized(@"aboutXiaokai");
    UIImage *brandImg = [UIImage imageNamed:@"meBrand"];
    UIImageView *brandIV = [[UIImageView alloc] initWithImage:brandImg];
    brandIV.frame = (CGRect){(kScreenWidth - brandImg.size.width) / 2, 44, brandImg.size};
    [self.view addSubview:brandIV];
    
    UIFont *font = [UIFont systemFontOfSize:12];
    
    UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(brandIV.frame) + 10, kScreenWidth, ceil([KDSTool.appVersion sizeWithAttributes:@{NSFontAttributeName : font}].height))];
    versionLabel.font = font;
    versionLabel.text = [@"v" stringByAppendingString:KDSTool.appVersion];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    versionLabel.textColor = KDSRGBColor(0xc1, 0xc1, 0xc1);
    [self.view addSubview:versionLabel];
    
    CGFloat height = 60;
    UIView *cornerView = [[UIView alloc] init];
    [self.view addSubview:cornerView];
    [cornerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(versionLabel.mas_bottom).offset(75);
        make.left.equalTo(self.view).offset(10);
        make.right.equalTo(self.view).offset(-10);
        make.height.mas_equalTo(height * 4 + 1.5);
    }];
    cornerView.backgroundColor = UIColor.whiteColor;
    cornerView.layer.cornerRadius = 5;
    
    UILabel *weixin = [self createLabelWithText:Localized(@"weixinPublicAccount") color:KDSRGBColor(0x2b, 0x2f, 0x50) font:font alignment:NSTextAlignmentLeft];
    [cornerView addSubview:weixin];
    [weixin mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(cornerView);
        make.left.equalTo(cornerView).offset(13);
        make.size.mas_equalTo(weixin.bounds.size);
    }];
    UILabel *weixinPublic = [self createLabelWithText:@"XIAOKAI小凯" color:KDSRGBColor(0xa5, 0xa6, 0xac) font:font alignment:NSTextAlignmentRight];
    [cornerView addSubview:weixinPublic];
    [weixinPublic mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(cornerView);
        make.right.equalTo(cornerView).offset(-13);
        make.size.mas_equalTo(weixinPublic.bounds.size);
    }];
    
    UIView *underlineView1 = [[UIView alloc] init];
    underlineView1.backgroundColor = KDSRGBColor(0xf0, 0xf0, 0xf0);
    [cornerView addSubview:underlineView1];
    [underlineView1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weixinPublic.mas_bottom);
        make.leftMargin.equalTo(weixin);
        make.rightMargin.equalTo(weixinPublic);
        make.height.mas_equalTo(0.5);
    }];
    
    UILabel *weibo = [self createLabelWithText:Localized(@"weiboPublicAccount") color:KDSRGBColor(0x2b, 0x2f, 0x50) font:font alignment:NSTextAlignmentLeft];
    [cornerView addSubview:weibo];
    [weibo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(underlineView1.mas_bottom);
        make.left.equalTo(cornerView).offset(13);
        make.size.mas_equalTo(weibo.bounds.size);
    }];
    UILabel *weiboPublic = [self createLabelWithText:@"XIAOKAI小凯互联" color:KDSRGBColor(0xa5, 0xa6, 0xac) font:font alignment:NSTextAlignmentRight];
    [cornerView addSubview:weiboPublic];
    [weiboPublic mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(underlineView1.mas_bottom);
        make.right.equalTo(cornerView).offset(-13);
        make.size.mas_equalTo(weiboPublic.bounds.size);
    }];
    
    UIView *underlineView2 = [[UIView alloc] init];
    underlineView2.backgroundColor = KDSRGBColor(0xf0, 0xf0, 0xf0);
    [cornerView addSubview:underlineView2];
    [underlineView2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(weiboPublic.mas_bottom);
        make.leftMargin.equalTo(weibo);
        make.rightMargin.equalTo(weiboPublic);
        make.height.mas_equalTo(0.5);
    }];
    
    UILabel *serviceTel = [self createLabelWithText:Localized(@"serviceTel") color:KDSRGBColor(0x2b, 0x2f, 0x50) font:font alignment:NSTextAlignmentLeft];
    [cornerView addSubview:serviceTel];
    [serviceTel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(underlineView2.mas_bottom);
        make.left.equalTo(cornerView).offset(13);
        make.size.mas_equalTo(serviceTel.bounds.size);
    }];
    UILabel *tel = [self createLabelWithText:@"400-698-1599" color:KDSRGBColor(0xfb, 0x71, 0x0b) font:font alignment:NSTextAlignmentRight];
    tel.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapServiceTelMakeACall:)];
    [tel addGestureRecognizer:tap];
    [cornerView addSubview:tel];
    [tel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(underlineView2.mas_bottom);
        make.right.equalTo(cornerView).offset(-13);
        make.size.mas_equalTo(tel.bounds.size);
    }];
    
    UIView *underlineView3 = [[UIView alloc] init];
    underlineView3.backgroundColor = KDSRGBColor(0xf0, 0xf0, 0xf0);
    [cornerView addSubview:underlineView3];
    [underlineView3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(serviceTel.mas_bottom);
        make.leftMargin.equalTo(serviceTel);
        make.rightMargin.equalTo(tel);
        make.height.mas_equalTo(0.5);
    }];
    
    UILabel *website = [self createLabelWithText:Localized(@"officialWebsite") color:KDSRGBColor(0x2b, 0x2f, 0x50) font:font alignment:NSTextAlignmentLeft];
    [cornerView addSubview:website];
    [website mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(underlineView3.mas_bottom);
        make.left.equalTo(cornerView).offset(13);
        make.size.mas_equalTo(website.bounds.size);
    }];
    UILabel *websiteUrl = [self createLabelWithText:@"www.xiaokai.com" color:KDSRGBColor(0xa5, 0xa6, 0xac) font:font alignment:NSTextAlignmentRight];
    websiteUrl.userInteractionEnabled = YES;
    UITapGestureRecognizer *utap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapUrlOpenUrlWithSafari:)];
    [websiteUrl addGestureRecognizer:utap];
    [cornerView addSubview:websiteUrl];
    [websiteUrl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(underlineView3.mas_bottom);
        make.right.equalTo(cornerView).offset(-13);
        make.size.mas_equalTo(websiteUrl.bounds.size);
    }];
}

///根据字体颜色、大小、对齐方式和文本创建一个标签，返回的标签已经设置好bounds(高60)属性。
- (UILabel *)createLabelWithText:(NSString *)text color:(UIColor *)color font:(UIFont *)font alignment:(NSTextAlignment)alignment
{
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.textColor = color;
    label.font = font;
    label.textAlignment = alignment;
    label.bounds = CGRectMake(0, 0, ceil([text sizeWithAttributes:@{NSFontAttributeName : font}].width) , 60);
    return label;
}

//MARK:点击客服电话拨打。
- (void)tapServiceTelMakeACall:(UITapGestureRecognizer *)sender
{
    NSString *number = [((UILabel *)sender.view).text stringByReplacingOccurrencesOfString:@"-" withString:@""];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", number]];
    if ([[UIApplication sharedApplication] canOpenURL:url])
    {
        [[UIApplication sharedApplication] openURL:url];
    }
}

///点击网址用Safari打开。
- (void)tapUrlOpenUrlWithSafari:(UITapGestureRecognizer *)sender
{
    NSURL *url = [NSURL URLWithString:[@"http://" stringByAppendingString:((UILabel *)sender.view).text]];
    if ([[UIApplication sharedApplication] canOpenURL:url])
    {
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
