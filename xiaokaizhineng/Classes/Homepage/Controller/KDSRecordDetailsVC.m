//
//  KDSRecordDetailsVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/18.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSRecordDetailsVC.h"
#import "Masonry.h"
#import "KDSHttpManager+Ble.h"
#import "KDSRecordCell.h"
#import "MJRefresh.h"
#import "MBProgressHUD+MJ.h"
#import "KDSDBManager.h"
#import "KDSRecordHeaderFooterView.h"
#import "MJRefresh.h"
#import "KDSBleOpRec.h"
#import "KDSOperationalRecord.h"

///专门测试开锁、报警记录完整性时，将此宏设置为1
#define kRecordDebug 0

@interface KDSRecordDetailsVC () <UITableViewDataSource, UITableViewDelegate>

///格式yyyy-MM-dd HH:mm:ss
@property (nonatomic, strong) NSDateFormatter *fmt;
///开锁记录按钮。
@property (nonatomic, strong) UIButton *unlockRecBtn;
///报警记录按钮。
@property (nonatomic, strong) UIButton *alarmRecBtn;
///绿色移动游标。
@property (nonatomic, strong) UIView *cursorView;
///同步门锁状态标签。
@property (nonatomic, strong) UILabel *label;
///同步记录按钮。
@property (nonatomic, strong) UIButton *syncRecBtn;
///横向滚动的滚动视图，装着开锁记录和报警记录的表视图。
@property (nonatomic, strong) UIScrollView *scrollView;
///显示开锁记录的表视图。
@property (nonatomic, strong) UITableView *unlockTableView;
///显示报警记录的表视图。
@property (nonatomic, strong) UITableView *alarmTableView;
///服务器请求回来的开锁记录数组。
@property (nonatomic, strong) NSMutableArray<News *> *unlockRecordArr;
///服务器请求回来开锁记录数组后按日期(天)提取的记录分组数组。
@property (nonatomic, strong) NSArray<NSArray<News *> *> *unlockRecordSectionArr;
///服务器请求回来的操作记录数组。
@property (nonatomic, strong) NSMutableArray<KDSOperationalRecord *> * czOperationalArr;
///服务器请求回来操作记录数组后按日期(天)提取的记录分组数组。
@property (nonatomic, strong)NSArray<NSArray<KDSOperationalRecord *> *> *czOPerationalSectionArr;
///服务器请求回来的报警记录数组。
@property (nonatomic, strong) NSMutableArray<KDSAlarmModel *> *alarmRecordArr;
///服务器请求回来报警记录数组后按日期(天)提取的记录分组数组。
@property (nonatomic, strong) NSArray<NSArray<KDSAlarmModel *> *> *alarmRecordSectionArr;
///开锁记录页数，初始化1.
@property (nonatomic, assign) int unlockIndex;
///报警记录页数，初始化1.
@property (nonatomic, assign) int alarmIndex;
///获取开锁记录时转的菊花。
@property (nonatomic, strong) UIActivityIndicatorView *unlockActivity;
///获取报警记录时转的菊花。
@property (nonatomic, strong) UIActivityIndicatorView *alarmActivity;
///点同步开锁记录时获取的蓝牙任务凭证，由于获取全部记录耗时久，因此退出控制器时要删除队列中的任务，否则任务未完成立即再进入无法查询。
@property (nonatomic, strong) NSString *uReceipt;
///点同步报警记录时获取的蓝牙任务凭证，由于获取全部记录耗时久，因此退出控制器时要删除队列中的任务，否则任务未完成立即再进入无法查询。。
@property (nonatomic, strong) NSString *aReceipt;
///报警记录映射。
@property (nonatomic, strong) NSDictionary<NSNumber *, NSString *> *alarmMaps;
///密匙列表。
@property (nonatomic, strong) NSArray<KDSPwdListModel *> *keys;

@end

@implementation KDSRecordDetailsVC

#pragma mark - getter setter
- (NSDateFormatter *)fmt
{
    if (!_fmt)
    {
        _fmt = [[NSDateFormatter alloc] init];
        _fmt.timeZone = [NSTimeZone localTimeZone];
        _fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    }
    return _fmt;
}

- (NSMutableArray<News *> *)unlockRecordArr
{
    if (!_unlockRecordArr)
    {
        _unlockRecordArr = [NSMutableArray array];
    }
    return _unlockRecordArr;
}
- (NSMutableArray<KDSOperationalRecord *> *)czOperationalArr
{
    if (!_czOperationalArr) {
        _czOperationalArr = [NSMutableArray array];
    }
    return _czOperationalArr;
}
- (NSMutableArray<KDSAlarmModel *> *)alarmRecordArr
{
    if (!_alarmRecordArr)
    {
        _alarmRecordArr = [NSMutableArray array];
    }
    return _alarmRecordArr;
}

- (UIActivityIndicatorView *)unlockActivity
{
    if (!_unlockActivity)
    {
        _unlockActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        CGPoint center = CGPointMake(kScreenWidth / 2.0, self.scrollView.bounds.size.height / 2.0);
        _unlockActivity.center = center;
        [self.scrollView addSubview:_unlockActivity];
    }
    return _unlockActivity;
}

- (UIActivityIndicatorView *)alarmActivity
{
    if (!_alarmActivity)
    {
        _alarmActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        CGPoint center = CGPointMake(kScreenWidth * 1.5, self.scrollView.bounds.size.height / 2.0);;
        _alarmActivity.center = center;
        [self.scrollView addSubview:_alarmActivity];
    }
    return _alarmActivity;
}

- (NSDictionary<NSNumber *,NSString *> *)alarmMaps
{
    if (!_alarmMaps)
    {
        _alarmMaps = @{@1:Localized(@"num1Alarm"), @2:Localized(@"num2Alarm"), @3:Localized(@"num3Alarm"), @4:Localized(@"num4Alarm"), @8:Localized(@"num8Alarm"), @16:Localized(@"num16Alarm"), @32:Localized(@"num32Alarm"), @64:Localized(@"num64Alarm")};
    }
    return _alarmMaps;
}

#pragma mark - 生命周期、界面设置相关方法。
- (void)viewDidLoad {
    [super viewDidLoad];
    self.unlockIndex = 1;
    self.alarmIndex = 1;
//    self.lock.device.model = @"T5S";
    [self setupUI];
    [self loadNewUnlockRecord];
    [self loadNewAlarmRecord];
}

- (void)dealloc
{
    [self.lock.bleTool cancelTaskWithReceipt:self.uReceipt];
    [self.lock.bleTool cancelTaskWithReceipt:self.aReceipt];
}

