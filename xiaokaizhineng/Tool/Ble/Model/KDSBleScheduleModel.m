//
//  KDSBleScheduleModel.m
//  lock
//
//  Created by orange on 2019/1/10.
//  Copyright © 2019年 zhao. All rights reserved.
//

#import "KDSBleScheduleModel.h"

@implementation KDSBleScheduleModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.keyType = KDSBleKeyTypeInvalid;
    }
    return self;
}

@end
