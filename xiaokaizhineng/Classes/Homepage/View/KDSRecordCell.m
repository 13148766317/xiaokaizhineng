//
//  KDSRecordCell.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/18.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSRecordCell.h"
#import "Masonry.h"

@interface KDSRecordCell ()

///容器视图。
@property (nonatomic, strong) UIView *containerView;
///竖线视图。
@property (nonatomic, strong) UIImageView *vLineIV;
///日期标签。
@property (nonatomic, strong) UILabel *dateLabel;
///昵称标签。
@property (nonatomic, strong) UILabel *nicknameLabel;
///记录类型内容标签。
@property (nonatomic, strong) UILabel *typeLabel;
///底部分割线。
@property (nonatomic, strong) UIView *separatorView;
///上圆角阴影。
@property (nonatomic, strong) CAShapeLayer *topLayer;
///下圆角阴影。
@property (nonatomic, strong) CAShapeLayer *bottomLayer;
///全角阴影。
@property (nonatomic, strong) CAShapeLayer *allCornerLayer;

@end

@implementation KDSRecordCell

#pragma mark - 懒加载。
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

#pragma mark - 初始化等重载的父类方法。
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        _hideSeparator = NO;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.clearColor;
        
        self.containerView = [[UIView alloc] init];
        self.containerView.backgroundColor = UIColor.whiteColor;
        [self.contentView addSubview:self.containerView];
        [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.bottom.right.equalTo(self);
        }];
        
        self.vLineIV = [[UIImageView alloc] init];
        [self.containerView addSubview:self.vLineIV];
        [self.vLineIV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.containerView);
            make.left.equalTo(self.containerView).offset(10);
            make.size.mas_equalTo(CGSizeMake(3, 40));
        }];
        
        UIFont *font = [UIFont systemFontOfSize:12];
        CGFloat width = ceil([@"68:59:00" sizeWithAttributes:@{NSFontAttributeName : font}].width) + 3;
        CGFloat height = ceil([Localized(@"forgotPassword") sizeWithAttributes:@{NSFontAttributeName : font}].height);
        
        self.dateLabel = [[UILabel alloc] init];
        self.dateLabel.font = font;
        self.dateLabel.textColor = KDSRGBColor(0xc2, 0xc2, 0xc2);
        [self.containerView addSubview:self.dateLabel];
        [self.dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.containerView).offset(14);
            make.left.equalTo(self.vLineIV.mas_right).offset(11);
            make.width.mas_equalTo(width);
            make.height.mas_equalTo(height);
        }];
        
        self.nicknameLabel = [[UILabel alloc] init];
        self.nicknameLabel.font = font;
        self.nicknameLabel.textColor = KDSRGBColor(0x2b, 0x2f, 0x50);
        [self.containerView addSubview:self.nicknameLabel];
        [self.nicknameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.topMargin.bottomMargin.equalTo(self.dateLabel);
            make.left.equalTo(self.dateLabel.mas_right).offset(9);
            make.right.equalTo(self.containerView).offset(62);
        }];
        
        self.typeLabel = [[UILabel alloc] init];
        self.typeLabel.font = font;
        self.typeLabel.textColor = KDSRGBColor(0xc2, 0xc2, 0xc2);
        [self.containerView addSubview:self.typeLabel];
        [self.typeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.vLineIV.mas_right).offset(11);
            make.bottom.equalTo(self.containerView).offset(-14);
            make.right.equalTo(self.containerView).offset(-34);
            make.height.mas_equalTo(height);
        }];
        
        self.separatorView = [UIView new];
        self.separatorView.backgroundColor = KDSRGBColor(0xf0, 0xf0, 0xf0);
        [self.containerView addSubview:self.separatorView];
        [self.separatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.containerView).offset(13);
            make.bottom.equalTo(self.containerView);
            make.right.equalTo(self.containerView).offset(-13);
            make.height.mas_equalTo(0.5);
        }];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

/*- (void)layoutSubviews
{
    ///FIXME:圆角大小改变需要修改这里
    CGFloat radius = 5;
    UIBezierPath *path1 = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight) cornerRadii:CGSizeMake(radius, radius)];
    self.topLayer.path = path1.CGPath;
    
    UIBezierPath *path2 = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight) cornerRadii:CGSizeMake(radius, radius)];
    self.bottomLayer.path = path2.CGPath;
    
    UIBezierPath *path3 = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(radius, radius)];
    self.allCornerLayer.path = path3.CGPath;
}*/

#pragma mark - setter
- (void)setDate:(NSString *)date
{
    _date = date;
    self.dateLabel.text = [[date substringToIndex:date.length /* - 3 不显示秒数就打开注释*/] componentsSeparatedByString:@" "].lastObject;
}

- (void)setNickname:(NSString *)nickname
{
    _nickname = nickname;
    self.nicknameLabel.text = nickname;
}

- (void)setRecType:(NSString *)recType
{
    _recType = recType;
    self.typeLabel.text = recType;
}

- (void)setType:(int)type
{
    _type = type;
    if (type == 0)
    {
        self.vLineIV.image = [UIImage imageNamed:@"homeUnlockRecordLine"];
    }
    else
    {
        self.vLineIV.image = [UIImage imageNamed:@"homeAlarmRecordLine"];
    }
}

- (void)setCornerType:(int)cornerType
{
    _cornerType = cornerType;
    if (cornerType == 0)
    {
        self.containerView.layer.mask = nil;
    }
    else if (cornerType == 1)
    {
        self.containerView.layer.mask = self.topLayer;
    }
    else if (cornerType == 2)
    {
        self.containerView.layer.mask = self.bottomLayer;
    }
    else
    {
        self.containerView.layer.mask = self.allCornerLayer;
    }
}

- (void)setHideSeparator:(BOOL)hideSeparator
{
    _hideSeparator = hideSeparator;
    self.separatorView.hidden = hideSeparator;
}

@end
