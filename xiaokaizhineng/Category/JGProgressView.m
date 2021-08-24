//
//  JGProgressView.m
//  JGProgressView
//
//  Created by 郭军 on 2017/3/16.
//  Copyright © 2017年 ZJNY. All rights reserved.
//

#import "JGProgressView.h"

#define KProgressBorderWidth 0.0f
#define KProgressPadding 1.0f
#define KProgressColor [UIColor colorWithRed:38/255.0 green:223/255.0 blue:190/255.0 alpha:1]

@interface JGProgressView ()

@end

@implementation JGProgressView

-(void)setProgressView{
    //进度
    UIView *tView = [[UIView alloc] init];
    tView.backgroundColor = KProgressColor;
    tView.layer.cornerRadius = (self.bounds.size.height - (KProgressBorderWidth + KProgressPadding) * 2) * 0.5;
    tView.layer.masksToBounds = YES;
    [self addSubview:tView];
    self.tView = tView;
}
- (void)setProgress:(CGFloat)progress
{
    if (!self.tView) {
        [self setProgressView];
    }
    _progress = progress;
    
    CGFloat margin = KProgressBorderWidth + KProgressPadding;
    CGFloat maxWidth = self.bounds.size.width - margin * 2;
    CGFloat heigth = self.bounds.size.height - margin * 2;
    NSLog(@"");
    _tView.frame = CGRectMake(margin, margin, maxWidth * progress, heigth);
}


@end
