//
//  KDSFingerprintManaViewController.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/18.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSFingerprintManaViewController.h"
#import "KDSPwsTongbu.h"
#import "KDSBleBindVC.h"
#import "KDSFingerprintManaTableViewCell.h"
#import "KDSFingerprintDetailVC.h"
#import "KDSHttpManager+Ble.h"
#import "MBProgressHUD+MJ.h"
#import "KDSAddKeyVC.h"
#import "KDSDBManager.h"

@interface KDSFingerprintManaViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UIView *noFingerprintView;
@property (nonatomic, strong) UITableView *tableView;
///添加指纹按钮。
@property (weak, nonatomic) IBOutlet UIButton *addFpBtn;
///自定义同步视图。
@property (nonatomic, strong) KDSPwsTongbu *syncView;
///同步锁中卡片信息时返回的凭证，用于控制器销毁时从蓝牙任务队列中移除任务。
@property (nonatomic, strong) NSString *receipt;
@property (nonatomic, strong) NSMutableArray<KDSPwdListModel *> *listArray;
@end

@implementation KDSFingerprintManaViewController
- (NSMutableArray<KDSPwdListModel *> *)listArray
{
    if (!_listArray)
    {
        _listArray = [NSMutableArray array];
    }
    return _listArray;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationTitleLabel.text = Localized(@"fingerprintManage");
    self.noFingerprintView.hidden = YES;
    [self addlistView];
    self.noFingerprintView.frame = self.tableView.bounds;
    self.noFingerprintView.subviews.firstObject.frame = CGRectMake((kScreenWidth - 125) / 2, 138, 116, 105);
    self.noFingerprintView.subviews.lastObject.frame = CGRectMake((kScreenWidth - 320) / 2, CGRectGetMaxY(self.noFingerprintView.subviews.firstObject.frame) + 60, 300, 60);
    self.noFingerprintView.backgroundColor = self.view.backgroundColor;
    for (UIButton *btn in self.noFingerprintView.subviews)
    {
        if ([btn isKindOfClass:UIButton.class])
        {
            [btn setTitle:Localized(@"addFingerprint") forState:UIControlStateNormal];
            break;
        }
    }
    [self addHeadView];
    [self.view bringSubviewToFront:self.noFingerprintView];
    if ([self.lock.device.is_admin boolValue])
    {
        [self setRightButton];
        [self.rightButton setImage:[UIImage imageNamed:@"添加"] forState:UIControlStateNormal];
    }
    [self.addFpBtn setTitle:Localized(@"addFingerprint") forState:UIControlStateNormal];
    __weak typeof(self) weakSelf = self;
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf getFingerprintPwdList];
    }];
    
    NSArray *cache = [[KDSDBManager sharedManager] queryPwdAttrWithBleName:self.lock.device.device_name type:3];
    !cache ?: [self.listArray addObjectsFromArray:cache];
    [self getFingerprintPwdList];
}

- (void)dealloc
{
    [self.lock.bleTool cancelTaskWithReceipt:self.receipt];
}

-(void)addlistView{
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(10, 0, kScreenWidth-20, kScreenHeight - kStatusBarHeight - kNavBarHeight) style:UITableViewStylePlain];
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.rowHeight = 60;
    _tableView.tableFooterView = [[UIView alloc] init];
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.layer.cornerRadius = 5;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_tableView registerNib:[UINib nibWithNibName:@"KDSFingerprintManaTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"KDSFingerprintManaTableViewCell"];
    [self.view addSubview:_tableView];
}

-(void)addHeadView{
    KDSPwsTongbu *tongbuHeadView = [[KDSPwsTongbu alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth - 20, 67)];
    tongbuHeadView.layer.cornerRadius = 5;
    _tableView.tableHeaderView = tongbuHeadView;
    __weak typeof(self) weakSelf = self;
    tongbuHeadView.syncBtnClickBlock = ^(UIButton * _Nonnull sender) {
        [weakSelf syncFingerprintsOnLock:sender];
    };
    self.syncView = tongbuHeadView;
}

