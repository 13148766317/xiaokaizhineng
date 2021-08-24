//
//  KDSHomepageVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/1/15.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//
#import "KDSHomepageVC.h"
#import "Masonry.h"
#import "KDSHttpManager+Ble.h"
#import "KDSDeviceNicknameView.h"
#import "KDSLockInfoVC.h"
#import "KDSDeviceModelListTableVC.h"
#import "MJRefresh.h"
#import "MBProgressHUD+MJ.h"
#import "KDSDBManager.h"
#import "KDSRecordDetailsVC.h"

@interface KDSHomepageVC () <UIScrollViewDelegate>
@property (nonatomic, strong) UIView *naviView;
///顶部显示门锁名称的视图。
@property (nonatomic, strong) KDSDeviceNicknameView *nicknameView;
///指示当前门锁的绿色线条。
@property (nonatomic, strong) UIView *lineView;
///门锁信息页面的滚动视图。
@property (nonatomic, strong) UIScrollView *scrollView;
///没有设备时显示xiaokai。
@property (nonatomic, strong) UIImageView *noDeviceXiaoKaiImg;
///没有设备时显示的按钮。
@property (nonatomic, strong) UIButton *noDeviceBtn;
///开锁、报警详情按钮。初始化和没有绑定设备时隐藏，获取绑定设备后显示。
@property (nonatomic, strong) UIButton *recordDetailsBtn;
///从服务器获取的绑定设备。
@property (nonatomic, strong) NSMutableArray<MyDevice *> *devicesArr;
///日期格式器，使用前先设置格式。
@property (nonatomic, strong) NSDateFormatter *dateFmt;

@end

@implementation KDSHomepageVC

- (NSMutableArray<MyDevice *> *)devicesArr
{
    if (_devicesArr == nil)
    {
        _devicesArr = [NSMutableArray array];
    }
    return _devicesArr;
}

- (NSDateFormatter *)dateFmt
{
    if (!_dateFmt)
    {
        _dateFmt = [[NSDateFormatter alloc] init];
    }
    return _dateFmt;
}

