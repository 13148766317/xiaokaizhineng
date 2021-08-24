//
//  KDSBleBindVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/12.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSBleBindVC.h"
#import "Masonry.h"
#import "KDSHttpManager+Ble.h"
#import "MBProgressHUD+MJ.h"
#import "KDSHelpViewController.h"
#import "UIView+Extension.h"

@interface KDSBleBindVC ()

///步骤标签。
@property (nonatomic, strong) UILabel *stepLabel;
///提示标签。
@property (nonatomic, strong) UILabel *tipsLabel;
///提示图片。
@property (nonatomic, strong) UIImageView *tipsIV;
///步骤按钮。
@property (nonatomic, strong) UIButton *stepBtn;
///锁型号，当代理执行时记录锁的型号。给个默认值X5，免得读取不到特征值时为空。
@property (nonatomic, strong) NSString *lockModel;
///pwd1，根据蓝牙返回的序列号从服务器获取，鉴权时用。
@property (nonatomic, strong) NSString *pwd1;
///记录是否绑定成功，如果绑定成功创建一个设备对象，跳到第三步是否锁定stepBtn按钮和发送通知时使用。
@property (nonatomic, strong) MyDevice *bindedDevice;
///表视图，用来防止挡住输入框的。
@property (nonatomic, strong) UITableView *tableView;
///输入锁昵称的文本框。
@property (nonatomic, strong) UITextField *textField;
///家按钮。
@property (nonatomic, strong) UIButton *homeBtn;
///卧室按钮。
@property (nonatomic, strong) UIButton *bedroomBtn;
///公司按钮。
@property (nonatomic, strong) UIButton *companyBtn;


@end

@implementation KDSBleBindVC

#pragma mark - getter setter
- (UITableView *)tableView
{
    if (!_tableView)
    {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.tableFooterView = [UIView new];
        [self.view addSubview:_tableView];
        [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.bottom.right.equalTo(self.view);
        }];
        [_tableView addSubview:self.tipsIV];
        [_tableView addSubview:self.stepLabel];
        [_tableView addSubview:self.stepBtn];
        [_tableView addSubview:self.textField];
        [_tableView addSubview:self.bedroomBtn];//先添加中间的按钮，两边的按钮约束已中间的为准。
        [_tableView addSubview:self.homeBtn];
        [_tableView addSubview:self.companyBtn];
        UIFont *font = [UIFont systemFontOfSize:13];
        NSString *bedroom = self.bedroomBtn.currentTitle;
        NSString *home = self.homeBtn.currentTitle;
        NSString *company = self.companyBtn.currentTitle;
        NSDictionary *attr = @{NSFontAttributeName : font};
        CGFloat bedroomWidth = [bedroom sizeWithAttributes:attr].width + 22;
        CGFloat homeWidth = [home sizeWithAttributes:attr].width + 22;
        CGFloat companyWidth = [company sizeWithAttributes:attr].width + 22;
        CGFloat btnsWidth = bedroomWidth + homeWidth + companyWidth;
        //V:[2.5-btn-1-btn-1-btn-2.5]比例
        CGFloat space = (kScreenWidth - btnsWidth) / 7.0;
        [_bedroomBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.textField.mas_bottom).offset(16);
            make.centerX.equalTo(self.view);
            make.width.mas_equalTo(bedroomWidth);
            make.height.mas_equalTo(34);
        }];
        [_homeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.topMargin.bottomMargin.equalTo(self.bedroomBtn);
            make.right.equalTo(self.bedroomBtn.mas_left).offset(-space);
            make.width.mas_equalTo(homeWidth);
        }];
        [_companyBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.topMargin.bottomMargin.equalTo(self.bedroomBtn);
            make.left.equalTo(self.bedroomBtn.mas_right).offset(space);
            make.width.mas_equalTo(companyWidth);
        }];
    }
    return _tableView;
}

