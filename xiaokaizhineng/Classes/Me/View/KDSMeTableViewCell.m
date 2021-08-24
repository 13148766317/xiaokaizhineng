//
//  KDSMeTableViewCell.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/22.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSMeTableViewCell.h"
#import "Masonry.h"

@interface KDSMeTableViewCell ()

///容器视图。
@property (nonatomic, strong) UIView *containerView;
///左边标题类型图片视图。
@property (nonatomic, strong) UIImageView *imageV;
///标题标签。
@property (nonatomic, strong) UILabel *titleLabel;
///右边的箭头图片视图。
@property (nonatomic, strong) UIImageView *arrowIV;
///底部分割线。
@property (nonatomic, strong) UIView *separatorView;
///上圆角阴影。
@property (nonatomic, strong) CAShapeLayer *topLayer;
///下圆角阴影。
@property (nonatomic, strong) CAShapeLayer *bottomLayer;
///全角阴影。
@property (nonatomic, strong) CAShapeLayer *allCornerLayer;

@end

@implementation KDSMeTableViewCell

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
        
        self.imageV = [[UIImageView alloc] init];
        [self.containerView addSubview:self.imageV];
        [self.imageV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.containerView).offset(18);
            make.centerY.equalTo(self.containerView);
//            make.width.mas_equalTo(23);
            make.width.height.mas_equalTo(19);
        }];
        
        UIFont *font = [UIFont systemFontOfSize:12];
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.font = font;
        self.titleLabel.textColor = KDSRGBColor(0x2b, 0x2f, 0x50);
        [self.containerView addSubview:self.titleLabel];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self.containerView);
            make.left.equalTo(self.imageV.mas_right).offset(11);
            make.right.equalTo(self.containerView).offset(-48);
        }];
        
        UIImage *arrow = [UIImage imageNamed:@"right"];
        self.arrowIV = [[UIImageView alloc] initWithImage:arrow];
        [self.containerView addSubview:self.arrowIV];
        [self.arrowIV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.containerView);
            make.right.equalTo(self.containerView).offset(-13);
            make.size.mas_equalTo(arrow.size);
        }];
        
        self.separatorView = [UIView new];
        self.separatorView.backgroundColor = KDSRGBColor(0xf0, 0xf0, 0xf0);
        [self.containerView addSubview:self.separatorView];
        [self.separatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leftMargin.equalTo(self.titleLabel);
            make.bottom.equalTo(self.containerView);
            make.rightMargin.equalTo(self.arrowIV);
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

- (void)layoutSubviews
{
    ///FIXME:圆角大小改变需要修改这里
    CGFloat radius = 5;
    UIBezierPath *path1 = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight) cornerRadii:CGSizeMake(radius, radius)];
    self.topLayer.path = path1.CGPath;
    
    UIBezierPath *path2 = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight) cornerRadii:CGSizeMake(radius, radius)];
    self.bottomLayer.path = path2.CGPath;
    
    UIBezierPath *path3 = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(radius, radius)];
    self.allCornerLayer.path = path3.CGPath;
}

#pragma mark - setter
- (void)setImgName:(NSString *)imgName
{
    _imgName = imgName;
    UIImage *img = [UIImage imageNamed:imgName];
    self.imageV.frame = CGRectMake(self.imageV.frame.origin.x, self.imageV.frame.origin.y, img.size.width, img.size.height);
    NSLog(@"------%f %f %f %f",self.imageV.frame.origin.x, self.imageV.frame.origin.y, img.size.width, img.size.height);
    self.imageV.image = img;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleLabel.text = title;
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
