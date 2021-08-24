//
//  KDSRecordHeaderFooterView.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/19.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSRecordHeaderFooterView.h"

@interface KDSRecordHeaderFooterView ()

///标题标签。
@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation KDSRecordHeaderFooterView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self)
    {
        UIView *view = [UIView new];
        view.backgroundColor = KDSRGBColor(249, 249, 249);
        self.backgroundView = view;
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.textColor = KDSRGBColor(0xc2, 0xc2, 0xc2);
        self.titleLabel.font = [UIFont systemFontOfSize:12];
        self.titleLabel.backgroundColor = UIColor.clearColor;
        [self.contentView addSubview:self.titleLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    self.backgroundView.frame = self.bounds;
    self.titleLabel.frame = self.bounds;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleLabel.text = title;
}

@end
