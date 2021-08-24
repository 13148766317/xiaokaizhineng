//
//  KDSPersonalProfileCell.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/22.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSPersonalProfileCell.h"
#import "Masonry.h"

@interface KDSPersonalProfileCell ()

///标题标签。
@property (nonatomic, strong) UILabel *titleLabel;
///头像视图。
@property (nonatomic, strong) UIImageView *avatarIV;
///昵称标签。
@property (nonatomic, strong) UILabel *nicknameLabel;
///账号标签。
@property (nonatomic, strong) UILabel *accountLabel;
///右边的箭头图片视图。
@property (nonatomic, strong) UIImageView *arrowIV;
///底部分割线。
@property (nonatomic, strong) UIView *separatorView;

@end

@implementation KDSPersonalProfileCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIFont *font = [UIFont systemFontOfSize:12];
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.font = font;
        self.titleLabel.textColor = KDSRGBColor(0x2b, 0x2f, 0x50);
        [self.contentView addSubview:self.titleLabel];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self);
            make.left.equalTo(self).offset(13);
            make.width.lessThanOrEqualTo(self).multipliedBy(0.3);
        }];
        
        UIImage *arrow = [UIImage imageNamed:@"right"];
        self.arrowIV = [[UIImageView alloc] initWithImage:arrow];
        [self.contentView addSubview:self.arrowIV];
        [self.arrowIV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.right.equalTo(self).offset(-13);
            make.size.mas_equalTo(arrow.size);
        }];
        
        self.avatarIV = [[UIImageView alloc] init];
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 34, 34) cornerRadius:17];
        CAShapeLayer *layer = [CAShapeLayer layer];
        layer.path = path.CGPath;
        self.avatarIV.layer.mask = layer;
        [self.contentView addSubview:self.avatarIV];
        [self.avatarIV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.right.equalTo(self.arrowIV.mas_left).offset(-10);
            make.width.height.mas_equalTo(34);
        }];
        
        self.nicknameLabel = [[UILabel alloc] init];
        self.nicknameLabel.font = font;
        self.nicknameLabel.textColor = KDSRGBColor(0xc2, 0xc2, 0xc2);
        self.nicknameLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:self.nicknameLabel];
        [self.nicknameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self);
            make.left.equalTo(self.titleLabel.mas_right).offset(10);
            make.right.equalTo(self.arrowIV.mas_left).offset(-10);
        }];
        
        self.accountLabel = [[UILabel alloc] init];
        self.accountLabel.font = font;
        self.accountLabel.textColor = KDSRGBColor(0xc2, 0xc2, 0xc2);
        self.accountLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:self.accountLabel];
        [self.accountLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self);
            make.left.equalTo(self.titleLabel.mas_right).offset(10);
            make.rightMargin.equalTo(self.arrowIV);
        }];
        
        self.separatorView = [UIView new];
        self.separatorView.backgroundColor = KDSRGBColor(0xf0, 0xf0, 0xf0);
        [self.contentView addSubview:self.separatorView];
        [self.separatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leftMargin.equalTo(self.titleLabel);
            make.bottom.equalTo(self);
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

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleLabel.text = title;
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    self.arrowIV.hidden = NO;
    self.avatarIV.hidden = NO;
    self.nicknameLabel.hidden = YES;
    self.accountLabel.hidden = YES;
    self.avatarIV.image = image;
}

- (void)setNickname:(NSString *)nickname
{
    _nickname = nickname;
    self.arrowIV.hidden = NO;
    self.avatarIV.hidden = YES;
    self.nicknameLabel.hidden = NO;
    self.accountLabel.hidden = YES;
    self.nicknameLabel.text = nickname;
}

- (void)setAccount:(NSString *)account
{
    _account = account;
    self.arrowIV.hidden = YES;
    self.avatarIV.hidden = YES;
    self.nicknameLabel.hidden = YES;
    self.accountLabel.hidden = NO;
    self.accountLabel.text = account;
}

- (void)setIsPwdCell:(BOOL)isPwdCell
{
    _isPwdCell = isPwdCell;
    self.arrowIV.hidden = NO;
    self.avatarIV.hidden = YES;
    self.nicknameLabel.hidden = YES;
    self.accountLabel.hidden = YES;
}

- (void)setHideSeparator:(BOOL)hideSeparator
{
    _hideSeparator = hideSeparator;
    self.separatorView.hidden = hideSeparator;
}

@end
