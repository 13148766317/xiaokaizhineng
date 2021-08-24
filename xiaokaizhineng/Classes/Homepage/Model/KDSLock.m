//
//  KDSLock.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/14.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSLock.h"

@implementation KDSLock

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.state = KDSLockStateInitial;
    }
    return self;
}

- (NSString *)name
{
    return self.device.device_nickname ?: self.device.device_name;
}

@end
