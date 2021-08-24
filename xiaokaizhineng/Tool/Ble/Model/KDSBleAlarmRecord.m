//
//  KDSBleAlarmRecord.m
//  lock
//
//  Created by orange on 2019/1/18.
//  Copyright © 2019年 zhao. All rights reserved.
//

#import "KDSBleAlarmRecord.h"

@implementation KDSBleAlarmRecord

- (instancetype)initWithData:(NSData *)data
{
    self = [super init];
    if (self)
    {
        const unsigned char *bytes = data.bytes;
        _total = bytes[4];
        _current = bytes[5];
        _type = bytes[8];
        NSMutableString *hex = [NSMutableString stringWithCapacity:data.length * 2];
        for (NSUInteger i = 0; i < data.length; ++i)
        {
            [hex appendFormat:@"%02x", bytes[i]];
        }
        _hexString = hex.copy;
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[self class]]) return NO;
    KDSBleAlarmRecord * record = (KDSBleAlarmRecord *)object;
    if (self.hexString.length<12 || record.hexString.length<12) return NO;
    return  [[self.hexString substringFromIndex:12] isEqualToString:[((KDSBleAlarmRecord *)object).hexString substringFromIndex:12]];
}

- (NSUInteger)hash
{
    return self.hexString.length ? [self.hexString substringFromIndex:12].hash : self.hexString.hash;
}


- (void)encodeWithCoder:(nonnull NSCoder *)aCoder
{
    [aCoder encodeInt:self.total forKey:@"total"];
    [aCoder encodeInt:self.current forKey:@"current"];
    [aCoder encodeInteger:(NSInteger)self.type forKey:@"type"];
    [aCoder encodeObject:self.date forKey:@"date"];
    [aCoder encodeObject:self.hexString forKey:@"hexString"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        _total = [aDecoder decodeIntForKey:@"total"];
        _current = [aDecoder decodeIntForKey:@"current"];
        _type = (KDSBleAlarmType)[aDecoder decodeIntegerForKey:@"type"];
        self.date = [aDecoder decodeObjectForKey:@"date"];
        _hexString = [aDecoder decodeObjectForKey:@"hexString"];
    }
    return self;
}

@end
