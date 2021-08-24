//
//  KDSPwsTongbu.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/11.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSPwsTongbu.h"

@interface KDSPwsTongbu()

@end

@implementation KDSPwsTongbu

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self = [[[NSBundle mainBundle] loadNibNamed:@"KDSPwsTongbu" owner:self options:nil] lastObject];
    if (self) {
        self.frame = frame;
    }
    self.tongbuBtn.layer.borderColor = KDSRGBColor(45, 217, 186).CGColor;
    self.titleLab.text = Localized(@"BLESynchronize");
    [self.tongbuBtn setTitle:Localized(@"synchronize") forState:UIControlStateNormal];
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.titleLab.text = Localized(@"BLESynchronize");
    [self.tongbuBtn setTitle:Localized(@"synchronize") forState:UIControlStateNormal];
}

- (IBAction)tongbuClick:(id)sender {
    !self.syncBtnClickBlock ?: self.syncBtnClickBlock(sender);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