- (void)setupUI
{
    //导航栏位置的标题和关闭按钮。
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kStatusBarHeight + kNavBarHeight)];
    bgView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:bgView];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, kStatusBarHeight, kScreenWidth, kNavBarHeight)];
    titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = Localized(@"deviceStatus");
    [self.view addSubview:titleLabel];
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *closeImg = [UIImage imageNamed:@"loginClose"];
    [closeBtn setImage:closeImg forState:UIControlStateNormal];
    CGFloat del = 20 - ((44 - closeImg.size.width) / 2.0);
    closeBtn.frame = CGRectMake(kScreenWidth - del - 44, kStatusBarHeight, 44, 44);
    [closeBtn addTarget:self action:@selector(clickCloseBtnDismissController:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeBtn];
    //顶部功能选择按钮
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, kStatusBarHeight + kNavBarHeight, kScreenWidth, 40)];
    view.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:view];
    self.unlockRecBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    NSString * unLockRectBtnTitle;
    if ([self.lock.device.model containsString:@"T5S"] || [self.lock.device.model containsString:@"X5S"]) {
        unLockRectBtnTitle = Localized(@"OperationalRecords");
    }else{
        unLockRectBtnTitle = Localized(@"unlockRecord");
    }
    [self.unlockRecBtn setTitle:unLockRectBtnTitle forState:UIControlStateNormal];
    [self.unlockRecBtn setTitleColor:KDSRGBColor(0x14, 0x14, 0x14) forState:UIControlStateNormal];
    self.unlockRecBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.unlockRecBtn addTarget:self action:@selector(clickRecordBtnAdjustScrollViewContentOffset:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:self.unlockRecBtn];
    self.alarmRecBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.alarmRecBtn setTitle:Localized(@"alarmRecord") forState:UIControlStateNormal];
    [self.alarmRecBtn setTitleColor:KDSRGBColor(0x14, 0x14, 0x14) forState:UIControlStateNormal];
    self.alarmRecBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.alarmRecBtn addTarget:self action:@selector(clickRecordBtnAdjustScrollViewContentOffset:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:self.alarmRecBtn];
    CGSize unlockSize = [self.unlockRecBtn.currentTitle sizeWithAttributes:@{NSFontAttributeName : self.unlockRecBtn.titleLabel.font}];
    CGSize alarmSize = [self.alarmRecBtn.currentTitle sizeWithAttributes:@{NSFontAttributeName : self.alarmRecBtn.titleLabel.font}];
    [self.unlockRecBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(view);
        make.left.equalTo(view).offset((kScreenWidth - ceil(unlockSize.width) - ceil(alarmSize.width)) / 4);
        make.size.mas_equalTo(CGSizeMake(ceil(unlockSize.width), 22 + ceil(unlockSize.height)));
    }];
    [self.alarmRecBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(view);
        make.right.equalTo(view).offset(-(kScreenWidth - ceil(unlockSize.width) - ceil(alarmSize.width)) / 4);
        make.size.mas_equalTo(CGSizeMake(ceil(alarmSize.width), 22 + ceil(alarmSize.height)));
    }];
    self.cursorView = [[UIView alloc] init];
    self.cursorView.layer.cornerRadius = 1.5;
    self.cursorView.backgroundColor = KDSRGBColor(0x2d, 0xd9, 0xba);
    [view addSubview:self.cursorView];
    [self.cursorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.unlockRecBtn);
        make.bottom.equalTo(view);
        make.size.mas_equalTo(CGSizeMake(34, 3));
    }];
    UIView *vLineView = [[UIView alloc] init];
    vLineView.backgroundColor = KDSRGBColor(245, 245, 245);
    [view addSubview:vLineView];
    [vLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(view).offset(4);
        make.centerX.equalTo(view);
        make.width.mas_equalTo(1);
        make.bottom.equalTo(view).offset(-9);
    }];
    //中间同步功能视图
    UIView *cornerView = [[UIView alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(view.frame) + 10, kScreenWidth - 20, 48)];
    cornerView.layer.cornerRadius = 3;
    cornerView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:cornerView];
    self.label = [[UILabel alloc] init];
    self.label.textColor = KDSRGBColor(0x89, 0x89, 0x89);
    self.label.font = [UIFont systemFontOfSize:14];
    self.label.text = Localized(@"bleSyncLockStatus");
    [cornerView addSubview:self.label];
    self.syncRecBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.syncRecBtn setTitle:Localized(@"syncRecord") forState:UIControlStateNormal];
    [self.syncRecBtn setTitleColor:KDSRGBColor(0x2d, 0xd9, 0xba) forState:UIControlStateNormal];
    self.syncRecBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    self.syncRecBtn.layer.cornerRadius = 3;
    self.syncRecBtn.layer.borderColor = KDSRGBColor(0x2d, 0xd9, 0xba).CGColor;
    self.syncRecBtn.layer.borderWidth = 1;
    self.syncRecBtn.exclusiveTouch = YES;
    [self.syncRecBtn addTarget:self action:@selector(clickSyncRecBtnSyncUnlockOrAlarmRecord:) forControlEvents:UIControlEventTouchUpInside];
    [cornerView addSubview:self.syncRecBtn];
    [self.label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(cornerView);
        make.left.equalTo(cornerView).offset(10);
        make.right.equalTo(self.syncRecBtn.mas_left).offset(-10);
    }];
    [self.syncRecBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(cornerView);
        make.right.equalTo(cornerView).offset(-10);
        make.width.mas_equalTo(ceil([self.syncRecBtn.currentTitle sizeWithAttributes:@{NSFontAttributeName : self.syncRecBtn.titleLabel.font}].width) + 12);
        make.height.mas_equalTo(30);
    }];
    
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.delegate = self;
    self.scrollView.bounces = NO;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(cornerView.mas_bottom);
        make.left.bottom.right.equalTo(self.view);
    }];
    
    self.unlockTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.unlockTableView.showsVerticalScrollIndicator = NO;
    self.unlockTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.unlockTableView.tableFooterView = [UIView new];
    self.unlockTableView.dataSource = self;
    self.unlockTableView.delegate = self;
    self.unlockTableView.backgroundColor = self.view.backgroundColor;
    self.unlockTableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewUnlockRecord)];
    self.unlockTableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreUnlockRecord)];
    [self.scrollView addSubview:self.unlockTableView];
    
    self.alarmTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.alarmTableView.showsVerticalScrollIndicator = NO;
    self.alarmTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.alarmTableView.tableFooterView = [UIView new];
    self.alarmTableView.dataSource = self;
    self.alarmTableView.delegate = self;
    self.alarmTableView.backgroundColor = self.view.backgroundColor;
    self.alarmTableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewAlarmRecord)];
    self.alarmTableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreAlarmRecord)];
    [self.scrollView addSubview:self.alarmTableView];
    
    self.unlockTableView.rowHeight = self.alarmTableView.rowHeight = 60;
    self.unlockTableView.sectionHeaderHeight = self.alarmTableView.sectionHeaderHeight = 32;
    self.unlockTableView.backgroundColor = self.alarmTableView.backgroundColor = UIColor.clearColor;
}

- (void)viewDidLayoutSubviews
{
    if (CGRectIsEmpty(self.unlockTableView.frame))
    {
        self.scrollView.contentSize = CGSizeMake(kScreenWidth * 2, self.scrollView.bounds.size.height);
        CGRect frame = self.scrollView.bounds;
        frame.origin.x += 10;
        frame.size.width -= 20;
        self.unlockTableView.frame = frame;
        frame.origin.x += kScreenWidth;
        self.alarmTableView.frame = frame;
    }
}

/**
 *@abstract 刷新表视图，调用此方法前请确保开锁或者报警记录的属性数组内容已经更新。方法执行时会自动提取分组记录。
 *@param tableView 要刷新的表视图。
 */
