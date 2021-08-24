//
//  KDSAddTempPwdViewController.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/15.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSAddTempPwdViewController.h"
#import "CBGroupAndStreamView.h"
#import "MBProgressHUD+MJ.h"
#import "KDSHttpManager+Ble.h"
#import "KDSAddPwdSuccesVC.h"
#import "UIView+Extension.h"

@interface KDSAddTempPwdViewController ()<CBGroupAndStreamDelegate>
@property (strong, nonatomic) CBGroupAndStreamView * menueView;
@property (weak, nonatomic) IBOutlet UIView *pwdView;
@property (weak, nonatomic) IBOutlet UIView *nameView;
@property (weak, nonatomic) IBOutlet UILabel *tipLab;
@property (weak, nonatomic) IBOutlet UIView *scroContentView;
@property (weak, nonatomic) IBOutlet UITextField *pwdLab;
//密码名称
@property (weak, nonatomic) IBOutlet UITextField *pwdNmaeLab;
///管理密钥错误对应的字典，键是错误码，值是错误信息。
@property (nonatomic, readonly) NSDictionary<NSNumber *, NSString *> *errorMsgDict;
@property (weak, nonatomic) IBOutlet UIButton *randomBtn;
@property (weak, nonatomic) IBOutlet UILabel *tempTipLab;
@property (weak, nonatomic) IBOutlet UIButton *generateBtn;
@property (nonatomic, strong)NSMutableArray *bleeEistPwdArray;
@end

