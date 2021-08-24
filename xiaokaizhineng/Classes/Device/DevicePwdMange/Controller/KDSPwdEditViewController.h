//
//  KDSPwdEditViewController.h
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/12.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSAutoConnectViewController.h"
#import "KDSPwdListModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface KDSPwdEditViewController : KDSAutoConnectViewController
///关联的锁。
@property (nonatomic, strong) KDSLock *lock;
@property (weak, nonatomic) IBOutlet UILabel *schedulLab;
@property(nonatomic,copy)NSString *schedulStr;
@property(nonatomic,strong)KDSPwdListModel *pwdModel;
@end

NS_ASSUME_NONNULL_END
