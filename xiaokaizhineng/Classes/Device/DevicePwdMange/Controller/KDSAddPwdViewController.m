//
//  KDSAddPwdViewController.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/12.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSAddPwdViewController.h"
#import "SectionChooseView.h"
#import "KDSAgingViewController.h"
#import "KDSCycleViewController.h"

@interface KDSAddPwdViewController ()<UIScrollViewDelegate,SectionChooseVCDelegate>

@property(nonatomic,strong)SectionChooseView *sectionChooseView;
//底部滚动ScrollView
@property (nonatomic, strong) UIScrollView *contentScrollView;

@end

@implementation KDSAddPwdViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationTitleLabel.text = Localized(@"AddaPassword");
    // 首次进入加载第一个界面通知
    self.automaticallyAdjustsScrollViewInsets = false;
    NSLog(@"self.view.frame.size.width =%f",self.view.frame.size.width);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showFirstVC) name:@"ABC" object:nil];
    //添加所有子控制器
    [self setupChildViewController];
    //初始化UIScrollView
    [self setupUIScrollView];
    // Do any additional setup after loading the view from its nib.
}
- (void)showFirstVC {
    [self showVc:0];
}
- (void)setupUIScrollView {
    // 创建底部滚动视图
    self.contentScrollView = [[UIScrollView alloc] init];
    CGFloat y = 54;
    _contentScrollView.frame = CGRectMake(0, y, kScreenWidth, kScreenHeight);
    _contentScrollView.contentSize = CGSizeMake(self.view.frame.size.width * 2, 0);
    // 开启分页
    _contentScrollView.pagingEnabled = YES;
    // 没有弹簧效果
    _contentScrollView.bounces = YES;
    // 隐藏水平滚动条
    _contentScrollView.showsHorizontalScrollIndicator = NO;
    // 设置代理
    _contentScrollView.delegate = self;
    [self.view addSubview:_contentScrollView];
    self.sectionChooseView = [[SectionChooseView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 54) titleArray:@[Localized(@"aging"), Localized(@"cycle")]];
    self.sectionChooseView.selectIndex = 0;
    self.sectionChooseView.delegate = self;
    //设置阴影
    self.sectionChooseView.layer.shadowColor = KDSRGBColor(244, 244, 244).CGColor;
    self.sectionChooseView.layer.shadowOffset = CGSizeMake(2, 2);
    self.sectionChooseView.layer.shadowOpacity = 1.0;
    self.sectionChooseView.clipsToBounds = NO;
    
    self.sectionChooseView.normalBackgroundColor = [UIColor whiteColor];
    self.sectionChooseView.selectBackgroundColor = [UIColor whiteColor];
    self.sectionChooseView.titleNormalColor = [UIColor grayColor];
    self.sectionChooseView.titleSelectColor = KDSRGBColor(45, 217, 186);
    self.sectionChooseView.normalTitleFont = 14;
    self.sectionChooseView.selectTitleFont = 16;
    [self.view addSubview:self.sectionChooseView];
}
#pragma mark -添加所有子控制器
-(void)setupChildViewController {
    KDSAgingViewController *AgingVC = [[KDSAgingViewController alloc] init];
    AgingVC.lock = self.lock;
    [self addChildViewController:AgingVC];
    
    KDSCycleViewController*CycleVC = [[KDSCycleViewController alloc] init];
    CycleVC.lock = self.lock;
    [self addChildViewController:CycleVC];
    
}
#pragma mark -SMCustomSegmentDelegate
- (void)SectionSelectIndex:(NSInteger)selectIndex {
    // 1 计算滚动的位置
    CGFloat offsetX = selectIndex * self.view.frame.size.width;
    [self.contentScrollView setContentOffset:CGPointMake(offsetX, 0) animated:true];
    // 2.给对应位置添加对应子控制器
    [self showVc:selectIndex];
}
#pragma mark -显示控制器的view
/**
 *  显示控制器的view
 *
 *  @param index 选择第几个
 *
 */
- (void)showVc:(NSInteger)index {
    CGFloat offsetX = index * self.view.frame.size.width;
    UIViewController *vc = self.childViewControllers[index];
    // 判断控制器的view有没有加载过,如果已经加载过,就不需要加载
    if (vc.isViewLoaded) return;
    vc.view.frame = CGRectMake(offsetX, 0, CGRectGetWidth(_contentScrollView.bounds), CGRectGetHeight(_contentScrollView.bounds));
    [self.contentScrollView addSubview:vc.view];
}

#pragma mark -UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    // 计算滚动到哪一页
    CGPoint offset = scrollView.contentOffset;
    NSUInteger index = offset.x / scrollView.bounds.size.width;
    // 1.添加子控制器view
    [self showVc:index];
    // 2.把对应的标题选中
    self.sectionChooseView.selectIndex = index;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
