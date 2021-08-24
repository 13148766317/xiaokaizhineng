//
//  CBPeripheral+Extension.h
//  BLETest
//
//  Created by zhaowz on 2017/9/13.
//  Copyright © 2017年 zhaowz. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

@interface CBPeripheral (Extension)

/**给系统的CBPeripheral增加属性：用来保存广播包中的数据*/
@property (nonatomic, copy)NSString *advDataLocalName;
///mac地址，从advDataLocalName中提取后12位后添加:号，如果advDataLocalName长度小于12，则返回nil。
@property (nonatomic, strong, nullable, readonly) NSString *mac;
///是否是新蓝牙设备。如果外设名称含有"KDS"或者”KdsLock"是旧蓝牙，否则是新蓝牙。
@property (nonatomic, assign) BOOL isNewDevice;
///新蓝牙锁的产品型号，180A服务2A26特征的值，蓝牙协议标注的是FirmwareRev。大写如果包含DB2可以添加20个密码，其它可以添加10个密码。
@property (nonatomic, strong) NSString *lockModelType;
///新蓝牙锁最大能设置的密码(用户)数，根据lockModelType判断。不失一般性，如果lockModelType属性为nil，返回默认的10个。
@property (nonatomic, assign, readonly) NSUInteger maxUsers;
///新蓝牙模块代号，180A服务的2A24特征的值，如果等于RGBT1761，则开锁时不用密码。
@property (nonatomic, strong) NSString *lockModelNumber;
///新蓝牙用，根据lockModelNumber是否等于RGBT1761判断开锁时是否需要密码。
@property (nonatomic, assign, readonly) BOOL unlockPIN;
///蓝牙锁的序列号，180A服务2A25特征。
@property (nonatomic, strong) NSString *serialNumber;
///蓝牙锁的硬件版本号，180A服务2A27特征。
@property (nonatomic, strong) NSString *hardwareVer;
///蓝牙锁的硬件版本号，180A服务2A28特征。
@property (nonatomic, strong) NSString *softwareVer;
///蓝牙锁的电量，FFB0服务FFB1特征，0-100.每次连接和开锁时会更新。工具类会自动赋值，如果没有设置过此值，默认返回负数。
@property (nonatomic, assign) int power;
///锁是否是自动模式，从FFF0服务FFF3特征中提取。连接后首次工具类会自动赋值。
@property (nonatomic, assign) BOOL isAutoMode;
///锁音量，从FFF0服务FFF5特征中提取。0静音，1低音，2高音。连接后首次工具类会自动赋值，如果没有设置过此值，默认返回负数。。
@property (nonatomic, assign) int volume;
///锁语言，从FFF0服务FFF4特征中提取。zh中文，en英文。连接后首次工具类和自动赋值。
@property (nonatomic, strong) NSString *language;

@end
