//
//  KDSFamilyMemberlistVC.h
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/18.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSViewController.h"
#import "KDSLock.h"

NS_ASSUME_NONNULL_BEGIN

@interface KDSFamilyMemberlistVC : KDSViewController

///关联的锁。
@property (nonatomic, strong) KDSLock *lock;

@end

NS_ASSUME_NONNULL_END
