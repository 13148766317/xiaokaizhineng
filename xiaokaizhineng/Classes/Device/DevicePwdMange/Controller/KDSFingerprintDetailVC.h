//
//  KDSFingerprintDetailVC.h
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/18.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSAutoConnectViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface KDSFingerprintDetailVC : KDSAutoConnectViewController

///密码模型。
@property (nonatomic, strong) KDSPwdListModel *model;
///指纹被删除执行的回调，参数是被删除的门卡模型，@see model。锁中删除成功后有向服务器发删除请求，本地数据库没有。
@property (nonatomic, copy) void(^fpHasBeenDeletedBlock) (KDSPwdListModel *model);
///指纹信息修改成功执行的回调，参数是被删除的门卡模型，@see model。服务器信息有发送更新，本地数据库没有。
@property (nonatomic, copy) void(^fpInfoDidUpdateBlock) (KDSPwdListModel *model);

@end

NS_ASSUME_NONNULL_END
