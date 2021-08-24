//
//  KDSLockInfoVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/1/25.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSLockInfoVC.h"
#import "Masonry.h"
#import "KDSBluetoothTool.h"
#import "MBProgressHUD+MJ.h"
#import "KDSHttpManager+Ble.h"
#import "KDSBleBindVC.h"
#import "KDSDBManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import "KDSDFUViewController.h"


@interface KDSLockInfoVC () <KDSBluetoothToolDelegate>

///圆角视图。
@property (nonatomic, strong) UIView *cornerView;
///型号标签。
@property (nonatomic, strong) UILabel *modelLabel;
///浅绿色图片。该视图添加了2个手势，一个是长按开锁，一个是点击重新搜索外设。
@property (nonatomic, strong) UIImageView *imageView;
///浅绿色图片上的长按手势。
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGesture;
///提示蓝牙和锁状态的图片视图，例如蓝牙已关、锁已反锁等。
@property (nonatomic, strong) UIImageView *stateImageView;
///提示蓝牙和锁状态的标签，例如蓝牙已关、锁已反锁等。
@property (nonatomic, strong) UILabel *stateLabel;
///守护时间标签。
@property (nonatomic, strong) UILabel *durationLabel;
///守护时间按钮。
@property (nonatomic, strong) UIButton *durationBtn;
///电量标签。
@property (nonatomic, strong) UILabel *batteryLabel;
///电量按钮。
@property (nonatomic, strong) UIButton *batteryBtn;
///开锁次数标签。
@property (nonatomic, strong) UILabel *timesLabel;
///开锁次数按钮。
@property (nonatomic, strong) UIButton *timesBtn;
///蓝牙工具。
@property (nonatomic, strong) KDSBluetoothTool *bleTool;
///锁状态，用于设置状态标签和状态图片。
@property (nonatomic, assign) KDSLockState lockState;
///获取锁信息接口成功返回的锁信息，用于更新锁反锁等状态。
@property (nonatomic, strong) KDSBleLockInfoModel *lockInfo;
///锁型号。
@property (nonatomic, strong) NSString *lockModel;
///锁使用时长，单位天。
@property (nonatomic, strong) NSString *lockDuration;
///锁电量，初始化-1。
@property (nonatomic, assign) int lockEnergy;
///开锁次数。
@property (nonatomic, strong) NSString *lockUnlockTimes;

@end

@implementation KDSLockInfoVC