- (void)reloadTableView:(UITableView *)tableView
{
    if (tableView == self.unlockTableView)
    {
        if ([self.lock.device.model containsString:@"T5S"] || [self.lock.device.model containsString:@"X5S"]) {
            
            NSMutableArray *sections = [NSMutableArray array];
            NSMutableArray<KDSOperationalRecord *> *section = [NSMutableArray array];
            __block NSString *date = nil;
            [self.czOperationalArr sortUsingComparator:^NSComparisonResult(KDSOperationalRecord *  _Nonnull obj1, KDSOperationalRecord *  _Nonnull obj2) {
                return [obj2.open_time compare:obj1.open_time];
            }];
            [self.czOperationalArr enumerateObjectsUsingBlock:^(KDSOperationalRecord * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (!date)
                {
                    date = [obj.open_time componentsSeparatedByString:@" "].firstObject;
                    [section addObject:obj];
                }
                else if ([date isEqualToString:[obj.open_time componentsSeparatedByString:@" "].firstObject])
                {
                    [section addObject:obj];
                }
                else
                {
                    [sections addObject:[NSArray arrayWithArray:section]];
                    [section removeAllObjects];
                    date = [obj.open_time componentsSeparatedByString:@" "].firstObject;
                    [section addObject:obj];
                }
            }];
            [sections addObject:[NSArray arrayWithArray:section]];
            self.czOPerationalSectionArr = [NSArray arrayWithArray:sections];
            [self.unlockTableView reloadData];
        }else{
            
            NSMutableArray *sections = [NSMutableArray array];
            NSMutableArray<News *> *section = [NSMutableArray array];
            __block NSString *date = nil;
            [self.unlockRecordArr sortUsingComparator:^NSComparisonResult(News *  _Nonnull obj1, News *  _Nonnull obj2) {
                return [obj2.open_time compare:obj1.open_time];
            }];
            [self.unlockRecordArr enumerateObjectsUsingBlock:^(News * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (!date)
                {
                    date = [obj.open_time componentsSeparatedByString:@" "].firstObject;
                    [section addObject:obj];
                }
                else if ([date isEqualToString:[obj.open_time componentsSeparatedByString:@" "].firstObject])
                {
                    [section addObject:obj];
                }
                else
                {
                    [sections addObject:[NSArray arrayWithArray:section]];
                    [section removeAllObjects];
                    date = [obj.open_time componentsSeparatedByString:@" "].firstObject;
                    [section addObject:obj];
                }
            }];
            [sections addObject:[NSArray arrayWithArray:section]];
            self.unlockRecordSectionArr = [NSArray arrayWithArray:sections];
            [self.unlockTableView reloadData];
        }
    }
    else
    {
        NSMutableArray *sections = [NSMutableArray array];
        NSMutableArray<KDSAlarmModel *> *section = [NSMutableArray array];
        __block NSString *date = nil;
        [self.alarmRecordArr sortUsingComparator:^NSComparisonResult(KDSAlarmModel *  _Nonnull obj1, KDSAlarmModel *  _Nonnull obj2) {
            return obj2.warningTime < obj1.warningTime ? NSOrderedAscending : NSOrderedDescending;
        }];
        [self.alarmRecordArr enumerateObjectsUsingBlock:^(KDSAlarmModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!date)
            {
                date = [obj.date componentsSeparatedByString:@" "].firstObject;
                [section addObject:obj];
            }
            else if ([date isEqualToString:[obj.date componentsSeparatedByString:@" "].firstObject])
            {
                [section addObject:obj];
            }
            else
            {
                [sections addObject:[NSArray arrayWithArray:section]];
                [section removeAllObjects];
                date = [obj.date componentsSeparatedByString:@" "].firstObject;
                [section addObject:obj];
            }
        }];
        [sections addObject:[NSArray arrayWithArray:section]];
        self.alarmRecordSectionArr = [NSArray arrayWithArray:sections];
        [self.alarmTableView reloadData];
    }
}

#pragma mark - 控件等事件方法。
///点击开锁记录、预警信息按钮调整滚动视图的偏移，切换页面。
- (void)clickRecordBtnAdjustScrollViewContentOffset:(UIButton *)sender
{
    [UIView animateWithDuration:0.3 animations:^{
        self.cursorView.center = CGPointMake(sender.center.x, self.cursorView.center.y);
        self.scrollView.contentOffset = CGPointMake(sender == self.unlockRecBtn ? 0 : kScreenWidth, 0);
    }];
}

/**
 *@abstract 点击同步记录按钮同步开锁或报警记录。
 *@param sender button.
 */

//MARK:点击同步记录按钮同步开锁或报警记录
- (void)clickSyncRecBtnSyncUnlockOrAlarmRecord:(UIButton *)sender
{
    if (!self.lock.bleTool.connectedPeripheral)
    {
        [MBProgressHUD showError:Localized(@"bleNotConnect")];
        return;
    }
    CGFloat offsetX = self.scrollView.contentOffset.x;
    NSUInteger index = offsetX / self.scrollView.bounds.size.width;
    if (ceil(offsetX / self.scrollView.bounds.size.width) != index) return;
    //获取开锁记录，如果获取到的记录跟本地记录的最后一个记录的时间一样就停止。
    if (index == 0)
    {
#if kRecordDebug
        [self.unlockRecordArr removeAllObjects];//测试用
        [self reloadTableView:self.unlockTableView];
#endif
        if (self.uReceipt) return;
        [self updateAllUnlockRecord];
    }
    else
    {
#if kRecordDebug
        [self.alarmRecordArr removeAllObjects];//测试用
        [self reloadTableView:self.alarmTableView];
#endif
        if (self.aReceipt) return;
        [self updateAllAlarmRecord];
    }
}

/**
 *@abstract 获取锁中指定数据后的的开锁记录，然后更新最后一次更新时间后的开锁记录。
 */
- (void)updateAllUnlockRecord
{
    if ([self.lock.device.model containsString:@"T5S"] || [self.lock.device.model containsString:@"X5S"]) {
        [self updateAllCzRecord];
    }else{
        __weak typeof(self) weakSelf = self;
        KDSDBManager *manager = [KDSDBManager sharedManager];
        NSString *bleName = self.lock.device.device_name;
        NSString *data = [manager queryUploadRecordDataWithBleName:bleName type:0];
#if kRecordDebug
        data = nil;
#endif
        NSArray<KDSUnlockAttr *> *attrs = [manager queryUnlockAttrWithBleName:bleName];
        NSMutableArray<KDSBleUnlockRecord *> *total = [NSMutableArray array];
        //提取缓存的昵称词典。
        NSMutableDictionary *nicknameMap = [NSMutableDictionary dictionaryWithCapacity:attrs.count];
        for (KDSUnlockAttr *attr in attrs)
        {
            nicknameMap[[NSString stringWithFormat:@"%02d%@", attr.number, attr.unlockType]] = attr.nickname;
        }
        self.uReceipt = [self.lock.bleTool updateUnlockRecordAfterData:data completion:^(BOOL finished, KDSBleError error, NSArray<KDSBleUnlockRecord *> * _Nullable records) {
            if (!records)
            {
                [weakSelf.unlockActivity stopAnimating];
                weakSelf.uReceipt = nil;
                error != KDSBleErrorNotFound?[MBProgressHUD showError:[NSString stringWithFormat:@"error: %ld", (long)error]]:[MBProgressHUD showError:Localized(@"noRecord")];
                return;
            }
            NSInteger index = -1;
            for (KDSBleUnlockRecord *record in records)
            {
                if (data.length > 12 && [[record.hexString substringFromIndex:12] isEqualToString:[data substringFromIndex:12]] && index==-1)
                {
                    index = [records indexOfObject:record];
                    break;
                }
                if ([total containsObject:record]) continue;
                [total addObject:record];
                News *n = [[News alloc] init];
                n.open_type = record.unlockType;
                n.open_time = record.unlockDate;
                n.user_num = record.userNum;
                n.nickName = nicknameMap[[NSString stringWithFormat:@"%02d%@", n.user_num.intValue, n.open_type]];
                if (![weakSelf.unlockRecordArr containsObject:n])
                {
                    [weakSelf.unlockRecordArr addObject:n];
                }
            }
            [weakSelf reloadTableView:weakSelf.unlockTableView];
#if kRecordDebug
            weakSelf.label.text = @(weakSelf.unlockRecordArr.count).stringValue;//测试用
#endif
            if (finished/* || records.firstObject.total == records.count || index != -1*/)
            {
                [weakSelf.unlockActivity stopAnimating];
                [MBProgressHUD showSuccess:Localized(@"syncComplete")];
                weakSelf.uReceipt = nil;
                NSArray *unuploadRecords = [manager queryRecord:0 bleName:bleName];
                if (unuploadRecords.count)//最后把未上传的记录也显示一下
                {
                    for (KDSBleUnlockRecord *rec in unuploadRecords)
                    {
                        if ([total containsObject:rec]) continue;
                        [total addObject:rec];
                        News *n = [[News alloc] init];
                        n.open_type = rec.unlockType;
                        n.open_time = rec.unlockDate;
                        n.user_num = rec.userNum;
                        //n.nickName = nicknameMap[[NSString stringWithFormat:@"%02d%@", n.user_num.intValue, n.open_type]];
                        if (![weakSelf.unlockRecordArr containsObject:n])
                        {
                            [weakSelf.unlockRecordArr addObject:n];
                        }
                    }
                    [weakSelf reloadTableView:weakSelf.unlockTableView];
                }
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    if (index != -1)
                    {
                        if ([KDSUserManager sharedManager].netWorkIsAvailable) {
                            [manager updateUploadRecordData:records.firstObject.hexString withBleName:bleName type:0];
                            [weakSelf uploadUnlockRecord:[records subarrayWithRange:NSMakeRange(0, index)]];
                        }
                      
                    }
                    else if (records.firstObject.total == records.count)
                    {
                        if ([KDSUserManager sharedManager].netWorkIsAvailable) {
                            [manager updateUploadRecordData:records.firstObject.hexString withBleName:bleName type:0];
                            [weakSelf uploadUnlockRecord:records];
                        }
                       
                    }
                    else
                    {
                        if ([KDSUserManager sharedManager].netWorkIsAvailable) {
                            [weakSelf uploadUnlockRecord:records];
                        }
                    }
                });
            }
        }];
        !self.uReceipt ?: [self.unlockActivity startAnimating];
    }
 
}

