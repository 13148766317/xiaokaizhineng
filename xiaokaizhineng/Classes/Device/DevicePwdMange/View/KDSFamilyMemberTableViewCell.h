//
//  KDSFamilyMemberTableViewCell.h
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/18.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KDSAuthMember.h"

NS_ASSUME_NONNULL_BEGIN

@interface KDSFamilyMemberTableViewCell : UITableViewCell

@property (nonatomic, strong) KDSAuthMember *member;
///序号。
@property (nonatomic, assign) NSInteger number;
///是否隐藏分隔线。
@property (nonatomic, assign) BOOL hideSeparator;
///cell圆角类型，0无圆角，1顶部圆角，2底部圆角，3顶部+底部圆角。
@property (nonatomic, assign) int cornerType;

@end

NS_ASSUME_NONNULL_END