#pragma mark - 生命周期和界面设置方法
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.bleTool = [[KDSBluetoothTool alloc] initWithVC:self];
//        self.bleTool.onAdminModeBlock = ^{
//            [MBProgressHUD showError:Localized(@"onAdminModeTips")];
//        };
        _lockEnergy = -1;
        _lockState = KDSLockStateInitial;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.lock.bleTool = self.bleTool;
    self.lock.bleTool.isAdmin = self.lock.device.is_admin.boolValue;
    self.enablePulldown = YES;
    [self setupUI];
    int times = [[KDSDBManager sharedManager] queryUnlockTimesWithBleName:self.lock.device.device_name];
    if (times > 0)
    {
        self.lockUnlockTimes = @(times).stringValue;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lockDidOpen:) name:KDSLockDidOpenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lockDidClose:) name:KDSLockDidCloseNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localeLanguageDidChange:) name:KDSLocaleLanguageDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lockAuthentiateFailed:) name:KDSLockAuthFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lockDidReport:) name:KDSLockDidReportNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.lockState != self.lock.state)
    {
        self.lockState = self.lock.state;
    }
    self.bleTool.delegate = self;
    if (!self.bleTool.connectedPeripheral)
    {
        [self beginScanForPeripherals];
    }
    else
    {
        if (self.lockState == KDSLockStateUnauth)//锁鉴权失败时断开重新连接再次鉴权。
        {
            [self.bleTool endConnectPeripheral:self.bleTool.connectedPeripheral];
            return;
        }
        //如果在其它页面连接了蓝牙，设置正确的状态。
        else if ((NSInteger)self.lockState < (NSInteger)KDSLockStateNormal)
        {
            self.lockState = KDSLockStateNormal;
        }
        //有时会获取不到电量或开锁次数。
        if (self.bleTool.connectedPeripheral.power <= 0)
        {
            [self.bleTool getDeviceElectric];
        }
        if (!self.lockUnlockTimes)
        {
            [self getUnlockTimes];
        }
        if (self.lockModel.length == 0)
        {
            self.lockModel = self.bleTool.connectedPeripheral.lockModelType;
        }
        if (self.lockEnergy < 0)
        {
            self.lockEnergy = self.bleTool.connectedPeripheral.power;
        }
        __weak typeof(self) weakSelf = self;
        [self.bleTool getLockInfo:^(KDSBleError error, KDSBleLockInfoModel * _Nullable infoModel) {
            if (error == KDSBleErrorSuccess)
            {
                weakSelf.lockInfo = infoModel;
                weakSelf.lockState = weakSelf.lockState;
            }
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSTimeInterval interval = self.lock.device.currentTime - self.lock.device.createTime;
    [self setLockDuration:@((NSInteger)(interval / 24.0 / 3600)).stringValue];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.bleTool.delegate = nil;
    [self.bleTool endConnectPeripheral:self.bleTool.connectedPeripheral];
}

- (void)setupUI
{
    UIFont *fontSize12 = [UIFont systemFontOfSize:12];
    
    self.cornerView = [[UIView alloc] init];
    self.cornerView.backgroundColor = UIColor.whiteColor;
    self.cornerView.layer.cornerRadius = 5;
    [self.tableView addSubview:self.cornerView];
    [self.cornerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tableView).offset(15);
        //make.bottom.equalTo(self.tableView).offset(kScreenHeight < 667.0 ? -66 : -86);
        //make.left.equalTo(self.tableView).offset(kScreenWidth < 375 ? 20 : 28);
        //make.right.equalTo(self.tableView).offset(kScreenWidth < 375 ? -20 : -28);
        //只设置top和bottom约束高度会为0，宽度约束也同理.
        make.centerX.equalTo(self.tableView);
        make.width.mas_equalTo(kScreenWidth - (kScreenWidth < 375 ? 40 : 56));
        make.height.mas_equalTo(kScreenHeight - kStatusBarHeight - kNavBarHeight - 1 - 15 - (kScreenHeight < 667 ? 66 : 86) - self.tabBarController.tabBar.bounds.size.height);
    }];
    
    self.modelLabel = [[UILabel alloc] init];
    self.modelLabel.text = self.lock.device.model;
    self.modelLabel.textColor = KDSRGBColor(0x14, 0x14, 0x13);
    self.modelLabel.textAlignment = NSTextAlignmentCenter;
    self.modelLabel.font = fontSize12;
    [self.cornerView addSubview:self.modelLabel];
    [self.modelLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cornerView).offset(kScreenHeight < 667 ? 20 : 34);
        make.left.right.equalTo(self.cornerView);
        make.height.mas_equalTo(15);
    }];
    
    self.imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"homepageBleOpen"]];
    self.imageView.userInteractionEnabled = YES;
    self.longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressImageViewUnlock:)];
    [self.imageView addGestureRecognizer:self.longPressGesture];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImageViewScanOrRebindPeripheral:)];
    [self.imageView addGestureRecognizer:tap];
    [self.cornerView addSubview:self.imageView];
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.modelLabel.mas_bottom).offset(kScreenHeight < 667 ? 30 : 41);
        make.centerX.equalTo(self.cornerView);
        make.width.height.mas_equalTo(210);
    }];
    
    self.stateImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"homepageBleStateSearching"]];
    self.stateImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.cornerView addSubview:self.stateImageView];
    [self.stateImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imageView).offset(77);
        make.centerX.equalTo(self.imageView);
        make.width.height.mas_equalTo(35);
    }];
    
    self.stateLabel = [[UILabel alloc] init];
    self.stateLabel.font = fontSize12;
    self.stateLabel.textAlignment = NSTextAlignmentCenter;
    self.stateLabel.numberOfLines = 0;
    self.stateLabel.text = Localized(@"searchingLockBle");
    [self.cornerView addSubview:self.stateLabel];
    [self.stateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.stateImageView.mas_bottom).offset(9);
        make.left.equalTo(self.imageView).offset(29);
        make.right.equalTo(self.imageView).offset(-29);
        make.height.mas_lessThanOrEqualTo(30);
    }];
    
    //灰线
    UIView *lineView = [UIView new];
    lineView.backgroundColor = KDSRGBColor(0xf4, 0xf4, 0xf4);
    [self.cornerView addSubview:lineView];
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.cornerView);
        make.bottom.equalTo(self.cornerView).offset(-93);
        make.height.mas_equalTo(1);
    }];
    
    self.durationBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.durationBtn.userInteractionEnabled = NO;
    [self.durationBtn setImage:[UIImage imageNamed:@"homepageLockDuration"] forState:UIControlStateNormal];
    [self.durationBtn setTitle:Localized(@"lockDuration") forState:UIControlStateNormal];
    [self.durationBtn setTitleColor:KDSRGBColor(0x14, 0x14, 0x13) forState:UIControlStateNormal];
    self.durationBtn.imageEdgeInsets = UIEdgeInsetsMake(0, -2.5, 0, 0);
    self.durationBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -5);
    self.durationBtn.titleLabel.font = fontSize12;
    [self.cornerView addSubview:self.durationBtn];
    [self.durationBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cornerView).offset(kScreenWidth < 375 ? 20 : 22);
        make.bottom.equalTo(self.cornerView).offset(kScreenHeight < 667 ? -20 : -26);
        make.width.mas_equalTo(13 + 5 + ceil([Localized(@"lockDuration") sizeWithAttributes:@{NSFontAttributeName : fontSize12}].width));
        make.height.mas_equalTo(15);
    }];
    self.durationLabel = [[UILabel alloc] init];
    self.durationLabel.textAlignment = NSTextAlignmentCenter;
    NSTimeInterval interval = self.lock.device.currentTime - self.lock.device.createTime;
    [self setLockDuration:@((NSInteger)(interval / 24.0 / 3600)).stringValue];
    [self.cornerView addSubview:self.durationLabel];
    [self.durationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.cornerView);
        make.bottom.equalTo(self.durationBtn.mas_top).offset(-11);
        make.centerX.equalTo(self.durationBtn);
        make.height.mas_equalTo(15);
    }];
    
    self.batteryBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.batteryBtn.userInteractionEnabled = NO;
    [self.batteryBtn setImage:[UIImage imageNamed:@"homepageLock100Energy"] forState:UIControlStateNormal];
    [self.batteryBtn setTitle:Localized(@"lockEnergy") forState:UIControlStateNormal];
    [self.batteryBtn setTitleColor:KDSRGBColor(0x14, 0x14, 0x13) forState:UIControlStateNormal];
    self.batteryBtn.imageEdgeInsets = UIEdgeInsetsMake(0, -2.5, 0, 0);
    self.batteryBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -5);
    self.batteryBtn.titleLabel.font = fontSize12;
    [self.cornerView addSubview:self.batteryBtn];
    [self.batteryBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.cornerView);
        make.bottom.height.equalTo(self.durationBtn);
        make.width.mas_equalTo(15 + 5 + ceil([Localized(@"lockEnergy") sizeWithAttributes:@{NSFontAttributeName : fontSize12}].width));
    }];
    self.batteryLabel = [[UILabel alloc] init];
    self.batteryLabel.text = Localized(@"none");
    self.batteryLabel.font = fontSize12;
    self.batteryLabel.textColor = KDSRGBColor(0x14, 0x14, 0x13);
    self.batteryLabel.textAlignment = NSTextAlignmentCenter;
    [self.cornerView addSubview:self.batteryLabel];
    [self.batteryLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.batteryBtn).offset(-50);
        make.bottom.height.equalTo(self.durationLabel);
        make.right.equalTo(self.batteryBtn).offset(50);
    }];
    
    self.timesBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.timesBtn.userInteractionEnabled = NO;
    [self.timesBtn setImage:[UIImage imageNamed:@"homepageLockUnlockTime"] forState:UIControlStateNormal];
    [self.timesBtn setTitle:Localized(@"lockUnlockTime") forState:UIControlStateNormal];
    [self.timesBtn setTitleColor:KDSRGBColor(0x14, 0x14, 0x13) forState:UIControlStateNormal];
    self.timesBtn.imageEdgeInsets = UIEdgeInsetsMake(0, -2.5, 0, 0);
    self.timesBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -5);
    self.timesBtn.titleLabel.font = fontSize12;
    [self.cornerView addSubview:self.timesBtn];
    [self.timesBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.cornerView).offset(kScreenWidth < 375 ? -20 : -22);
        make.bottom.height.equalTo(self.durationBtn);
        make.width.mas_equalTo(15 + 5 + ceil([Localized(@"lockUnlockTime") sizeWithAttributes:@{NSFontAttributeName : fontSize12}].width));
    }];
    self.timesLabel = [[UILabel alloc] init];
    self.timesLabel.textAlignment = NSTextAlignmentCenter;
    [self.cornerView addSubview:self.timesLabel];
    [self.timesLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.timesBtn);
        make.bottom.height.equalTo(self.durationLabel);
        make.right.equalTo(self.cornerView);
    }];
}

