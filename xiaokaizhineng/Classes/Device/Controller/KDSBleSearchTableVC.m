//
//  KDSBleSearchTableVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/12.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSBleSearchTableVC.h"
#import "Masonry.h"
#import "KDSHttpManager+Ble.h"
#import "KDSBleInfoCell.h"
#import "MBProgressHUD+MJ.h"
#import "KDSBleBindVC.h"
#import "KDSHelpViewController.h"

@interface KDSBleSearchTableVC () <KDSBluetoothToolDelegate, UITableViewDataSource, UITableViewDelegate>
{
    KDSBluetoothTool *_bleTool;
}

///搜索动画视图。
@property (nonatomic, strong) UIImageView *animationIV;
///搜索提示标签。
@property (nonatomic, strong) UILabel *label;
///重新搜索按钮。
@property (nonatomic, strong) UIButton *searchBtn;
///已绑定的蓝牙，从服务器获取，重新请求时清除。
@property (nonatomic, strong) NSArray<MyDevice *> *devices;
///搜索到的蓝牙，重新搜索时清除数据。
@property (nonatomic, strong) NSMutableArray<CBPeripheral *> *peripheralsArr;
///动画定时器。
@property (nonatomic, strong) NSTimer *animationTimer;
///仿射变换偏转角弧度，默认0.
@property (nonatomic, assign) CGFloat deflectionRadian;
///仿射变换偏半径，默认20.
@property (nonatomic, assign) CGFloat deflectionRadius;

@end

@implementation KDSBleSearchTableVC

#pragma mark - getter setter
- (KDSBluetoothTool *)bleTool
{
    if (!_bleTool)
    {
        _bleTool = [[KDSBluetoothTool alloc] initWithVC:self];
    }
    return _bleTool;
}

- (NSMutableArray<CBPeripheral *> *)peripheralsArr
{
    if (!_peripheralsArr)
    {
        _peripheralsArr = [NSMutableArray array];
    }
    return _peripheralsArr;
}

- (NSTimer *)animationTimer
{
    if (!_animationTimer)
    {
        _animationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 30 target:self selector:@selector(animationTimerActionChangeAnimationIVTransform:) userInfo:nil repeats:YES];
    }
    return _animationTimer;
}

#pragma mark - 生命周期、界面设置方法
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.deflectionRadian = 0;
    self.deflectionRadius = 20;
    self.navigationTitleLabel.text = Localized(@"addDoorLock");
    self.animationIV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"deviceBindDone"]];
    [self.view addSubview:self.animationIV];
    [self.animationIV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(kScreenHeight < 667 ? 20 : 47);
        make.centerX.equalTo(self.view);
        make.width.mas_equalTo(116);
        make.height.mas_equalTo(103);
    }];
    
    self.label = [[UILabel alloc] init];
    self.label.text = Localized(@"searchingNearbyBle");
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.font = [UIFont systemFontOfSize:18];
    self.label.textColor = KDSRGBColor(0x14, 0x14, 0x14);
    [self.view addSubview:self.label];
    [self.label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.animationIV.mas_bottom).offset(kScreenHeight < 667 ? 20 : 41);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(ceil([self.label.text sizeWithAttributes:@{NSFontAttributeName : self.label.font}].height));
    }];
    
    self.searchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.searchBtn.layer.cornerRadius = 30;
    self.searchBtn.backgroundColor = KDSRGBColor(0x2d, 0xd9, 0xba);
    [self.searchBtn setTitle:Localized(@"searchAgain") forState:UIControlStateNormal];
    [self.searchBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.searchBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.searchBtn addTarget:self action:@selector(searchNearbyBleAgain:) forControlEvents:UIControlEventTouchUpInside];
    //self.searchBtn.hidden = YES;
    [self.view addSubview:self.searchBtn];
    [self.searchBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(kScreenHeight < 667 ? - 20 :-44);
        make.width.mas_equalTo(kScreenWidth < 375 ? kScreenWidth - 76 : 300);
        make.height.mas_equalTo(60);
    }];
    
    [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.label.mas_bottom).offset(kScreenHeight < 667 ? 20 : 47);
        make.left.equalTo(self.view).offset(10);
        make.bottom.equalTo(self.searchBtn.mas_top).offset(kScreenHeight < 667 ? -20 : -63);
        make.right.equalTo(self.view).offset(-10);
    }];
    self.tableView.layer.masksToBounds = YES;
    self.tableView.layer.cornerRadius = 5;
    self.tableView.layer.shadowColor = KDSRGBColor(0xf3, 0xf3, 0xf3).CGColor;
    self.tableView.layer.shadowOffset = CGSizeMake(2, 2);
    self.tableView.layer.shadowOpacity = 1.0;
    self.tableView.rowHeight = 60;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
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
    if (self.bleTool.connectedPeripheral)
    {
        [self.bleTool endConnectPeripheral:self.bleTool.connectedPeripheral];
    }
    self.bleTool.delegate = self;
    [self startSearchingAnimation];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSUInteger index = [self.navigationController.viewControllers indexOfObject:self];
    if (index == NSNotFound)
    {
        [self stopSearchingAnimation];
        [_animationTimer invalidate];
        _animationTimer = nil;
    }
}

///开始搜索动画。
- (void)startSearchingAnimation
{
    self.deflectionRadian = M_PI_4 * 3;
    self.animationIV.transform = CGAffineTransformMake(1, 0, 0, 1, -self.deflectionRadius * sin(self.deflectionRadian), self.deflectionRadius * cos(self.deflectionRadian));
    self.animationTimer.fireDate = [NSDate date];
    [self getBindedDeviceList];
    [self.bleTool beginScanForPeripherals];
    self.label.text = Localized(@"searchingNearbyBle");
}

