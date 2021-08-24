//
//  KDSAutoConnectViewController.m
//  xiaokaizhineng
//
//  Created by orange on 2019/3/1.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSAutoConnectViewController.h"

@interface KDSAutoConnectViewController ()

///记录上一个蓝牙工具的代理。
@property (nonatomic, weak, nullable) id<KDSBluetoothToolDelegate> preDelegate;

@end

@implementation KDSAutoConnectViewController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.autoConnect = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.lock.bleTool.connectedPeripheral && self.autoConnect)
    {
        [self.lock.bleTool beginScanForPeripherals];
        self.lock.state = KDSLockStateInitial;
    }
    if (self.autoConnect)
    {
        if (!self.preDelegate) self.preDelegate = self.lock.bleTool.delegate;
        self.lock.bleTool.delegate = self;
    }
}

- (void)dealloc
{
    if (self.preDelegate) self.lock.bleTool.delegate = self.preDelegate;
}

#pragma mark - KDSBluetoothToolDelegate
- (void)didDiscoverPeripheral:(CBPeripheral *)peripheral
{
    if ([peripheral.advDataLocalName isEqualToString:self.lock.device.device_name]||[peripheral.identifier.UUIDString isEqualToString:self.lock.device.peripheralId])
    {
        [self.lock.bleTool beginConnectPeripheral:peripheral];
    }
}

- (void)didConnectPeripheral:(CBPeripheral *)peripheral
{
    [self.lock.bleTool stopScanPeripherals];
    if (!peripheral.isNewDevice)
    {
        self.lock.device.connected = YES;
        self.lock.state = KDSLockStateNormal;
    }
}

- (void)centralManagerDidStopScan:(CBCentralManager *)cm
{
    if (!self.lock.bleTool.connectedPeripheral)
    {
        self.lock.state = KDSLockStateBleNotFound;
    }
}

- (void)didGetSystemID:(CBPeripheral *)peripheral
{
    __weak typeof(self) weakSelf = self;
    [self.lock.bleTool authenticationWithPwd1:self.lock.device.password1 pwd2:self.lock.device.password2 completion:^(KDSBleError error) {
        if (error == KDSBleErrorSuccess)
        {
            weakSelf.lock.state = KDSLockStateNormal;
            weakSelf.lock.device.connected = YES;
            if (weakSelf.authenticateSuccess)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    weakSelf.authenticateSuccess();
                });
            }
        }
        else if (error != KDSBleErrorDuplOrAuthenticating)
        {
            weakSelf.lock.state = KDSLockStateUnauth;
        }
    }];
}

- (void)didDisConnectPeripheral:(CBPeripheral *)peripheral
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.lock.bleTool beginConnectPeripheral:peripheral];
        self.lock.state = KDSLockStateInitial;
    });
}

@end