- (void)loadNewData
{
    !self.pulldownRefreshBlock ?: self.pulldownRefreshBlock();
}

#pragma mark - 控件、手势等事件方法
///长按中间的浅绿色视图开锁
- (void)longPressImageViewUnlock:(UILongPressGestureRecognizer *)sender
{
    if (!self.bleTool.connectedPeripheral) return;
    if (sender.state == UIGestureRecognizerStateBegan && self.lockState == KDSLockStateNormal)
    {
        [self checkUnlockAuthThenDealWithResult];
    }
}

///当状态为没有搜索到蓝牙时，点击中间的浅绿色视图重新搜索外设。当状态为未鉴权时，跳去重新绑定。
- (void)tapImageViewScanOrRebindPeripheral:(UITapGestureRecognizer *)sender
{
    if (sender.state != UIGestureRecognizerStateEnded) return;
    if (self.lockState == KDSLockStateBleNotFound)
    {
        [self beginScanForPeripherals];
    }
    else if (self.lockState == KDSLockStateUnauth || self.lockState == KDSLockStateReset)
    {
        [self.bleTool endConnectPeripheral:self.bleTool.connectedPeripheral];
    }
    /*else if (self.lockState == KDSLockStateReset)
    {
        KDSBleBindVC *vc = [KDSBleBindVC new];
        vc.bleTool = self.bleTool;
        vc.bleTool.delegate = vc;
        vc.destPeripheral = self.bleTool.connectedPeripheral;
        vc.hasBinded = YES;
        vc.model = [self.lock.device.model containsString:@"X5"] ? KDSDeviceModelX5 : KDSDeviceModelT5;
        vc.step = 1;
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }*/
}

#pragma mark - 通知事件
///锁已打开
- (void)lockDidOpen:(NSNotification *)noti
{
    CBPeripheral *p = noti.userInfo[@"peripheral"];
    if (p != self.bleTool.connectedPeripheral) return;
    
    uint32_t state = self.lockInfo.lockState;
    state |= 0x00000004;
    self.lockInfo.lockState = state;
    [self setLockState:KDSLockStateUnlocked];
    [self getUnlockTimes];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self getUnlockResultThenReport];
    });
}

///锁已关闭
- (void)lockDidClose:(NSNotification *)noti
{
    CBPeripheral *p = noti.userInfo[@"peripheral"];
    if (p != self.bleTool.connectedPeripheral) return;
    [self setLockState:KDSLockStateClosed];
}

///收到更改了本地语言的通知，更新页面文字。
- (void)localeLanguageDidChange:(NSNotification *)noti
{
    self.lockState = self.lockState;
    self.lockModel = self.lockModel;
    self.lockDuration = self.lockDuration;
    self.lockEnergy = self.lockEnergy;
    self.lockUnlockTimes = self.lockUnlockTimes;
    
    UIFont *font = self.durationBtn.titleLabel.font;
    [self.durationBtn setTitle:Localized(@"lockDuration") forState:UIControlStateNormal];
    self.durationBtn.imageEdgeInsets = UIEdgeInsetsMake(0, -2.5, 0, 0);
    self.durationBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -5);
    [self.durationBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(13 + 5 + ceil([Localized(@"lockDuration") sizeWithAttributes:@{NSFontAttributeName : font}].width));
    }];
    
    [self.batteryBtn setTitle:Localized(@"lockEnergy") forState:UIControlStateNormal];
    self.batteryBtn.imageEdgeInsets = UIEdgeInsetsMake(0, -2.5, 0, 0);
    self.batteryBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -5);
    [self.batteryBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(15 + 5 + ceil([Localized(@"lockEnergy") sizeWithAttributes:@{NSFontAttributeName : font}].width));
    }];
    
    [self.timesBtn setTitle:Localized(@"lockUnlockTime") forState:UIControlStateNormal];
    self.timesBtn.imageEdgeInsets = UIEdgeInsetsMake(0, -2.5, 0, 0);
    self.timesBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -5);
    [self.timesBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(15 + 5 + ceil([Localized(@"lockUnlockTime") sizeWithAttributes:@{NSFontAttributeName : font}].width));
    }];
}

