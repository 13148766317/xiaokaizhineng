//
//  KDSAlarmModel.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/27.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSAlarmModel.h"

@implementation KDSAlarmModel

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self._id forKey:@"_id"];
    [aCoder encodeObject:self.devName forKey:@"devName"];
    [aCoder encodeInt:self.warningType forKey:@"warningType"];
    [aCoder encodeDouble:self.warningTime forKey:@"warningTime"];
    [aCoder encodeObject:self.date forKey:@"date"];
    [aCoder encodeObject:self.content forKey:@"content"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    self._id = [aDecoder decodeObjectForKey:@"_id"];
    self.devName = [aDecoder decodeObjectForKey:@"devName"];
    self.warningType = [aDecoder decodeIntForKey:@"warningType"];
    self.warningTime = [aDecoder decodeDoubleForKey:@"warningTime"];
    self.date = [aDecoder decodeObjectForKey:@"date"];
    self.content = [aDecoder decodeObjectForKey:@"content"];
    return self;
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[self class]]) return NO;
    if (object == self) return YES;
    KDSAlarmModel *model = object;
    return [self.devName isEqualToString:model.devName] && self.warningType==model.warningType && (self.warningTime==model.warningTime || [self.date isEqualToString:model.date]);
}

@end
