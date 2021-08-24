//
//  KDSBleAlarmRecord.h
//  lock
//
//  Created by orange on 2019/1/18.
//  Copyright © 2019年 zhao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KDSBleOptions.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *@abstract 锁报警记录。新蓝牙。
 */
@interface KDSBleAlarmRecord : NSObject <NSCoding>

/**
 *@abstract 便利初始化方法。新模块date属性需要用到NSDateFormatter比较消耗性能，因此该属性在此方法中不提取，由外部赋值。
 *@param data 蓝牙模块返回的报警记录数据。
 *@return instance。
 */
- (instancetype)initWithData:(NSData *)data;

///报警总记录条数，如果没有报警记录，此值为0.
@property (nonatomic, readonly) uint8_t total;
///当前记录的编号，从0开始，编号越小，报警越晚。
@property (nonatomic, readonly) uint8_t current;
///报警类型。
@property (nonatomic, readonly) KDSBleAlarmType type;
///报警时间，格式yyyy-MM-dd HH:mm:ss。
@property (nonatomic, strong) NSString *date;
///蓝牙返回的开锁记录二进制数据的16进制字符串。
@property (nonatomic, readonly) NSString *hexString;


@end

NS_ASSUME_NONNULL_END