///锁鉴权失败，更改状态，保存日志到数据库。
- (void)lockAuthentiateFailed:(NSNotification *)noti
{
    CBPeripheral *peripheral = (CBPeripheral *)noti.userInfo[@"peripheral"];
    if (peripheral != self.bleTool.connectedPeripheral) return;
    NSInteger code = [noti.userInfo[@"code"] integerValue];
    self.lockState = /*code==0xc2 ? KDSLockStateReset : */KDSLockStateUnauth;
    NSString *bleName = peripheral.advDataLocalName, *nickname = nil;
    for (KDSLock *lock in [KDSUserManager sharedManager].locks)
    {
        if (lock.bleTool.connectedPeripheral == peripheral)
        {
            nickname = lock.device.device_nickname;
            break;
        }
    }
    KDSAuthException *exception = [KDSAuthException new];
    exception.bleName = bleName;
    exception.nickname = nickname;
    exception.date = [NSDate date];
    self.lock.bleTool.dateFormatter.dateFormat = @"yyyy/MM/dd HH:mm:ss";
    exception.dateString = [self.lock.bleTool.dateFormatter stringFromDate:exception.date];
    exception.code = (int)code;
    [[KDSDBManager sharedManager] insertAuthExceptions:@[exception]];
}

///锁上报信息。
- (void)lockDidReport:(NSNotification *)noti
{
    CBPeripheral *peripheral = (CBPeripheral *)noti.userInfo[@"peripheral"];
    NSData *data = (NSData *)noti.userInfo[@"data"];
    if (peripheral != self.bleTool.connectedPeripheral || data.length != 20) return;
    Byte *bytes = (Byte *)data.bytes;
    if (bytes[5] == 9)
    {
        int state = self.lockInfo.lockState;
        Byte byte = bytes[6];//1反锁0不反锁
        (byte & 0x1) ? (state &= 0xfffffffb) : (state |= 0x00000004);
        ((byte >> 1) & 0x1) ? (state |= 0x00000100) : (state &= 0xfffffeff);
        ((byte >> 2) & 0x1) ? (state |= 0x00000020) : (state &= 0xffffffdf);
        self.lockInfo.lockState = state;
        if (self.lockState != KDSLockStateUnlocking && self.lockState != KDSLockStateUnlocked)
        {
            [self setLockState:KDSLockStateNormal];
        }
    }
}

#pragma mark - 网络请求相关方法
///检查授权并处理结果(开锁或者提示没有授权)。
- (void)checkUnlockAuthThenDealWithResult
{
    [self setLockState:KDSLockStateUnlocking];
    //如果鉴权失败或者本地没有密码记录，弹框让用户输入密码。如果鉴权失败failed传YES，否则传NO代表本地没有密码记录。
    __weak typeof(self) weakSelf = self;
    void(^authenticateFailedOrNoPwd)(BOOL) = ^(BOOL failed){
        BOOL isRestricted = NO;
        KDSDBManager *manager = [KDSDBManager sharedManager];
        NSString *name = self.lock.device.device_name;
        int times = [manager queryPwdIncorrectTimesWithBleName:name];
        double serverTime = [KDSHttpManager sharedManager].serverTime;
        if (times == 1 && [KDSHttpManager sharedManager].serverTime > 0)
        {
            [manager updatePwdIncorrectFirstTime:serverTime withBleName:name];
        }
        else if (times > 9)
        {
            double time = [manager queryPwdIncorrectFirstTimeWithBleName:name];
            if (serverTime - time < 300)
            {
                isRestricted = YES;
                self.lockState = KDSLockStateNormal;;
            }
            else
            {
                [manager updatePwdIncorrectFirstTime:serverTime withBleName:name];
                [manager updatePwdIncorrectTimes:0 withBleName:name];
            }
        }
        NSString *title = failed ? Localized(@"checkUnlockAuthrizationFailed") : Localized(@"pleaseInputLockPassword");
        title = isRestricted ? Localized(@"unlockRestricted") : title;
        NSString *message = failed ? Localized(@"pleaseInputLockPassword") : nil;
        message = isRestricted ? Localized(@"pwdIncorrectTooMany") : message;
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        if (!isRestricted)
        {
            [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.keyboardType = UIKeyboardTypeNumberPad;
                textField.secureTextEntry = YES;
                textField.textAlignment = NSTextAlignmentCenter;
                textField.textColor = KDSRGBColor(0x10, 0x10, 0x10);
                textField.font = [UIFont systemFontOfSize:13];
                [textField addTarget:weakSelf action:@selector(textFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
            }];
        }
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:Localized(@"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            weakSelf.lockState = KDSLockStateNormal;
        }];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (isRestricted) return;
            NSString *pwd = [ac.textFields.firstObject.text stringByReplacingOccurrencesOfString:@" " withString:@""];
            if (pwd.length < 6 || pwd.length > 12) {
                
                    [MBProgressHUD showError:@"请输入正确的6-12位的数字密码"];
                    [weakSelf setLockState:KDSLockStateNormal];
            }else{
                
                  pwd.length==0 ? (void)(weakSelf.lockState = KDSLockStateNormal) : [weakSelf unlockWithPassword:pwd];
            }
          
        }];
        if (!isRestricted) [ac addAction:cancel];
        [ac addAction:ok];
        
        [self presentViewController:ac animated:YES completion:nil];
        
    };
    [[KDSHttpManager sharedManager] checkUnlockAuthWithUid:[KDSUserManager sharedManager].user.uid token:[KDSUserManager sharedManager].user.token bleName:self.lock.device.device_name isAdmin:self.lock.device.is_admin.boolValue isNewDevice:self.bleTool.connectedPeripheral.isNewDevice success:^{
        if (!self.lock.device.is_admin.boolValue)
        {
            [self unlockWithPassword:nil];
        }
        else
        {
            NSString *pwd = [[KDSDBManager sharedManager] queryUnlockPwdWithBleName:self.lock.device.device_name];
            
            pwd.length>0 ? [self unlockWithPassword:pwd] : authenticateFailedOrNoPwd(NO);
        }
    } error:^(NSError * _Nonnull error) {
        authenticateFailedOrNoPwd(YES);
    } failure:^(NSError * _Nonnull error) {
        authenticateFailedOrNoPwd(YES);
    }];
}

