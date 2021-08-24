//
//  KDSPwdListTableViewCell.h
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/11.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KDSPwdListModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface KDSPwdListTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLab;
@property (weak, nonatomic) IBOutlet UILabel *timeLab;
@property (weak, nonatomic) IBOutlet UILabel *numberLab;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *numLabTopConstraint;

-(void)setValueWithPwdListModel:(KDSPwdListModel*)model;
@end

NS_ASSUME_NONNULL_END
