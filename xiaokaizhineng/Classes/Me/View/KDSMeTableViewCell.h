//
//  KDSMeTableViewCell.h
//  xiaokaizhineng
//
//  Created by orange on 2019/2/22.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KDSMeTableViewCell : UITableViewCell

///左边显示的图片的图片名称。
@property (nonatomic, strong) NSString *imgName;
///显示的标题。
@property (nonatomic, strong) NSString *title;
///cell圆角类型，0无圆角，1顶部圆角，2底部圆角，3顶部+底部圆角。
@property (nonatomic, assign) int cornerType;
///是否隐藏分隔线，默认否。
@property (nonatomic, assign) BOOL hideSeparator;

@end

NS_ASSUME_NONNULL_END