///获取开锁记录并向服务器上传记录。
- (void)getUnlockResultThenReport
{
    __weak typeof(self) weakSelf = self;
    KDSDBManager *manager = [KDSDBManager sharedManager];
    NSString *bleName = self.lock.device.device_name;
    __block NSString *data = [manager queryUploadRecordDataWithBleName:bleName type:0];
    [self.bleTool updateUnlockRecordAfterData:data completion:^(BOOL finished, KDSBleError error, NSArray<KDSBleUnlockRecord *> * _Nullable records) {
        if (finished)
        {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                data = data.length<12 ? @"0000000000000" : data;
                NSMutableArray<KDSBleUnlockRecord *> *mRecords = [NSMutableArray arrayWithArray:[manager queryRecord:0 bleName:bleName] ?: @[]];
                NSInteger index = -1;
                for (KDSBleUnlockRecord *record in records)
                {
                    if ([[record.hexString substringFromIndex:12] isEqualToString:[data substringFromIndex:12]])
                    {
                        index = [records indexOfObject:record];
                        break;
                    }
                    [mRecords containsObject:record] ?: [mRecords addObject:record];
                }
                [mRecords sortUsingComparator:^NSComparisonResult(KDSBleUnlockRecord *  _Nonnull obj1, KDSBleUnlockRecord *  _Nonnull obj2) {
                    return [obj2.unlockDate compare:obj1.unlockDate];
                }];
                if (index != -1 || records.firstObject.total == records.count)
                {
                    [manager updateUploadRecordData:records.firstObject.hexString withBleName:bleName type:0];
                }
                //获取完全部数据再在数据库中记录
                if (records.firstObject.total==records.count || [[records.lastObject.hexString substringFromIndex:12] isEqualToString:[data substringFromIndex:12]])
                {
                    [manager updateUploadRecordData:mRecords.firstObject.hexString withBleName:bleName type:0];
                }
                NSString *uid = [KDSUserManager sharedManager].user.uid;
                [[KDSHttpManager sharedManager] getBlePwdListWithUid:uid bleName:bleName pwdType:KDSServerKeyTpyeAll success:^(NSArray<KDSPwdListModel *> * _Nonnull pwdlistArray) {
                    NSMutableArray *news = [NSMutableArray array];
                    for (KDSBleUnlockRecord *record in mRecords)
                    {
                        News *n = [News new];
                        n.open_time = record.unlockDate;
                        n.open_type = record.unlockType;
                        n.user_num = record.userNum;
                        if ([n.open_type isEqualToString:@"密码"])
                        {
                            for (KDSPwdListModel *m in pwdlistArray)
                            {
                                if ((m.pwdType == KDSServerKeyTpyePIN || m.pwdType == KDSServerKeyTpyeTempPIN) && m.num.intValue == n.user_num.intValue)
                                {
                                    if (m.nickName) n.nickName = m.nickName;
                                    break;
                                }
                            }
                        }
                        else if ([n.open_type isEqualToString:@"卡片"])
                        {
                            for (KDSPwdListModel *m in pwdlistArray)
                            {
                                if (m.pwdType == KDSServerKeyTpyeCard && m.num.intValue == n.user_num.intValue)
                                {
                                    if (m.nickName) n.nickName = m.nickName;
                                    break;
                                }
                            }
                        }
                        else if ([n.open_type isEqualToString:@"指纹"])
                        {
                            for (KDSPwdListModel *m in pwdlistArray)
                            {
                                if (m.pwdType == KDSServerKeyTpyeFingerprint && m.num.intValue == n.user_num.intValue)
                                {
                                    if (m.nickName) n.nickName = m.nickName;
                                    break;
                                }
                            }
                        }
                        [news addObject:n];
                    }
                    [[KDSHttpManager sharedManager] uploadBindedDeviceUnlockRecord:news withUid:uid device:weakSelf.lock.device success:^{
                        [manager deleteRecord:0 bleName:bleName];
                    } error:^(NSError * _Nonnull error) {
                        [manager insertRecord:mRecords type:0 bleName:bleName];
                    } failure:^(NSError * _Nonnull error) {
                        [manager insertRecord:mRecords type:0 bleName:bleName];
                    }];
                } error:^(NSError * _Nonnull error) {
                    [manager insertRecord:mRecords type:0 bleName:bleName];
                } failure:^(NSError * _Nonnull error) {
                    [manager insertRecord:mRecords type:0 bleName:bleName];
                }];
            });
        }
    }];
}

#pragma mark - 蓝牙工具相关方法。
///搜索蓝牙，更新界面。
- (void)beginScanForPeripherals
{
    if (self.bleTool.centralManager.state != CBCentralManagerStatePoweredOn || self.bleTool.connectedPeripheral) return;
    [self.bleTool beginScanForPeripherals];
    self.lockState = KDSLockStateInitial;
}

