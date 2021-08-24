//
//  KDSSysMsgCell.h
//  xiaokaizhineng
//
//  Created by orange on 2019/3/8.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KDSSysMsgCell : UITableViewCell

///标题。
@property (nonatomic, strong) NSString *title;
///日期，yyyy/MM/dd
@property (nonatomic, strong) NSString *date;
///是否隐藏分隔线。
@property (nonatomic, assign) BOOL hideSeparator;

@end

NS_ASSUME_NONNULL_END
