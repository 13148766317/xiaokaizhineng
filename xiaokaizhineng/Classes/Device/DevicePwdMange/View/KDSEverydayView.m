//
//  KDSEverydayView.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/15.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSEverydayView.h"

@implementation KDSEverydayView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self = [[[NSBundle mainBundle] loadNibNamed:@"KDSEverydayView" owner:self options:nil] lastObject];
    if (self) {
        self.frame = frame;
    }
    self.bgView.layer.cornerRadius = 5;
    return self;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