#pragma mark - 生命周期、界面设置相关方法
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSArray<MyDevice *> *cacheDevices = [[KDSDBManager sharedManager] queryBindedDevices];
    if (cacheDevices.count)
    {
        [self.devicesArr addObjectsFromArray:cacheDevices];
    }
    _naviView =  [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, kStatusBarHeight + kNavBarHeight)];
    _naviView.backgroundColor = UIColor.whiteColor;
    self.nicknameView = [[KDSDeviceNicknameView alloc] initWithFrame:CGRectMake(30, kStatusBarHeight + 15, self.view.bounds.size.width - 60, 20)];
    __weak typeof(self) weakSelf = self;
    self.nicknameView.selectDeviceBlock = ^(MyDevice * _Nonnull device) {
        NSUInteger index = [weakSelf.devicesArr indexOfObject:device];
        if (index != weakSelf.scrollView.contentOffset.x / kScreenWidth)
        {
            [weakSelf.scrollView setContentOffset:CGPointMake(index * kScreenWidth, 0) animated:YES];
        }
    };
    [_naviView addSubview:self.nicknameView];
    ///绿色线条。
    self.lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 3)];
    self.lineView.hidden = YES;
    self.lineView.layer.cornerRadius = 1.5;
    self.lineView.center = CGPointMake(_naviView.center.x, _naviView.bounds.size.height - 1.5);
    self.lineView.backgroundColor = KDSRGBColor(0x2d, 0xd9, 0xba);
    [_naviView addSubview:self.lineView];
    [self.view addSubview:_naviView];
    
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.delegate = self;
    self.scrollView.bounces = NO;
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.lineView.mas_bottom).offset(1);
        make.left.bottom.right.equalTo(self.view);
    }];
    
    self.noDeviceBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.noDeviceBtn setTitle:@"点击添加设备" forState:UIControlStateNormal];
    self.noDeviceBtn.adjustsImageWhenHighlighted = NO; 
    [self.noDeviceBtn setTitleColor:KDSRGBColor(89, 86, 86) forState:UIControlStateNormal];
    self.noDeviceBtn.titleLabel.font = [UIFont systemFontOfSize: 12.0];
    [self.noDeviceBtn setBackgroundImage:[UIImage imageNamed:@"中间bg-无设备"] forState:UIControlStateNormal];
    [self.noDeviceBtn addTarget:self action:@selector(clickNoDeviceBtnAddDevice:) forControlEvents:UIControlEventTouchUpInside];
    self.noDeviceBtn.hidden = NO;
    [self.scrollView addSubview:self.noDeviceBtn];
    [self.noDeviceBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.scrollView);
        make.width.mas_equalTo(221);
        make.height.mas_equalTo(221);
    }];
    self.noDeviceXiaoKaiImg = [[UIImageView alloc] init];
    [self.noDeviceXiaoKaiImg setImage:[UIImage imageNamed:@"xiaokai"]];
    [self.scrollView addSubview:self.noDeviceXiaoKaiImg];
    [self.noDeviceXiaoKaiImg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.view).offset(88+64);
        make.width.mas_equalTo(172);
        make.height.mas_equalTo(24);
    }];
    
    self.recordDetailsBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.recordDetailsBtn.hidden = YES;
    self.recordDetailsBtn.exclusiveTouch = YES;
    NSString *title = Localized(@"unlockDetails");
    UIFont *font = [UIFont systemFontOfSize:11];
    [self.recordDetailsBtn setTitle:title forState:UIControlStateNormal];
    [self.recordDetailsBtn setTitleColor:KDSRGBColor(0x2d, 0xd9, 0xba) forState:UIControlStateNormal];
    [self.recordDetailsBtn setImage:[UIImage imageNamed:@"homepageUnlockDetails"] forState:UIControlStateNormal];
    self.recordDetailsBtn.titleLabel.font = font;
    CGSize titleSize = [title sizeWithAttributes:@{NSFontAttributeName : font}];
    self.recordDetailsBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.recordDetailsBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    CGSize imageSize = [UIImage imageNamed:@"homepageUnlockDetails"].size;
    self.recordDetailsBtn.imageEdgeInsets = UIEdgeInsetsMake(0, (ceil(titleSize.width) - imageSize.width) / 2, 0, 0);
    self.recordDetailsBtn.titleEdgeInsets = UIEdgeInsetsMake(imageSize.height + 6, -imageSize.width, 0, 0);
    [self.recordDetailsBtn addTarget:self action:@selector(clickRecordDetailsBtnViewRecordDetails:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.recordDetailsBtn];
    [self.recordDetailsBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(kScreenHeight < 667 ? -11 : -16);
        make.width.mas_equalTo(ceil(titleSize.width));
        make.height.mas_equalTo(12 + 6 + ceil(titleSize.height));
    }];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localeLanguageDidChange:) name:KDSLocaleLanguageDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lockHasBeenDeleted:) name:KDSLockHasBeenDeletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lockDidAlarm:) name:KDSLockDidAlarmNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lockHasBeenAdded:) name:KDSLockHasBeenAddedNotification object:nil];
    if (cacheDevices.count) [self refreshWhenBindedDevieDidChange:cacheDevices];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"netWorkIsAvailable: %@" ,[KDSUserManager sharedManager].netWorkIsAvailable?@"YES":@"NO");
    [self getBindedDeviceList];
    //下面2句是为了不让导航栏的昵称滚动视图发生看得见的偏移动作用的，不知道为什么此偏移会自动归零，请求设备回来再设置会看到偏移动作。
    CGPoint offset = self.scrollView.contentOffset;
    if (offset.x/self.scrollView.bounds.size.width < self.devicesArr.count)
    {
        self.nicknameView.offsetX = offset.x / self.scrollView.bounds.size.width;
    }
}

/**
 *@abstract 当绑定的设备被删除时，或从服务器拉取到新的设备列表时，刷新主界面。加入了缓存数据，没有网络的时候应该使用缓存数据刷新。
 *@param devices 新的绑定设备列表。
 */
