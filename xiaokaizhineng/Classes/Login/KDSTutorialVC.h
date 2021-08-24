//
//  KDSTutorialVC.h
//  xiaokaizhineng
//
//  Created by orange on 2019/3/14.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSViewController.h"

NS_ASSUME_NONNULL_BEGIN

///引导页。
@interface KDSTutorialVC : KDSViewController

///引导完成执行的回调。
@property (nonatomic, copy) void(^tutorialComplete) (void);

@end

NS_ASSUME_NONNULL_END
