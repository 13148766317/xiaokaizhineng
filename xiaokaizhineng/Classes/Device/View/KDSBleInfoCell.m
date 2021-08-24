//
//  KDSBleInfoCell.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/12.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSBleInfoCell.h"
#import "Masonry.h"

@interface KDSBleInfoCell ()

///蓝牙名称标签。
@property (nonatomic, strong) UILabel *nameLabel;
///绑定按钮。
@property (nonatomic, strong) UIButton *bindBtn;
///下划线。
@property (nonatomic, strong) UIView *underlineView;

@end

@implementation KDSBleInfoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.bindBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        UIFont *font = [UIFont systemFontOfSize:12];
        self.bindBtn.titleLabel.font = font;
        [self.bindBtn setTitleColor:KDSRGBColor(0x2d, 0xd9, 0xba) forState:UIControlStateNormal];
        [self.bindBtn setTitleColor:KDSRGBColor(0xc7, 0xef, 0xe8) forState:UIControlStateDisabled];
        [self.bindBtn setTitle:Localized(@"gotoBindBle") forState:UIControlStateNormal];
        [self.bindBtn setTitle:Localized(@"bleHasBinded") forState:UIControlStateDisabled];
        [self.bindBtn addTarget:self action:@selector(bindBtnDidClickAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.bindBtn];
        [self.bindBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self);
            make.right.equalTo(self).offset(-17);
            make.width.mas_equalTo([self.bindBtn.currentTitle sizeWithAttributes:@{NSFontAttributeName : self.bindBtn.titleLabel.font}].width + 10);
        }];
        
        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.textColor = KDSRGBColor(0x89, 0x89, 0x89);
        self.nameLabel.font = font;
        [self.contentView addSubview:self.nameLabel];
        [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.equalTo(self);
            make.left.equalTo(self).offset(23);
            make.right.equalTo(self.bindBtn.mas_left).offset(-23);
        }];
        
        self.underlineView = [[UIView alloc] init];
        self.underlineView.backgroundColor = KDSRGBColor(0xf9, 0xf9, 0xf9);
        [self.contentView addSubview:self.underlineView];
        [self.underlineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(13);
            make.bottom.equalTo(self);
            make.right.equalTo(self).offset(-13);
            make.height.mas_equalTo(1);
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

- (void)setBleName:(NSString *)bleName
{
    _bleName = bleName;
    if (!bleName) return;
    self.nameLabel.text = [@"Xiaokai-L-" stringByAppendingString:[bleName substringFromIndex:bleName.length>3 ? bleName.length-4 : 0]];
}

- (void)setHasBinded:(BOOL)hasBinded
{
    _hasBinded = hasBinded;
    self.bindBtn.enabled = !hasBinded;
    [self layoutIfNeeded];
}

- (void)setUnderlineHidden:(BOOL)underlineHidden
{
    _underlineHidden = underlineHidden;
    self.underlineView.hidden = underlineHidden;
}

- (void)bindBtnDidClickAction:(UIButton *)sender
{
    !self.bindBtnDidClickBlock ?: self.bindBtnDidClickBlock(sender);
}

@end