/**
 *@abstract 通过蓝牙发送开锁命令。
 *@param password 开锁密码，如果此密码长度不为0，则使用此密码开锁(请确保密码长度为6~12字节)，否则使用不鉴权模式开锁。
 */
- (void)unlockWithPassword:(nullable NSString *)password
{
    __weak typeof(self) weakSelf = self;
    NSString *bleName = self.lock.device.device_name;
    KDSBleLockControl keytype = password.length>0 ? KDSBleLockControlKeyPIN : KDSBleLockControlKeyAPP;
    [self.bleTool operateLockWithPwd:password actionType:KDSBleLockControlActionUnlock keyType:keytype completion:^(KDSBleError error, CBPeripheral * _Nullable peripheral) {
        if (error == KDSBleErrorSuccess)
        {
            AudioServicesPlaySystemSound(1520);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (!weakSelf.lockInfo || (weakSelf.lockInfo.lockState>>7) & 1)
                {
                    if (weakSelf.lockState == KDSLockStateUnlocking)
                    {
                        weakSelf.lockState = KDSLockStateNormal;
                    }
                }
            });
        }
        else
        {
            [weakSelf setLockState:KDSLockStateFailed];
        }
        if (password.length)
        {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                if (error == KDSBleErrorSuccess)
                {
                    [[KDSDBManager sharedManager] updateUnlockPwd:password withBleName:bleName];
                }
                else if ((NSInteger)error <= 255)
//                else if (error == KDSBleErrorNotFound)
                {
                    [[KDSDBManager sharedManager] updateUnlockPwd:nil withBleName:bleName];
                }
            });
        }
    }];
}

///获取开锁次数。
- (void)getUnlockTimes
{
    __weak typeof(self) weakSelf = self;
    [self.bleTool getUnlockTimes:^(KDSBleError error, int times) {
        if (error == KDSBleErrorSuccess)
        {
            [weakSelf setLockUnlockTimes:@(times).stringValue];
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [[KDSDBManager sharedManager] updateUnlockTimes:times withBleName:weakSelf.lock.device.device_name];
            });
        }
    }];
}
///检查蓝牙固件是否需要升级
- (void)checkBleOTA{
    
    NSString *softwareRev = [self parseBluetoothVersion];
    //    NSLog(@"--{Kaadas}--检查OTA的softwareVer111=%@",softwareRev);
    //    NSLog(@"--{Kaadas}--检查OTA的deviceSN111:%@",self.lock.device.deviceSN);
    [[KDSHttpManager sharedManager] checkBleOTAWithSerialNumber:self.lock.device.deviceSN withCustomer:2 withVersion:softwareRev success:^(NSString *URL) {
        
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:Localized(@"tips") message:Localized(@"newImage") preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            //检测到DFU启动服务:1802->P6方案
            KDSDFUViewController *dfuVC = [[KDSDFUViewController alloc]init];
            dfuVC.url = URL;
            dfuVC.hidesBottomBarWhenPushed = YES;
            dfuVC.isBootLoadModel = YES;
            dfuVC.lock = self.lock;
            [self.navigationController pushViewController:dfuVC animated:YES];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:Localized(@"cancel") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.lock.bleTool endConnectPeripheral:self.lock.bleTool.connectedPeripheral];
        }];
        [ac addAction:okAction];
        [ac addAction:cancelAction];
        [self presentViewController:ac animated:YES completion:nil];
        
    } error:^(NSError * _Nonnull error) {
        
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:Localized(@"Lock OTA upgrade") message:[NSString stringWithFormat:@"%@",error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.bleTool endConnectPeripheral:self.bleTool.connectedPeripheral];
        }];
        [ac addAction:okAction];
        [self presentViewController:ac animated:YES completion:nil];
    } failure:^(NSError * _Nonnull error) {
        
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:Localized(@"Lock OTA upgrade") message:[NSString stringWithFormat:@"%@",error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.bleTool endConnectPeripheral:self.bleTool.connectedPeripheral];
        }];
        [ac addAction:okAction];
        [self presentViewController:ac animated:YES completion:nil];
    }];
    
}
/**
 解析蓝牙版本为存数字的字符串以便比较大小
 @return 蓝牙版本
 */
-(NSString *)parseBluetoothVersion{
    //截取出字符串后带了\u0000
    //    NSString *bleVesion = [self.lock.bleTool.connectedPeripheral.softwareVer componentsSeparatedByString:@"-"].lastObject;
    NSString *bleVesion ;
    if (!self.lock.bleTool.connectedPeripheral.softwareVer.length) {
        bleVesion = [self.lock.device.softwareVersion componentsSeparatedByString:@"-"].firstObject;
    }else{
        bleVesion = [self.lock.bleTool.connectedPeripheral.softwareVer componentsSeparatedByString:@"-"].firstObject;
    }
    //去掉NSString中的\u0000
    if (bleVesion.length > 9) {
        //挽救K9S、V6、V7第一版本的字符串带\u0000错误
        bleVesion = [bleVesion substringToIndex:9];
    }
    //去掉NSString中的V
    bleVesion = [bleVesion stringByReplacingOccurrencesOfString:@"V" withString:@""];
    //带T为测试固件
    bleVesion = [bleVesion stringByReplacingOccurrencesOfString:@"T" withString:@""];
    return bleVesion;
}
#pragma mark - KDSBluetoothToolDelegate
-(void)hasInBootload{
    KDSLog(@"--{Kaadas}--锁蓝牙已进入bootloadm模式");
    [self checkBleOTA];
    
}

