//
//  KDSAddPwdSuccesVC.h
//  xiaokaizhineng
//
//  Created by wzr on 2019/3/19.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSAutoConnectViewController.h"
#import "KDSPwdListModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface KDSAddPwdSuccesVC : KDSAutoConnectViewController
@property (nonatomic, strong) KDSPwdListModel *pwdModel;
@property (nonatomic, copy) NSString *createTimeStr;

@end

NS_ASSUME_NONNULL_END