/**
 *@abstract 获取锁中指定数据后的的操作记录，然后更新最后一次更新时间后的操作记录。
 */
-(void)updateAllCzRecord
{
    __weak typeof(self) weakSelf = self;
    KDSDBManager *manager = [KDSDBManager sharedManager];
    NSString *bleName = self.lock.device.device_name;
    NSString *data = [manager queryUploadRecordDataWithBleName:bleName type:0];
#if kRecordDebug
    data = nil;
#endif
    NSArray<KDSUnlockAttr *> *attrs = [manager queryUnlockAttrWithBleName:bleName];
    NSMutableArray<KDSBleOpRec *> *total = [NSMutableArray array];
    //提取缓存的昵称词典。
    NSMutableDictionary *nicknameMap = [NSMutableDictionary dictionaryWithCapacity:attrs.count];
    for (KDSUnlockAttr *attr in attrs)
    {
        nicknameMap[[NSString stringWithFormat:@"%02d%@", attr.number, attr.unlockType]] = attr.nickname;
    }
    self.uReceipt = [self.lock.bleTool getOpRecAfterData:data completion:^(BOOL finished, KDSBleError error, NSArray<KDSBleOpRec *> * _Nullable records) {
        if (!records)
        {
            [weakSelf.unlockActivity stopAnimating];
            weakSelf.uReceipt = nil;
            error != KDSBleErrorNotFound?[MBProgressHUD showError:[NSString stringWithFormat:@"error: %ld", (long)error]]:[MBProgressHUD showError:Localized(@"noRecord")];
            
            return;
        }
        NSInteger index = -1;
        for (KDSBleOpRec *record in records)
        {
            if (data.length > 12 && [[record.hexString substringFromIndex:12] isEqualToString:[data substringFromIndex:12]] && index==-1)
            {
                index = [records indexOfObject:record];
                //                break;
            }
            if ([total containsObject:record]) continue;
            [total addObject:record];
            KDSOperationalRecord * op = [[KDSOperationalRecord alloc] init];
            op.eventSource = record.eventSource;
            op.open_type = [NSString stringWithFormat:@"%d",record.eventCode];
            op.user_num = [NSString stringWithFormat:@"%d",record.userID];
            op.open_time = record.date;
            op.eventType = record.eventType;
            op.cmdType = record.cmdType;
            if (![weakSelf.czOperationalArr containsObject:op] && op.eventType != 3)
            {
                [weakSelf.czOperationalArr addObject:op];
            }
        }
        [weakSelf reloadTableView:weakSelf.unlockTableView];
        
        if (finished) {
            [weakSelf.unlockActivity stopAnimating];
            [MBProgressHUD showSuccess:Localized(@"syncComplete")];
            weakSelf.uReceipt = nil;
            NSArray *unuploadRecords = [manager queryRecord:0 bleName:bleName];
            if (unuploadRecords.count)//最后把未上传的记录也显示一下
            {
                for (KDSBleOpRec *record in records)
                {
                    if ([total containsObject:record]) continue;
                    [total addObject:record];
                    KDSOperationalRecord * op = [[KDSOperationalRecord alloc] init];
                    op.eventSource = record.eventSource;
                    op.open_type = [NSString stringWithFormat:@"%d",record.eventCode];
                    op.user_num = [NSString stringWithFormat:@"%d",record.userID];
                    op.open_time = record.date;
                    op.eventType = record.eventType;
                    op.cmdType = record.cmdType;
                    if (![weakSelf.czOperationalArr containsObject:op] && op.eventType != 3)
                    {
                        [weakSelf.czOperationalArr addObject:op];
                    }
                }
                [weakSelf reloadTableView:weakSelf.unlockTableView];
            }
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                if (index != -1)
                {
                    if ([KDSUserManager sharedManager].netWorkIsAvailable) {
                        [weakSelf uploadCzRecord:[records subarrayWithRange:NSMakeRange(0, index)]];
                    }
                }
                else if (records.firstObject.niketotal == records.count)
                {
                    if ([KDSUserManager sharedManager].netWorkIsAvailable) {
                        [weakSelf uploadCzRecord:records];
                    }
                }
                else
                {
                    if ([KDSUserManager sharedManager].netWorkIsAvailable) {
                        [weakSelf uploadCzRecord:records];
                    }
                }
            });
        }
    }];
    !self.uReceipt ?: [self.unlockActivity startAnimating];
}

/**
 *@abstract 获取锁中指定数据后的的报警记录，然后更新最后一次更新时间后的报警记录。
 */
- (void)updateAllAlarmRecord
{
    __weak typeof(self) weakSelf = self;
    KDSDBManager *manager = [KDSDBManager sharedManager];
    NSString *bleName = self.lock.device.device_name;
    NSString *data = [manager queryUploadRecordDataWithBleName:bleName type:1];
#if kRecordDebug
    data = nil;
#endif
    self.aReceipt = [self.lock.bleTool updateAlarmRecordAfterData:data completion:^(BOOL finished, KDSBleError error, NSArray<KDSBleAlarmRecord *> * _Nullable records) {
        
        if (!records)
        {
//            [weakSelf.alarmActivity stopAnimating];
//            weakSelf.aReceipt = nil;
//            [MBProgressHUD showError:[NSString stringWithFormat:@"error: %ld", (long)error]];
            [weakSelf.alarmActivity stopAnimating];
            weakSelf.aReceipt = nil;
            error != KDSBleErrorNotFound?[MBProgressHUD showError:[NSString stringWithFormat:@"error: %ld", (long)error]]:[MBProgressHUD showError:Localized(@"noRecord")];
            [weakSelf reloadTableView:weakSelf.alarmTableView];
            return;
        }
        NSInteger index = -1;
        for (KDSBleAlarmRecord *record in records)
        {
            if (data.length > 12 && [[record.hexString substringFromIndex:12] isEqualToString:[data substringFromIndex:12]] && index==-1)
            {
                index = [records indexOfObject:record];
                break;
            }
            KDSAlarmModel *m = [[KDSAlarmModel alloc] init];
            m.date = record.date;
            m.warningType = (int)record.type;
            m.devName = bleName;
            m.warningTime = [self.fmt dateFromString:record.date].timeIntervalSince1970 * 1000;
            if (![weakSelf.alarmRecordArr containsObject:m])
            {
                [weakSelf.alarmRecordArr addObject:m];
            }
        }
        [weakSelf reloadTableView:weakSelf.alarmTableView];
#if kRecordDebug
        weakSelf.label.text = @(weakSelf.alarmRecordArr.count).stringValue;//测试用
#endif
        if (finished/* || records.firstObject.total == records.count || index != -1*/)
        {
            [weakSelf.alarmActivity stopAnimating];
            [MBProgressHUD showSuccess:Localized(@"syncComplete")];
            weakSelf.aReceipt = nil;
            NSArray *unuploadRecords = [manager queryRecord:1 bleName:bleName];
            if (unuploadRecords.count)//最后把未上传的记录也显示一下
            {
                for (KDSBleAlarmRecord *rec in unuploadRecords)
                {
                    KDSAlarmModel *m = [[KDSAlarmModel alloc] init];
                    m.date = rec.date;
                    m.warningType = (int)rec.type;
                    m.devName = bleName;
                    if (![weakSelf.alarmRecordArr containsObject:m])
                    {
                        [weakSelf.alarmRecordArr addObject:m];
                    }
                }
                [weakSelf reloadTableView:weakSelf.alarmTableView];
            }
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                if (records.firstObject.total == records.count)
                {
                    if ([KDSUserManager sharedManager].netWorkIsAvailable) {
                        [manager updateUploadRecordData:records.firstObject.hexString withBleName:bleName type:1];
                        [weakSelf uploadAlarmRecord:records];
                    }
                  
                }
                else if (index != -1)
                {
                    if ([KDSUserManager sharedManager].netWorkIsAvailable) {
                        [manager updateUploadRecordData:records.firstObject.hexString withBleName:bleName type:1];
                        [weakSelf uploadAlarmRecord:[records subarrayWithRange:NSMakeRange(0, index)]];
                    }
                }
                else
                {
                    if ([KDSUserManager sharedManager].netWorkIsAvailable) {
                        [weakSelf uploadAlarmRecord:records];
                    }
                  
                }
            });
        }
    }];
    !self.aReceipt ?: [self.alarmActivity startAnimating];
}

