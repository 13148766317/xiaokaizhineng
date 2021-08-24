//
//  KDSFingerprintManaTableViewCell.h
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/18.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KDSFingerprintManaTableViewCell : UITableViewCell

///序号。
@property (nonatomic, assign) NSInteger number;
///名称。
@property (nonatomic, strong) NSString *name;
///是否隐藏分隔线。
@property (nonatomic, assign) BOOL hideSeparator;
///cell圆角类型，0无圆角，1顶部圆角，2底部圆角，3顶部+底部圆角。
@property (nonatomic, assign) int cornerType;

@end

NS_ASSUME_NONNULL_END
