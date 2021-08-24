//
//  KDSLock.h
//  xiaokaizhineng
//
//  Created by orange on 2019/2/14.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KDSBluetoothTool.h"
#import "MyDevice.h"
#import "KDSPwdListModel.h"
/**
 *@abstract 锁状态枚举，用于设置页面状态标签和状态图片等。
 */
typedef NS_ENUM(NSUInteger, KDSLockState) {
    ///初始态，页面初始化时的状态，显示的是正在搜索蓝牙。
    KDSLockStateInitial = 0,
    ///系统蓝牙关闭的状态。
    KDSLockStateBleClosed,
    ///没有搜索到已绑定的蓝牙。
    KDSLockStateBleNotFound,
    ///连接蓝牙后鉴权不成功的状态。
    KDSLockStateUnauth,
    ///连接蓝牙后鉴权不成功且错误码为0XC2(密码2被修改)的状态，此时锁应该是被重置了。
    KDSLockStateReset,
    ///标准态，即蓝牙已连接且未操作开锁前。
    KDSLockStateNormal,
    ///开锁中。
    KDSLockStateUnlocking,
    ///锁已打开。
    KDSLockStateUnlocked,
    ///开锁失败。
    KDSLockStateFailed,
    ///锁已关闭。
    KDSLockStateClosed,
};

/**
 *@abstract 门锁模型，包含门锁设备模型+门锁蓝牙工具等。
 */
@interface KDSLock : NSObject

///从服务器获取到的门锁设备模型。
@property (nonatomic, strong) MyDevice *device;
///门锁设备的显示名称，昵称或蓝牙名称。
@property (nonatomic, strong, readonly) NSString *name;
///一般是首页根据门锁设备模型创建的蓝牙工具类。@note 此属性是弱引用，因此，当首页显示蓝牙信息的控制器销毁后该属性就变为空了。
@property (nonatomic, weak) KDSBluetoothTool *bleTool;

//服务器已经存在的密码列表
@property (nonatomic,strong) NSArray <KDSPwdListModel *> *existPwdArray;

#pragma mark - 共用属性。
///锁状态，初始化时为KDSLockStateInitial。
@property (nonatomic, assign) KDSLockState state;
///锁电量，0~100，初始为-1.当连接上设备并获取最新电量后更新到此值并存储到数据库(一并存储时间)，当离线时使用数据库的数据。
@property (nonatomic, assign) int power;
///是否已连接到锁。如果是蓝牙，需要鉴权完毕才算已连接；如果是网关锁，根据网关和设备状态判断是否已连接。
@property (nonatomic, assign) BOOL connected;

@end

