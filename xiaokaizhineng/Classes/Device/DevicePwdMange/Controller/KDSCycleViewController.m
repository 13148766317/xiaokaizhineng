//
//  KDSCycleViewController.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/12.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSCycleViewController.h"
#import "CBGroupAndStreamView.h"
#import "WSDatePickerView.h"
#import "UIView+BlockGesture.h"
#import "KDSCycleSelectViewController.h"
#import "MBProgressHUD+MJ.h"
#import "KDSHttpManager+Ble.h"
#import "KDSAddPwdSuccesVC.h"
#import "UIView+Extension.h"

@interface KDSCycleViewController ()<CBGroupAndStreamDelegate>
@property (weak, nonatomic) IBOutlet UIView *pwdView;
@property (weak, nonatomic) IBOutlet UIView *nameView;
@property (weak, nonatomic) IBOutlet UIView *scroContentView;
@property (strong, nonatomic) CBGroupAndStreamView * menueView;
@property (weak, nonatomic) IBOutlet UIView *startTimeView;
@property (weak, nonatomic) IBOutlet UIView *repeatRulesView;
@property (weak, nonatomic) IBOutlet UILabel *cycleStarLab;
@property (weak, nonatomic) IBOutlet UILabel *cycleEndLab;
@property (weak, nonatomic) IBOutlet UIView *cycleEndView;
@property (weak, nonatomic) IBOutlet UILabel *tipLab;
@property (weak, nonatomic) IBOutlet UITextField *nameLab;
@property (weak, nonatomic) IBOutlet UITextField *pwdLab;
@property (nonatomic, strong) NSMutableArray * selectArray;
///管理密钥错误对应的字典，键是错误码，值是错误信息。
@property (nonatomic, readonly) NSDictionary<NSNumber *, NSString *> *errorMsgDict;
@property (nonatomic, strong)WSDatePickerView *datepicker;
//生效时间，格式为NSString类型17：00
@property (nonatomic, copy) NSString *startTime;
@property (nonatomic, copy) NSString *endTime;
//生效时间，格式为NSDate类型17：00
@property (nonatomic, strong)NSDate *startDate;
@property (nonatomic, strong)NSDate *endDate;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UILabel *timeTipLab;
@property (weak, nonatomic) IBOutlet UIButton *randomBtn;
@property (weak, nonatomic) IBOutlet UIButton *addBtn;
@property (nonatomic, strong)NSMutableArray *bleeEistPwdArray;

@end

