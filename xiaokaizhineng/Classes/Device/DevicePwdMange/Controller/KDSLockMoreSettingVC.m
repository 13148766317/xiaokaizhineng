//
//  KDSLockMoreSettingVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/14.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSLockMoreSettingVC.h"
#import "Masonry.h"
#import "KDSHttpManager+Ble.h"
#import "KDSLockMoreSettingCell.h"
#import "KDSHttpManager+Ble.h"
#import "MBProgressHUD+MJ.h"
#import "KDSLockParamVC.h"
#import "KDSLockPwdManageVC.h"
#import "MBProgressHUD+MJ.h"
#import "KDSAMModeSpecificationVC.h"
#import "KDSLockLanguageAlterVC.h"
#import "KDSLockAlterTimeVC.h"
#import "KDSLockSecurityModeVC.h"
#import "UIView+Extension.h"

@interface KDSLockMoreSettingVC () <UITableViewDataSource, UITableViewDelegate>

///表视图。
@property (nonatomic, strong) UITableView *tableView;
///删除按钮。
@property (nonatomic, strong) UIButton *deleteBtn;
///门锁信息模型，如果请求成功从蓝牙工具中获取。初始化时从已提取的属性中赋值音量、手自动模式和语言3个属性。
@property (nonatomic, strong) KDSBleLockInfoModel *infoModel;

@end

@implementation KDSLockMoreSettingVC

#pragma mark - 生命周期、界面设置相关方法。
- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.lock.bleTool.connectedPeripheral)
    {
        self.infoModel = [[KDSBleLockInfoModel alloc] init];
        self.infoModel.language = self.lock.bleTool.connectedPeripheral.language;
        self.infoModel.volume = self.lock.bleTool.connectedPeripheral.volume;
        self.infoModel.lockState = 0 | (self.lock.bleTool.connectedPeripheral.isAutoMode ? 128 : 0);
    }
    
    self.navigationTitleLabel.text = Localized(@"more");
    self.deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat height = kScreenHeight < 667 ? 48 : 60;
    CGFloat width = height * 5;
    self.deleteBtn.layer.cornerRadius = height / 2.0;
    self.deleteBtn.backgroundColor = KDSRGBColor(0x2d, 0xd9, 0xba);
    [self.deleteBtn setTitle:Localized(@"deleteDevice") forState:UIControlStateNormal];
    [self.deleteBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.deleteBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.deleteBtn addTarget:self action:@selector(clickDeleteBtnDeleteBindedLock:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.deleteBtn];
    [self.deleteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(kScreenHeight < 667 ? -20 : -35);
        make.width.mas_equalTo(width);
        make.height.mas_equalTo(height);
    }];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableHeaderView = [UIView new];
    self.tableView.tableFooterView = [UIView new];
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.view).offset(10);
        make.right.equalTo(self.view).offset(-10);
        make.bottom.equalTo(self.deleteBtn.mas_top).offset(kScreenHeight < 667 ? -20 : -28);
    }];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = kScreenHeight < 667 ? 44 : 52;//48 60?
    self.tableView.layer.cornerRadius = 5;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.lock.bleTool.connectedPeripheral)
    {
        __weak typeof(self) weakSelf = self;
        [self.lock.bleTool getLockInfo:^(KDSBleError error, KDSBleLockInfoModel * _Nullable infoModel) {
            if (infoModel)
            {
                weakSelf.infoModel = infoModel;
                [weakSelf.tableView reloadData];
            }
        }];
    }
    else
    {
        [MBProgressHUD showError:Localized(@"bleNotConnect")];
    }
}