- (UITextField *)textField
{
    if (!_textField)
    {
        _textField = [[UITextField alloc] init];
        _textField.backgroundColor = UIColor.whiteColor;
        _textField.textColor = KDSRGBColor(0x33, 0x33, 0x33);
        [_textField addTarget:self action:@selector(textFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
        _textField.layer.cornerRadius = 25;
        _textField.layer.shadowColor = KDSRGBColor(0xdd, 0xdd, 0xdd).CGColor;
        _textField.layer.shadowOffset = CGSizeMake(3, 3);
        _textField.layer.shadowOpacity = 1;
        CGFloat width = 300;
        CGFloat height = kScreenHeight < 667 ? 40 : 50;
        [self.tableView addSubview:_textField];
        [_textField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.stepLabel.mas_bottom).offset(kScreenHeight < 667 ? 30 : 60);
            make.centerX.equalTo(self.tableView);
            make.width.mas_equalTo(width);
            make.height.mas_equalTo(height);
        }];
        UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 27, height)];
        _textField.leftView = leftView;
        _textField.leftViewMode = UITextFieldViewModeAlways;
        UIView *rightView = [[UIView alloc] initWithFrame:CGRectMake(width - 46, 0, 46, height)];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(0, 0, 20, height);
        [btn setImage:[UIImage imageNamed:@"deviceEditNickname"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(clickEditBtnEditLockNickname:) forControlEvents:UIControlEventTouchUpInside];
        [rightView addSubview:btn];
        _textField.rightView = rightView;
        _textField.rightViewMode = UITextFieldViewModeAlways;
    }
    return _textField;
}

- (UIButton *)homeBtn
{
    if (!_homeBtn)
    {
        _homeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _homeBtn.layer.cornerRadius = 17;
        _homeBtn.layer.borderColor = KDSRGBColor(0xee, 0xee, 0xee).CGColor;
        _homeBtn.layer.borderWidth = 1;
        NSString *title = Localized(@"myHome");
        [_homeBtn setTitle:title forState:UIControlStateNormal];
        [_homeBtn setTitleColor:KDSRGBColor(0x33, 0x33, 0x33) forState:UIControlStateSelected];
        [_homeBtn setTitleColor:KDSRGBColor(0x8f, 0x92, 0xa6) forState:UIControlStateNormal];
        _homeBtn.selected = YES;
        [_homeBtn addTarget:self action:@selector(selectLockProperty:) forControlEvents:UIControlEventTouchUpInside];
        UIFont *font = [UIFont systemFontOfSize:13];
        _homeBtn.titleLabel.font = font;
        _homeBtn.backgroundColor = KDSRGBColor(0xf8, 0xf8, 0xf8);
    }
    return _homeBtn;
}

