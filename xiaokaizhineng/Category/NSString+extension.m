//
//  NSString+extension.m
//  xiaokaizhineng
//
//  Created by orange on 2019/1/24.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "NSString+extension.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (extension)

- (NSString *)md5
{
    NSAssert(self, @"字符串不能为空");
    unsigned char md5[CC_MD5_DIGEST_LENGTH];
    CC_MD5(self.UTF8String, CC_MD5_DIGEST_LENGTH, md5);
    NSMutableString *ms = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; ++i)
    {
        [ms appendFormat:@"%x", md5[i]];
    }
    return ms.copy;
}

+ (NSString *)uuid
{
    CFUUIDRef cfuuid = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef cfstr = CFUUIDCreateString(kCFAllocatorDefault, cfuuid);
    CFRelease(cfuuid);
    return (__bridge_transfer NSString *)cfstr;
}

@end
