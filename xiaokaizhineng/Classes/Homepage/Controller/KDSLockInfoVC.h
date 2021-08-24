//
//  KDSLockInfoVC.h
//  xiaokaizhineng
//
//  Created by orange on 2019/1/25.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSTableViewController.h"
#import "KDSLock.h"

NS_ASSUME_NONNULL_BEGIN

@interface KDSLockInfoVC : KDSTableViewController

///绑定的设备对应的门锁模型，设置此属性前，请确保device已设置，蓝牙工具类属性一般会在此类中设置。
@property (nonatomic, strong) KDSLock *lock;
///下拉刷新执行的操作。由于首页控制器添加下拉刷新会造成滚动视图上下弹跳，不美观，因此将下拉刷新放到此控制器做。
@property (nonatomic, copy, nullable) void(^pulldownRefreshBlock) (void);

///如果蓝牙没有连接，调用此方法搜索蓝牙并更新界面。
- (void)beginScanForPeripherals;

@end

NS_ASSUME_NONNULL_END