- (UIButton *)bedroomBtn
{
    if (!_bedroomBtn)
    {
        _bedroomBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _bedroomBtn.layer.cornerRadius = 17;
        _bedroomBtn.layer.borderColor = KDSRGBColor(0xee, 0xee, 0xee).CGColor;
        _bedroomBtn.layer.borderWidth = 1;
        NSString *title = Localized(@"myBedroom");
        [_bedroomBtn setTitle:title forState:UIControlStateNormal];
        [_bedroomBtn setTitleColor:KDSRGBColor(0x8f, 0x92, 0xa6) forState:UIControlStateNormal];
        [_bedroomBtn setTitleColor:KDSRGBColor(0x33, 0x33, 0x33) forState:UIControlStateSelected];
        UIFont *font = [UIFont systemFontOfSize:13];
        _bedroomBtn.titleLabel.font = font;
        _bedroomBtn.backgroundColor = UIColor.whiteColor;
        [_bedroomBtn addTarget:self action:@selector(selectLockProperty:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _bedroomBtn;
}

- (UIButton *)companyBtn
{
    if (!_companyBtn)
    {
        _companyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _companyBtn.layer.cornerRadius = 17;
        _companyBtn.layer.borderColor = KDSRGBColor(0xee, 0xee, 0xee).CGColor;
        _companyBtn.layer.borderWidth = 1;
        NSString *title = Localized(@"myCompany");
        [_companyBtn setTitle:title forState:UIControlStateNormal];
        [_companyBtn setTitleColor:KDSRGBColor(0x8f, 0x92, 0xa6) forState:UIControlStateNormal];
        [_companyBtn setTitleColor:KDSRGBColor(0x33, 0x33, 0x33) forState:UIControlStateSelected];
        UIFont *font = [UIFont systemFontOfSize:13];
        _companyBtn.titleLabel.font = font;
        _companyBtn.backgroundColor = UIColor.whiteColor;
        [_companyBtn addTarget:self action:@selector(selectLockProperty:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _companyBtn;
}


#pragma mark - 生命周期和界面设置方法
- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.step = 0;
        self.bindedDevice = nil;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationTitleLabel.text = Localized(@"addDoorLock");
    UIView * supView = [UIView new];
    supView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:supView];
    [supView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(0);
        make.top.mas_equalTo(self.view.mas_top).offset(8);
    }];
    self.stepLabel = [[UILabel alloc] init];
    self.stepLabel.text = Localized(@"bleBindStep1");
    self.stepLabel.textColor = KDSRGBColor(0x14, 0x14, 0x14);
    self.stepLabel.font = [UIFont systemFontOfSize:18];
    self.stepLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.stepLabel];
    [self.stepLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(kScreenHeight < 667.0 ? 10 : 38);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(ceil([self.stepLabel.text sizeWithAttributes:@{NSFontAttributeName : self.stepLabel.font}].height));
    }];
    
    self.tipsLabel = [[UILabel alloc] init];
    self.tipsLabel.text = Localized(@"bleBindTips1");
    self.tipsLabel.numberOfLines = 0;
    self.tipsLabel.textColor = KDSRGBColor(0x86, 0x86, 0x86);
    self.tipsLabel.font = [UIFont systemFontOfSize:12];
    self.tipsLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.tipsLabel];
    [self.tipsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.stepLabel.mas_bottom).offset(10);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
        make.height.mas_lessThanOrEqualTo(108);///<=9行
    }];
    
    self.stepBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.stepBtn setTitle:Localized(@"nextStep") forState:UIControlStateNormal];
    [self.stepBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.stepBtn.backgroundColor = KDSRGBColor(0x2d, 0xd9, 0xba);
    self.stepBtn.layer.cornerRadius = 30;
    [self.stepBtn addTarget:self action:@selector(stepBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.stepBtn];
    [self.stepBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(kScreenHeight < 667.0 ? -10 : -43);
        make.width.mas_equalTo(kScreenWidth < 375 ? kScreenWidth - 76 : 300);
        make.height.mas_equalTo(60);
    }];
    
    self.tipsIV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"添加门锁-1"]];
    [self.view addSubview:self.tipsIV];
    [self.tipsIV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.stepBtn.mas_top).offset(kScreenHeight < 667.0 ? -10 : -48);
        make.width.mas_equalTo(234);
        make.height.mas_equalTo(284);
    }];
    
    if (self.step == 1)
    {
        self.stepBtn.tag = 1;
        [self stepBtnAction:self.stepBtn];
    }
    
    //导航栏帮助按钮。
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:@"deviceBleSearchHelp"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(showDeviceBleSearchHelp:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.rightBarButtonItem = item;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.bleTool.isBinding = !self.hasBinded;
    //锁被重置时跳进来已经有序列号了。
    if (self.destPeripheral.serialNumber.length)
    {
        //由于解密退网收到的数据的时候要使用密码1+<00 00 00 00>，不能使用密码1+密码2，否则解密的数据不对，因此这里要置空密码2
        self.bleTool.pwd2 = nil;
        self.bleTool.pwd3 = nil;
        [self didGetDeviceSN:self.destPeripheral.serialNumber];
    }
    
    if (!self.bleTool.connectedPeripheral && self.step == 1)
    {
        [MBProgressHUD showMessage:Localized(@"connectingLock") toView:self.view];
        [self.bleTool beginConnectPeripheral:self.destPeripheral];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.bleTool.isBinding = NO;
    [self.bleTool endConnectPeripheral:self.destPeripheral];
}

- (void)dealloc
{
    if (self.bleTool.connectedPeripheral)
    {
        [self.bleTool endConnectPeripheral:self.bleTool.connectedPeripheral];
    }
    if (self.bindedDevice)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:KDSLockHasBeenAddedNotification object:nil userInfo:@{@"device" : self.bindedDevice}];
    }
}