///dismiss控制器。
- (void)clickCloseBtnDismissController:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 网络请求相关方法。
///获取第一页的开锁/操作记录。
- (void)loadNewUnlockRecord
{
#if kRecordDebug
    return;
#endif
    
    /************目前：T5S,X5S锁查询获取的是操作记录，其余锁都是开锁记录，报警记录不变*************/
    [[KDSHttpManager sharedManager] getBlePwdListWithUid:[KDSUserManager sharedManager].user.uid bleName:self.lock.device.device_name pwdType:KDSServerKeyTpyeAll success:^(NSArray<KDSPwdListModel *> * _Nonnull pwdlistArray) {
        self.keys = pwdlistArray;
        [self reloadTableView:self.unlockTableView];
    } error:nil failure:nil];
    if ([self.lock.device.model containsString:@"T5S"] || [self.lock.device.model containsString:@"X5S"]) {
        [self loadOperationalRecords];
    }else{
        [self loadNewUnLock];
    }
}
////开锁记录
-(void)loadNewUnLock
{
    
    [[KDSHttpManager sharedManager] getBindedDeviceUnlockRecordWithUid:[KDSUserManager sharedManager].user.uid bleName:self.lock.device.device_name index:1 success:^(NSArray<News *> * _Nonnull news) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        if (news.count == 0)
        {
            self.unlockTableView.mj_header.state = MJRefreshStateIdle;
            return;
        }
        [self.unlockTableView.mj_footer resetNoMoreData];
        BOOL contain = NO;
        for (News *n in news)
        {
            if ([self.unlockRecordArr containsObject:n])
            {
                contain = YES;
                break;
            }
            [self.unlockRecordArr insertObject:n atIndex:[news indexOfObject:n]];
        }
        //如果第一页的数据部分包含于之前已加载的数据，那么不要改变当前页数，将首页没有加载过的数据添加到已加载的数据后刷新。否则用首页的数据刷新页面。
        if (!contain)
        {
            self.unlockIndex = 1;
            [self.unlockRecordArr removeAllObjects];
            [self.unlockRecordArr addObjectsFromArray:news];
        }
        [self reloadTableView:self.unlockTableView];
        [self cachePwdAttrWithNews:news];
        self.unlockTableView.mj_header.state = MJRefreshStateIdle;
        
    } error:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.unlockTableView.mj_footer.state = MJRefreshStateIdle;
        self.unlockTableView.mj_header.state = MJRefreshStateIdle;
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.unlockTableView.mj_footer.state = MJRefreshStateIdle;
        self.unlockTableView.mj_header.state = MJRefreshStateIdle;
    }];
    
}
////操作记录
-(void)loadOperationalRecords
{
    [[KDSHttpManager sharedManager] getBindedDeviceOperationalRecordsWithBleName:self.lock.device.device_name index:1 success:^(NSArray<KDSOperationalRecord *> * _Nonnull news) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if (news.count == 0)
        {
            self.unlockTableView.mj_header.state = MJRefreshStateNoMoreData;
            return;
        }
        NSMutableArray * opArrs = [NSMutableArray array];
        //        [self.unlockTableView.mj_footer resetNoMoreData];
        self.unlockTableView.mj_header.state = MJRefreshStateIdle;
        BOOL contain = NO;
        for (KDSOperationalRecord * new in news) {
            if (new.eventType != 3) {///非报警记录
                [opArrs addObject:new];
            }
        }
        for (KDSOperationalRecord *n in opArrs)
        {
            if ([self.czOperationalArr containsObject:n])
            {
                contain = YES;
                break;
            }
            [self.czOperationalArr insertObject:n atIndex:[opArrs indexOfObject:n]];
        }
        //如果第一页的数据部分包含于之前已加载的数据，那么不要改变当前页数，将首页没有加载过的数据添加到已加载的数据后刷新。否则用首页的数据刷新页面。
        if (!contain)
        {
            self.unlockIndex = 1;
            [self.unlockRecordArr removeAllObjects];
            [self.unlockRecordArr addObjectsFromArray:opArrs];
        }
        [self reloadTableView:self.unlockTableView];
        //        [self cachePwdAttrWithNews:opArrs];
        self.unlockTableView.mj_header.state = MJRefreshStateIdle;
    } error:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.unlockTableView.mj_footer.state = MJRefreshStateIdle;
        self.unlockTableView.mj_header.state = MJRefreshStateIdle;
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        self.unlockTableView.mj_footer.state = MJRefreshStateIdle;
        self.unlockTableView.mj_header.state = MJRefreshStateIdle;
    }];
}

///获取第一页的报警记录。
- (void)loadNewAlarmRecord
{
#if kRecordDebug
    return;
#endif
    [[KDSHttpManager sharedManager] getBindedDeviceAlarmRecordWithDevName:self.lock.device.device_name index:1 success:^(NSArray<KDSAlarmModel *> * _Nonnull models) {
        
        if (models.count == 0)
        {
            self.alarmTableView.mj_header.state = MJRefreshStateIdle;
            return;
        }
        [self.alarmTableView.mj_footer resetNoMoreData];
        BOOL contain = NO;
        for (KDSAlarmModel *model in models)
        {
            if ([self.alarmRecordArr containsObject:model])
            {
                contain = YES;
                break;
            }
            model.date = [self.fmt stringFromDate:[NSDate dateWithTimeIntervalSince1970:model.warningTime / 1000]];
            [self.alarmRecordArr insertObject:model atIndex:[models indexOfObject:model]];
        }
        if (!contain)
        {
            self.alarmIndex = 1;
            [self.alarmRecordArr removeAllObjects];
            [self.alarmRecordArr addObjectsFromArray:models];
        }
        [self reloadTableView:self.alarmTableView];
        self.alarmTableView.mj_header.state = MJRefreshStateIdle;
        
    } error:^(NSError * _Nonnull error) {
        self.alarmTableView.mj_footer.state = MJRefreshStateIdle;
        self.alarmTableView.mj_header.state = MJRefreshStateIdle;
    } failure:^(NSError * _Nonnull error) {
        self.alarmTableView.mj_footer.state = MJRefreshStateIdle;
        self.alarmTableView.mj_header.state = MJRefreshStateIdle;
    }];
}