@implementation KDSAddTempPwdViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationTitleLabel.text = Localized(@"AddaPassword");
    [self setUI];
    // Do any additional setup after loading the view from its nib.
}
-(void)setUI{
    self.pwdLab.placeholder = Localized(@"Pleaseenteryoursixtotwelvedigitpassword");
    self.pwdNmaeLab.placeholder = Localized(@"Pleaseenterthepasswordname");
    [self.pwdNmaeLab addTarget:self action:@selector(textFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.pwdLab addTarget:self action:@selector(pwdtextFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
    self.tempTipLab.text = Localized(@"Temporarypasswordscanonlybeusedonce");
    [self.generateBtn setTitle:Localized(@"generate") forState:UIControlStateNormal];
    [self.randomBtn setTitle:Localized(@"Randomlygenerated") forState:UIControlStateNormal];
    NSString *tips = @"提示：请打开手机蓝牙在门锁附近设置密码\n为确保您的安全，密码请自行保存，手机只显示名称";
    NSMutableAttributedString *attriStr = [[NSMutableAttributedString alloc] initWithString:tips attributes:@{NSForegroundColorAttributeName : KDSRGBColor(194, 194, 194)}];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:5];
    [attriStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [self.tipLab.text length])];
    [attriStr addAttribute:NSForegroundColorAttributeName value:KDSRGBColor(45, 217, 186) range:NSMakeRange(0, 2)];
    _tipLab.attributedText = attriStr;
    self.tipLab.lineBreakMode = NSLineBreakByCharWrapping;
    self.tipLab.textAlignment = NSTextAlignmentLeft;
    //密码视图添加阴影
    self.pwdView.layer.shadowColor = KDSRGBColor(0xdd, 0xdd, 0xdd).CGColor;
    self.pwdView.layer.shadowOffset = CGSizeMake(3, 3);
    self.pwdView.layer.shadowOpacity = 1.0;
    self.pwdView.clipsToBounds = NO;
    
    //名称视图添加阴影
    self.nameView.layer.shadowColor = KDSRGBColor(0xdd, 0xdd, 0xdd).CGColor;
    self.nameView.layer.shadowOffset = CGSizeMake(3, 3);
    self.nameView.layer.shadowOpacity = 1.0;
    self.nameView.clipsToBounds = NO;
    
    NSArray * titleArr = @[@"关系"];
    NSArray *contentArr = @[@[@"保姆",@"爷爷",@"奶奶",@"姐姐",@"姥爷",@"姥姥",@"妈妈",@"我"]];
    
    //标签选择视图
    CBGroupAndStreamView * silde = [[CBGroupAndStreamView alloc] initWithFrame:CGRectMake(40, CGRectGetMaxY(_nameView.frame)+20, [UIScreen mainScreen].bounds.size.width-80, 98)];
    silde.delegate = self;
    silde.isDefaultSel = YES;
    silde.isSingle = YES;
    silde.radius = 17;
    silde.font = [UIFont systemFontOfSize:12];
    silde.titleTextFont = [UIFont systemFontOfSize:18];
    silde.singleFlagArr = @[@1,@0,@1,@0];
    silde.defaultSelectIndex = 5;
    silde.defaultSelectIndexArr = @[@0,@[@1,@3],@0,@[@1,@9,@4]];
    silde.selColor = KDSRGBColor(248, 248, 248);
    [silde setContentView:contentArr titleArr:titleArr];
    [self.scroContentView addSubview:silde];
    _menueView = silde;
    silde.cb_confirmReturnValueBlock = ^(NSArray *valueArr, NSArray *groupIdArr) {
        NSLog(@"valueArr = %@ \ngroupIdArr = %@",valueArr,groupIdArr);
    };
    silde.cb_selectCurrentValueBlock = ^(NSString *value, NSInteger index, NSInteger groupId) {
        NSLog(@"value = %@----index = %ld------groupId = %ld",value,index,groupId);
        self.pwdNmaeLab.text = value;
    };
}
- (IBAction)randomClick:(id)sender {
//    NSMutableArray *array = [[NSMutableArray alloc] init];
//    NSInteger m = arc4random() %7;
//    NSInteger x = 1000000;
//    for (int i= 0; i<7; i++) {
//        NSUInteger n = arc4random() % x;
//        x = x*10;
//        [array addObject:[NSString stringWithFormat:@"%lu",(unsigned long)n]];
//    }
//    NSInteger  y= [[array objectAtIndex:m] integerValue];
    int a = arc4random() % 100000;
    NSString *str = [NSString stringWithFormat:@"%06d", a];
    self.pwdLab.text = [NSString stringWithFormat:@"%@",str];
}
///密码文本框文字改变后，限制长度不超过6-12位数字密码。
- (void)pwdtextFieldTextDidChange:(UITextField *)sender
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
    
}
///密码名称文本框文字改变后，限制长度不超过16个字符。
- (void)textFieldTextDidChange:(UITextField *)sender
{
    [sender trimTextToLength:-1];
}
- (IBAction)addclick:(id)sender {
    if (!self.lock.bleTool.connectedPeripheral) {
        [MBProgressHUD showError:@"您的设备没有连接"];
        return;
    }
    ///如果密码是空或者小于6位提示，如果大于12提示输入6-12位数字密码
    if (self.pwdLab.text.length == 0 || [self.pwdLab.text isEqual: @" "] || self.pwdLab.text.length < 6) {
        [MBProgressHUD showError:@"请输入6-12位数字密码"];
        return;
    }
    if (self.pwdNmaeLab.text.length == 0 || [self.pwdNmaeLab.text isEqual: @" "]) {
        [MBProgressHUD showError:@"请输入密码名称"];
        return;
    }
    if ([KDSTool checkSimplePassword:self.pwdLab.text]) {
        [MBProgressHUD showError:@"密码过于简单"];
        return;
    }
    [self getAvailablePWDNum];

}
#pragma mark 发送蓝牙命令添加密码
-(void)addPwdWithPwdModel:(KDSPwdListModel *)model{
    [MBProgressHUD showMessage:@"正在添加"];
    KDSWeakSelf(self)
    //添加密码 查询 删除 -03
    [self.lock.bleTool manageKeyWithPwd:model.pwd userId:model.num action:KDSBleKeyManageActionSet keyType:KDSBleKeyTypePIN completion:^(KDSBleError error) {
        if (error == KDSBleErrorSuccess)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakself addNewUserToSeversWithUid:model pwdtype:KDSServerKeyTpyeTempPIN type:@""];
            });
            return;
        }
        [MBProgressHUD hideHUD];
        NSString *msg;
        if (error == KDSBleErrorDuplicateExist) {
            msg = [NSString stringWithFormat:@"%@:%@", weakself.errorMsgDict[@(error)] ?: Localized(@"添加失败"), @"密码已存在"];
        }else{
            msg = [NSString stringWithFormat:@"%@", weakself.errorMsgDict[@(error)] ?: Localized(@"添加失败")];
        }
        [MBProgressHUD showError:msg];
    }];
}
#pragma mark 从锁中同步用户密码
-(void)getAvailablePWDNum{
    NSLog(@"正在锁中同步用户密码。。。。。。");
    __weak typeof(self) weakSelf = self;
    static NSString * pwdMax;
    [self.lock.bleTool getAllUsersWithKeyType:KDSBleKeyTypePIN completion:^(KDSBleError error, NSArray<KDSBleUserType *> * _Nullable users) {
        NSLog(@"锁中存在用户密码 %lu组",users.count);
        //添加服务器不存在，锁中存在的密码
        weakSelf.bleeEistPwdArray = [[NSMutableArray alloc] init];
        for (KDSBleUserType *user in users)
        {
            KDSPwdListModel *pwdModel = [[KDSPwdListModel alloc] init];
            pwdModel.num = pwdModel.nickName = [NSString stringWithFormat:@"%02lu", (unsigned long)user.userId];
            if (user.keyType == KDSBleKeyTypePIN) {
                pwdModel.pwdType = KDSServerKeyTpyePIN;
            }
            //通过密码类型判断是否存在时间计划
            if (pwdModel.pwdType == KDSServerKeyTpyePIN && pwdModel.num.intValue < 9 && pwdModel.num.intValue >4) {
                [weakSelf.bleeEistPwdArray addObject:pwdModel];
            }
        }
        NSMutableArray *numArray = [[NSMutableArray alloc] init];
        if (weakSelf.bleeEistPwdArray.count != 0) {
            if (weakSelf.bleeEistPwdArray.count == 4 || self.lock.existPwdArray.count == 4) {
                [MBProgressHUD showError:@"您的临时密码库已满,请删除密码"];
                return;
            }
            for (KDSPwdListModel *pwdModel in weakSelf.bleeEistPwdArray) {
                [numArray addObject: pwdModel.num];
            }
            if (![numArray containsObject:@"05"]) {
                pwdMax = @"05";
            }else if (![numArray containsObject:@"06"]) {
                pwdMax = @"06";
            }else if (![numArray containsObject:@"07"]){
                pwdMax = @"07";
            }else if (![numArray containsObject:@"08"]){
                pwdMax = @"08";
            }
        }else{
            pwdMax = @"05";
        }
        KDSPwdListModel * pwdModel = [[KDSPwdListModel alloc] init];
        pwdModel.nickName = self.pwdNmaeLab.text;
        pwdModel.pwd = self.pwdLab.text;
        pwdModel.num = pwdMax;
        [self addPwdWithPwdModel:pwdModel];
    }];
}
#pragma mark 添加密码到服务器
- (void)addNewUserToSeversWithUid:(KDSPwdListModel*)pwdListModel pwdtype:(KDSServerKeyTpye)pwdtype type:(KDSServerCycleTpye)type{
    pwdListModel.type = type;
    pwdListModel.pwdType = pwdtype;
    NSArray *pwdlistarray = [[NSArray alloc] initWithObjects:pwdListModel, nil];
    [[KDSHttpManager sharedManager] addNewUserToSeversWithGuest:[KDSUserManager sharedManager].user.uid bleName:self.lock.device.device_name pwdarray:pwdlistarray success:^(NSString * _Nonnull timeStr){
        [MBProgressHUD hideHUD];
        [MBProgressHUD showSuccess:Localized(@"Addasuccess")];
        KDSAddPwdSuccesVC *vc = [[KDSAddPwdSuccesVC alloc] init];
        vc.createTimeStr = timeStr;
        vc.pwdModel = pwdListModel;
        [self.navigationController pushViewController:vc animated:YES];
    } error:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUD];
        NSLog(@"添加失败哦2%@",error.localizedDescription);
        [MBProgressHUD showError:[Localized(@"saveFailed") stringByAppendingString:error.localizedDescription]];
    } failure:^(NSError * _Nonnull failure) {
        [MBProgressHUD hideHUD];
        NSLog(@"添加失败哦2%@",failure.localizedDescription);
        [MBProgressHUD showError:[Localized(@"saveFailed") stringByAppendingString:failure.localizedDescription]];
    }];
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
