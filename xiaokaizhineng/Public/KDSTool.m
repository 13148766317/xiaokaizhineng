//
//  KDSTool.m
//  xiaokaizhineng
//
//  Created by orange on 2019/1/15.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSTool.h"
#import <sys/utsname.h>

NSString * const KDSLocaleLanguageDidChangeNotification = @"KDSLocaleLanguageDidChangeNotification";

@implementation KDSTool

@dynamic crc;

+ (void)setLanguage:(nullable NSString *)language
{
    NSString *lanExisted = [self getLanguage];
    NSString *lan_ = language;
    if (!language)
    {
        if (lanExisted) return;
        NSArray *preferredLanguages = [NSLocale preferredLanguages];
        language = preferredLanguages.firstObject;
        /*NSArray<NSString *> *comps = [language componentsSeparatedByString:@"-"];
        if ([[NSLocale ISOCountryCodes] containsObject:comps.lastObject])
        {
            language = [language substringToIndex:lan.length - 3];
        }*/
    }
    
    if ([language hasPrefix:JianTiZhongWen]) {//开头匹配简体中文
        language = JianTiZhongWen;
    }
    else if ([language hasPrefix:FanTiZhongWen]) {//开头匹配繁体中文
        language = FanTiZhongWen;
    }else if ([language hasPrefix:@"th"]){
        language = Thailand;
    }else{//其他一律设置为英文
        language = English;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:language forKey:AppLanguage];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (![lanExisted isEqualToString:language] && lan_)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:KDSLocaleLanguageDidChangeNotification object:nil];
    }
}

+ (NSString *)getLanguage
{
    NSString *language = [[NSUserDefaults standardUserDefaults] objectForKey:AppLanguage];
    return language;
}

+ (void)setCrc:(NSString *)crc
{
    [[NSUserDefaults standardUserDefaults] setObject:crc forKey:@"countryOrRegionCode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)crc
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"countryOrRegionCode"];
}

