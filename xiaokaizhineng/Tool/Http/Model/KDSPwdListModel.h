//
//  KDSPwdListModel.h
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/21.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import <Foundation/Foundation.h>

///服务器定义的密匙类型。
typedef NS_ENUM(NSUInteger, KDSServerKeyTpye) {
    ///所有类型。
    KDSServerKeyTpyeAll = 0,
    ///普通密码。
    KDSServerKeyTpyePIN,
    ///临时密码。
    KDSServerKeyTpyeTempPIN,
    ///指纹密码。
    KDSServerKeyTpyeFingerprint,
    ///卡片密码。
    KDSServerKeyTpyeCard,
};
///服务器定义的普通密匙周期类型。
typedef NS_ENUM(NSUInteger, KDSServerCycleTpye) {
    ///所有类型。
    KDSServerCycleTpyeAll = 0,
    ///永久。
    KDSServerCycleTpyeForever,
    ///时间段。
    KDSServerCycleTpyePeriod,
    ///周期计划。
    KDSServerCycleTpyeCycle,
    ///24小时。
    KDSServerCycleTpyeTwentyfourHours,
};
NS_ASSUME_NONNULL_BEGIN
//授权密码用户列表

@interface KDSPwdListModel : NSObject <NSCoding>
///id，这个id属于对应的设备。
@property (nonatomic, strong) NSString *_id;
@property (nonatomic, strong) NSString *nickName;      //用户昵称
@property (nonatomic, copy) NSString *num;//用户编码
///添加时间，距70年的本地时间秒数。当调用添加密码接口时，这个值由服务器确定。
@property (nonatomic, assign) NSTimeInterval createTime;
///密钥类型
@property (nonatomic, assign) KDSServerKeyTpye pwdType;
@property (nonatomic, strong) NSString *scheduleID; //周，年计划编码
@property (nonatomic, strong) NSString *pwd;      //用户密码
///用户权限，"1"1次(年月日)或一段时间，"2"多次(多次)，"3"永久，"4"1次且已经使用过。
@property (nonatomic, strong) NSString *open_purview;   //权限
@property (nonatomic, strong) NSArray *items;           //周期
@property (nonatomic, strong) NSString *startTime;      //开始时间
@property (nonatomic, strong) NSString *endTime;        //结束时间
@property (nonatomic, assign) KDSServerCycleTpye type;        //密钥周期类型
@end

NS_ASSUME_NONNULL_END