///刷新表视图。调用此方法前请确保已经对数据源进行了更新。
- (void)reloadData
{
    if (!self.listArray.count && self.lock.device.is_admin.boolValue)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.noFingerprintView.hidden = NO;
            self.tableView.tableHeaderView = self.noFingerprintView;
            [self.tableView.tableHeaderView addSubview:self.syncView];
        });
    }
    else
    {
        self.noFingerprintView.hidden = YES;
        self.tableView.tableHeaderView = self.syncView;
    }
    [self.listArray sortUsingComparator:^NSComparisonResult(KDSPwdListModel *_Nonnull obj1, KDSPwdListModel *_Nonnull obj2) {
        return obj1.num.intValue > obj2.num.intValue;
    }];
    [self.tableView reloadData];
}

#pragma UITableViewDelegate,UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.listArray.count;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    KDSFingerprintDetailVC * FVC = [[KDSFingerprintDetailVC alloc] init];
    FVC.lock = self.lock;
    FVC.model = self.listArray[indexPath.row];
    FVC.fpHasBeenDeletedBlock = ^(KDSPwdListModel * _Nonnull model) {
        [self.listArray removeObject:model];
        [self reloadData];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [[KDSDBManager sharedManager] deletePwdAttr:model bleName:self.lock.device.device_name];
        });
    };
    KDSFingerprintManaTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    FVC.fpInfoDidUpdateBlock = ^(KDSPwdListModel * _Nonnull model) {
        cell.name = model.nickName;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [[KDSDBManager sharedManager] insertPwdAttr:@[model] bleName:self.lock.device.device_name];
        });
    };
    [self.navigationController pushViewController:FVC animated:YES];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    KDSFingerprintManaTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"KDSFingerprintManaTableViewCell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    KDSPwdListModel *m = self.listArray[indexPath.row];
    cell.number = m.num.intValue;
    cell.name = m.nickName;
    cell.hideSeparator = indexPath.row == self.listArray.count - 1;
    if (self.listArray.count == 1)
    {
        cell.cornerType = 3;
    }
    else
    {
        cell.cornerType = indexPath.row==0 ? 1 : (indexPath.row == self.listArray.count - 1 ? 2 : 0);
    }
    return cell;
}