#pragma mark - 控件等事件。
///点击下一步或入网按钮，更改提示语和图片等界面。
- (void)stepBtnAction:(UIButton *)sender
{
    sender.tag = (sender.tag + 1) % 5;
    switch (sender.tag)
    {
        case 0://添加且取名完成。
            sender.tag = 4;
            [self alterLockNickname];
            break;
            
        case 1:
        {
            KDSBleSearchTableVC *vc = [[KDSBleSearchTableVC alloc] init];
            vc.model = self.model;
            sender.tag = 0;
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        case 2:
        {
            self.stepLabel.text = Localized(@"bleBindStep2");
            self.tipsLabel.text = Localized(@"bleBindTips2");
           
            self.tipsIV.image = [UIImage imageNamed:self.model == (KDSDeviceModelT5 || KDSDeviceModelT5S) ? @"deviceBleBindStep2T5" : @"deviceBleBindStep2X5"];
        }
            break;
            
        case 3:
            self.stepLabel.text = Localized(@"bleBindStep3");
//            self.tipsLabel.text = Localized(self.bleTool.isBinding && (self.model == KDSDeviceModelX5S || self.model == KDSDeviceModelT5S) ? @"bleBindTips3" : @"thisDeviceHasBeenBindedTips");
            if (self.bleTool.isBinding) {
                if (self.model == KDSDeviceModelX5S || self.model == KDSDeviceModelT5S) {
                    self.tipsLabel.text = Localized(@"bleBindTips3-2");
                }else if (self.model == KDSDeviceModelX5 || self.model == KDSDeviceModelT5){
                    self.tipsLabel.text = Localized(@"bleBindTips3-1");
                }
            }else{
                self.tipsLabel.text = Localized(@"thisDeviceHasBeenBindedTips");
            }
            
            self.tipsIV.image = [UIImage imageNamed:self.model == (KDSDeviceModelT5 || KDSDeviceModelT5S) ? @"deviceBleBindStep3T5" : @"deviceBleBindStep3X5"];
            [self.stepBtn setTitle:Localized(@"bleBindSuccess") forState:UIControlStateNormal];
            if (!self.bindedDevice)//如果绑定成功后已经直接跳到第三步且略过。
            {
                [self.stepBtn setTitle:Localized(@"bleBindSuccess") forState:UIControlStateDisabled];
                [self.stepBtn setTitleColor:UIColor.lightGrayColor forState:UIControlStateDisabled];
                sender.enabled = NO;//锁定按钮，等到绑定成功后再激活。
            }
            break;
            
        case 4://完成界面，删除之前的子视图，添加完成子视图。
        {
            [self.tipsLabel removeFromSuperview];
            self.tipsLabel = nil;
            [self.stepBtn setTitle:Localized(@"done") forState:UIControlStateNormal];
            self.tipsIV.image = [UIImage imageNamed:@"deviceBindDone"];
            [self tableView];
            [self.tipsIV mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.tableView).offset(kScreenHeight < 667 ? 20 : 47);
                make.centerX.equalTo(self.tableView);
                make.width.mas_equalTo(116);
                make.height.mas_equalTo(103);
            }];
            self.stepLabel.text = Localized(@"deviceBindDone");
            self.stepLabel.font = [UIFont systemFontOfSize:18];
            [self.stepLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.tipsIV.mas_bottom).offset(kScreenHeight < 667 ? 20 : 41);
                make.left.right.equalTo(self.view);
                make.height.mas_equalTo(ceil([self.stepLabel.text sizeWithAttributes:@{NSFontAttributeName : self.stepLabel.font}].height));
            }];
        }
            break;
            
        default:
            break;
    }
}

