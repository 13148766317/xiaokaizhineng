//
//  KDSTempPwdDetailVC.h
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/15.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSAutoConnectViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface KDSTempPwdDetailVC : KDSAutoConnectViewController
///关联的锁。
@property (nonatomic, strong) KDSLock *lock;
@property(nonatomic,strong)KDSPwdListModel *pwdModel;
@end

NS_ASSUME_NONNULL_END
