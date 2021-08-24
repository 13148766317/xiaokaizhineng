//
//  KDSBleUnlockRecord.h
//  lock
//
//  Created by orange on 2018/12/19.
//  Copyright © 2018年 zhao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/** 开锁记录模型 */
@interface KDSBleUnlockRecord : NSObject <NSCoding>

/**
 *@abstract 便利初始化方法。新模块unlockDate属性需要用到NSDateFormatter比较消耗性能，因此该属性在此方法中不提取，由外部赋值。
 *@param data 蓝牙模块返回的开锁记录数据。
 *@return instance。
 */
- (instancetype)initWithData:(NSData *)data;

///开锁总记录条数，如果没有开锁记录，此值为0.旧蓝牙协议不使用。
@property (nonatomic, readonly) uint8_t total;
///当前记录的编号，从0开始，编号越小，开锁越晚。旧蓝牙协议不使用。
@property (nonatomic, readonly) uint8_t current;
///用户编号%02d格式
@property (nonatomic, strong) NSString *userNum;
///开锁类型，如果是@"手机"表示APP开锁。
@property (nonatomic, strong) NSString *unlockType;
///开锁时间，格式yyyy-MM-dd HH:mm:ss
@property (nonatomic, strong) NSString *unlockDate;
///蓝牙返回的开锁记录二进制数据的16进制字符串。
@property (nonatomic, readonly) NSString *hexString;

@end

NS_ASSUME_NONNULL_END
