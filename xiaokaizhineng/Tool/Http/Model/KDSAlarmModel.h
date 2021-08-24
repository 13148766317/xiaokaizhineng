//
//  KDSAlarmModel.h
//  xiaokaizhineng
//
//  Created by orange on 2019/2/27.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

///报警记录接口模型。
@interface KDSAlarmModel : NSObject <NSCoding>

///记录id。
@property (nonatomic, strong) NSString *_id;
///设备名称(一般是蓝牙广播名)。
@property (nonatomic, strong) NSString *devName;
///报警类型(和蓝牙协议的报警类型一样)。@see KDSBleAlarmRecord.
@property (nonatomic, assign) int warningType;
///报警时间，当前时区当前时间至70年的毫秒数。
@property (nonatomic, assign) NSTimeInterval warningTime;
///本地添加的，从warningTime转换的时间字符串，格式yyyy-MM-dd HH:mm:ss
@property (nonatomic, strong, nullable) NSString *date;
///报警内容。
@property (nonatomic, strong, nullable) NSString *content;

@end

NS_ASSUME_NONNULL_END
