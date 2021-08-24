//
//  KDSAuthHelpCell.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/26.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSAuthHelpCell.h"
#import "Masonry.h"

@interface KDSAuthHelpCell ()

///异常代码+蓝牙名称标签。
@property (nonatomic, strong) UILabel *codeLabel;
///异常原因标签。
@property (nonatomic, strong) UILabel *reasonLabel;
///日期标签。
@property (nonatomic, strong) UILabel *dateLabel;
///分隔线。
@property (nonatomic, strong) UIView *separatorView;

@end

@implementation KDSAuthHelpCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        UIFont *font = [UIFont systemFontOfSize:12];
        
        self.dateLabel = [[UILabel alloc] init];
        self.dateLabel.textColor = KDSRGBColor(0xc2, 0xc2, 0xc2);
        self.dateLabel.font = font;
        self.dateLabel.textAlignment = NSTextAlignmentRight;
        CGSize size = [@"2999/99/99 99:99:99" sizeWithAttributes:@{NSFontAttributeName : font}];
        [self.contentView addSubview:self.dateLabel];
        [self.dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(14);
            make.right.equalTo(self).offset(-13);
            make.size.mas_lessThanOrEqualTo(CGSizeMake(size.width + 2, size.height + 1));
        }];
        
        self.codeLabel = [[UILabel alloc] init];
        self.codeLabel.textColor = KDSRGBColor(0x2b, 0x2f, 0x50);
        self.codeLabel.font = font;
        self.codeLabel.lineBreakMode = NSLineBreakByCharWrapping;
        [self.contentView addSubview:self.codeLabel];
        [self.codeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).offset(14);
            make.left.equalTo(self).offset(13);
            make.right.equalTo(self.dateLabel.mas_left).offset(-10);
            make.height.mas_lessThanOrEqualTo((60 - 28) / 2.0);
        }];
        
        self.reasonLabel = [[UILabel alloc] init];
        self.reasonLabel.textColor = KDSRGBColor(0xc2, 0xc2, 0xc2);
        self.reasonLabel.font = font;
        [self.contentView addSubview:self.reasonLabel];
        [self.reasonLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self).offset(-14);
            make.left.equalTo(self).offset(13);
            make.right.equalTo(self).offset(-13);
            make.height.mas_lessThanOrEqualTo((60 - 28) / 2.0);
        }];
        
        self.separatorView = [UIView new];
        self.separatorView.backgroundColor = KDSRGBColor(0xf0, 0xf0, 0xf0);
        [self.contentView addSubview:self.separatorView];
        [self.separatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(13);
            make.right.equalTo(self).offset(-13);
            make.bottom.equalTo(self);
            make.height.mas_equalTo(0.5);
        }];
        
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setException:(KDSAuthException *)exception
{
    _exception = exception;
    self.codeLabel.text = [NSString stringWithFormat:@"%@: 0x%02x", exception.nickname ?: exception.bleName, exception.code];
    self.dateLabel.text = exception.dateString;
    NSString *reason = @"";
    switch (exception.code)
    {//0x7e未绑定(pwd2为空)，0x91鉴权内容不正确，0x9A重复，0xC0硬件错误，0xC2校验错误(一般是pwd2被修改)
        case 1:
            reason = Localized(@"authFailed");
            break;
            
        case 0x7e:
            reason = Localized(@"notBind");
            break;
            
        case 0x91:
            reason = Localized(@"authParamIncorrect");
            break;
            
        case 0x9a:
            reason = Localized(@"authDuplicate");
            break;
            
        case 0xc0:
            reason = Localized(@"hardwareError");
            break;
            
        case 0xc2:
            reason = Localized(@"authCheckFailed");
            break;
            
        default:
            break;
    }
    self.reasonLabel.text = reason;
}

- (void)setHideSeparator:(BOOL)hideSeparator
{
    _hideSeparator = hideSeparator;
    self.separatorView.hidden = hideSeparator;
}

@end
