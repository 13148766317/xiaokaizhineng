//
//  KDSAuthHelpCell.h
//  xiaokaizhineng
//
//  Created by orange on 2019/2/26.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KDSAuthException.h"

NS_ASSUME_NONNULL_BEGIN

@interface KDSAuthHelpCell : UITableViewCell

///鉴权异常模型。
@property (nonatomic, strong) KDSAuthException *exception;
///是否隐藏分隔线。
@property (nonatomic, assign) BOOL hideSeparator;

@end

NS_ASSUME_NONNULL_END
