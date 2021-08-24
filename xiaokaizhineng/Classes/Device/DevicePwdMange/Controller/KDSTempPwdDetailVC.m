//
//  KDSTempPwdDetailVC.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/15.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//
#define UILABEL_LINE_SPACE 4

#define HEIGHT [ [ UIScreen mainScreen ] bounds ].size.height
#import "KDSTempPwdDetailVC.h"
#import "KDSHttpManager+Ble.h"
#import "MBProgressHUD+MJ.h"
#import "UIView+Extension.h"

@interface KDSTempPwdDetailVC ()
@property (weak, nonatomic) IBOutlet UILabel *timeDescriptionLab;
@property (weak, nonatomic) IBOutlet UIView *nameView;
@property (weak, nonatomic) IBOutlet UIView *createTimeView;
@property (weak, nonatomic) IBOutlet UILabel *creatTimeLabel;
///管理密钥错误对应的字典，键是错误码，值是错误信息。
@property (weak, nonatomic) IBOutlet UILabel *pwdnameLab;

@property (nonatomic, readonly) NSDictionary<NSNumber *, NSString *> *errorMsgDict;
@end

@implementation KDSTempPwdDetailVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationTitleLabel.text = @"临时密码详情";
    [self setUI];
    [self setRightButton];
    [self.rightButton setImage:[UIImage imageNamed:@"删除"]forState:UIControlStateNormal];
    // Do any additional setup after loading the view from its nib.
}

-(void)setUI{
    self.pwdnameLab.text = self.pwdModel.nickName;
    [self setLabelSpace:_timeDescriptionLab withValue:@"密码将每周一周二周三  15：25至16：30重复生效" withFont:[UIFont systemFontOfSize:16]];
    self.nameView.layer.shadowColor = KDSRGBColor(0xdd, 0xdd, 0xdd).CGColor;
    self.nameView.layer.shadowOffset = CGSizeMake(3, 3);
    self.nameView.layer.shadowOpacity = 1.0;
    self.nameView.clipsToBounds = NO;
    self.lock.bleTool.dateFormatter.dateFormat = @"yyyy/MM/dd HH:mm";
    NSString *date = [self.lock.bleTool.dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.pwdModel.createTime]];
    self.creatTimeLabel.text = [Localized(@"authorizationTime") stringByAppendingFormat:@": %@", date];
    
    self.createTimeView.layer.shadowColor = KDSRGBColor(0xdd, 0xdd, 0xdd).CGColor;
    self.createTimeView.layer.shadowOffset = CGSizeMake(3, 3);
    self.createTimeView.layer.shadowOpacity = 1.0;
    self.createTimeView.clipsToBounds = NO;
}
- (IBAction)editeClick:(id)sender {
    [self alterDeviceNickname];
}
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
-(void)navRightClick{
    NSLog(@"确定删除密码？");
    UIAlertView *alertView=[[UIAlertView alloc]initWithTitle:@"提示" message:@"确定删除密码吗？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];//一般在if判断中加入
    [alertView show];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *btnTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if ([btnTitle isEqualToString:@"取消"]) {}else if ([btnTitle isEqualToString:@"确定"] ) {
        [self deletUserToBleWithModel];
//        [self deletePwdToServer:self.pwdModel];
    }
}
///修改密码昵称。
- (void)alterDeviceNickname
{
    __weak typeof(self) weakSelf = self;
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"请输入密码名称" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textAlignment = NSTextAlignmentCenter;
        textField.textColor = KDSRGBColor(0x10, 0x10, 0x10);
        textField.font = [UIFont systemFontOfSize:13];
        [textField addTarget:weakSelf action:@selector(textFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:Localized(@"cancel") style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        NSString *newNickname = ac.textFields.firstObject.text;
        if (newNickname.length && ![newNickname isEqualToString:weakSelf.lock.name])
        {
            self.pwdModel.nickName = newNickname;
            [self editBlePWDNickName:self.pwdModel];
        }
        
    }];
    [ac addAction:cancelAction];
    [ac addAction:okAction];
    [self presentViewController:ac animated:YES completion:nil];
}

#pragma mark 删除密码到服务器
- (void)deletePwdToServer:(KDSPwdListModel*)pwdListModel{
    NSArray *pwdlistarray = [[NSArray alloc] initWithObjects:pwdListModel, nil];
    [[KDSHttpManager sharedManager] deleteBlePwd:pwdlistarray withUid:[KDSUserManager sharedManager].user.uid bleName:self.lock.device.device_name success:^{
        NSLog(@"删除密码id = %@ 成功",pwdListModel.num);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUD];
            [MBProgressHUD showSuccess:@"删除成功"];
            [self.navigationController popViewControllerAnimated:YES];
        });
    } error:^(NSError * _Nonnull error) {
        NSLog(@"删除失败哦1");
        [MBProgressHUD showError:[Localized(@"saveFailed") stringByAppendingFormat:@"%ld", (long)error.localizedDescription]];
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"删除失败哦2%@",error.localizedDescription);
        [MBProgressHUD showError:[Localized(@"saveFailed") stringByAppendingString:error.localizedDescription]];
    }];
}
#pragma mark 发送蓝牙命令删除密码
-(void)deletUserToBleWithModel{
    [MBProgressHUD showMessage:@"正在删除"];
    KDSWeakSelf(self)
    [self.lock.bleTool manageKeyWithPwd:self.pwdModel.pwd userId:self.pwdModel.num action:KDSBleKeyManageActionDelete keyType:KDSBleKeyTypePIN completion:^(KDSBleError error) {
        if (error == KDSBleErrorSuccess || error == KDSBleErrorNotFound)
        {
            [weakself deletePwdToServer:self.pwdModel];
            return ;
        }
        [MBProgressHUD hideHUD];
        NSString *msg = error == KDSBleErrorSuccess ? Localized(@"deleteUserSuccess") : (weakself.errorMsgDict[@(error)] ?: Localized(@"deleteUserFailure"));
        [MBProgressHUD showSuccess:msg];
    }];
}
-(void)editBlePWDNickName:(KDSPwdListModel*)model{
    [MBProgressHUD showMessage:@"请稍后.."];
    [[KDSHttpManager sharedManager] setBlePwd:model withUid:[KDSUserManager sharedManager].user.uid bleName:self.lock.device.device_name  success:^{
        [MBProgressHUD hideHUD];
        [MBProgressHUD showSuccess:@"修改成功"];
        self.pwdnameLab.text = model.nickName;
    } error:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUD];
        NSLog(@"编辑昵称失败%@",error.localizedDescription);
        [MBProgressHUD showError:[NSString stringWithFormat:@"编辑失败:%@",error.localizedDescription]];
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUD];
        NSLog(@"编辑失败%@",error.localizedDescription);
        [MBProgressHUD showError:[NSString stringWithFormat:@"编辑失败:%@",error.localizedDescription]];
    }];
}
///密码昵称文本输入框，长度不能超过16
- (void)textFieldTextDidChange:(UITextField *)sender
{
    [sender trimTextToLength:-1];
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
