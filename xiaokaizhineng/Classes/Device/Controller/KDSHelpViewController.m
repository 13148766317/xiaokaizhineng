//
//  KDSHelpViewController.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/11.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//
#define UILABEL_LINE_SPACE 8

#define HEIGHT [ [ UIScreen mainScreen ] bounds ].size.height

#import "KDSHelpViewController.h"

@interface KDSHelpViewController ()
@property (weak, nonatomic) IBOutlet UILabel *helpStepLab;
@property (weak, nonatomic) IBOutlet UILabel *helptitleLab;

@end

@implementation KDSHelpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationTitleLabel.text = @"帮助";
    [self setupUI];
    // Do any additional setup after loading the view from its nib.
}

-(void)setupUI{
    [self setLabelSpace:self.helptitleLab withValue:@"您无法发现您的蓝牙设备，请按照以下步骤对设备进行检查:" withFont:[UIFont fontWithName:@"Helvetica-Bold" size:14]];
    [self setLabelSpace:self.helpStepLab withValue:@"1.请保证您的设备已经接通，或电池电量充足。 \n2.请打开您的手机蓝牙。 \n3.保持待添加的设备与手机的距离不超过5米，从而保证设备间的通信。 \n4.按重置键后松开，重启系统。" withFont:[UIFont systemFontOfSize:12]];
    
}
/**
 设置lab字符串行间距与文字间距

 @param label label
 @param str 字符串内容
 @param font 文字字体
 */
-(void)setLabelSpace:(UILabel*)label withValue:(NSString*)str withFont:(UIFont*)font {
    NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
    paraStyle.lineBreakMode = NSLineBreakByCharWrapping;
    paraStyle.alignment = NSTextAlignmentLeft;
    paraStyle.lineSpacing = UILABEL_LINE_SPACE; //设置行间距
    paraStyle.hyphenationFactor = 1.0;
    paraStyle.firstLineHeadIndent = 0.0;
    paraStyle.paragraphSpacingBefore = 0.0;
    paraStyle.headIndent = 0;
    paraStyle.tailIndent = 0;
    //设置字间距 NSKernAttributeName:@1.5f
    NSDictionary *dic = @{NSFontAttributeName:font, NSParagraphStyleAttributeName:paraStyle, NSKernAttributeName:@1.5f
                          };
    NSAttributedString *attributeStr = [[NSAttributedString alloc] initWithString:str attributes:dic];
    label.attributedText = attributeStr;
    
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
