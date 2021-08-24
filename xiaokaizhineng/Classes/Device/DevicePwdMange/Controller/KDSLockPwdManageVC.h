//
//  KDSLockPwdManageVC.h
//  xiaokaizhineng
//
//  Created by orange on 2019/2/15.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSViewController.h"
#import "KDSLock.h"

NS_ASSUME_NONNULL_BEGIN

@interface KDSLockPwdManageVC : KDSViewController

///关联的锁。
@property (nonatomic, strong) KDSLock *lock;

@end

NS_ASSUME_NONNULL_END
