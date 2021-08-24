//
//  KDSAddPwdSuccesVC.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/3/19.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//
#define UILABEL_LINE_SPACE 4

#define HEIGHT [ [ UIScreen mainScreen ] bounds ].size.height

#import "KDSAddPwdSuccesVC.h"
#import "UIView+BlockGesture.h"
#import<MessageUI/MessageUI.h>
#import "MBProgressHUD+MJ.h"
#import "WXApi.h"
@interface KDSAddPwdSuccesVC ()<MFMessageComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIView *pwdNameView;
@property (weak, nonatomic) IBOutlet UIView *pwdTimeView;
@property (weak, nonatomic) IBOutlet UILabel *pwdNmaeLab;
@property (weak, nonatomic) IBOutlet UILabel *pwdTimeLab;
@property (weak, nonatomic) IBOutlet UIView *shortMessageView;
@property (weak, nonatomic) IBOutlet UIView *weChatView;
@property (weak, nonatomic) IBOutlet UIView *copysView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topTipLabTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UILabel *schedulLab;
@property (weak, nonatomic) IBOutlet UILabel *pwdLab;

@end

@implementation KDSAddPwdSuccesVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationTitleLabel.text = @"密码详情";
    [self setUI];
    // Do any additional setup after loading the view from its nib.
}
-(void)setUI{
    NSLog(@"kScreenHeight = %f",kScreenHeight);
    if (kScreenHeight<= 568) {//4寸屏
        self.topViewHeightConstraint.constant = 160;
        self.topTipLabTopConstraint.constant = 30;
    }else if (kScreenHeight<= 667) {//4.7寸屏
            self.topViewHeightConstraint.constant = 240;
    }else{
        self.bottomViewHeightConstraint.constant = 160;
    }
    self.pwdNmaeLab.text = self.pwdModel.nickName;
    self.pwdNameView.layer.shadowColor = KDSRGBColor(0xdd, 0xdd, 0xdd).CGColor;
    self.pwdNameView.layer.shadowOffset = CGSizeMake(3, 3);
    self.pwdNameView.layer.shadowOpacity = 1.0;
    self.pwdNameView.clipsToBounds = NO;
//    self.lock.bleTool.dateFormatter.dateFormat = @"yyyy/MM/dd HH:mm";
//    NSString *date = [self.lock.bleTool.dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.pwdModel.createTime]];
//    self.pwdTimeLab.text = [Localized(@"authorizationTime") stringByAppendingFormat:@": %@", date];
    
    self.pwdTimeView.layer.shadowColor = KDSRGBColor(0xdd, 0xdd, 0xdd).CGColor;
    self.pwdTimeView.layer.shadowOffset = CGSizeMake(3, 3);
    self.pwdTimeView.layer.shadowOpacity = 1.0;
    self.pwdTimeView.clipsToBounds = NO;
    if (self.pwdModel.pwdType == KDSServerKeyTpyePIN) {
        if (self.pwdModel.type == KDSServerCycleTpyeCycle) {
            NSString *timeStr = @"密码将于每";
            NSMutableArray * weekDay = [[NSMutableArray alloc] init];
            [self.pwdModel.items enumerateObjectsUsingBlock:^(NSString *i,NSUInteger idx,BOOL*_Nonnullstop) {
                NSLog(@"%@",i);
                if (idx == 0 && [i isEqualToString:@"1"]) {
                    [weekDay addObject:@"周日,"];
                }else if(idx == 1 && [i isEqualToString:@"1"]) {
                    [weekDay addObject:@"周一,"];
                }else if(idx == 2 && [i isEqualToString:@"1"]) {
                    [weekDay addObject:@"周二,"];
                }else if(idx == 3 && [i isEqualToString:@"1"]) {
                    [weekDay addObject:@"周三,"];
                }else if(idx == 4 && [i isEqualToString:@"1"]) {
                    [weekDay addObject:@"周四,"];
                }else if(idx == 5 && [i isEqualToString:@"1"]) {
                    [weekDay addObject:@"周五,"];
                }else if(idx == 6 && [i isEqualToString:@"1"]) {
                    [weekDay addObject:@"周六"];
                }
            }];
            if (weekDay.count == 7) {
                timeStr = [timeStr stringByAppendingPathComponent:@"天"];
            }else{
                for (NSString *str in weekDay) {
                    timeStr = [timeStr stringByAppendingPathComponent:str];
                }
            }
            NSString *second = [[self time_timestampToStringWithHM:[self.pwdModel.startTime integerValue]] stringByAppendingString:[NSString stringWithFormat:@"-%@生效",[self time_timestampToStringWithHM:[self.pwdModel.endTime integerValue]]]];
            self.schedulLab.text = [[timeStr stringByReplacingOccurrencesOfString:@"/" withString:@""] stringByAppendingString:second];
        }else if (self.pwdModel.type == KDSServerCycleTpyePeriod || self.pwdModel.type == KDSServerCycleTpyeTwentyfourHours) {
            NSString *str = [NSString stringWithFormat:@"%@至%@",[self time_timestampToString:[self.pwdModel.startTime integerValue]],[self time_timestampToString:[self.pwdModel.endTime integerValue]]];
            NSString *s = [str stringByReplacingOccurrencesOfString:@"-"withString:@"/"];
            self.schedulLab.text = [NSString stringWithFormat:@"%@有效",[s stringByReplacingOccurrencesOfString:@"至" withString:@"-"]];
        }else if (self.pwdModel.type == 1){
            self.schedulLab.text = @"密码永久生效";
        }
    }else{
        self.schedulLab.text = @"密码仅可使用一次";
    }
    
    [self setLabelSpace:self.schedulLab withValue:self.schedulLab.text withFont:[UIFont systemFontOfSize:16] withAlignment:self.schedulLab.text.length>8? @"left":@"center"];
    self.pwdLab.text = self.pwdModel.pwd;
    [self setLabelSpace:self.pwdLab withValue:self.pwdLab.text withFont:[UIFont systemFontOfSize:29] withAlignment:@"center"];
    __weak typeof(self) weakSelf = self;
    [self.shortMessageView addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
        NSLog(@"点击了短信分享");
        [weakSelf showMessageView:[NSArray arrayWithObjects:@"",nil]title:@"test"body:[NSString stringWithFormat:@"【小凯智能】密码: %@。此密码只能用于小凯智能锁验证开门,%@。",self.pwdLab.text,self.schedulLab.text]];
    }];
    [self.weChatView addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
        NSLog(@"点击了微信分享");
        BOOL weixinEnable= [[UIApplication sharedApplication]canOpenURL:[NSURL URLWithString:@"weixin://"]];
        if (!weixinEnable) {
            [MBProgressHUD showError:@"您的手机未安装微信"];
            return ;
        }
        NSString *string = [NSString stringWithFormat:@"【小凯智能】密码: %@。此密码只能用于小凯智能锁验证开门,%@。",self.pwdLab.text,self.schedulLab.text];
        [self sendToWeChatWithMessage:string];
        
    }];
    [self.copysView addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
        UIPasteboard *pab = [UIPasteboard generalPasteboard];
        NSString *string = [NSString stringWithFormat:@"【小凯智能】密码: %@。此密码只能用于小凯智能锁验证开门,%@。",self.pwdLab.text,self.schedulLab.text];
        [pab setString:string];
        if (pab == nil) {
            [MBProgressHUD showSuccess:@"复制成功"];
        }else
        {
            [MBProgressHUD showSuccess:@"已复制"];
        }
    }];
    self.pwdTimeLab.text = [Localized(@"authorizationTime") stringByAppendingFormat:@": %@", [self time_timestampToString:self.createTimeStr.integerValue]];
}
-(void)sendToWeChatWithMessage:(NSString *)mes{
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.bText = YES;
    req.text = mes;
    req.scene = WXSceneSession;
    [WXApi sendReq:req];
}
-(void)showMessageView:(NSArray*)phones title:(NSString*)title body:(NSString*)body
{
    if([MFMessageComposeViewController canSendText]){
        MFMessageComposeViewController*controller=[[MFMessageComposeViewController alloc]init];
        controller.recipients = phones;
        controller.navigationBar.tintColor=[UIColor redColor];
        controller.body=body;
        controller.messageComposeDelegate=self;
        [self presentViewController:controller animated:YES completion:nil];
        [[[[controller viewControllers]lastObject]navigationItem]setTitle:title];//修改短信界面标题
    }else{
        UIAlertView*alert=[[UIAlertView alloc]initWithTitle:@"提示信息"
                                                   message:@"该设备不支持短信功能"
                                                  delegate:nil
                                         cancelButtonTitle:@"确定"
                                         otherButtonTitles:nil,nil];
        [alert show];
    }
}
- (void)messageComposeViewController:(nonnull MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    switch(result){
        case MessageComposeResultSent:
            //信息传送成功
            [MBProgressHUD showSuccess:@"发送成功"];
            break;
        case MessageComposeResultFailed:
            //信息传送失败
            [MBProgressHUD showError:@"发送失败"];
            break;
        case MessageComposeResultCancelled:
            //信息被用户取消传送
            [MBProgressHUD showSuccess:@"取消发送"];
            break;
        default:
            break;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
///时间戳转化为字符转0000-00-00 00:00
-(NSString *)time_timestampToString:(NSInteger)timestamp{
    NSDate *confromTimesp = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter *dateFormat=[[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"yyyy/MM/dd HH:mm"];
    NSString* string=[dateFormat stringFromDate:confromTimesp];
    return string;
}
///时间戳转化为字符转0000-00-00 00:00
-(NSString *)time_timestampToStringWithHM:(NSInteger)timestamp{
    NSDate *confromTimesp = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter *dateFormat=[[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"HH:mm"];
    NSString* string=[dateFormat stringFromDate:confromTimesp];
    return string;
}
-(void)setLabelSpace:(UILabel*)label withValue:(NSString*)str withFont:(UIFont*)font withAlignment:(NSString*)alignment{
    NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
    paraStyle.lineBreakMode = NSLineBreakByCharWrapping;
    if ([alignment isEqualToString:@"left"]) {
        paraStyle.alignment = NSTextAlignmentLeft;
    }else if ([alignment isEqualToString:@"center"]){
        paraStyle.alignment = NSTextAlignmentCenter;
    }
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
-(NSString*)getCurrentTimes{
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    // ----------设置你想要的格式,hh与HH的区别:分别表示12小时制,24小时制
    
    [formatter setDateFormat:@"yyyy/MM/dd HH:mm"];
    
    //现在时间,你可以输出来看下是什么格式
    
    NSDate *datenow = [NSDate date];
    
    //----------将nsdate按formatter格式转成nsstring
    
    NSString *currentTimeString = [formatter stringFromDate:datenow];
    
    NSLog(@"currentTimeString =  %@",currentTimeString);
    
    return currentTimeString;
    
}
@end