@implementation KDSCycleViewController
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    if ([KDSUserManager sharedManager].weekSelectArray.count != 0) {
        self.timeTipLab.hidden = NO;
        [self setTimeTip];
    }else{
        self.timeTipLab.hidden = YES;
    }
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    [[KDSUserManager sharedManager].weekSelectArray removeAllObjects];
}
- (NSMutableArray *)selectArray
{
    if (!_selectArray)
    {
        _selectArray = [NSMutableArray array];
    }
    return _selectArray;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUI];
    
    // Do any additional setup after loading the view from its nib.
}
-(void)setUI{
    
    [self.pwdLab addTarget:self action:@selector(pwdTextFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.nameLab addTarget:self action:@selector(textFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    [self.addBtn setTitle:Localized(@"AddaPassword") forState:UIControlStateNormal];
    [self.randomBtn setTitle:Localized(@"Randomlygenerated") forState:UIControlStateNormal];
    self.timeTipLab.hidden = YES;
    if (kScreenHeight <=667) {
        self.contentViewHeightConstraint.constant = 720;
    }else{
        self.contentViewHeightConstraint.constant = kScreenHeight;
    }
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
        self.nameLab.text = value;
    };
    //
    self.startTimeView.layer.shadowColor = KDSRGBColor(0xdd, 0xdd, 0xdd).CGColor;
    self.startTimeView.layer.shadowOffset = CGSizeMake(3, 3);
    self.startTimeView.layer.shadowOpacity = 1.0;
    self.startTimeView.clipsToBounds = NO;
    
    //
    self.cycleEndView.layer.shadowColor = KDSRGBColor(0xdd, 0xdd, 0xdd).CGColor;
    self.cycleEndView.layer.shadowOffset = CGSizeMake(3, 3);
    self.cycleEndView.layer.shadowOpacity = 1.0;
    self.cycleEndView.clipsToBounds = NO;
    
    //
    self.repeatRulesView.layer.borderColor = KDSRGBColor(238, 238, 238).CGColor;
    self.repeatRulesView.layer.borderWidth = 1;
    __weak typeof(self) weakSelf = self;
    [self.startTimeView addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
        [weakSelf showDatePickViewWith:@"start"];
        NSLog(@"点击了生效时间");
    }];
    [self.repeatRulesView addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
        KDSCycleSelectViewController *CVC = [[KDSCycleSelectViewController alloc] init];
        [weakSelf.navigationController pushViewController:CVC animated:YES];
        NSLog(@"点击了重复规则");
    }];
    [self.cycleEndView addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
        [weakSelf showDatePickViewWith:@"end"];
        NSLog(@"点击了终止时间");
    }];
    self.startTime = [self getCurrentTimes];
    self.endTime = [self getNextHourTime];
    _startDate =[NSDate dateWithTimeIntervalSince1970:[[self transTotimeSp:self.startTime] integerValue]];
    _endDate =[NSDate dateWithTimeIntervalSince1970:[[self transTotimeSp:self.endTime] integerValue]];
    [self setStartTimelabWithDate:_startDate];
    [self setEndTimelabWithDate:_endDate];
}
-(void)setTimeTip{
    NSString *timeStr = @"密码将于每";
    NSMutableArray * weekDay = [[NSMutableArray alloc] init];
    [[KDSUserManager sharedManager].weekSelectArray enumerateObjectsUsingBlock:^(NSString *i,NSUInteger idx,BOOL*_Nonnullstop) {
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
    NSString *second = [self.startTime  stringByAppendingString:[NSString stringWithFormat:@"-%@生效",self.endTime]];
    self.timeTipLab.text = [[timeStr stringByReplacingOccurrencesOfString:@"/" withString:@""] stringByAppendingString:second];
}
-(void)showDatePickViewWith:(NSString*)startOrEnd{
    NSString * s = [NSString stringWithFormat:@"%@ %@",[self getCurrentYMD],self.startTime ];
    NSDate * startDate =[NSDate dateWithTimeIntervalSince1970:[[self transTotimeSpYMD:s] integerValue]];
    NSString * e = [NSString stringWithFormat:@"%@ %@",[self getCurrentYMD],self.endTime ];
    NSDate * endDate =[NSDate dateWithTimeIntervalSince1970:[[self transTotimeSpYMD:e] integerValue]];
    __weak typeof(self) weakSelf = self;
    _datepicker = [[WSDatePickerView alloc] initWithDateStyle:DateStyleShowHourMinute scrollToDate:[startOrEnd isEqualToString:@"start"]?startDate:endDate startOrEnd:startOrEnd StartBlock:^(NSDate *selectDate) {
        [weakSelf setStartTimelabWithDate:selectDate];
    } EndBlock:^(NSDate *selectDate) {
        [weakSelf setEndTimelabWithDate:selectDate];
    }];
    _datepicker.hideBackgroundYearLabel = YES;
    _datepicker.dateLabelColor = KDSRGBColor(45, 217, 186);//年-月-日-时-分 颜色
    _datepicker.datePickerColor = [UIColor blackColor];//滚轮日期颜色
    _datepicker.doneButtonColor = KDSRGBColor(45, 217, 186);//确定按钮的颜色
    [_datepicker show];
}
- (IBAction)randomclick:(id)sender {
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

- (IBAction)addClick:(id)sender {
    NSLog(@"点击了确定生成");
    if (!([self.startTime compare:self.endTime]==NSOrderedAscending))
    {
        NSLog(@"a大于b");
        [MBProgressHUD showError:@"生效时间必须小于截止时间!"];
        return;
    }
    if (!self.lock.bleTool.connectedPeripheral) {
        [MBProgressHUD showError:@"您的设备没有连接"];
        return;
    }
    if (self.pwdLab.text.length == 0 || [self.pwdLab.text isEqual: @" "] || self.pwdLab.text.length < 6) {
        [MBProgressHUD showError:@"请输入6-12位数字密码"];
        return;
    }
    if ([KDSTool checkSimplePassword:self.pwdLab.text]) {
        [MBProgressHUD showError:@"密码过于简单"];
        return;
    }
    if (self.pwdLab.text.length == 0 || [self.nameLab.text isEqual: @" "]) {
        [MBProgressHUD showError:@"请输入密码名称"];
        return;
    }
    if ([KDSUserManager sharedManager].weekSelectArray.count == 0) {
        [MBProgressHUD showError:@"请选择重复规则"];
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
        NSString *msg = [NSString stringWithFormat:@"%@:%d", weakself.errorMsgDict[@(error)] ?: Localized(@"添加失败"), (int)error];
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
            if (pwdModel.pwdType == KDSServerKeyTpyePIN && pwdModel.num.intValue < 5) {
                [weakSelf.bleeEistPwdArray addObject:pwdModel];
            }
        }
        NSMutableArray *numArray = [[NSMutableArray alloc] init];
        if (weakSelf.bleeEistPwdArray.count != 0) {
            if (weakSelf.bleeEistPwdArray.count == 5 || self.lock.existPwdArray.count == 5) {
                [MBProgressHUD showError:@"您的密码库已满,请删除密码"];
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
        pwdModel.nickName = self.nameLab.text;
        pwdModel.pwd = self.pwdLab.text;
        pwdModel.num = pwdMax;
        [self addPwdWithPwdModel:pwdModel];
    }];
}
#pragma mark 设置用户年月日计划
-(void)setUserTypeOrYMDOrWeeklySchedule:(KDSPwdListModel *)pwdModel{
    //向蓝牙上传周计划
    self.startTime = self.cycleStarLab.text;
    self.endTime = self.cycleEndLab.text;
    int  scheduleID = [pwdModel.num intValue];
    char mask = 0;
    char op[7] = {0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40};
    self.selectArray = [KDSUserManager sharedManager].weekSelectArray;
    for (NSInteger i = _selectArray.count - 1; i >= 0; --i)
    {
        mask |= ([_selectArray[i] intValue] ? op[i] : 0x00);
    }
    int startHour =  [[self.startTime substringWithRange:NSMakeRange(0, 2)]intValue];
    int startMin =  [[self.startTime substringWithRange:NSMakeRange(3, 2)]intValue];
    int endHour =  [[self.endTime substringWithRange:NSMakeRange(0, 2)]intValue];
    int endMin =  [[self.endTime substringWithRange:NSMakeRange(3, 2)]intValue];
    __weak typeof(self) weakSelf = self;
    [self.lock.bleTool scheduleWeeklyWithScheduleId:scheduleID userId:[pwdModel.num intValue] keyType:KDSBleKeyTypePIN weekMask:mask beginHour:startHour beginMin:startMin endHour:endHour endMin:endMin completion:^(KDSBleError error) {
        if (error != KDSBleErrorSuccess)
        {
            [MBProgressHUD showError:Localized(@"保存失败")];
            return;
        }
        [weakSelf.lock.bleTool getWeeklyScheduleWithScheduleId:pwdModel.num.intValue completion:^(KDSBleError error, KDSBleWeeklyModel * _Nullable model) {
            if (error != KDSBleErrorSuccess || model.mask != mask || model.beginHour != startHour || model.beginMin != startMin || model.endHour != endHour || model.endMin != endMin)
            {
                [MBProgressHUD showError:Localized(@"保存失败")];
                return;
            }
            [weakSelf.lock.bleTool setUserTypeWithId:pwdModel.num KeyType:KDSBleKeyTypePIN userType:KDSBleSetUserTypeSchedule completion:^(KDSBleError error) {
                if (error != KDSBleErrorSuccess)
                {
                    [MBProgressHUD showError:Localized(@"保存失败")];
                    return;
                }
                [weakSelf addNewUserToSeversWithUid:pwdModel pwdtype:KDSServerKeyTpyePIN type:KDSServerCycleTpyeCycle];
            }];
        }];
    }];
}
-(void)setStartTimelabWithDate:(NSDate *)selectDate{
    NSString *dateString = [selectDate stringWithFormat:@"HH:mm"];
    NSLog(@"选择的开始日期：%@",dateString);
    self.cycleStarLab.text = dateString;
    self.startTime = dateString;
    [self setTimeTip];
}
-(void)setEndTimelabWithDate:(NSDate *)selectDate{
    NSString *dateString = [selectDate stringWithFormat:@"HH:mm"];
    NSLog(@"选择的截止日期：%@",dateString);
    self.cycleEndLab.text = dateString;
    self.endTime = dateString;
    [self setTimeTip];
}
#pragma mark 添加密码到服务器
- (void)addNewUserToSeversWithUid:(KDSPwdListModel*)pwdListModel pwdtype:(KDSServerKeyTpye)pwdtype type:(KDSServerCycleTpye)type{
    NSString *startTime = [[NSString alloc] initWithString:[self transTotimeSp:self.startTime?:@""]];
    NSString *endTime = [[NSString alloc] initWithString:[self transTotimeSp:self.endTime?:@""]];
    pwdListModel.type = type;
    pwdListModel.pwdType = pwdtype;
    pwdListModel.startTime = startTime;
    pwdListModel.endTime = endTime;
    pwdListModel.items =self.selectArray;
    NSArray *pwdlistarray = [[NSArray alloc] initWithObjects:pwdListModel, nil];
    __weak typeof(self) weakSelf = self;
    [[KDSHttpManager sharedManager] addNewUserToSeversWithGuest:[KDSUserManager sharedManager].user.uid bleName:self.lock.device.device_name pwdarray:pwdlistarray success:^(NSString * _Nonnull timeStr) {
        [MBProgressHUD hideHUD];
        [MBProgressHUD showSuccess:Localized(@"Addasuccess")];
        KDSAddPwdSuccesVC *vc = [[KDSAddPwdSuccesVC alloc] init];
        vc.createTimeStr = timeStr;
        vc.pwdModel = pwdListModel;
        [weakSelf.navigationController pushViewController:vc animated:YES];
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
-(NSString *)transTotimeSp:(NSString *)time{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]]; //设置本地时区
    [dateFormatter setDateFormat:@"HH:mm"];
    NSDate *date = [dateFormatter dateFromString:time];
    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[date timeIntervalSince1970]];//时间戳
    return timeSp;
}
-(NSString *)transTotimeSpYMD:(NSString *)time{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]]; //设置本地时区
    [dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm"];
    NSDate *date = [dateFormatter dateFromString:time];
    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[date timeIntervalSince1970]];//时间戳
    return timeSp;
}
//获取当前的时间
-(NSString*)getCurrentTimes{
    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm"];
    NSString *currentTimeString = [formatter stringFromDate:dat];
    return currentTimeString;
}
-(NSString*)getNextHourTime{
    NSDate *datenow = [NSDate date];
    NSDate *nextDay = [NSDate dateWithTimeInterval:60*60 sinceDate:datenow];//后一天
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm"];
    NSString *nextTimeString = [formatter stringFromDate:nextDay];
    return nextTimeString;
}
///时间戳转化为字符转0000-00-00 00:00
-(NSString *)time_timestampToStringWithHM:(NSInteger)timestamp{
    NSDate *confromTimesp = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter *dateFormat=[[NSDateFormatter alloc]init];
    [dateFormat setDateFormat:@"HH:mm"];
    NSString* string=[dateFormat stringFromDate:confromTimesp];
    return string;
}
-(NSString*)getCurrentYMD{
    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd"];
    NSString *currentTimeString = [formatter stringFromDate:dat];
    return currentTimeString;
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
