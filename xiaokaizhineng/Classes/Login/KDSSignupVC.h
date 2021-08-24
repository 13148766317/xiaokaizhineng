//
//  KDSSignupVC.h
//  xiaokaizhineng
//
//  Created by orange on 2019/1/15.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *@abstract 注册和忘记密码共用。
 */
@interface KDSSignupVC : KDSTableViewController

///类型，默认0是注册，如果忘记密码设置为1.
@property (nonatomic, assign) int type;
///注册成功执行的回调，如果类型是忘记密码此回调不会执行。回调参数分别是地区码(如果有，带+号)、用户名和密码。
@property (nonatomic, copy) void(^signupSuccess) (NSString * _Nullable crc, NSString *username, NSString *password);

@end

NS_ASSUME_NONNULL_END
