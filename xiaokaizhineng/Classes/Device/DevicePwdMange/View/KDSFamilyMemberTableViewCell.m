//
//  KDSFamilyMemberTableViewCell.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/18.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSFamilyMemberTableViewCell.h"

@interface KDSFamilyMemberTableViewCell ()

///序号标签。
@property (weak, nonatomic) IBOutlet UILabel *numberLabel;
///名称标签。
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
///分隔线。
@property (weak, nonatomic) IBOutlet UIView *separatorView;
///上圆角阴影。
@property (nonatomic, strong) CAShapeLayer *topLayer;
///下圆角阴影。
@property (nonatomic, strong) CAShapeLayer *bottomLayer;
///全角阴影。
@property (nonatomic, strong) CAShapeLayer *allCornerLayer;

@end

@implementation KDSFamilyMemberTableViewCell

- (CAShapeLayer *)topLayer
{
    if (!_topLayer)
    {
        _topLayer = [CAShapeLayer layer];
        CGFloat radius = 5;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, kScreenWidth - 20, 60) byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight) cornerRadii:CGSizeMake(radius, radius)];
        _topLayer.path = path.CGPath;
    }
    return _topLayer;
}

- (CAShapeLayer *)bottomLayer
{
    if (!_bottomLayer)
    {
        _bottomLayer = [CAShapeLayer layer];
        CGFloat radius = 5;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, kScreenWidth - 20, 60) byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight) cornerRadii:CGSizeMake(radius, radius)];
        _bottomLayer.path = path.CGPath;
    }
    return _bottomLayer;
}

- (CAShapeLayer *)allCornerLayer
{
    if (!_allCornerLayer)
    {
        _allCornerLayer = [CAShapeLayer layer];
        CGFloat radius = 5;
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, kScreenWidth - 20, 60) byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(radius, radius)];
        _allCornerLayer.path = path.CGPath;
    }
    return _allCornerLayer;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setMember:(KDSAuthMember *)member
{
    _member = member;
    self.nameLabel.text = member.unickname ?: member.uname;
}

- (void)setNumber:(NSInteger)number
{
    _number = number;
    self.numberLabel.text = [NSString stringWithFormat:@"%02ld", (long)number + 1];
}

- (void)setHideSeparator:(BOOL)hideSeparator
{
    _hideSeparator = hideSeparator;
    self.separatorView.hidden = hideSeparator;
}

- (void)setCornerType:(int)cornerType
{
    _cornerType = cornerType;
    if (cornerType == 0)
    {
        self.layer.mask = nil;
    }
    else if (cornerType == 1)
    {
        self.layer.mask = self.topLayer;
    }
    else if (cornerType == 2)
    {
        self.layer.mask = self.bottomLayer;
    }
    else
    {
        self.layer.mask = self.allCornerLayer;
    }
}

@end
