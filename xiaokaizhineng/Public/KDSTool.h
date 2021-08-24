//
//  KDSTool.h
//  xiaokaizhineng
//
//  Created by orange on 2019/1/15.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KDSTool : NSObject

///在NSUserDefaults中设置/获取电话国际区号，不包含最前面的+号。
@property (nonatomic, strong, class, nullable) NSString *crc;
///app版本。
@property (nonatomic, strong, readonly, class) NSString *appVersion;

/**
 *@abstract 设置界面语言。新增语言时，需要更新内部实现。如果设置的语言和上一次的不一样且不为空，会发送一个本地语言改变的通知。
 *@param language 语言代码，如果空，已有设置使用已有设置，未有设置使用系统的设置。否则请确保参数为正确的语言代码。
 */
+ (void)setLanguage:(nullable NSString *)language;

/**
 *@abstract 获取当前界面的本地化设置语言。
 *@return 如果没有设置过，返回nil，其它返回已设置的语言。
 */
+ (nullable NSString *)getLanguage;

/**获取设备类型*/
+ (NSString*)getIphoneType;

/**判断是否是邮箱*/
+ (BOOL)isValidateEmail:(NSString *)email;

/**判断是否是手机号(以1开头的11位数字)*/
+ (BOOL)isValidatePhoneNumber:(NSString *)phone;

/**
 *@abstract 判断字符串是否是有效的密码。有效的密码必须包含数字+字母，且长度在6-16位之间。
 *@param text 要判断的字符串。
 *@return 判断结果。
 */
+ (BOOL)isValidPassword:(NSString *)text;

/**
 *@abstract 当登录/退出成功后，调用此方法设置当前登录的用户账号。免登录以及获取数据库数据时使用。
 *@param account 用户账号，如果为nil，会清除当前记录的信息。
 */
+ (void)setDefaultLoginAccount:(nullable NSString *)account;

/**
 *@abstract 调用此方法获取当前登录的用户账号。免登录以及获取数据库数据时使用。
 *@return 用户账号，如果为nil，则当前没有记录的信息。
 */
+ (nullable NSString *)getDefaultLoginAccount;

/**
 *@abstract 设置是否开启锁报警通知。在允许通知消息的情况下，默认开启。该属性只关联APP内页面展示的报警UI，不关联系统本地通知。
 *@param on YES开启，NO关闭。
 *@param bleName 蓝牙名称。
 */
+ (void)setNotificationOn:(BOOL)on forBle:(NSString *)bleName;

/**
 *@abstract 获取是否开启锁报警通知。在允许通知消息的情况下，默认开启。该属性只关联APP内页面展示的报警UI，不关联系统本地通知。
 *@param bleName 蓝牙名称。
 *@return YES开启，NO关闭。默认是开启的。
 */
+ (BOOL)getNotificationOnForBle:(NSString *)bleName;


/**
 获取通过UTF8转码后的Data

 @param string 需要转码的字符串
 @return 转码的Data
 */
+(NSData *)getTranscodingStringDataWithString:(NSString *)string;

/**
 *@brief 从原字符串截取至限制长度(16字节)后的字符串。utf8编码。
 *@param string 原字符串。
 *@return 截取至限制长度后的字符串。
 */
+ (NSString *)limitedLengthStringWithString:(NSString *)string;

///语言设置改变的通知名字。当更改字符串常量时，请同步修改MJRefreshComponent.m中的通知名字。
FOUNDATION_EXTERN NSString * const KDSLocaleLanguageDidChangeNotification;

//判断简单密码
+(BOOL)checkSimplePassword:(NSString*)pwdStr;

/**
 *@brief 根据电量选择要显示的对应的图片名称。统一各处使用到的逻辑。
 *@param power 电量。
 *@return 电量对应的图片名称。
 */
+ (NSString *)imageNameForPower:(int)power;

@end

NS_ASSUME_NONNULL_END