///上拉开锁/操作记录表视图加载新的开锁记录。
- (void)loadMoreUnlockRecord
{
#if kRecordDebug
    return;
#endif
    [[KDSHttpManager sharedManager] getBlePwdListWithUid:[KDSUserManager sharedManager].user.uid bleName:self.lock.device.device_name pwdType:KDSServerKeyTpyeAll success:^(NSArray<KDSPwdListModel *> * _Nonnull pwdlistArray) {
        self.keys = pwdlistArray;
        [self reloadTableView:self.unlockTableView];
    } error:nil failure:nil];
    if ([self.lock.device.model containsString:@"T5S"] || [self.lock.device.model containsString:@"X5S"]) {
        [self loadMoreOperationalRecords];
    }else{
        [self loadMoreUnLock];
    }
 
}
///加载新的开锁记录
-(void)loadMoreUnLock{
    [[KDSHttpManager sharedManager] getBindedDeviceUnlockRecordWithUid:[KDSUserManager sharedManager].user.uid bleName:self.lock.device.device_name index:self.unlockIndex + 1 success:^(NSArray<News *> * _Nonnull news) {
        
        if (news.count == 0)
        {
            self.unlockTableView.mj_footer.state = MJRefreshStateNoMoreData;
            return;
        }
        self.unlockTableView.mj_footer.state = MJRefreshStateIdle;
        self.unlockIndex++;
        BOOL contain = NO;
        for (News *n in news)
        {
            for (News *s in self.unlockRecordArr)
            {
                if ([s isEqual:n])
                {
                    [self.unlockRecordArr replaceObjectAtIndex:[self.unlockRecordArr indexOfObject:s] withObject:n];//更新昵称。
                    contain = YES;
                    break;
                }
                contain = NO;
            }
            contain ?: [self.unlockRecordArr addObject:n];
        }
        [self reloadTableView:self.unlockTableView];
        [self cachePwdAttrWithNews:news];
        
    } error:^(NSError * _Nonnull error) {
        self.unlockTableView.mj_footer.state = MJRefreshStateIdle;
    } failure:^(NSError * _Nonnull error) {
        self.unlockTableView.mj_footer.state = MJRefreshStateIdle;
    }];
}
///加载新的操作记录
-(void)loadMoreOperationalRecords
{
    [[KDSHttpManager sharedManager] getBindedDeviceOperationalRecordsWithBleName:self.lock.device.device_name index:self.unlockIndex + 1 success:^(NSArray<KDSOperationalRecord *> * _Nonnull news) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if (news.count == 0)
        {
            self.unlockTableView.mj_footer.state = MJRefreshStateNoMoreData;
            return;
        }
        self.unlockTableView.mj_footer.state = MJRefreshStateIdle;
        self.unlockIndex++;
        BOOL contain = NO;
        NSMutableArray * opArrs = [NSMutableArray array];
        for (KDSOperationalRecord * new in news) {
            if (new.eventType != 3) {
                [opArrs addObject:new];
            }
        }
        for (KDSOperationalRecord *n in opArrs)
        {
            for (KDSOperationalRecord *s in self.czOperationalArr)
            {
                if ([s isEqual:n])
                {
                    [self.czOperationalArr replaceObjectAtIndex:[self.czOperationalArr indexOfObject:s] withObject:n];//更新昵称。
                    contain = YES;
                    break;
                }
                contain = NO;
            }
            contain ?: [self.czOperationalArr addObject:n];
        }
        [self reloadTableView:self.unlockTableView];
        //        [self cachePwdAttrWithNews:opArrs];
    } error:^(NSError * _Nonnull error) {
        self.unlockTableView.mj_footer.state = MJRefreshStateIdle;
        self.unlockTableView.mj_header.state = MJRefreshStateIdle;
    } failure:^(NSError * _Nonnull error) {
        self.unlockTableView.mj_footer.state = MJRefreshStateIdle;
        self.unlockTableView.mj_header.state = MJRefreshStateIdle;
    }];
}

///上拉报警记录表视图加载新的报警记录。
- (void)loadMoreAlarmRecord
{
#if kRecordDebug
    return;
#endif
    [[KDSHttpManager sharedManager] getBindedDeviceAlarmRecordWithDevName:self.lock.device.device_name index:self.alarmIndex + 1 success:^(NSArray<KDSAlarmModel *> * _Nonnull models) {
        
        if (models.count == 0)
        {
            self.alarmTableView.mj_footer.state = MJRefreshStateNoMoreData;
            return;
        }
        self.alarmTableView.mj_footer.state = MJRefreshStateIdle;
        self.alarmIndex++;
        for (KDSAlarmModel *model in models)
        {
            if ([self.alarmRecordArr containsObject:model]) continue;
            model.date = [self.fmt stringFromDate:[NSDate dateWithTimeIntervalSince1970:model.warningTime / 1000]];
            [self.alarmRecordArr addObject:model];
        }
        [self reloadTableView:self.alarmTableView];
    } error:^(NSError * _Nonnull error) {
        self.alarmTableView.mj_footer.state = MJRefreshStateIdle;
    } failure:^(NSError * _Nonnull error) {
        self.alarmTableView.mj_footer.state = MJRefreshStateIdle;
    }];
}

/**
 *@abstract 上传开锁记录到服务器。
 *@param records 要上传的开锁记录。
 */
- (void)uploadUnlockRecord:(nullable NSArray<KDSBleUnlockRecord *> *)records
{
#if kRecordDebug
    return;
#endif
    KDSDBManager *manager = [KDSDBManager sharedManager];
    NSString *bleName = self.lock.device.device_name;
    NSArray *unuploadRecords = [manager queryRecord:0 bleName:bleName];
    //总的上传记录。
    NSMutableArray *totalArr = [NSMutableArray arrayWithArray:records ?: @[]];
    for (KDSBleUnlockRecord *record in unuploadRecords)
    {
        if (![records containsObject:record])
        {
            [totalArr addObject:record];
        }
    }
    [totalArr sortUsingComparator:^NSComparisonResult(KDSBleUnlockRecord *  _Nonnull obj1, KDSBleUnlockRecord *  _Nonnull obj2) {
        return [obj2.unlockDate compare:obj1.unlockDate];
    }];
    NSString *uid = [KDSUserManager sharedManager].user.uid;
    [[KDSHttpManager sharedManager] getBlePwdListWithUid:uid bleName:bleName pwdType:KDSServerKeyTpyeAll success:^(NSArray<KDSPwdListModel *> * _Nonnull pwdlistArray) {
        NSMutableArray *news = [NSMutableArray array];
        for (KDSBleUnlockRecord *record in totalArr)
        {
            News *n = [News new];
            n.open_time = record.unlockDate;
            n.open_type = record.unlockType;
            n.user_num = record.userNum;
            if ([n.open_type isEqualToString:@"密码"])
            {
                for (KDSPwdListModel *m in pwdlistArray)
                {
                    if ((m.pwdType == KDSServerKeyTpyePIN || m.pwdType == KDSServerKeyTpyeTempPIN) && m.num.intValue == n.user_num.intValue)
                    {
                        if (m.nickName) n.nickName = m.nickName;
                        break;
                    }
                }
            }
            else if ([n.open_type isEqualToString:@"卡片"])
            {
                for (KDSPwdListModel *m in pwdlistArray)
                {
                    if (m.pwdType == KDSServerKeyTpyeCard && m.num.intValue == n.user_num.intValue)
                    {
                        if (m.nickName) n.nickName = m.nickName;
                        break;
                    }
                }
            }
            else if ([n.open_type isEqualToString:@"指纹"])
            {
                for (KDSPwdListModel *m in pwdlistArray)
                {
                    if (m.pwdType == KDSServerKeyTpyeFingerprint && m.num.intValue == n.user_num.intValue)
                    {
                        if (m.nickName) n.nickName = m.nickName;
                        break;
                    }
                }
            }
            [news addObject:n];
        }
        [[KDSHttpManager sharedManager] uploadBindedDeviceUnlockRecord:news withUid:uid device:self.lock.device success:^{
            [manager deleteRecord:0 bleName:bleName];
        } error:^(NSError * _Nonnull error) {
            [manager insertRecord:totalArr type:0 bleName:bleName];
        } failure:^(NSError * _Nonnull error) {
            [manager insertRecord:totalArr type:0 bleName:bleName];
        }];
    } error:^(NSError * _Nonnull error) {
        [manager insertRecord:totalArr type:0 bleName:bleName];
    } failure:^(NSError * _Nonnull error) {
        [manager insertRecord:totalArr type:0 bleName:bleName];
    }];
}

/**
 *@abstract 上传操作记录到服务器。
 *@param records 要上传的开锁记录。
 */