#pragma mark - 控件等事件方法。
-(void)navRightClick{
    KDSAddKeyVC *vc = [KDSAddKeyVC new];
    vc.lock = self.lock;
    vc.type = 1;
    vc.keyAddSuccessBlock = ^(KDSPwdListModel * _Nonnull model) {
        [self getFingerprintPwdList];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

///同步锁中指纹信息。
- (void)syncFingerprintsOnLock:(UIButton *)sender
{
    if (!self.lock.bleTool.connectedPeripheral)
    {
        [MBProgressHUD showError:Localized(@"bleNotConnect")];
        return;
    }
    if (self.receipt) return;
//    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    hud.removeFromSuperViewOnHide = YES;
    [MBProgressHUD showMessage:@"正在同步"];
    __weak typeof(self) weakSelf = self;
    self.receipt = [self.lock.bleTool getAllUsersWithKeyType:KDSBleKeyTypeFingerprint completion:^(KDSBleError error, NSArray<KDSBleUserType *> * _Nullable users) {
        NSLog(@"锁中存在指纹 %lu组",users.count);
//        [hud hide:YES];
        weakSelf.receipt = nil;
        if (error == KDSBleErrorSuccess)
        {
            NSMutableArray<KDSPwdListModel *> *models = [NSMutableArray arrayWithCapacity:users.count];
            for (KDSBleUserType *user in users)
            {
                KDSPwdListModel *m = [KDSPwdListModel new];
                m.num = [NSString stringWithFormat:@"%02lu", (unsigned long)user.userId];
                m.pwdType = KDSServerKeyTpyeFingerprint;
                [models addObject:m];
            }
            
            //先删掉锁没有但服务器却保留有的信息。
            NSMutableArray *deleted = [NSMutableArray array];
            for (KDSPwdListModel *m in weakSelf.listArray)
            {
                if (![models containsObject:m])
                {
                    [deleted addObject:m];
                }
            }
            [weakSelf deleteFingerprints:deleted];

            //再添加锁有服务器却没有的。
            NSMutableArray *latest = [NSMutableArray array];
            for (KDSPwdListModel *m in models)
            {
                if (![weakSelf.listArray containsObject:m])
                {
                    m.createTime = NSDate.date.timeIntervalSince1970;
                    [weakSelf.listArray addObject:m];
                    [latest addObject:m];
                }
            }
            [weakSelf addFingerprints:latest];

            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                for (KDSPwdListModel *model in deleted)
                {
                    [[KDSDBManager sharedManager] deletePwdAttr:model bleName:weakSelf.lock.device.device_name];
                }
                [[KDSDBManager sharedManager] insertPwdAttr:latest bleName:weakSelf.lock.device.device_name];

            });

            [weakSelf.listArray sortUsingComparator:^NSComparisonResult(KDSPwdListModel * obj1, KDSPwdListModel * obj2) {
                return [obj1.num compare:obj2.num];
            }];

            [weakSelf reloadData];
            [MBProgressHUD hideHUD];
            [MBProgressHUD showSuccess:@"同步完成"];
        }
        else
        {
            [MBProgressHUD showError:[NSString stringWithFormat:@"error: %ld", (long)error]];
        }
    }];
}

///点击添加指纹按钮添加指纹。
- (IBAction)clickFingerprintBtnAddFingerprint:(UIButton *)sender
{
    [self navRightClick];
}

#pragma mark - 网络请求方法。
///获取指纹列表
- (void)getFingerprintPwdList
{
    [[KDSHttpManager sharedManager] getBlePwdListWithUid:[KDSUserManager sharedManager].user.uid bleName:self.lock.device.device_name pwdType:KDSServerKeyTpyeFingerprint success:^(NSArray<KDSPwdListModel *> * _Nonnull pwdlistArray) {
        
        [self.listArray removeAllObjects];
        [self.listArray addObjectsFromArray:pwdlistArray];
        [self reloadData];
        self.tableView.mj_header.state = MJRefreshStateIdle;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [[KDSDBManager sharedManager] insertPwdAttr:pwdlistArray bleName:self.lock.device.device_name];
        });
        
    } error:^(NSError * _Nonnull error) {
        self.tableView.mj_header.state = MJRefreshStateIdle;
        [MBProgressHUD showError:[NSString stringWithFormat:@"%@: %ld", Localized(@"saveFailed"), (long)error.localizedDescription]];
    } failure:^(NSError * _Nonnull error) {
        self.tableView.mj_header.state = MJRefreshStateIdle;
        [MBProgressHUD showError:error.localizedDescription];
    }];
}

///添加新的指纹。
- (void)addFingerprints:(NSArray<KDSPwdListModel *> *)models
{
    if (models.count == 0) return;
    [[KDSHttpManager sharedManager] addBlePwds:models withUid:[KDSUserManager sharedManager].user.uid bleName:self.lock.device.device_name success:nil error:nil failure:nil];
}

///删除锁中没有的指纹。
- (void)deleteFingerprints:(NSArray<KDSPwdListModel *> *)models
{
    if (models.count == 0) return;
    [[KDSHttpManager sharedManager] deleteBlePwd:models withUid:[KDSUserManager sharedManager].user.uid bleName:self.lock.device.device_name success:^{
        NSLog(@"删除指纹成功");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUD];
            //            [MBProgressHUD showSuccess:@"操作成功"];
            [self getFingerprintPwdList];
        });
    } error:nil failure:nil];
}

@end