- (void)discoverManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn)
    {
        self.imageView.userInteractionEnabled = YES;
        self.imageView.image = [UIImage imageNamed:@"homepageBleOpen"];
        [self beginScanForPeripherals];
    }
    else
    {
        self.imageView.userInteractionEnabled = NO;
        self.imageView.image = [UIImage imageNamed:@"homepageBleClosed"];
        self.lockState = KDSLockStateBleClosed;
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:nil message:Localized(@"pleaseOpenBle") preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:nil];
        [ac addAction:action];
        [self presentViewController:ac animated:YES completion:^{
            [self.bleTool stopScanPeripherals];
        }];
    }
}

- (void)didDiscoverPeripheral:(CBPeripheral *)peripheral
{
    if ([peripheral.advDataLocalName isEqualToString:self.lock.device.device_name]||[peripheral.identifier.UUIDString isEqualToString:self.lock.device.peripheralId])
    {
        [self.bleTool beginConnectPeripheral:peripheral];
    }
}

- (void)didConnectPeripheral:(CBPeripheral *)peripheral
{
    if (!peripheral.isNewDevice)
    {
        self.lockState = KDSLockStateNormal;
        self.lock.device.connected = YES;
    }
}

- (void)didDisConnectPeripheral:(CBPeripheral *)peripheral
{
    [MBProgressHUD showError:Localized(@"peripheralDidDisconnect") toView:self.view];
    [self setLockEnergy:-1];
    self.lock.device.connected = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self beginScanForPeripherals];
    });
}

- (void)centralManagerDidStopScan:(CBCentralManager *)cm
{
    if (!self.bleTool.connectedPeripheral)
    {
        self.lockState = KDSLockStateBleNotFound;
    }
}

- (void)didGetSystemID:(CBPeripheral *)peripheral
{
    __weak typeof(self) weakSelf = self;
    [self.bleTool authenticationWithPwd1:self.lock.device.password1 pwd2:self.lock.device.password2 completion:^(KDSBleError error) {
        
        if (error == KDSBleErrorSuccess)
        {
            weakSelf.lockState = KDSLockStateNormal;
            weakSelf.lock.device.connected = YES;
        }
        else if (error != KDSBleErrorDuplOrAuthenticating)
        {
            weakSelf.lockState = KDSLockStateUnauth;
        }
    }];
}

- (void)didReceiveDeviceElctInfo:(int)elct
{
    [self setLockEnergy:elct];
    __weak typeof(self) weakSelf = self;
    if (self.lockInfo == nil)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.bleTool getLockInfo:^(KDSBleError error, KDSBleLockInfoModel * _Nullable infoModel) {
                if (error == KDSBleErrorSuccess)
                {
                    weakSelf.lockInfo = infoModel;
                    if ((((infoModel.lockState >> 3) & 0x1) == 0) && (weakSelf.lockState == KDSLockStateUnlocked))
                    {
                        weakSelf.lockState = KDSLockStateNormal;
                    }
                    else if (((infoModel.lockState >> 3) & 0x1) == 1)
                    {
                        weakSelf.lockState = KDSLockStateUnlocked;
                    }
                    else
                    {
                        weakSelf.lockState = weakSelf.lockState;
                    }
                }
            }];
        });
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self getUnlockTimes];
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristicOfLockModel:(NSString *)model
{
    if (!model.length || [model caseInsensitiveCompare:@"xxxxxVx.x"]==NSOrderedSame) return;
    [self setLockModel:model];
    self.lock.device.model = model;
}

#pragma mark - setter：当蓝牙返回的锁状态发送改变时，刷新界面。
///锁及蓝牙状态改变时设置状态标签和图片，刷新界面。
- (void)setLockState:(KDSLockState)lockState
{
    _lockState = lockState;
    self.lock.state = lockState;
    
    switch (lockState)
    {
        case KDSLockStateInitial:
            self.stateImageView.image = [UIImage imageNamed:@"homepageBleStateSearching"];
            self.stateLabel.text = Localized(@"searchingLockBle");
            break;
            
        case KDSLockStateBleClosed:
            self.stateImageView.image = [UIImage imageNamed:@"homepageBleStateClosed"];
            self.stateLabel.text = Localized(@"bleNotOpen");
            break;
            
        case KDSLockStateBleNotFound:
            self.stateLabel.text = Localized(@"lockOutOfScope");
            self.stateImageView.image = [UIImage imageNamed:@"homepageBleStateNotFound"];
            break;
            
        case KDSLockStateReset://返回的值不能作为一定被重置的条件
        case KDSLockStateUnauth:
            self.stateLabel.text = Localized(@"lockAuthFailed");
            self.stateImageView.image = [UIImage imageNamed:@"homepageBleStateNotFound"];
            break;
            
        /*case KDSLockStateReset:
            self.stateLabel.text = Localized(@"lockHasBeenReset,rebind");
            self.stateImageView.image = [UIImage imageNamed:@"homepageBleStateNotFound"];
            break;*/
            
        case KDSLockStateNormal:
            if (self.lockInfo)
            {
                int32_t state = self.lockInfo.lockState;
                int32_t func = self.lockInfo.lockFunc;
                NSString *tips = nil, *imgName = nil;
                char defenceMode = ((state >> 8) & 1) && ((func >> 4) & 0x1);
                tips = defenceMode ? Localized(@"Defence&LongPressUnlock") : tips;
                imgName = defenceMode ? @"homepageDefence" : imgName;
                char lockInside = !((state >> 2) & 1) && ((func >> 14) & 0x1);
                tips = tips ?: (lockInside ? Localized(@"LockInside&unlockInside") : tips);
                imgName = imgName ?: (lockInside ? @"homepageLockInside" : imgName);
                char securityMode = ((state >> 5) & 1) && ((func >> 13) & 0x1);
                tips = tips ?: (securityMode ? Localized(@"Security&can'tUnlock") : tips);
                imgName = imgName ?: (securityMode ? @"首页指纹识别" : imgName);
                self.imageView.userInteractionEnabled = !(lockInside || securityMode);
                if (tips)
                {
                    self.stateImageView.image = [UIImage imageNamed:imgName];
                    self.stateLabel.text = tips;
                    break;
                }
            }
            self.stateImageView.image = [UIImage imageNamed:@"homepageBleStateSearching"];
            self.stateLabel.text = self.bleTool.connectedPeripheral ? Localized(@"bleDidConnect") : Localized(@"searchingLockBle");
            break;
            
        case KDSLockStateUnlocking:
            self.stateImageView.image = [UIImage imageNamed:@"homepageUnlocking"];
            self.stateLabel.text = Localized(@"unlocking");
            break;
            
        case KDSLockStateUnlocked:
        {
            self.stateImageView.image = [UIImage imageNamed:@"homepageUnlocked"];
            self.stateLabel.text = Localized(@"unlocked");
            //好像并不是所有的锁都会主动发送锁已关闭消息。
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (!self.lockInfo || (self.lockInfo.lockState>>7) & 1)
                {
                    self.lockState = KDSLockStateNormal;
                }
            });
        }
            break;
            
        case KDSLockStateFailed:
            [self setLockState:KDSLockStateNormal];
            break;
            
        case KDSLockStateClosed:
            [self setLockState:KDSLockStateNormal];
            break;
            
        default:
            break;
    }
}