- (void)uploadCzRecord:(nullable NSArray<KDSBleOpRec *> *)records
{
#if kRecordDebug
    return;
#endif
    KDSDBManager *manager = [KDSDBManager sharedManager];
    NSString *bleName = self.lock.device.device_name;
//    NSArray *unuploadRecords = [manager queryRecord:0 bleName:bleName];
    //总的上传记录。
    NSMutableArray *totalArr = [NSMutableArray arrayWithArray:records ?: @[]];
//    for (KDSBleOpRec *record in unuploadRecords)
//    {
//        if (![records containsObject:record])
//        {
//            [totalArr addObject:record];
//        }
//    }
    [totalArr sortUsingComparator:^NSComparisonResult(KDSBleOpRec *  _Nonnull obj1, KDSBleOpRec *  _Nonnull obj2) {
        return [obj2.date compare:obj1.date];
    }];
    NSString *uid = [KDSUserManager sharedManager].user.uid;
    NSMutableArray * news = [NSMutableArray array];
    for (KDSBleOpRec * op in totalArr) {
        KDSOperationalRecord * n = [[KDSOperationalRecord alloc] init];
        n.eventSource = op.eventSource;
        n.open_type = [NSString stringWithFormat:@"%d",op.eventCode];
        n.user_num = [NSString stringWithFormat:@"%d",op.userID];
        n.open_time = op.date;
        n.eventType = op.eventType;
        n.cmdType = op.cmdType;
        if (n.eventType != 3) {
            [news addObject:n];
        }
    }
    [[KDSHttpManager sharedManager] uploadBindedDeviceOperationalRecords:news withUid:uid device:self.lock.device success:^{
        [manager deleteRecord:0 bleName:bleName];
    } error:^(NSError * _Nonnull error) {
//        [manager insertRecord:totalArr type:0 bleName:bleName];
    } failure:^(NSError * _Nonnull error) {
//        [manager insertRecord:totalArr type:0 bleName:bleName];
    }];
    
}

/**
 *@abstract 上传报警记录到服务器。
 *@param records 要上传的开锁记录。
 */
- (void)uploadAlarmRecord:(nullable NSArray<KDSBleAlarmRecord *> *)records
{
#if kRecordDebug
    return;
#endif
    KDSDBManager *manager = [KDSDBManager sharedManager];
    NSString *bleName = self.lock.device.device_name;
    NSArray *unuploadRecords = [manager queryRecord:1 bleName:bleName];
    NSMutableArray *totalArr = [NSMutableArray arrayWithArray:records ?: @[]];
    for (KDSBleAlarmRecord *record in unuploadRecords)
    {
        if (![records containsObject:record])
        {
            [totalArr addObject:record];
        }
    }
    NSMutableArray *models = [NSMutableArray array];
    for (KDSBleAlarmRecord *record in totalArr)
    {
        KDSAlarmModel *m = [KDSAlarmModel new];
        m.warningType = (int)record.type;
        m.devName = bleName;
        m.warningTime = [self.fmt dateFromString:record.date].timeIntervalSince1970 * 1000;
        [models addObject:m];
    }
    [[KDSHttpManager sharedManager] uploadBindedDeviceAlarmRecord:models success:^{
        [[KDSDBManager sharedManager] deleteRecord:1 bleName:bleName];
        [self loadNewAlarmRecord];
    } error:^(NSError * _Nonnull error) {
        [[KDSDBManager sharedManager] insertRecord:totalArr type:1 bleName:bleName];
    } failure:^(NSError * _Nonnull error) {
        [[KDSDBManager sharedManager] insertRecord:totalArr type:1 bleName:bleName];
    }];
}

///根据请求回来的开锁记录信息，提取密码属性(主要是昵称)缓存到本地，此方法在子线程异步执行。
- (void)cachePwdAttrWithNews:(NSArray<News *> *)news
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
    
        NSMutableArray<KDSUnlockAttr *> *attrs = [NSMutableArray array];
        NSMutableArray<NSNumber *> *users = [NSMutableArray array];
        for (News *n in news)
        {
            if ([users containsObject:@(n.user_num.intValue)]) continue;
            KDSUnlockAttr *attr = [KDSUnlockAttr new];
            attr.bleName = self.lock.device.device_name;
            attr.unlockType = n.open_type;
            attr.number = n.user_num.intValue;
            attr.nickname = n.nickName;
            [attrs addObject:attr];
            [users addObject:@(n.user_num.intValue)];
        }
        [[KDSDBManager sharedManager] insertUnlockAttr:attrs];
        
    });
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.scrollView)
    {
        self.cursorView.center = CGPointMake(self.unlockRecBtn.center.x + (self.alarmRecBtn.center.x - self.unlockRecBtn.center.x) * scrollView.contentOffset.x / scrollView.bounds.size.width, self.cursorView.center.y);
    }
}

