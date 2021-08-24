//
//  SectionChooseView.h
//  CommunityService
//
//  Created by lujh on 2017/3/8.
//  Copyright © 2017年 卢家浩. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SectionChooseVCDelegate <NSObject>
@required
- (void)SectionSelectIndex:(NSInteger)selectIndex;

@end
@interface SectionChooseView : UIView
/**
 *  圆角 默认 4
 */
@property (nonatomic, assign) CGFloat cornerRadius;
/**
 *  边框宽度 默认 1
 */
@property (nonatomic, assign) CGFloat borderWidth;
/**
 *  未点击状态及高亮状态下item背景颜色 默认 [UIColor whiteColor]
 */
@property (nonatomic, copy) UIColor * normalBackgroundColor;
/**
 *  选中状态下item颜色 默认 [UIColor redColor]
 */
@property (nonatomic, copy) UIColor * selectBackgroundColor;
/**
 *  未选中状态下item字体颜色 默认 [UIColor lightGrayColor]
 */
@property (nonatomic, copy) UIColor * titleNormalColor;
/**
 *  选中状态下item字体颜色 默认 [UIColor blueColor]
 */
@property (nonatomic, copy) UIColor * titleSelectColor;
/**
 *  选中第几个item 默认 0
 */
@property (nonatomic, assign) NSInteger selectIndex;

/**
 *  正常状态下item字体大小
 */
@property (nonatomic, assign) CGFloat normalTitleFont;
/**
 *  选中状态下item字体大小
 */
@property (nonatomic, assign) CGFloat selectTitleFont;

@property (nonatomic, assign) id <SectionChooseVCDelegate>delegate;

- (instancetype)initWithFrame:(CGRect)frame titleArray:(NSArray *)titleArray;
@end