- (void)refreshWhenBindedDevieDidChange:(NSArray<MyDevice *> *)devices
{
    KDSUserManager *userMgr = [KDSUserManager sharedManager];
    //先记录当前显示的页面设备及索引。
    NSInteger index = self.scrollView.contentOffset.x / self.scrollView.bounds.size.width + 0.5;
    MyDevice *currentDevice = self.devicesArr.count > index ? [self.devicesArr objectAtIndex:index] : nil;
    [self.devicesArr removeAllObjects];
    [self.devicesArr addObjectsFromArray:devices];
    for (KDSLockInfoVC *vc in self.childViewControllers)
    {
        if (![self.devicesArr containsObject:vc.lock.device])
        {
            [userMgr.locks removeObject:vc.lock];
            [vc.view removeFromSuperview];
            [vc removeFromParentViewController];
        }
    }
    for (MyDevice *device in self.devicesArr)
    {
        NSUInteger index = [self.devicesArr indexOfObject:device];
        KDSLockInfoVC *vc = [self lockInfoVCForDevice:device];
        if (!vc)
        {
            vc = [[KDSLockInfoVC alloc] init];
            KDSLock *lock = [[KDSLock alloc] init];
            lock.device = device;
            [userMgr.locks addObject:lock];
            vc.lock = lock;
            __weak typeof(self) weakSelf = self;
            vc.pulldownRefreshBlock = ^{
                [weakSelf getBindedDeviceList];
                [weakSelf syncChildViewControllersViewRefreshState:MJRefreshStateRefreshing];
            };
            [self addChildViewController:vc];
            [self.scrollView addSubview:vc.view];
        }
        else
        {
            userMgr.locks[index].device = device;
        }
        CGRect frame = self.scrollView.bounds;
        frame.origin.x = index * self.scrollView.bounds.size.width;
        vc.view.frame = frame;
    }
    self.scrollView.contentSize = CGSizeMake(self.devicesArr.count * kScreenWidth, self.scrollView.bounds.size.height);
    //如果更新设备列表前显示的设备还在，那么当前页面继续显示该设备，否则显示之前的索引页或者最后一个设备页。
    NSInteger newIndex = index;
    if ([self.devicesArr containsObject:currentDevice])
    {
        newIndex = [self.devicesArr indexOfObject:currentDevice];
    }
    else
    {
        newIndex = index >= self.devicesArr.count ? self.devicesArr.count - 1 : index;
        newIndex = self.devicesArr.count == 0 ? 0 : newIndex;
    }
    self.scrollView.contentOffset = CGPointMake(self.scrollView.bounds.size.width * index, 0);
    self.lineView.hidden = self.devicesArr.count == 0;
    self.noDeviceBtn.hidden = self.devicesArr.count != 0;
    self.recordDetailsBtn.hidden = self.devicesArr.count == 0;
    self.nicknameView.devices = self.devicesArr;
    self.naviView.hidden = self.devicesArr.count == 0;
    //如果新旧的偏移相同就不做偏移操作了。
    if (newIndex != index)
    {
        self.scrollView.contentOffset = CGPointMake(kScreenWidth * newIndex, 0);
        self.nicknameView.offsetX = newIndex;
    }
}

/**
 *@abstract 根据device从已显示的设备页中找出是否包含对应的device。
 *@param device 设备。
 *@return 如果已显示的页面中包含该设备，则将该页面控制器返回，否则返回nil。
 */
- (nullable KDSLockInfoVC *)lockInfoVCForDevice:(MyDevice *)device
{
    for (KDSLockInfoVC *vc in self.childViewControllers)
    {
        if ([vc.lock.device isEqual:device]) return vc;
    }
    return nil;
}

///子控制器下拉刷新时，为保持同步，需将每个子控制的状态都设置为同一刷新中状态。
- (void)syncChildViewControllersViewRefreshState:(MJRefreshState)state
{
    //0.5秒大概比mj_header动画时间多一点，不然置空下拉刷新没效果。置空下拉刷新回调是防止循环调用。
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(state == MJRefreshStateRefreshing ? 0 : 0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __weak typeof(self) weakSelf = self;
        for (KDSLockInfoVC *vc in self.childViewControllers)
        {
            vc.pulldownRefreshBlock = state == MJRefreshStateRefreshing ? nil : ^{
                [weakSelf getBindedDeviceList];
                [weakSelf syncChildViewControllersViewRefreshState:MJRefreshStateRefreshing];
            };
        }
        
        for (KDSLockInfoVC *vc in self.childViewControllers)
        {
            vc.tableView.mj_header.state = state;
        }
    });
}

#pragma mark - 网络请求方法。
///从服务器获取账号下绑定的设备列表，并刷新界面。
- (void)getBindedDeviceList
{
    static NSURLSessionDataTask *task = nil;
    if (task)
    {
        [task cancel];
        task = nil;
    }
    MBProgressHUD *hud = nil;
    if (!_devicesArr)//首次进入转菊花。
    {
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.removeFromSuperViewOnHide = YES;
    }
    void(^errorBlock)(NSError *) = ^(NSError *error){//网络请求出错执行的回调。
        NSArray<MyDevice *> *devices = [[KDSDBManager sharedManager] queryBindedDevices];
        if (devices.count)
        {
            if (!self->_devicesArr)
            {
                for (MyDevice *device in devices)
                {
                    device.connected = NO;//首次进入的时候设备不可能已连接。
                }
            }
            [self refreshWhenBindedDevieDidChange:devices];
        }
        else
        {
            NSString *msg = error.userInfo ? error.localizedDescription : [NSString stringWithFormat:@"error, code = %ld", (long)error.code];
            [MBProgressHUD showError:msg];
        }
    };
    task = [[KDSHttpManager sharedManager] getBindedDeviceListWithUid:[KDSUserManager sharedManager].user.uid success:^(NSArray<MyDevice *> * _Nonnull devices) {
        task = nil;
        [hud hide:YES];
        [self syncChildViewControllersViewRefreshState:MJRefreshStateIdle];
        [self refreshWhenBindedDevieDidChange:devices];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [[KDSDBManager sharedManager] updateBindedDevices:devices];
        });
    } error:^(NSError * _Nonnull error) {
        task = nil;
        [hud hide:YES];
        [self syncChildViewControllersViewRefreshState:MJRefreshStateIdle];
        errorBlock(error);
    } failure:^(NSError * _Nonnull error) {
        task = nil;
        [hud hide:YES];
        [self syncChildViewControllersViewRefreshState:MJRefreshStateIdle];
        if (error.code != NSURLErrorCancelled)
        {
            errorBlock(error);
        }
    }];
}

