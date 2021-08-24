//
//  MyDevice.m
//  kaadas
//
//  Created by ise on 16/9/12.
//  Copyright © 2016年 ise. All rights reserved.
//
/*************************************************************************
 * 公       司： 深圳市高金科技有限公司
 * 作       者： 深圳市高金科技有限公司	king
 * 文件名称：MyDevice.h
 * 内容摘要：蓝牙设备模型
 * 日        期： 2016/11/30
 ************************************************************************/
#import "MyDevice.h"
#import "MJExtension.h"

@implementation MyDevice

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        self.center_latitude = [aDecoder decodeDoubleForKey:@"center_latitude"];
        self.center_longitude = [aDecoder decodeDoubleForKey:@"center_longitude"];
        self.circle_radius = [aDecoder decodeDoubleForKey:@"circle_radius"];
        self.edge_longitude = [aDecoder decodeDoubleForKey:@"edge_longitude"];
        self.edge_latitude = [aDecoder decodeDoubleForKey:@"edge_latitude"];
        self.devmac = [aDecoder decodeObjectForKey:@"devmac"];
        self.device_name = [aDecoder decodeObjectForKey:@"device_name"];
        self.deviceType = [aDecoder decodeObjectForKey:@"deviceType"];
        self.password1 = [aDecoder decodeObjectForKey:@"password1"];
        self.password2 = [aDecoder decodeObjectForKey:@"password2"];
        self.device_nickname = [aDecoder decodeObjectForKey:@"device_nickname"];
        self.is_admin = [aDecoder decodeObjectForKey:@"is_admin"];
        self.open_purview = [aDecoder decodeObjectForKey:@"open_purview"];
        self.user_id = [aDecoder decodeObjectForKey:@"user_id"];
        self.cid = [aDecoder decodeObjectForKey:@"cid"];
        self.datestart = [aDecoder decodeObjectForKey:@"datestart"];
        self.dateend = [aDecoder decodeObjectForKey:@"dateend"];
        self.items = [aDecoder decodeObjectForKey:@"items"];
        self.isAutoLock = [aDecoder decodeObjectForKey:@"isAutoLock"];
        self.connected = [aDecoder decodeBoolForKey:@"connected"];
        self.elcet = [aDecoder decodeIntForKey:@"elect"];
        self.isAwayHome = [aDecoder decodeBoolForKey:@"isAwayHome"];
        self.isHighPriority = [aDecoder decodeBoolForKey:@"isHighPriority"];
        self.isWait = [aDecoder decodeBoolForKey:@"isWait"];
        self.satisfyCount = [aDecoder decodeInt64ForKey:@"satisfyCount"];
        self.spanLatitude = [aDecoder decodeObjectForKey:@"spanLatitude"];
        self.spanLongitude = [aDecoder decodeObjectForKey:@"spanLongitude"];
        self.createTime = [aDecoder decodeDoubleForKey:@"createTime"];
        self.currentTime = [aDecoder decodeDoubleForKey:@"currentTime"];
        self.serialNumber = [aDecoder decodeObjectForKey:@"serialNumber"];
        self.model = [aDecoder decodeObjectForKey:@"model"];
        self.deviceSN = [aDecoder decodeObjectForKey:@"deviceSN"];
        self.softwareVersion = [aDecoder decodeObjectForKey:@"softwareVersion"];
        self.peripheralId = [aDecoder decodeObjectForKey:@"peripheralId"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeDouble:self.edge_latitude forKey:@"center_latitude"];
    [aCoder encodeDouble:self.center_longitude forKey:@"center_longitude"];
    [aCoder encodeDouble:self.circle_radius forKey:@"circle_radius"];
    [aCoder encodeDouble:self.edge_longitude forKey:@"edge_longitude"];
    [aCoder encodeDouble:self.edge_latitude forKey:@"edge_latitude"];
    [aCoder encodeObject:self.devmac forKey:@"devmac"];
    [aCoder encodeObject:self.device_name forKey:@"device_name"];
    [aCoder encodeObject:self.deviceType forKey:@"deviceType"];
    [aCoder encodeObject:self.password1 forKey:@"password1"];
    [aCoder encodeObject:self.password2 forKey:@"password2"];
    [aCoder encodeObject:self.device_nickname forKey:@"device_nickname"];
    [aCoder encodeObject:self.is_admin forKey:@"is_admin"];
    [aCoder encodeObject:self.open_purview forKey:@"open_purview"];
    [aCoder encodeObject:self.user_id forKey:@"user_id"];
    [aCoder encodeObject:self.cid forKey:@"cid"];
    [aCoder encodeObject:self.datestart forKey:@"datestart"];
    [aCoder encodeObject:self.dateend forKey:@"dateend"];
    [aCoder encodeObject:self.items forKey:@"items"];
    [aCoder encodeObject:self.isAutoLock forKey:@"isAutoLock"];
    [aCoder encodeBool:self.connected forKey:@"connected"];
    [aCoder encodeInt:self.elcet forKey:@"elcet"];
    [aCoder encodeBool:self.isAwayHome forKey:@"isAwayHome"];
    [aCoder encodeBool:self.isHighPriority forKey:@"isHighPriority"];
    [aCoder encodeBool:self.isWait forKey:@"isWait"];
    [aCoder encodeInteger:self.satisfyCount forKey:@"satisfyCount"];
    [aCoder encodeObject:self.spanLatitude forKey:@"spanLatitude"];
    [aCoder encodeObject:self.spanLongitude forKey:@"spanLongitude"];
    [aCoder encodeDouble:self.createTime forKey:@"createTime"];
    [aCoder encodeDouble:self.currentTime forKey:@"currentTime"];
    [aCoder encodeObject:self.serialNumber forKey:@"serialNumber"];
    [aCoder encodeObject:self.model forKey:@"model"];
    [aCoder encodeObject:self.deviceSN forKey:@"deviceSN"];
    [aCoder encodeObject:self.softwareVersion forKey:@"softwareVersion"];
    [aCoder encodeObject:self.peripheralId forKey:@"peripheralId"];

}

+ (NSDictionary *)mj_replacedKeyFromPropertyName{
    //key为模型属性值
    return @{
             @"device_mac":@"devmac",
             @"isAutoLock":@"auto_lock",
             @"address":@"macLock",
             
             
             
             };
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:self.class]) return NO;
    if (self == object) return YES;
    MyDevice *other = object;
    return [self.device_name isEqualToString:other.device_name] && [self.is_admin isEqualToString:other.is_admin];
}

@end
