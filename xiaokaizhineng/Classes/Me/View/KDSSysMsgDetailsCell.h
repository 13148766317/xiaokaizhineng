//
//  KDSSysMsgDetailsCell.h
//  xiaokaizhineng
//
//  Created by orange on 2019/3/8.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KDSSysMsgDetailsCell : UITableViewCell

///日期，yyyy/MM/dd HH:mm。
@property (nonatomic, strong) NSString *date;
///标题。
@property (nonatomic, strong) NSString *title;
///内容。
@property (nonatomic, strong) NSString *content;

@end

NS_ASSUME_NONNULL_END
