//
//  KDSUserManager.h
//  xiaokaizhineng
//
//  Created by orange on 2019/1/25.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KDSUser.h"
#import "KDSLock.h"

NS_ASSUME_NONNULL_BEGIN

///使用此类统一管理与用户有关的属性。
@interface KDSUserManager : NSObject

+ (instancetype)sharedManager;

///用户模型。请在AppDelegate中免登录或者登录后设置此变量，以后所有使用到用户属性相关的从此变量获取。
@property (nonatomic, strong) KDSUser *user;
///用户昵称。登录/免登录，从数据库中获取，在”我的“页面从服务器获取或修改成功后，修改此值(这里并没有保存到数据库，请自行更新数据库)。
@property (nonatomic, strong) NSString *userNickname;
/**
 *@abstract 根据用户绑定设备列表创建的门锁数组。请在主页从服务器拉取设备列表和创建页面后设置此变量，以后所有使用到门锁相关的从此变量获取。
 *@note 门锁模型中的蓝牙工具类一般在viewDidLoad或初始化方法中创建。由于蓝牙工具类代理只能有一个，因此请注意设置方式。
 */
@property (nonatomic, strong) NSMutableArray<KDSLock *> *locks;
@property(nonatomic, assign)BOOL netWorkIsAvailable;

/**
 *@abstract 当收到锁报警通知时，调用此方法添加一个报警记录，由本类统一弹出报警UI。*此功能也可以在首页做。
 *@param bleName 外设蓝牙名称。
 *@param alarmData 蓝牙返回的20字节协议数据。
 */
- (void)addAlarmForLockWithBleName:(NSString *)bleName data:(NSData *)alarmData;

/**
 *@abstract 重置用户管理器。一般当登录token过期重新登录或发生其它异常等时，需调用此方法重置本类保存的数据。
 */
- (void)resetManager;
/**
 *@abstract 用来缓存此次选择的周计划数组
 */
@property (nonatomic, strong)NSMutableArray* weekSelectArray;
#pragma mark - 通知相关
///主动解除账号下已绑定的锁时会发出该通知，通知userInfo的lock属性是被删除的KDSLock模型，一般用于刷新首页等界面。
FOUNDATION_EXTERN NSString * const KDSLockHasBeenDeletedNotification;
///成功绑定新的锁时会发出该通知，通知userInfo的device属性是绑定的设备模型，一般用于刷新首页等界面。
FOUNDATION_EXTERN NSString * const KDSLockHasBeenAddedNotification;
///退出登录通知。为方便管理所有的退出登录操作，设立此通知，统一使用通知在AppDelegate中处理退出登录。
FOUNDATION_EXTERN NSString * const KDSLogoutNotification;

@end

NS_ASSUME_NONNULL_END