#pragma mark - 控件等事件方法
//MARK:没有设备时，点击按钮添加设备。
- (void)clickNoDeviceBtnAddDevice:(UIButton *)sender
{
    KDSDeviceModelListTableVC *vc = [KDSDeviceModelListTableVC new];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

//MARK:点击记录详情按钮跳转查看开门、报警记录详细。
- (void)clickRecordDetailsBtnViewRecordDetails:(UIButton *)sender
{
    CGFloat offsetX = self.scrollView.contentOffset.x;
    NSUInteger index = offsetX / self.scrollView.bounds.size.width;
    if (offsetX / self.scrollView.bounds.size.width != index) return;
    KDSLockInfoVC *infoVC = self.childViewControllers[index];
//    if (!infoVC.lock.device.is_admin.boolValue)
//    {
//        [MBProgressHUD showError:Localized(@"noAuthorization")];
//        return;
//    }
    KDSRecordDetailsVC *vc = [KDSRecordDetailsVC new];
    vc.lock = infoVC.lock;
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - 通知事件
///收到更改了本地语言的通知，更新按钮文字及约束。
- (void)localeLanguageDidChange:(NSNotification *)noti
{
    NSString *title = Localized(@"unlockDetails");
    [self.recordDetailsBtn setTitle:title forState:UIControlStateNormal];
    CGSize titleSize = [title sizeWithAttributes:@{NSFontAttributeName : self.recordDetailsBtn.titleLabel.font}];
    CGSize imageSize = self.recordDetailsBtn.currentImage.size;
    self.recordDetailsBtn.imageEdgeInsets = UIEdgeInsetsMake(0, (ceil(titleSize.width) - imageSize.width) / 2, 0, 0);
    self.recordDetailsBtn.titleEdgeInsets = UIEdgeInsetsMake(imageSize.height + 6, -imageSize.width, 0, 0);
    [self.recordDetailsBtn mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(ceil(titleSize.width));
        make.height.mas_equalTo(12 + 6 + ceil(titleSize.height));
    }];
}

- (void)appDidBecomeActive:(NSNotification *)noti
{
    if ([KDSUserManager sharedManager].netWorkIsAvailable) {
        [self getBindedDeviceList];
    }

}

///设备被删除的通知。
- (void)lockHasBeenDeleted:(NSNotification *)noti
{
    KDSLock *deleted = noti.userInfo[@"lock"];
    [[KDSUserManager sharedManager].locks removeObject:deleted];
    NSMutableArray<MyDevice *> *array = [NSMutableArray array];
    for (KDSLock *lock in [KDSUserManager sharedManager].locks)
    {
        [array addObject:lock.device];
    }
    [self refreshWhenBindedDevieDidChange:array];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[KDSDBManager sharedManager] updateBindedDevices:array];
    });
}

///锁上报报警通知。
- (void)lockDidAlarm:(NSNotification *)noti
{
    CBPeripheral *p = noti.userInfo[@"peripheral"];
    NSData *data = noti.userInfo[@"data"];
    [[KDSUserManager sharedManager] addAlarmForLockWithBleName:p.advDataLocalName data:data];
}

///绑定新设备的通知。
- (void)lockHasBeenAdded:(NSNotification *)noti
{
    NSMutableArray *devices = [NSMutableArray array];
    for (KDSLock *lock in [KDSUserManager sharedManager].locks)
    {
        [devices addObject:lock.device];
    }
    [devices addObject:noti.userInfo[@"device"]];
    [self refreshWhenBindedDevieDidChange:devices];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[KDSDBManager sharedManager] updateBindedDevices:devices];
    });
    
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    self.nicknameView.offsetX = scrollView.contentOffset.x / scrollView.bounds.size.width;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat x = scrollView.contentOffset.x / scrollView.bounds.size.width;
    self.nicknameView.offsetX = x;
    if (x < self.childViewControllers.count)
    {
        KDSLockInfoVC *vc = self.childViewControllers[(int)x];
        if (!vc.lock.bleTool.connectedPeripheral)
        {
            [vc beginScanForPeripherals];
        }
    }
}

@end