#pragma mark - UITableViewDataSource, UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section ? 7 : 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1 && indexPath.row == 3 && [self.lock.device.model containsString:@"T5"])
    {
        return 0.001;
    }
    return kScreenHeight < 667 ? 44 : 52;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return section ? 0.001 : 10;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [UIView new];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseId = NSStringFromClass([self class]);
    KDSLockMoreSettingCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if (!cell)
    {
        cell = [[KDSLockMoreSettingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
    }
    
    if (indexPath.section == 0)
    {
        cell.title = indexPath.row ? Localized(@"silent") : Localized(@"doNotDisturb");
        cell.cornerState = indexPath.row ? KDSCornerStateBottom : KDSCornerStateTop;
        cell.hideSwitch = NO;
        cell.switchOn = indexPath.row==0 ? [KDSTool getNotificationOnForBle:self.lock.device.device_name] : ((self.infoModel && self.infoModel.volume == 0) ? YES : NO);
        __weak typeof(self) weakSelf = self;
        cell.switchStateDidChangeBlock = indexPath.row==1 ? ^(UISwitch * _Nonnull sender) {
            [weakSelf switchClickSetLockVolume:sender];
        } : ^(UISwitch * _Nonnull sender){
            [weakSelf switchClickSetNotificationMode:sender];
        };
        cell.hideSeparator = indexPath.row != 0;
    }
    else
    {
        NSArray *titles = @[Localized(@"deviceName"), Localized(@"managePwd"), Localized(@"securityMode"), Localized(@"Auto/ManualMode"), Localized(@"calibrationTime"), Localized(@"switchLanguage"), Localized(@"deviceInfo")];
        cell.title = indexPath.row >= titles.count ? nil : titles[indexPath.row];
        NSString *language = !self.infoModel.language ? nil : ([self.infoModel.language isEqualToString:@"zh"] ? Localized(@"languageChinese") : Localized(@"languageEnglish"));
        cell.subtitle = indexPath.row == 0 ? self.lock.name : (indexPath.row == 5 ? language : nil);
        cell.hideSwitch = YES;
        cell.cornerState = indexPath.row == 0 ? KDSCornerStateTop : (indexPath.row == 6 ? KDSCornerStateBottom : KDSCornerStateNone);
        cell.hideSeparator = indexPath.row == 7;
    }
    cell.clipsToBounds = YES;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        
    }
    else
    {
        if (!self.lock.device.is_admin.boolValue)
        {
            [MBProgressHUD showError:Localized(@"noAuthorization")];
            return;
        }
        if (!self.lock.bleTool.connectedPeripheral && indexPath.row != 3 && indexPath.row != 0)
        {
            [MBProgressHUD showError:Localized(@"bleNotConnect")];
            //return;
        }
        switch (indexPath.row)
        {
            case 0://修改锁昵称
                [self alterDeviceNickname];
                break;
                
            case 1://密码管理
            {
                KDSLockPwdManageVC *vc = [KDSLockPwdManageVC new];
                vc.lock = self.lock;
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
                
            case 2://安全模式
            {
                KDSLockSecurityModeVC *vc = [KDSLockSecurityModeVC new];
                KDSLockMoreSettingCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                vc.title = cell.title;
                vc.lock = self.lock;
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
                
            case 3://自动/手动
            {
                KDSAMModeSpecificationVC *vc = [KDSAMModeSpecificationVC new];
                KDSLockMoreSettingCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                vc.title = cell.title;
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
                
            case 4://时间校准
            {
                KDSLockAlterTimeVC *vc = [KDSLockAlterTimeVC new];
                vc.lock = self.lock;
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
                
            case 5://语言切换
            {
                KDSLockLanguageAlterVC *vc = [KDSLockLanguageAlterVC new];
                KDSLockMoreSettingCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                vc.language = cell.subtitle;
                vc.lockLanguageDidAlterBlock = ^(NSString * _Nonnull newLanguage) {
                    cell.subtitle = newLanguage;
                };
                vc.lock = self.lock;
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
                
            case 6://锁参数信息
            {
                KDSLockParamVC *vc = [[KDSLockParamVC alloc] init];
                vc.lock = self.lock;
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
            case 7://检查固件升级
            {
                
                
            }
                break;
            default:
                break;
        }
    }
}

#pragma mark - KDSBluetoothToolDelegate
- (void)didReceiveDeviceElctInfo:(int)elct
{
    __weak typeof(self) weakSelf = self;
    [self.lock.bleTool getLockInfo:^(KDSBleError error, KDSBleLockInfoModel * _Nullable infoModel) {
        if (infoModel)
        {
            weakSelf.infoModel = infoModel;
            [weakSelf.tableView reloadData];
        }
    }];
}

#pragma mark - 控件等事件方法。
//MARK:点击删除按钮删除绑定的设备。
- (void)clickDeleteBtnDeleteBindedLock:(UIButton *)sender
{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:Localized(@"beSureDeleteDevice?") message:Localized(@"deviceWillBeUnbindAfterDelete") preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:Localized(@"cancel") style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self deleteBindedDevice];
        
    }];
    [ac addAction:cancelAction];
    [ac addAction:okAction];
    [self presentViewController:ac animated:YES completion:nil];
}

///锁昵称修改文本框文字改变后，限制长度不超过16个字符。
- (void)textFieldTextDidChange:(UITextField *)sender
{
    [sender trimTextToLength:-1];
}

///点击静音cell中的开关时设置锁的音量，开->锁设置静音，关->锁设置低音。
- (void)switchClickSetLockVolume:(UISwitch *)sender
{
    if (!self.lock.bleTool.connectedPeripheral)
    {
        [MBProgressHUD showError:Localized(@"bleNotConnect")];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [sender setOn:NO animated:YES];
        });
    }
    else if (!self.lock.device.is_admin.boolValue)
    {
        [MBProgressHUD showError:Localized(@"noAuthorization")];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [sender setOn:!sender.on animated:YES];
        });
    }
    else
    {
        __weak typeof(self) weakSelf = self;
        MBProgressHUD *hud = [MBProgressHUD showMessage:Localized(@"settingLockVolume")];
        [self.lock.bleTool setLockVolume:sender.on ? 0 : 1 completion:^(KDSBleError error) {
            [hud hide:YES];
            if (error == KDSBleErrorSuccess)
            {
                weakSelf.infoModel.volume = sender.on ? 0 : 1;
                //[weakSelf.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                weakSelf.lock.bleTool.connectedPeripheral.volume = sender.on ? 0 : 1;
                [MBProgressHUD showSuccess:Localized(@"setLockVolumeSuccess")];
            }
            else
            {
                [MBProgressHUD showError:[Localized(@"setLockVolumeFailed") stringByAppendingFormat:@": %ld", (long)error]];
                [sender setOn:!sender.on animated:YES];
            }
        }];
    }
}

