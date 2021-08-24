//
//  KDSGesturePwdVC.h
//  xiaokaizhineng
//
//  Created by orange on 2019/2/25.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSViewController.h"

NS_ASSUME_NONNULL_BEGIN

///我的->安全设置->手势密码
@interface KDSGesturePwdVC : KDSViewController

///手势密码功能类型，0设置手势密码，1修改手势密码，2验证手势密码。默认0.
@property (nonatomic, assign) int type;

@end

NS_ASSUME_NONNULL_END
