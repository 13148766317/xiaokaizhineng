//
//  KDSTutorialVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/3/14.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSTutorialVC.h"

@interface KDSTutorialVC () <UIScrollViewDelegate>

///翻页圆点。
@property (nonatomic, strong) UIPageControl *pageControl;

@end

@implementation KDSTutorialVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIScrollView *sv = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    sv.pagingEnabled = YES;
    sv.showsHorizontalScrollIndicator = NO;
    sv.delegate = self;
    [self.view addSubview:sv];
    
    //5s、se 320x568, X、XS 375x812, XR、Max 414x896,
    NSArray *names = @[@"tutorial61", @"tutorial62", @"tutorial63"];
    /*if (kScreenWidth == 320)
    {
        names = @[@"tutorial51", @"tutorial52", @"tutorial53"];
    }
    else if (kScreenHeight == 812)
    {
        names = @[@"tutorialX1", @"tutorialX2", @"tutorialX3"];
    }
    else if (kScreenHeight == 896)
    {
        names = @[@"tutorialMax1", @"tutorialMax2", @"tutorialMax3"];
    }*/
    UIImageView *last = nil;
    for (int i = 0; i < names.count; ++i)
    {
        UIImageView *iv =  [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:names[i] ofType:@"png"]]];
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.frame = CGRectMake(i * kScreenWidth, 0, kScreenWidth, kScreenHeight);
        [sv addSubview:iv];
        last = iv;
    }
    sv.contentSize = CGSizeMake(kScreenWidth * names.count, kScreenHeight);
    last.userInteractionEnabled = YES;
    UIButton *enterBtn = [[UIButton alloc] initWithFrame:CGRectMake((kScreenWidth - 142) / 2, kScreenHeight - 80 - 46, 142, 46)];
    enterBtn.backgroundColor = KDSRGBColor(45, 217, 186);
    enterBtn.layer.cornerRadius = 23;
    enterBtn.layer.shadowOffset = CGSizeMake(0, 4);
    enterBtn.layer.shadowColor = [UIColor colorWithRed:45/255.0 green:217/255.0 blue:186/255.0 alpha:0.43].CGColor;
    enterBtn.layer.shadowOpacity = 1;
    [enterBtn setTitle:Localized(@"openRightNow") forState:UIControlStateNormal];
    [enterBtn addTarget:self action:@selector(enterBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [last addSubview:enterBtn];
    
    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake((kScreenWidth - 100) / 2, kScreenHeight - 100 - 20, 100, 20)];
    self.pageControl.numberOfPages = names.count;
    self.pageControl.pageIndicatorTintColor = [UIColor colorWithRed:0x53/255.0 green:0xd3/255.0 blue:0xbc/255.0 alpha:0.5];
    self.pageControl.currentPageIndicatorTintColor = KDSRGBColor(0x2d, 0xd9, 0xba);
    //[self.view addSubview:self.pageControl];
}

- (void)enterBtnAction:(UIButton *)sender
{
    !self.tutorialComplete ?: self.tutorialComplete();
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.pageControl.currentPage = scrollView.contentOffset.x / scrollView.bounds.size.width;
    self.pageControl.hidden = self.pageControl.currentPage == self.pageControl.numberOfPages - 1;
//    scrollView.scrollEnabled = !self.pageControl.hidden;
}

@end