#pragma mark - UITableViewDataSource, UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.unlockTableView)
    {
        if ([self.lock.device.model containsString:@"X5S"] || [self.lock.device.model containsString:@"T5S"]){
            return self.czOPerationalSectionArr.count;
        }else{
            return self.unlockRecordSectionArr.count;
        }
        
    }
    else
    {
        return self.alarmRecordSectionArr.count;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.unlockTableView)
    {
       if ([self.lock.device.model containsString:@"X5S"] || [self.lock.device.model containsString:@"T5S"]){
            return self.czOPerationalSectionArr[section].count;
        }else{
           return self.unlockRecordSectionArr[section].count;
        }
    }
    else
    {
        return self.alarmRecordSectionArr[section].count;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *reuseId = [NSStringFromClass([self class]) stringByAppendingString:@"headerFooterReuseId"];
    KDSRecordHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:reuseId];
    if (!view)
    {
        view = [[KDSRecordHeaderFooterView alloc] initWithReuseIdentifier:reuseId];
    }
    
    NSString *todayStr = [[self.fmt stringFromDate:[NSDate date]] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    NSInteger today = [todayStr substringToIndex:8].integerValue;
    NSString *dateStr = nil;
    if (tableView == self.unlockTableView)
    {
        if ([self.lock.device.model containsString:@"X5S"] || [self.lock.device.model containsString:@"T5S"]) {
            dateStr = self.czOPerationalSectionArr[section].firstObject.open_time;
        }else{
            dateStr = self.unlockRecordSectionArr[section].firstObject.open_time;
        }
    }
    else
    {
        dateStr = self.alarmRecordSectionArr[section].firstObject.date;
    }
    NSInteger date = [[dateStr stringByReplacingOccurrencesOfString:@"-" withString:@""] substringToIndex:8].integerValue;
    if (today == date)
    {
        view.title = Localized(@"today");
    }
    else if (today - date == 1)
    {
        view.title = Localized(@"yesterday");
    }
    else
    {
        view.title = [[dateStr componentsSeparatedByString:@" "].firstObject stringByReplacingOccurrencesOfString:@"-" withString:@"/"];
    }
    
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseId = NSStringFromClass([self class]);
    KDSRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if (!cell)
    {
        cell = [[KDSRecordCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
    }
    if (tableView == self.unlockTableView)
    {
        if ([self.lock.device.model containsString:@"T5S"] || [self.lock.device.model containsString:@"X5S"]) {
            ///开门记录
            cell.type = 0;
            KDSOperationalRecord *n = self.czOPerationalSectionArr[indexPath.section][indexPath.row];
            cell.date = n.open_time;
            if (n.eventType == 1) {
                cell.recType = [n.user_num isEqualToString:@"103"] ? Localized(@"appUnlock") : Localized(n.open_type);
                if (cell.recType.intValue == 2) {
                    cell.recType = [self unlockTypeWithEvent:n.eventSource];
                }
                if (n.user_num.intValue == 103)
                {
                    cell.nickname = @"APP";
                }
                else if (n.eventSource == 2)
                {
                    cell.nickname = Localized(@"machineKey");
                }
                else if (n.eventSource == 0)
                {
                    NSString *nn = n.nickName;
                    for (KDSPwdListModel *m in self.keys)
                    {
                        if ((m.pwdType == KDSServerKeyTpyePIN || m.pwdType == KDSServerKeyTpyeTempPIN) && m.num.intValue == n.user_num.intValue)
                        {
                            if (m.nickName && !nn) nn = m.nickName;
                            break;
                        }
                    }
                    cell.nickname = nn ?: [NSString stringWithFormat:@"%02d", n.user_num.intValue];
                }
                else if (n.eventSource == 3)
                {
                    NSString *nn = n.nickName;
                    for (KDSPwdListModel *m in self.keys)
                    {
                        if (m.pwdType == KDSServerKeyTpyeCard && m.num.intValue == n.user_num.intValue)
                        {
                            if (m.nickName && !nn) nn = m.nickName;
                            break;
                        }
                    }
                    cell.nickname = nn ?: [NSString stringWithFormat:@"%02d", n.user_num.intValue];
                }
                else if (n.eventSource == 4)
                {
                    NSString *nn = n.nickName;
                    for (KDSPwdListModel *m in self.keys)
                    {
                        if (m.pwdType == KDSServerKeyTpyeFingerprint && m.num.intValue == n.user_num.intValue)
                        {
                            if (m.nickName && !nn) nn = m.nickName;
                            break;
                        }
                    }
                    cell.nickname = nn ?: [NSString stringWithFormat:@"%02d", n.user_num.intValue];
                }
                else
                {
                    cell.nickname = [NSString stringWithFormat:@"%02d", n.user_num.intValue];
                }
                
            }else{
                NSString * recTypeStr = [self recTypeByOpreType:n.open_type.intValue uid:n.user_num.intValue];
                cell.recType = recTypeStr;
                NSString * nickName = [self nickNameByOpreVehicle:n.open_type.intValue];
                cell.nickname = nickName;
            }
            cell.hideSeparator = indexPath.row == self.czOPerationalSectionArr[indexPath.section].count - 1;
            if (self.czOPerationalSectionArr[indexPath.section].count == 1)
            {
                cell.cornerType = 3;
            }
            else
            {
                cell.cornerType = indexPath.row==0 ? 1 : (cell.hideSeparator ? 2 : 0);
            }
        }else{
            cell.type = 0;
            News *n = self.unlockRecordSectionArr[indexPath.section][indexPath.row];
            cell.date = n.open_time;
            cell.recType = [n.user_num isEqualToString:@"103"] ? Localized(@"appUnlock") : Localized(n.open_type);
            //NSDictionary *map = @{@"密码":Localized(@"password"), @"遥控":Localized(@"remoteControl"), @"手动":Localized(@"machineKey"), @"卡片":Localized(@"card"), @"指纹":Localized(@"fingerprint"), @"语音":Localized(@"voice"), @"静脉":Localized(@"fingerVein"), @"人脸":Localized(@"face")};
            if (n.user_num.intValue == 103)
            {
                cell.nickname = @"APP";
            }
            else if ([n.open_type isEqualToString:@"手动"])
            {
                cell.nickname = Localized(@"machineKey");
            }
            else if ([n.open_type isEqualToString:@"密码"])
            {
                NSString *nn = n.nickName;
                for (KDSPwdListModel *m in self.keys)
                {
                    if ((m.pwdType == KDSServerKeyTpyePIN || m.pwdType == KDSServerKeyTpyeTempPIN) && m.num.intValue == n.user_num.intValue)
                    {
                        if (m.nickName && !nn) nn = m.nickName;
                        break;
                    }
                }
                cell.nickname = nn ?: [NSString stringWithFormat:@"%02d", n.user_num.intValue];
            }
            else if ([n.open_type isEqualToString:@"卡片"])
            {
                NSString *nn = n.nickName;
                for (KDSPwdListModel *m in self.keys)
                {
                    if (m.pwdType == KDSServerKeyTpyeCard && m.num.intValue == n.user_num.intValue)
                    {
                        if (m.nickName && !nn) nn = m.nickName;
                        break;
                    }
                }
                cell.nickname = nn ?: [NSString stringWithFormat:@"%02d", n.user_num.intValue];
            }
            else if ([n.open_type isEqualToString:@"指纹"])
            {
                NSString *nn = n.nickName;
                for (KDSPwdListModel *m in self.keys)
                {
                    if (m.pwdType == KDSServerKeyTpyeFingerprint && m.num.intValue == n.user_num.intValue)
                    {
                        if (m.nickName && !nn) nn = m.nickName;
                        break;
                    }
                }
                cell.nickname = nn ?: [NSString stringWithFormat:@"%02d", n.user_num.intValue];
            }
            else
            {
                cell.nickname = [NSString stringWithFormat:@"%02d", n.user_num.intValue];
            }
            
            cell.hideSeparator = indexPath.row == self.unlockRecordSectionArr[indexPath.section].count - 1;
            if (self.unlockRecordSectionArr[indexPath.section].count == 1)
            {
                cell.cornerType = 3;
            }
            else
            {
                cell.cornerType = indexPath.row==0 ? 1 : (cell.hideSeparator ? 2 : 0);
            }
        }
      
    }
    else
    {
        KDSAlarmModel *m = self.alarmRecordSectionArr[indexPath.section][indexPath.row];
        cell.date = m.date;
        cell.type = 1;
        
        cell.recType = self.alarmMaps[@(m.warningType)];
        cell.hideSeparator = indexPath.row == self.alarmRecordSectionArr[indexPath.section].count - 1;
        if (self.alarmRecordSectionArr[indexPath.section].count == 1)
        {
            cell.cornerType = 3;
        }
        else
        {
            cell.cornerType = indexPath.row==0 ? 1 : (cell.hideSeparator ? 2 : 0);
        }
    }
    return cell;
}

-(NSString *)recTypeByOpreType:(int)type uid:(int)uid
{
    
    __block NSString * str = nil;
    switch (type) {
        case 1:
            str = @"修改管理员密码";
            break;
        case 2:
        {
            if (uid>=0 && uid <= 4) {
                str = @"添加永久密码";
            }else if (uid == 9){
                str = @"添加胁迫密码";
            }else{
                str = @"添加临时密码";
            }
        }
            break;
        case 3:
        {
            if (uid >= 0 && uid <= 4) {
                str = @"删除永久密码";
            }else if (uid == 9){
                str = @"删除胁迫密码";
            }else if (uid >= 5 && uid <= 8){
                str = @"删除临时密码";
            }else{
                str = @"删除全部密码";
            }
        }
            
            break;
        case 4:
            str = @"修改密码";
            break;
        case 5:
            str = @"添加门卡";
            break;
        case 6:
            str = @"删除门卡";
            break;
        case 7:
            str = @"添加指纹";
            break;
        case 8:
            str = @"删除指纹";
            break;
        case 15:
            str = @"恢复出厂设置";
            break;
        default:
            break;
    }
    return str;
}
-(NSString *)unlockTypeWithEvent:(int)eventSource
{
    __block NSString * unlockTypeStr = nil;
    switch (eventSource) {
        case 0:
            unlockTypeStr = @"密码开锁";
            break;
        case 1:
            unlockTypeStr = @"遥控开锁";
            break;
        case 2:
            unlockTypeStr = @"手动开锁";
            break;
        case 3:
            unlockTypeStr = @"门卡开锁";
            break;
        case 4:
            unlockTypeStr = @"指纹开锁";
            break;
        case 5:
            unlockTypeStr = @"语音开锁";
            break;
        case 6:
            unlockTypeStr = @"指静脉开锁";
            break;
        case 7:
            unlockTypeStr = @"人脸识别开锁";
            break;
        case 8:
            unlockTypeStr = @"手机开锁";
            break;
        default:
            break;
    }
    return unlockTypeStr;
}

-(NSString *)nickNameByOpreVehicle:(int)vehicle
{
    __block NSString * nickName = nil;
    switch (vehicle) {
        case 1:
            nickName = @"修改管理员密码";
            break;
        case 2:
            nickName = @"添加密码";
            break;
        case 3:
            nickName = @"删除密码";
            break;
        case 4:
            nickName = @"修改密码";
            break;
        case 5:
            nickName = @"添加门卡";
            break;
        case 6:
            nickName = @"删除门卡";
            break;
        case 7:
            nickName = @"添加指纹";
            break;
        case 8:
            nickName = @"删除指纹";
            break;
        case 15:
            nickName = @"恢复出厂设置";
            break;
        default:
            break;
    }
    return nickName;
}

@end
