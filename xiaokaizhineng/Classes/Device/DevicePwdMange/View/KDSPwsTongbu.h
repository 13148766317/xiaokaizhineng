//
//  KDSPwsTongbu.h
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/11.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KDSPwsTongbu : UIView
@property (weak, nonatomic) IBOutlet UIButton *tongbuBtn;
@property (weak, nonatomic) IBOutlet UILabel *titleLab;
///点击同步按钮执行的回调，参数是同步按钮。
@property (nonatomic, copy) void(^syncBtnClickBlock) (UIButton *sender);

@end

NS_ASSUME_NONNULL_END
