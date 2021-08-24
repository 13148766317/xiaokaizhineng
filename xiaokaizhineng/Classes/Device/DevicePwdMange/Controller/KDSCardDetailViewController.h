//
//  KDSCardDetailViewController.h
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/18.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSAutoConnectViewController.h"
#import "KDSLock.h"
#import "KDSPwdListModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface KDSCardDetailViewController : KDSAutoConnectViewController

///密码模型。
@property (nonatomic, strong) KDSPwdListModel *model;
///门卡被删除执行的回调，参数是被删除的门卡模型，@see model。
@property (nonatomic, copy) void(^cardHasBeenDeletedBlock) (KDSPwdListModel *model);
///门卡信息修改成功执行的回调，参数是被删除的门卡模型，@see model。
@property (nonatomic, copy) void(^cardInfoDidUpdateBlock) (KDSPwdListModel *model);

@end

NS_ASSUME_NONNULL_END