///点击免打扰cell中的开关时设置锁报警信息本地通知功能，开->开启锁报警信息通知，关->关闭锁报警信息通知。
- (void)switchClickSetNotificationMode:(UISwitch *)sender
{
    [KDSTool setNotificationOn:sender.on forBle:self.lock.device.device_name];
}

#pragma mark - 网络请求相关
///删除绑定的设备
- (void)deleteBindedDevice
{
    MBProgressHUD *hud = [MBProgressHUD showMessage:Localized(@"deleting") toView:self.view];
    [[KDSHttpManager sharedManager] deleteBindedDeviceWithUid:[KDSUserManager sharedManager].user.uid bleName:self.lock.device.device_name success:^{
        [hud hide:YES];
        [MBProgressHUD showSuccess:Localized(@"deleteSuccess")];
        [self.lock.bleTool endConnectPeripheral:self.lock.bleTool.connectedPeripheral];
        [[NSNotificationCenter defaultCenter] postNotificationName:KDSLockHasBeenDeletedNotification object:nil userInfo:@{@"lock" : self.lock}];
        [self.navigationController popToRootViewControllerAnimated:YES];
    } error:^(NSError * _Nonnull error) {
        [hud hide:YES];
        [MBProgressHUD showError:[Localized(@"deleteFailed") stringByAppendingFormat:@":%ld", (long)error.localizedDescription]];
    } failure:^(NSError * _Nonnull error) {
        [hud hide:YES];
        [MBProgressHUD showError:[Localized(@"deleteFailed") stringByAppendingFormat:@", %@", error.localizedDescription]];
    }];
}

///修改锁昵称。
- (void)alterDeviceNickname
{
    __weak typeof(self) weakSelf = self;
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:Localized(@"inputDeviceName") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textAlignment = NSTextAlignmentCenter;
        textField.textColor = KDSRGBColor(0x10, 0x10, 0x10);
        textField.font = [UIFont systemFontOfSize:13];
        [textField addTarget:weakSelf action:@selector(textFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:Localized(@"cancel") style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        NSString *newNickname = ac.textFields.firstObject.text;
        newNickname = [newNickname stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (newNickname.length && ![newNickname isEqualToString:weakSelf.lock.name])
        {
            MBProgressHUD *hud = [MBProgressHUD showMessage:Localized(@"alteringLockNickname") toView:weakSelf.view];
            [[KDSHttpManager sharedManager] alterBindedDeviceNickname:newNickname withUid:[KDSUserManager sharedManager].user.uid bleName:weakSelf.lock.device.device_name success:^{
                [hud hide:YES];
                [MBProgressHUD showSuccess:Localized(@"saveSuccess")];
                weakSelf.lock.device.device_nickname = newNickname;
                [weakSelf.tableView reloadData];
            } error:^(NSError * _Nonnull error) {
                [hud hide:YES];
                [MBProgressHUD showError:[Localized(@"saveFailed") stringByAppendingFormat:@"%ld", (long)error.localizedDescription]];
            } failure:^(NSError * _Nonnull error) {
                [hud hide:YES];
                [MBProgressHUD showError:[Localized(@"saveFailed") stringByAppendingString:error.localizedDescription]];
            }];
        }
        
    }];
    [ac addAction:cancelAction];
    [ac addAction:okAction];
    [self presentViewController:ac animated:YES completion:nil];
}

@end
