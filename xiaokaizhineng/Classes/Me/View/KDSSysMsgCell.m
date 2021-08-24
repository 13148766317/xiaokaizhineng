//
//  KDSSysMsgCell.m
//  xiaokaizhineng
//
//  Created by orange on 2019/3/8.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSSysMsgCell.h"
#import "Masonry.h"

@interface KDSSysMsgCell ()

///图片视图。
@property (nonatomic, strong) UIImageView *figureIV;
///标题标签。
@property (nonatomic, strong) UILabel *titleLabel;
///日期标签。
@property (nonatomic, strong) UILabel *dateLabel;
///分隔线。
@property (nonatomic, strong) UIView *separatorView;

@end

@implementation KDSSysMsgCell

#pragma mark - 初始化等重载的父类方法。
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        _hideSeparator = NO;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.clearColor;
        
        UIImage *figure = [UIImage imageNamed:@"头像-默认"];
        self.figureIV = [[UIImageView alloc] initWithImage:figure];
        [self.contentView addSubview:self.figureIV];
        [self.figureIV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.equalTo(self).offset(10);
            make.size.mas_equalTo(CGSizeMake(34, 34));
        }];
        
        UIFont *font = [UIFont systemFontOfSize:12];
        self.dateLabel = [[UILabel alloc] init];
        self.dateLabel.font = font;
        self.dateLabel.textColor = KDSRGBColor(0xc2, 0xc2, 0xc2);
        [self.contentView addSubview:self.dateLabel];
        [self.dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self);
            make.right.equalTo(self).offset(-13);
            make.width.mas_lessThanOrEqualTo(kScreenWidth / 2);
        }];
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.font = font;
        self.titleLabel.textColor = KDSRGBColor(0x2b, 0x2f, 0x50);
        self.titleLabel.numberOfLines = 0;
        [self.contentView addSubview:self.titleLabel];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self);
            make.left.equalTo(self.figureIV.mas_right).offset(11);
            make.right.equalTo(self.dateLabel.mas_left).offset(-11);
        }];
        
        self.separatorView = [UIView new];
        self.separatorView.backgroundColor = KDSRGBColor(0xf0, 0xf0, 0xf0);
        [self.contentView addSubview:self.separatorView];
        [self.separatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.bottom.right.equalTo(self);
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

#pragma mark - setter
- (void)setTitle:(NSString *)title
{
    _title = title;
    self.titleLabel.text = title;
}

- (void)setDate:(NSString *)date
{
    _date = date;
    self.dateLabel.text = date;
}

- (void)setHideSeparator:(BOOL)hideSeparator
{
    _hideSeparator = hideSeparator;
    self.separatorView.hidden = hideSeparator;
}


@end
