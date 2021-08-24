//
//  KDSLockLanguageAlterVC.h
//  xiaokaizhineng
//
//  Created by orange on 2019/2/16.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSAutoConnectViewController.h"
#import "KDSLock.h"

NS_ASSUME_NONNULL_BEGIN

///密码管理->更多设置->锁语言修改。
@interface KDSLockLanguageAlterVC : KDSAutoConnectViewController

///锁当前语言。
@property (nonatomic, strong) NSString *language;
///锁当前语言修改成功后执行的回调，回调参数为已本地化的语言。
@property (nonatomic, copy) void(^lockLanguageDidAlterBlock) (NSString *newLanguage);

@end

NS_ASSUME_NONNULL_END
