//
//  KDSDeviceTableViewCell.h
//  xiaokaizhineng
//
//  Created by wzr on 2019/1/24.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyDevice.h"

NS_ASSUME_NONNULL_BEGIN

@interface KDSDeviceTableViewCell : UITableViewCell

///设置锁的电量，0~100。
@property (nonatomic, assign) int power;
///
@property (nonatomic, strong) MyDevice *device;

@end

NS_ASSUME_NONNULL_END