///显示设备蓝牙搜索帮助界面。
- (void)showDeviceBleSearchHelp:(UIButton *)sender
{
    KDSHelpViewController *vc = [[KDSHelpViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

///点击文本框上的编辑按钮编辑锁的昵称。
- (void)clickEditBtnEditLockNickname:(UIButton *)sender
{
    [self.textField becomeFirstResponder];
}

///锁昵称文本框文字改变后，限制长度不超过50个字符。
- (void)textFieldTextDidChange:(UITextField *)sender
{
    [sender trimTextToLength:-1];
}

///点击家、卧室、公司按钮，设置锁的属性。
- (void)selectLockProperty:(UIButton *)sender
{
    self.homeBtn.backgroundColor = self.bedroomBtn.backgroundColor = self.companyBtn.backgroundColor = UIColor.whiteColor;
    sender.backgroundColor = KDSRGBColor(0xf8, 0xf8, 0xf8);
    self.homeBtn.selected = self.bedroomBtn.selected = self.companyBtn.selected = NO;
    sender.selected = YES;
    self.textField.text = sender.currentTitle;
}

#pragma mark - 网络请求相关方法。
/**
 *@abstract 根据蓝牙返回的SN获取pwd1。
 *@param sn 蓝牙返回的序列号。
 */
- (void)getPwd1WithSN:(NSString *)sn
{
    MBProgressHUD *hud = [MBProgressHUD showMessage:Localized(@"fetchingInfo,pleaseWait") toView:self.view];
    [[KDSHttpManager sharedManager] getPwd1WithSN:sn success:^(NSString * _Nonnull pwd1) {
        self.pwd1 = pwd1;
        self.bleTool.pwd1 = pwd1;
        [hud hide:NO];
    } error:^(NSError * _Nonnull error) {
        [hud hide:NO];
        [MBProgressHUD showError:Localized(@"fetchingInfoFailed")];
    } failure:^(NSError * _Nonnull error) {
        [hud hide:NO];
        [MBProgressHUD showError:Localized(@"fetchingInfoFailed")];
    }];
}

///绑定设备。
- (void)bindDevice
{
    NSString *uid = [KDSUserManager sharedManager].user.uid;
    NSString *peripheralName = self.destPeripheral.advDataLocalName;
    NSString *pwd2 = [self.bleTool convertFromDataToHexStr:self.bleTool.pwd2];
    MyDevice *dev = [MyDevice new];
    dev.password1 = self.pwd1 ?: self.bleTool.pwd1;
    dev.password2 = pwd2;
    dev.device_name = peripheralName;
    dev.deviceType = self.destPeripheral.name;
    dev.is_admin = @"1";
    dev.open_purview = @"3";
    dev.isAutoLock = @"0";
    dev.devmac = self.destPeripheral.mac;
    dev.model = self.lockModel;
    dev.deviceSN = self.bleTool.connectedPeripheral.serialNumber;
    dev.softwareVersion = self.bleTool.connectedPeripheral.softwareVer;
    dev.peripheralId =  self.bleTool.connectedPeripheral.identifier.UUIDString;
    [[KDSHttpManager sharedManager] bindBleDevice:dev uid:uid success:^{
        [MBProgressHUD showSuccess:Localized(@"bindDeviceSuccess")];
        self.stepBtn.enabled = YES;
        self.bindedDevice = dev;
    } error:^(NSError * _Nonnull error) {
        [MBProgressHUD showError:[Localized(@"bindDeviceFailed") stringByAppendingFormat:@":%ld", (long)error.code]];
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD showError:[Localized(@"bindDeviceFailed") stringByAppendingString:error.localizedDescription]];
    }];
}

//MARK:解绑(重置)已绑定的设备。
- (void)unbindDevice
{
    NSString *uid = [KDSUserManager sharedManager].user.uid;
    NSString *peripheralName = self.destPeripheral.advDataLocalName;
    [[KDSHttpManager sharedManager] unbindBleDeviceWithBleName:peripheralName uid:uid success:^{
        //解绑成功后，pwd1传给蓝牙工具，操作绑定时蓝牙工具收到绑定请求会自动去鉴权。
        self.hasBinded = NO;
        self.bleTool.isBinding = YES;
        [MBProgressHUD showSuccess:Localized(@"resetBindedDeviceSuccess")];
        self.bleTool.pwd1 = self.pwd1 ?: self.bleTool.pwd1;
        if ([self.stepLabel.text isEqualToString:Localized(@"thisDeviceHasBeenBindedTips")])
        {
            self.stepLabel.text = Localized(@"bleBindTips3");
        }
    } error:^(NSError * _Nonnull error) {
        [MBProgressHUD showError:[Localized(@"resetBindedDeviceFailed") stringByAppendingFormat:@":%ld", (long)error.code]];
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD showError:[Localized(@"resetBindedDeviceFailed") stringByAppendingString:error.localizedDescription]];
    }];
}

- (void)alterLockNickname
{
    NSString *uid = [KDSUserManager sharedManager].user.uid;
    NSString *peripheralName = self.destPeripheral.advDataLocalName;
    MBProgressHUD *hud = [MBProgressHUD showMessage:Localized(@"alteringLockNickname") toView:self.view];
    NSString *nickname = self.textField.text;
    if (!nickname.length)
    {
        UIButton *btn = self.homeBtn.selected ? self.homeBtn : (self.bedroomBtn.selected ? self.bedroomBtn : self.companyBtn);
        nickname = btn.currentTitle;
    }
    [[KDSHttpManager sharedManager] alterBindedDeviceNickname:nickname withUid:uid bleName:peripheralName success:^{
        [hud hide:YES];
        self.bindedDevice.device_nickname = nickname;
        [MBProgressHUD showSuccess:Localized(@"saveSuccess")];
        [self.navigationController popToRootViewControllerAnimated:NO];
        UITabBarController *vc = (UITabBarController *)[UIApplication sharedApplication].keyWindow.rootViewController;
        if ([vc isKindOfClass:UITabBarController.class] && vc.viewControllers.count)
        {
            ((UITabBarController *)vc).selectedIndex = 0;
        }
    } error:^(NSError * _Nonnull error) {
        [hud hide:YES];
        [MBProgressHUD showError:[Localized(@"saveFailed") stringByAppendingFormat:@"%ld", (long)error.localizedDescription]];
    } failure:^(NSError * _Nonnull error) {
        [hud hide:YES];
        [MBProgressHUD showError:[Localized(@"saveFailed") stringByAppendingString:error.localizedDescription]];
    }];
}

#pragma mark - KDSBluetoothToolDelegate
- (void)centralManagerDidStopScan:(CBCentralManager *)cm
{
    [MBProgressHUD hideHUDForView:self.view animated:NO];
    if (!self.bleTool.connectedPeripheral)
    {
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:Localized(@"connectFailed") message:Localized(@"clickOKReconnect") preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:Localized(@"cancel") style:UIAlertActionStyleDefault handler:nil];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [MBProgressHUD showMessage:Localized(@"connectingLock") toView:self.view];
            [self.bleTool beginConnectPeripheral:self.destPeripheral];
        }];
        [ac addAction:cancel];
        [ac addAction:ok];
        [self presentViewController:ac animated:YES completion:nil];
    }
}

