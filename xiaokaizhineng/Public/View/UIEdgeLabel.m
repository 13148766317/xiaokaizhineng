//
//  UIEdgeLabel.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/15.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "UIEdgeLabel.h"

@implementation UIEdgeLabel

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines
{
    bounds.origin.x += self.edgeInsets.left;
    bounds.origin.y += self.edgeInsets.top;
    bounds.size.width = bounds.size.width - self.edgeInsets.left - self.edgeInsets.right;
    bounds.size.height = bounds.size.height - self.edgeInsets.top - self.edgeInsets.bottom;
    return bounds;
}

@end
