//
//  KDSAgingViewController.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/12.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSAgingViewController.h"
#import "CBGroupAndStreamView.h"
#import "WSDatePickerView.h"
#import "MBProgressHUD+MJ.h"
#import "KDSPwdListModel.h"
#import "KDSHttpManager+Ble.h"
#import "WeekModel.h"
#import "KDSAddPwdSuccesVC.h"
#import "KDSPwdListModel.h"
#import "UIView+Extension.h"

@interface KDSAgingViewController ()<CBGroupAndStreamDelegate>
@property (weak, nonatomic) IBOutlet UIView *numberView;
@property (weak, nonatomic) IBOutlet UIView *nameView;
@property (strong, nonatomic) CBGroupAndStreamView * menueView;
@property (weak, nonatomic) IBOutlet UIView *scroContentView;
///添加密码--时效，永久按钮
@property (weak, nonatomic) IBOutlet UIButton *permanentBtn;
///添加密码--时效，24小时按钮
@property (weak, nonatomic) IBOutlet UIButton *twentyFourBtn;
///添加密码--时效，自定义按钮
@property (weak, nonatomic) IBOutlet UIButton *customBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scroViewHeightConstant;
@property (weak, nonatomic) IBOutlet UIView *timeView;
@property (weak, nonatomic) IBOutlet UILabel *startYearLab;
@property (weak, nonatomic) IBOutlet UILabel *startMonthDayLab;
@property (weak, nonatomic) IBOutlet UILabel *startHourLab;
@property (weak, nonatomic) IBOutlet UILabel *startMuniteLab;
@property (weak, nonatomic) IBOutlet UILabel *endYearLab;
@property (weak, nonatomic) IBOutlet UILabel *endMonthDayLab;
@property (weak, nonatomic) IBOutlet UILabel *endMinuteLab;
@property (weak, nonatomic) IBOutlet UILabel *endHourLab;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *addPwdBtnTopConstant;
@property (weak, nonatomic) IBOutlet UILabel *tipLab;
//密码
@property (weak, nonatomic) IBOutlet UITextField *pwdLab;
//密码名称
@property (weak, nonatomic) IBOutlet UITextField *pwdNmaeLab;
///管理密钥错误对应的字典，键是错误码，值是错误信息。
@property (nonatomic, readonly) NSDictionary<NSNumber *, NSString *> *errorMsgDict;
@property (nonatomic, copy) NSString *permission;
//生效时间，格式为NSString类型2019-3-11 17：00
@property (nonatomic, copy) NSString *startTime;
//截止时间，格式为NSString类型2019-3-11 17：00
@property (nonatomic, copy) NSString *endTime;
//生效时间，格式为NSDate类型2019-3-11 17：00
@property (nonatomic, strong)NSDate *startDate;
//截止时间，格式为NSDate类型2019-3-11 17：00
@property (nonatomic, strong)NSDate *endDate;
@property (nonatomic, strong)NSMutableArray *bleeEistPwdArray;
@property (nonatomic, strong)WSDatePickerView *datepicker;
@property (weak, nonatomic) IBOutlet UIButton *randomBtn;
@property (weak, nonatomic) IBOutlet UIButton *addBtn;

@end