- (void)didConnectPeripheral:(CBPeripheral *)peripheral
{
    /**保存蓝牙uuid*/
    //[LoginTool saveBleDeviceUUIDWithPeripheral:peripheral];
    [MBProgressHUD hideHUDForView:self.view animated:NO];
}

- (void)didDisConnectPeripheral:(CBPeripheral *)peripheral
{
    [MBProgressHUD showMessage:[Localized(@"bleNotConnect") stringByAppendingFormat:@", %@", Localized(@"connectingLock")] toView:self.view];
    [self.bleTool beginConnectPeripheral:self.destPeripheral];
}

- (void)didGetDeviceSN:(NSString *)deviceSN
{
    if (!deviceSN.length)
    {
        [self.bleTool getDeviceInfoWithDevType:DeviceInfoSerialNum];
        return;
    }
    //根据SN去请求pwd1，赋值给bleTool的pwd1
    [self getPwd1WithSN:deviceSN];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristicOfLockModel:(NSString *)model
{
    self.lockModel = model;
    /*if ([model containsString:@"X5"])
    {
        self.model = KDSDeviceModelX5;
    }
    else
    {
        self.model = KDSDeviceModelT5;
    }*/
}

- (void)didReceiveInNetOrOutNetCommand:(BOOL)inNet
{
    if (inNet)//入网，如果已绑定还没有解绑，那么蓝牙工具的pwd2为空(退网时isBinding为NO，不记录pwd2)，是不可能鉴权成功去绑定的。
    {
        //如果已绑定就直接入网，提示先退网。此条件好像不必要，暂时留着。
        if (self.hasBinded)
        {
            [MBProgressHUD showError:Localized(@"thisDeviceHasBeenBindedTips")];
        }
        else
        {
            [self bindDevice];
        }
    }
    else
    {
        [self unbindDevice];
    }
}

@end
