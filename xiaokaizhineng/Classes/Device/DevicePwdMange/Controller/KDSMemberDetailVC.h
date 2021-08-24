//
//  KDSMemberDetailVC.h
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/18.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSViewController.h"
#import "KDSLock.h"
#import "KDSAuthMember.h"

NS_ASSUME_NONNULL_BEGIN

@interface KDSMemberDetailVC : KDSViewController

///关联的锁。
@property (nonatomic, strong) KDSLock *lock;
///关联的被授权用户。
@property (nonatomic, strong) KDSAuthMember *member;
///用户被删除执行的回调，参数是被删除的用户模型，等于关联的被授权用户member属性，@see member。
@property (nonatomic, copy) void(^memberHasBeenDeleteBlock) (KDSAuthMember *member);

@end

NS_ASSUME_NONNULL_END
