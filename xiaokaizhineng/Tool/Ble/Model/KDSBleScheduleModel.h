//
//  KDSBleScheduleModel.h
//  lock
//
//  Created by orange on 2019/1/10.
//  Copyright © 2019年 zhao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KDSBleOptions.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *@abstract 计划查询接口返回的公共数据模型。这是一个抽象基类，不直接使用。
 */
@interface KDSBleScheduleModel : NSObject

///计划编号。
@property (nonatomic, assign) NSUInteger scheduleId;
///用户编号。由于一个计划可以添加多个用户，不知道返回这个值有什么意义。
@property (nonatomic, assign) NSUInteger userId;
///密匙类型，协议标注2是保留值，默认无效值。
@property (nonatomic, assign) KDSBleKeyType keyType;

@end

NS_ASSUME_NONNULL_END