///设置锁型号
- (void)setLockModel:(NSString *)model
{
    NSLog(@"model===%@",model);
//    model = @"xxxxxVx.x";
    model = (model && [model caseInsensitiveCompare:@"xxxxxVx.x"]!=NSOrderedSame) ? model : self.lock.device.model;
    _lockModel = model;
    NSLog(@"model===111==%@",model);

    if (model.length == 0)
    {
        self.modelLabel.text = nil;
        return;
    }
//    if ([model isEqualToString:@"X5"]) {
//        model = @"X5";
//    }else if([model isEqualToString:@"X5S"]){
//        model = @"X5S";
//    }else if([model isEqualToString:@"T5"]){
//        model = @"T5";
//    }else if([model isEqualToString:@"T5S"]) {
//        model = @"T5S";
//    }else{
//        model = @"T5";
//    }

    self.modelLabel.text = [Localized(@"lockModel") stringByAppendingFormat:@": %@", model];
}

///设置锁使用时间，单位(天)。
- (void)setLockDuration:(NSString *)days
{
    _lockDuration = days;
    if (days.length == 0)
    {
        self.durationLabel.attributedText = nil;
        return;
    }
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] init];
    NSAttributedString *electricAttr = [[NSAttributedString alloc] initWithString:days attributes:@{NSForegroundColorAttributeName : KDSRGBColor(0x2d, 0xd9, 0xba), NSFontAttributeName : [UIFont systemFontOfSize:17]}];
    [attrStr appendAttributedString:electricAttr];
    NSAttributedString *percentAttr = [[NSAttributedString alloc] initWithString:Localized(@"days") attributes:@{NSForegroundColorAttributeName : KDSRGBColor(0x20, 0x20, 0x20), NSFontAttributeName : [UIFont systemFontOfSize:11]}];
    [attrStr appendAttributedString:percentAttr];
    self.durationLabel.attributedText = attrStr;
}


/**
 *@abstract 设置锁电量。
 *@param energy 电量，如果为负数，会隐藏电量值。
 */
- (void)setLockEnergy:(int)energy
{
    _lockEnergy = energy;
    NSString *imgName = [KDSTool imageNameForPower:energy];
    [self.batteryBtn setImage:[UIImage imageNamed:imgName] forState:UIControlStateNormal];
    if (energy < 0)
    {
        self.batteryLabel.attributedText = nil;
        self.batteryLabel.text = Localized(@"none");
        return;
    }
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] init];
    NSAttributedString *electricAttr = [[NSAttributedString alloc] initWithString:@(energy).stringValue attributes:@{NSForegroundColorAttributeName : KDSRGBColor(0x2d, 0xd9, 0xba), NSFontAttributeName : [UIFont systemFontOfSize:17]}];
    [attrStr appendAttributedString:electricAttr];
    NSAttributedString *percentAttr = [[NSAttributedString alloc] initWithString:@"%" attributes:@{NSForegroundColorAttributeName : KDSRGBColor(0x20, 0x20, 0x20), NSFontAttributeName : [UIFont systemFontOfSize:11]}];
    [attrStr appendAttributedString:percentAttr];
    self.batteryLabel.attributedText = attrStr;
}

///设置开锁次数。
- (void)setLockUnlockTimes:(NSString *)times
{
    _lockUnlockTimes = times;
    if (times.length == 0)
    {
        self.timesLabel.attributedText = nil;
        return;
    }
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] init];
    NSAttributedString *electricAttr = [[NSAttributedString alloc] initWithString:times attributes:@{NSForegroundColorAttributeName : KDSRGBColor(0x2d, 0xd9, 0xba), NSFontAttributeName : [UIFont systemFontOfSize:17]}];
    [attrStr appendAttributedString:electricAttr];
    NSAttributedString *percentAttr = [[NSAttributedString alloc] initWithString:Localized(@"times") attributes:@{NSForegroundColorAttributeName : KDSRGBColor(0x20, 0x20, 0x20), NSFontAttributeName : [UIFont systemFontOfSize:11]}];
    [attrStr appendAttributedString:percentAttr];
    self.timesLabel.attributedText = attrStr;
}
///首页长按开锁密码输入框限制6-12位数字密码
-(void)textFieldTextDidChange:(UITextField *)sender{
    
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

@end