+ (void)setNotificationOn:(BOOL)on forBle:(NSString *)bleName
{
    bleName = bleName ?: @"";
    [[NSUserDefaults standardUserDefaults] setObject:on ? @"YES" : @"NO" forKey:[@"notificationOn-" stringByAppendingString:bleName]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)getNotificationOnForBle:(NSString *)bleName
{
    bleName = bleName ?: @"";
   NSString *value = [[NSUserDefaults standardUserDefaults] objectForKey:[@"notificationOn-" stringByAppendingString:bleName]];
    return value ? value.boolValue : YES;
}

+ (NSString *)appVersion
{
    return [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
}

+ (NSString*)getIphoneType{
    
    //需要导入头文件：#import <sys/utsname.h>
    
    struct utsname systemInfo;
    
    uname(&systemInfo);
    
    NSString*platform = [NSString stringWithCString: systemInfo.machine encoding:NSASCIIStringEncoding];
    NSDictionary<NSString *, NSString *> *dict = @{
                                                   // iPhone
                                                   @"iPhone1,1" : @"iPhone 2G",
                                                   @"iPhone1,2" : @"iPhone 3G",
                                                   @"iPhone2,1" : @"iPhone 3GS",
                                                   @"iPhone3,1" : @"iPhone 4",
                                                   @"iPhone3,2" : @"iPhone 4",
                                                   @"iPhone3,3" : @"iPhone 4",
                                                   @"iPhone4,1" : @"iPhone 4S",
                                                   @"iPhone5,1" : @"iPhone 5",
                                                   @"iPhone5,2" : @"iPhone 5",
                                                   @"iPhone5,3" : @"iPhone 5c",
                                                   @"iPhone5,4" : @"iPhone 5c",
                                                   @"iPhone6,1" : @"iPhone 5s",
                                                   @"iPhone6,2" : @"iPhone 5s",
                                                   @"iPhone7,1" : @"iPhone 6 Plus",
                                                   @"iPhone7,2" : @"iPhone 6",
                                                   @"iPhone8,1" : @"iPhone 6s",
                                                   @"iPhone8,2" : @"iPhone 6s Plus",
                                                   @"iPhone8,4" : @"iPhone SE",
                                                   @"iPhone9,1" : @"iPhone 7",
                                                   @"iPhone9,2" : @"iPhone 7 Plus",
                                                   @"iPhone9,3" : @"iPhone 7",
                                                   @"iPhone9,4" : @"iPhone 7 Plus",
                                                   @"iPhone10,1" : @"iPhone 8",
                                                   @"iPhone10,4" : @"iPhone 8",
                                                   @"iPhone10,2" : @"iPhone 8 Plus",
                                                   @"iPhone10,5" : @"iPhone 8 Plus",
                                                   @"iPhone10,3" : @"iPhone X",
                                                   @"iPhone10,6" : @"iPhone X",
                                                   @"iPhone11,2" : @"iPhone XS",
                                                   @"iPhone11,4" : @"iPhone XS Max",
                                                   @"iPhone11,6" : @"iPhone XS Max",
                                                   @"iPhone11,8" : @"iPhone XR",
                                                   // iPad
                                                   @"iPad1,1" : @"iPad 1G",
                                                   @"iPad2,1" : @"iPad 2",
                                                   @"iPad2,2" : @"iPad 2",
                                                   @"iPad2,3" : @"iPad 2",
                                                   @"iPad2,4" : @"iPad 2",
                                                   @"iPad3,1" : @"iPad 3",
                                                   @"iPad3,2" : @"iPad 3",
                                                   @"iPad3,3" : @"iPad 3",
                                                   @"iPad3,4" : @"iPad 4",
                                                   @"iPad3,5" : @"iPad 4",
                                                   @"iPad3,6" : @"iPad 4",
                                                   @"iPad4,1" : @"iPad Air",
                                                   @"iPad4,2" : @"iPad Air",
                                                   @"iPad4,3" : @"iPad Air",
                                                   @"iPad5,3" : @"iPad Air 2",
                                                   @"iPad5,4" : @"iPad Air 2",
                                                   @"iPad6,7" : @"iPad Pro 12.9",
                                                   @"iPad6,8" : @"iPad Pro 12.9",
                                                   @"iPad6,3" : @"iPad Pro 9.7",
                                                   @"iPad6,4" : @"iPad Pro 9.7",
                                                   @"iPad6,11" : @"iPad 5",
                                                   @"iPad6,12" : @"iPad 5",
                                                   @"iPad7,1" : @"iPad Pro 12.9 inch 2nd gen",
                                                   @"iPad7,2" : @"iPad Pro 12.9 inch 2nd gen",
                                                   @"iPad7,3" : @"iPad Pro 10.5",
                                                   @"iPad7,4" : @"iPad Pro 10.5",
                                                   @"iPad7,5" : @"iPad 6",
                                                   @"iPad7,6" : @"iPad 6",
                                                   // iPad mini
                                                   @"iPad2,5" : @"iPad mini",
                                                   @"iPad2,6" : @"iPad mini",
                                                   @"iPad2,7" : @"iPad mini",
                                                   @"iPad4,4" : @"iPad mini 2",
                                                   @"iPad4,5" : @"iPad mini 2",
                                                   @"iPad4,6" : @"iPad mini 2",
                                                   @"iPad4,7" : @"iPad mini 3",
                                                   @"iPad4,8" : @"iPad mini 3",
                                                   @"iPad4,9" : @"iPad mini 3",
                                                   @"iPad5,1" : @"iPad mini 4",
                                                   @"iPad5,2" : @"iPad mini 4",
                                                   // Apple Watch
                                                   @"Watch1,1" : @"Apple Watch",
                                                   @"Watch1,2" : @"Apple Watch",
                                                   @"Watch2,6" : @"Apple Watch Series 1",
                                                   @"Watch2,7" : @"Apple Watch Series 1",
                                                   @"Watch2,3" : @"Apple Watch Series 2",
                                                   @"Watch2,4" : @"Apple Watch Series 2",
                                                   @"Watch3,1" : @"Apple Watch Series 3",
                                                   @"Watch3,2" : @"Apple Watch Series 3",
                                                   @"Watch3,3" : @"Apple Watch Series 3",
                                                   @"Watch3,4" : @"Apple Watch Series 3",
                                                   @"Watch4,1" : @"Apple Watch Series 4",
                                                   @"Watch4,2" : @"Apple Watch Series 4",
                                                   @"Watch4,3" : @"Apple Watch Series 4",
                                                   @"Watch4,4" : @"Apple Watch Series 4",
                                                   // iPod
                                                   @"iPod1,1" : @"iPod Touch 1G",
                                                   @"iPod2,1" : @"iPod Touch 2G",
                                                   @"iPod3,1" : @"iPod Touch 3G",
                                                   @"iPod4,1" : @"iPod Touch 4G",
                                                   @"iPod5,1" : @"iPod Touch 5G",
                                                   // 模拟器
                                                   @"i386" : @"iPhone Simulator",
                                                   @"x86_64" : @"iPhone Simulator",
                                                   };
    
    return dict[platform] ?: platform;
}

+ (BOOL)isValidateEmail:(NSString *)email{
    NSString *emailRegex = @"^[\\w-]+(\\.[\\w-]+)*@[\\w-]+(\\.[\\w-]+)+$";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES%@",emailRegex];
    return [emailTest evaluateWithObject:email];
}

+ (BOOL)isValidatePhoneNumber:(NSString *)phone{
    NSString *phoneRegex = @"^(13|14|15|16|17|18|19)[0-9]{9}$";
//    NSString *phoneRegex = @"^1[3-9]{1}\\d{9}$";
    NSPredicate *phoneTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", phoneRegex];
    return [phoneTest evaluateWithObject:phone];
}

+ (BOOL)isValidPassword:(NSString *)text
{
    NSString *expr = @"^(?=.*\\d)(?=.*[a-zA-Z])[0-9a-zA-Z]{6,16}$";
    NSPredicate *p = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", expr];
    return [p evaluateWithObject:text];
}

+ (void)setDefaultLoginAccount:(NSString *)account
{
    [[NSUserDefaults standardUserDefaults] setObject:account forKey:@"KDSLoginAccount"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)getDefaultLoginAccount
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"KDSLoginAccount"];
}

+ (NSData *)getTranscodingStringDataWithString:(NSString *)string{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    return data;
}

+ (NSString *)limitedLengthStringWithString:(NSString *)string
{
    if (!string) return @"";
    NSUInteger maxLength = 16;
    const char* utf8 = string.UTF8String;
    NSUInteger length = strlen(utf8);
    if (length <= 16) return string;
    NSUInteger i = 0;
    for (; i < length ;)
    {
        NSUInteger temp = i;
        for (int j = 7; j >= 0; --j)
        {
            if (((utf8[i] >> j) & 0x1) == 0)
            {
                i += (j==7 ? 1 : 7 - j);
                break;
            }
        }
        if (i >= maxLength)
        {
            i = i>maxLength ? temp : i;
            break;
        }
    }
    char dest[i + 1];
    strncpy(dest, utf8, i);
    dest[i] = 0;
    return @(dest);
}

+(BOOL)checkSimplePassword:(NSString*)pwdStr{
    NSMutableArray *pwdArray = [[NSMutableArray alloc] init];
//    = [pwdStr componentsSeparatedByString:@","];
    for (int i = 0; i<pwdStr.length; i++) {
        NSString * b= [pwdStr substringWithRange:NSMakeRange(i,1)];
        [pwdArray addObject:[NSString stringWithFormat:@"%@",b]];
    }
    BOOL isSimple = true;
    for (int i = 0; i<pwdArray.count-1; i++) {
        if (![pwdArray[i] isEqualToString:pwdArray[i+1]]) {
            isSimple = false;
            break;
        }
    }
    if (isSimple) {
        return isSimple;
    }
    isSimple = true;
    for (int i = 0; i<pwdArray.count-1; i++) {
        int s = [pwdArray[i] intValue] - [pwdArray[i+1] intValue];
        if (s != 1) {
            isSimple = false;
            break;
        }
    }
    if (isSimple) {
        return isSimple;
    }
    isSimple = true;
    for (int i = 0; i<pwdArray.count-1; i++) {
        int s = [pwdArray[i] intValue] - [pwdArray[i+1] intValue];
        if (s != -1) {
            isSimple = false;
            break;
        }
    }
    if (isSimple) {
        return isSimple;
    }
    return false;
}

+ (NSString *)imageNameForPower:(int)power
{
    NSString *imgName = @"homepageLock100Energy";
    if (power < 0)
    {
        
    }
    else if (power <= 20)
    {
        imgName = @"homepageLock0Energy";
    }
    else if (power <= 40)
    {
        imgName = @"homepageLock10Energy";
    }
    else if (power <= 60)
    {
        imgName = @"homepageLock60Energy";
    }
    else if (power <= 80)
    {
        imgName = @"homepageLock80Energy";
    }
    return imgName;
}

@end
