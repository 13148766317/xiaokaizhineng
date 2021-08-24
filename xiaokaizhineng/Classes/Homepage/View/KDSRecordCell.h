//
//  KDSRecordCell.h
//  xiaokaizhineng
//
//  Created by orange on 2019/2/18.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KDSRecordCell : UITableViewCell

///记录时间，格式yyyy-MM-dd HH:mm:ss。
@property (nonatomic, strong) NSString *date;
///开锁密匙昵称。
@property (nonatomic, strong, nullable) NSString *nickname;
///cell内容类型，0开锁记录，1报警记录，设置图片使用。
@property (nonatomic, assign) int type;
///cell圆角类型，0无圆角，1顶部圆角，2底部圆角，3顶部+底部圆角。
@property (nonatomic, assign) int cornerType;
///记录(开锁或报警)类型，如APP开锁或低电压报警。@note 设置此属性前请先设置内容类型属性type。
@property (nonatomic, strong) NSString *recType;
///是否隐藏分隔线，默认否。
@property (nonatomic, assign) BOOL hideSeparator;

@end

NS_ASSUME_NONNULL_END
