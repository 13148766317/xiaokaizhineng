//
//  UIEdgeLabel.h
//  xiaokaizhineng
//
//  Created by orange on 2019/2/15.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

///可以设置文字内边距的标签。@note 此类还没有完成。
@interface UIEdgeLabel : UILabel

///文字的内边距。
@property (nonatomic, assign) UIEdgeInsets edgeInsets;

@end

NS_ASSUME_NONNULL_END