///结束搜索动画。
- (void)stopSearchingAnimation
{
    self.animationTimer.fireDate = [NSDate distantFuture];
    self.animationIV.transform = CGAffineTransformIdentity;
    [self.bleTool stopScanPeripherals];
    self.searchBtn.hidden = NO;
    self.label.text = nil;
}

#pragma mark - 控件等事件方法。
///重新搜索蓝牙
- (void)searchNearbyBleAgain:(UIButton *)sender
{
    [self.peripheralsArr removeAllObjects];
    [self.tableView reloadData];
    [self startSearchingAnimation];
}

///显示设备蓝牙搜索帮助界面。
- (void)showDeviceBleSearchHelp:(UIButton *)sender
{
    KDSHelpViewController *vc = [[KDSHelpViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

///启动定时器时改变动画视图的转置矩阵。
- (void)animationTimerActionChangeAnimationIVTransform:(NSTimer *)timer
{
    self.deflectionRadian += M_PI / 25;
    self.animationIV.transform = CGAffineTransformMake(1, 0, 0, 1, -self.deflectionRadius * sin(self.deflectionRadian), self.deflectionRadius * cos(self.deflectionRadian));
}

#pragma mark - 网络请求相关方法
///从服务器获取账号下绑定的设备列表。
- (void)getBindedDeviceList
{
    self.devices = nil;
    [[KDSHttpManager sharedManager] getBindedDeviceListWithUid:[KDSUserManager sharedManager].user.uid success:^(NSArray<MyDevice *> * _Nonnull devices) {
        self.devices = devices;
    } error:^(NSError * _Nonnull error) {
        
    } failure:^(NSError * _Nonnull error) {
        
    }];
}

/**
 *@abstract 检查设备是否已被其它账号绑定，并重置或绑定。
 *@param peripheral 外设。
 */
//MARK:检查设备是否已被其它账号绑定，并重置或绑定
- (void)checkBleDeviceBindingStatus:(CBPeripheral *)peripheral
{
    MBProgressHUD *hud = [MBProgressHUD showMessage:Localized(@"checkingBleBindingStatus") toView:self.view];
    [[KDSHttpManager sharedManager] checkBleDeviceBindingStatusWithBleName:peripheral.advDataLocalName uid:[KDSUserManager sharedManager].user.uid success:^(int status) {
        [hud hide:YES];
        if (status == 201)
        {
            KDSBleBindVC *vc = [[KDSBleBindVC alloc] init];
            vc.bleTool = self.bleTool;
            vc.bleTool.delegate = vc;
            vc.destPeripheral = peripheral;
            vc.model = self.model;
            vc.step = 1;
            [self.navigationController pushViewController:vc animated:YES];
        }
        else
        {
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:Localized(@"tips") message:Localized(@"thisDeviceHasBeenBindedTips") preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                KDSBleBindVC *vc = [[KDSBleBindVC alloc] init];
                vc.bleTool = self.bleTool;
                vc.bleTool.delegate = vc;
                vc.destPeripheral = peripheral;
                vc.hasBinded = YES;
                vc.model = self.model;
                vc.step = 1;
                [self.navigationController pushViewController:vc animated:YES];
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:Localized(@"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            [ac addAction:cancelAction];
            [ac addAction:okAction];
            [self presentViewController:ac animated:YES completion:^{
                
            }];
        }
    } error:^(NSError * _Nonnull error) {
        [hud hide:YES];
        [MBProgressHUD showError:[NSString stringWithFormat:@"error:%ld", (long)error.localizedDescription]];
    } failure:^(NSError * _Nonnull error) {
        [hud hide:YES];
        [MBProgressHUD showError:error.localizedDescription];
    }];
}

#pragma mark - KDSBluetoothToolDelegate
- (void)discoverManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn)
    {
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:nil message:Localized(@"pleaseOpenBle") preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:nil];
        [ac addAction:action];
        [self presentViewController:ac animated:YES completion:^{
            [self stopSearchingAnimation];
        }];
    }
}

- (void)didDiscoverPeripheral:(CBPeripheral *)peripheral
{
    if ([self.peripheralsArr containsObject:peripheral]) return;
    [self.peripheralsArr addObject:peripheral];
    if (self.devices)
    {
        [self.tableView reloadData];
    }
}

- (void)centralManagerDidStopScan:(CBCentralManager *)cm
{
    [self stopSearchingAnimation];
}

#pragma mark - UITableViewDataSource, UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.peripheralsArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseId = NSStringFromClass([self class]);
    KDSBleInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if (!cell)
    {
        cell = [[KDSBleInfoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
    }
    NSString *bleName = self.peripheralsArr[indexPath.row].advDataLocalName;
    cell.bleName = bleName;
    BOOL hasBinded = NO;
    for (MyDevice *device in self.devices)
    {
        if (![device.device_name isEqualToString:cell.bleName]) continue;
        hasBinded = YES;
    }
    cell.hasBinded = hasBinded;
    cell.underlineHidden = indexPath.row == self.peripheralsArr.count - 1;
    __weak typeof(self) weakSelf = self;
    cell.bindBtnDidClickBlock = ^(UIButton * _Nonnull sender) {
        [weakSelf checkBleDeviceBindingStatus:weakSelf.peripheralsArr[indexPath.row]];
    };
    
    return cell;
}

@end