@implementation KDSAgingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setUI];
    
    // Do any additional setup after loading the view from its nib.
}
-(void)setUI{
    [self.pwdLab addTarget:self action:@selector(pwdTextFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.pwdNmaeLab addTarget:self action:@selector(textFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];

    [self.addBtn setTitle:Localized(@"AddaPassword") forState:UIControlStateNormal];
    [self.randomBtn setTitle:Localized(@"Randomlygenerated") forState:UIControlStateNormal];
    [self.permanentBtn setTitle:Localized(@"permanent") forState:UIControlStateNormal];
    [self.twentyFourBtn setTitle:Localized(@"Twentyfourhours") forState:UIControlStateNormal];
    [self.customBtn setTitle:Localized(@"custom") forState:UIControlStateNormal];
     self.scroViewHeightConstant.constant = 700;
    NSString *tips = @"提示：请打开手机蓝牙在门锁附近设置密码\n为确保您的安全，密码请自行保存，手机只显示名称";
    NSMutableAttributedString *attriStr = [[NSMutableAttributedString alloc] initWithString:tips attributes:@{NSForegroundColorAttributeName : KDSRGBColor(194, 194, 194)}];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:5];
    [attriStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [self.tipLab.text length])];
    [attriStr addAttribute:NSForegroundColorAttributeName value:KDSRGBColor(45, 217, 186) range:NSMakeRange(0, 2)];
    _tipLab.attributedText = attriStr;
    self.tipLab.lineBreakMode = NSLineBreakByCharWrapping;
    self.tipLab.textAlignment = NSTextAlignmentLeft;
    
    self.permanentBtn.selected = YES;
    self.permission = @"1";
    //密码视图添加阴影
    self.numberView.layer.shadowColor = KDSRGBColor(0xdd, 0xdd, 0xdd).CGColor;
    self.numberView.layer.shadowOffset = CGSizeMake(3, 3);
    self.numberView.layer.shadowOpacity = 1.0;
    self.numberView.clipsToBounds = NO;
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
    //自定义时间展示视图
    _timeView.layer.borderWidth = 1;
    _timeView.layer.borderColor = KDSRGBColor(238, 238, 238).CGColor;
    _timeView.hidden = YES;
    _addPwdBtnTopConstant.constant = 30;
}
- (IBAction)permanentClick:(id)sender {
    if (sender == self.permanentBtn) {
        self.permanentBtn.selected = YES;
        self.twentyFourBtn.selected = NO;
        self.customBtn.selected = NO;
        self.timeView.hidden = YES;
        self.scroViewHeightConstant.constant = 720;
        self.addPwdBtnTopConstant.constant = 30;
        self.permission = @"1";
        self.startTime = @"";
        self.endTime = @"";
        NSLog(@"选中永久");
    }else if (sender == self.twentyFourBtn){
        self.permanentBtn.selected = NO;
        self.twentyFourBtn.selected = YES;
        self.customBtn.selected = NO;
        self.timeView.hidden = YES;
        self.scroViewHeightConstant.constant = 700;
        self.addPwdBtnTopConstant.constant = 30;
        self.permission = @"2";
        self.startTime = [self getCurrentTimes];
        self.endTime = [self getNextDayTime];
        NSLog(@"选中24小时");
    }else if (sender == self.customBtn){
        self.permanentBtn.selected = NO;
        self.twentyFourBtn.selected = NO;
        self.customBtn.selected = YES;
        self.scroViewHeightConstant.constant = 720+100;
        self.timeView.hidden = NO;
        self.addPwdBtnTopConstant.constant = 220;
        self.permission = @"3";
        self.startTime = [self getCurrentTimes];
        self.endTime = [self getNextDayTime];
        _startDate =[NSDate dateWithTimeIntervalSince1970:[[self transTotimeSp:self.startTime] integerValue]];
        _endDate =[NSDate dateWithTimeIntervalSince1970:[[self transTotimeSp:self.endTime] integerValue]];
        [self setStartTimelabWithDate:_startDate];
        [self setEndTimelabWithDate:_endDate];
        NSLog(@"自定义");
    }
}
-(void)showDatePickViewWith:(NSString*)startOrEnd{
    _startDate =[NSDate dateWithTimeIntervalSince1970:[[self transTotimeSp:self.startTime] integerValue]];
    _endDate =[NSDate dateWithTimeIntervalSince1970:[[self transTotimeSp:self.endTime] integerValue]];
    _datepicker = [[WSDatePickerView alloc] initWithDateStyle:DateStyleShowYearMonthDayHourMinute scrollToDate:[startOrEnd isEqualToString:@"start"]?_startDate:_endDate startOrEnd:startOrEnd StartBlock:^(NSDate *selectDate) {
        [self setStartTimelabWithDate:selectDate];
    } EndBlock:^(NSDate *selectDate) {
        [self setEndTimelabWithDate:selectDate];
    }];
    _datepicker.hideBackgroundYearLabel = YES;
    _datepicker.dateLabelColor = KDSRGBColor(45, 217, 186);//年-月-日-时-分 颜色
    _datepicker.datePickerColor = [UIColor blackColor];//滚轮日期颜色
    _datepicker.doneButtonColor = KDSRGBColor(45, 217, 186);//确定按钮的颜色
    [_datepicker show];
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
//    self.pwdLab.text = [NSString stringWithFormat:@"%ld",(long)y];
    int a = arc4random() % 100000;
    NSString *str = [NSString stringWithFormat:@"%06d", a];
    self.pwdLab.text = [NSString stringWithFormat:@"%@",str];
}
- (IBAction)selectStartTimeClick:(id)sender {
    [self showDatePickViewWith:@"start"];
}
- (IBAction)selectEndTimeClick:(id)sender {
    [self showDatePickViewWith:@"end"];
}
///密码文本框文字改变后，限制长度不超过6-12位数字密码。
- (void)pwdTextFieldTextDidChange:(UITextField *)sender
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
///密码昵称文本框文字改变后，限制长度不超过16个字符。
- (void)textFieldTextDidChange:(UITextField *)sender
{
    [sender trimTextToLength:-1];
}
//MARK:添加密码---时效
- (IBAction)addClick:(id)sender {
    if (![self.permission isEqualToString:@"1"]) {
        if (!([self.startTime compare:self.endTime]==NSOrderedAscending))
        {
            NSLog(@"a大于b");
            [MBProgressHUD showError:@"生效时间必须小于截止时间!"];
            return;
        }
    }
    if (!self.lock.bleTool.connectedPeripheral) {
        [MBProgressHUD showError:@"您的设备没有连接"];
        return;
    }
     ///如果密码是空或者小于6位提示，如果大于12,提示输入6-12位数字密码
    if (self.pwdLab.text.length == 0 || [self.pwdLab.text isEqual: @" "] || self.pwdLab.text.length < 6) {
        [MBProgressHUD showError:@"请输入6-12位数字密码"];
        return;
    }
    if ([KDSTool checkSimplePassword:self.pwdLab.text]) {
        [MBProgressHUD showError:@"密码过于简单"];
        return;
    }
    if (self.pwdNmaeLab.text.length == 0 || [self.pwdNmaeLab.text isEqual: @" "]) {
        [MBProgressHUD showError:@"请输入密码名称"];
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
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakself setUserTypeOrYMDOrWeeklySchedule:model];
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
//        if (error == KDSBleErrorInvalidValue && ![weakself.dataArr containsObject:guest])
//        {
//            guest.unickname = guest.user_num;
//            [weakself addNewUserToSeversWithGuest:guest];
//        }
//    }];
    }];
}
#pragma mark 从锁中同步用户密码
-(void)getAvailablePWDNum{
    __weak typeof(self) weakSelf = self;
    static NSString * pwdMax;
    [self.lock.bleTool getAllUsersWithKeyType:KDSBleKeyTypePIN completion:^(KDSBleError error, NSArray<KDSBleUserType *> * _Nullable users) {
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
            if (pwdModel.pwdType == KDSServerKeyTpyePIN && pwdModel.num.intValue < 5) {
                [weakSelf.bleeEistPwdArray addObject:pwdModel];
            }
        }
        NSMutableArray *numArray = [[NSMutableArray alloc] init];
        if (weakSelf.bleeEistPwdArray.count != 0) {
            if (weakSelf.bleeEistPwdArray.count == 5 || self.lock.existPwdArray.count == 5) {
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"提示" message:@"密码库已满，请删除已有密码再添加" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *action = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:nil];
                [ac addAction:action];
                [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:ac animated:YES completion:nil];
                return;
            }
            for (KDSPwdListModel *pwdModel in weakSelf.bleeEistPwdArray) {
                [numArray addObject: pwdModel.num];
            }
            if (![numArray containsObject:@"00"]) {
                pwdMax = @"00";
            }else if (![numArray containsObject:@"01"]) {
                pwdMax = @"01";
            }else if (![numArray containsObject:@"02"]){
                pwdMax = @"02";
            }else if (![numArray containsObject:@"03"]){
                pwdMax = @"03";
            }else if (![numArray containsObject:@"04"]){
                pwdMax = @"04";
            }
        }else{
            pwdMax = @"00";
        }
        KDSPwdListModel * pwdModel = [[KDSPwdListModel alloc] init];
        pwdModel.nickName = self.pwdNmaeLab.text;
        pwdModel.pwd = self.pwdLab.text;
        pwdModel.num = pwdMax;
        [self addPwdWithPwdModel:pwdModel];
    }];
}
#pragma mark 设置用户年月日计划
-(void)setUserTypeOrYMDOrWeeklySchedule:(KDSPwdListModel *)pwdModel{
    KDSWeakSelf(self)
    if ([self.permission isEqualToString:@"1"]) {
        //设置永久
        [self addNewUserToSeversWithUid:pwdModel pwdtype:KDSServerKeyTpyePIN type:KDSServerCycleTpyeForever];
    }else if ([self.permission isEqualToString:@"2"]){
        //设置24小时
        NSString *begin = [self deleteSpecialCharacters:self.startTime];
        NSString *end = [self deleteSpecialCharacters:self.endTime];
        int  scheduleID = pwdModel.num.intValue;
        [self.lock.bleTool scheduleYMDWithScheduleId:scheduleID userId:pwdModel.num.intValue keyType:KDSBleKeyTypePIN begin:begin end:end completion:^(KDSBleError error) {
            if (error != KDSBleErrorSuccess)
            {
                [MBProgressHUD showError:Localized(@"设置失败")];
                return;
            }
            [weakself.lock.bleTool getYMDScheduleWithScheduleId:pwdModel.num.intValue completion:^(KDSBleError error, KDSBleYMDModel * _Nullable model) {
                if (error != KDSBleErrorSuccess)
                {
                    [MBProgressHUD showError:Localized(@"保存失败")];
                    return;
                }
                [weakself.lock.bleTool setUserTypeWithId:pwdModel.num KeyType:KDSBleKeyTypePIN userType:KDSBleSetUserTypeSchedule completion:^(KDSBleError error) {
                    if (error != KDSBleErrorSuccess)
                    {
                        [MBProgressHUD showError:Localized(@"保存失败")];
                        return;
                    }
                    [self addNewUserToSeversWithUid:pwdModel pwdtype:KDSServerKeyTpyePIN type:KDSServerCycleTpyeTwentyfourHours];
                }];
            }];
        }];
    }else{
        //设置自定义
        NSString *begin = [self deleteSpecialCharacters:self.startTime];
        NSString *end = [self deleteSpecialCharacters:self.endTime];
        int  scheduleID = pwdModel.num.intValue;
        [self.lock.bleTool scheduleYMDWithScheduleId:scheduleID userId:pwdModel.num.intValue keyType:KDSBleKeyTypePIN begin:begin end:end completion:^(KDSBleError error) {
            if (error != KDSBleErrorSuccess)
            {
                [MBProgressHUD showError:Localized(@"保存失败")];
                return;
            }
            [weakself.lock.bleTool getYMDScheduleWithScheduleId:pwdModel.num.intValue completion:^(KDSBleError error, KDSBleYMDModel * _Nullable model) {
                if (error != KDSBleErrorSuccess)
                {
                    [MBProgressHUD showError:Localized(@"保存失败")];
                    return;
                }
                [weakself.lock.bleTool setUserTypeWithId:pwdModel.num KeyType:KDSBleKeyTypePIN userType:KDSBleSetUserTypeSchedule completion:^(KDSBleError error) {
                    if (error != KDSBleErrorSuccess)
                    {
                        [MBProgressHUD showError:Localized(@"保存失败")];
                        return;
                    }
                    [self addNewUserToSeversWithUid:pwdModel pwdtype:KDSServerKeyTpyePIN type:KDSServerCycleTpyePeriod];
                }];
            }];
        }];
    }
}
#pragma mark 添加密码到服务器
- (void)addNewUserToSeversWithUid:(KDSPwdListModel*)pwdListModel pwdtype:(KDSServerKeyTpye)pwdtype type:(KDSServerCycleTpye)type{
    NSString *startTime = [[NSString alloc] initWithString:[self transTotimeSp:self.startTime?:@""]];
    NSString *endTime = [[NSString alloc] initWithString:[self transTotimeSp:self.endTime?:@""]];
    pwdListModel.type = type;
    pwdListModel.pwdType = pwdtype;
    pwdListModel.startTime = startTime;
    pwdListModel.endTime = endTime;
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
-(void)setStartTimelabWithDate:(NSDate *)selectDate{
    NSString *dateString = [selectDate stringWithFormat:@"yyyy-MM-dd HH:mm"];
    NSLog(@"选择的开始日期：%@",dateString);
    self.startYearLab.text = [NSString stringWithFormat:@"%@年",[dateString substringWithRange:NSMakeRange(0,4)]];
    NSString *monthStr = [NSString stringWithFormat:@"%@月",[dateString substringWithRange:NSMakeRange(5,2)]];
    NSString *dayhStr = [NSString stringWithFormat:@"%@日",[dateString substringWithRange:NSMakeRange(8,2)]];
    self.startMonthDayLab.text = [monthStr stringByAppendingString:dayhStr];
    self.startHourLab.text = [NSString stringWithFormat:@"%@",[dateString substringWithRange:NSMakeRange(11,2)]];
    self.startMuniteLab.text = [NSString stringWithFormat:@"%@",[dateString substringWithRange:NSMakeRange(14,2)]];
    self.startTime = dateString;
}
-(void)setEndTimelabWithDate:(NSDate *)selectDate{
    NSString *dateString = [selectDate stringWithFormat:@"yyyy-MM-dd HH:mm"];
    NSLog(@"选择的截止日期：%@",dateString);
    self.endYearLab.text = [NSString stringWithFormat:@"%@年",[dateString substringWithRange:NSMakeRange(0,4)]];
    NSString *monthStr = [NSString stringWithFormat:@"%@月",[dateString substringWithRange:NSMakeRange(5,2)]];
    NSString *dayhStr = [NSString stringWithFormat:@"%@日",[dateString substringWithRange:NSMakeRange(8,2)]];
    self.endMonthDayLab.text = [monthStr stringByAppendingString:dayhStr];
    self.endHourLab.text = [NSString stringWithFormat:@"%@",[dateString substringWithRange:NSMakeRange(11,2)]];
    self.endMinuteLab.text = [NSString stringWithFormat:@"%@",[dateString substringWithRange:NSMakeRange(14,2)]];
    self.endTime = dateString;
}
//获取当前的时间
-(NSString*)getCurrentTimes{
    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm"];
    NSString *currentTimeString = [formatter stringFromDate:dat];
    NSLog(@"currentTimeString =  %@",currentTimeString);
    return currentTimeString;
}
-(NSString*)getNextDayTime{
    NSDate *datenow = [NSDate date];
    NSDate *nextDay = [NSDate dateWithTimeInterval:24*60*60 sinceDate:datenow];//后一天
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm"];
    NSString *nextTimeString = [formatter stringFromDate:nextDay];
    NSLog(@"currentTimeString =  %@",nextTimeString);
    return nextTimeString;
}
//
-(NSString *)transTotimeSp:(NSString *)time{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]]; //设置本地时区
    [dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm"];
    NSDate *date = [dateFormatter dateFromString:time];
    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[date timeIntervalSince1970]];//时间戳
    return timeSp;
}
///时间戳转化为字符转0000-00-00 00:00
-(NSString *)time_timestampToString:(NSInteger)timestamp{
    NSDate *confromTimesp = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter *dateFormat=[[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm"];
    NSString* string=[dateFormat stringFromDate:confromTimesp];
    return string;
}
-(NSString *)deleteSpecialCharacters:(NSString *)currentStr {
    NSString *newStr = currentStr;
    newStr = [newStr stringByReplacingOccurrencesOfString:@"-" withString:@""];
    newStr = [newStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    newStr = [newStr stringByReplacingOccurrencesOfString:@":" withString:@""];
    newStr = [newStr stringByReplacingOccurrencesOfString:@"*" withString:@""];
    return newStr;
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
