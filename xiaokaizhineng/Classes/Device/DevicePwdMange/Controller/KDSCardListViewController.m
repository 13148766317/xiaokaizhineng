//
//  KDSCardListViewController.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/18.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSCardListViewController.h"
#import "KDSPwsTongbu.h"
#import "KDSCardListTableViewCell.h"
#import "KDSCardDetailViewController.h"
#import "MBProgressHUD+MJ.h"
#import "KDSPwdListModel.h"
#import "KDSHttpManager+Ble.h"
#import "MJRefresh.h"
#import "Masonry.h"
#import "KDSAddKeyVC.h"
#import "KDSDBManager.h"

@interface KDSCardListViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UIView *lessCardView;
@property (nonatomic, strong) UITableView *tableView;
///添加卡片按钮。
@property (weak, nonatomic) IBOutlet UIButton *addCardBtn;
///自定义同步视图。
@property (nonatomic, strong) KDSPwsTongbu *syncView;
///卡片密码模型数组。
@property (nonatomic, strong) NSMutableArray<KDSPwdListModel *> *cards;
///同步锁中卡片信息时返回的凭证，用于控制器销毁时从蓝牙任务队列中移除任务。
@property (nonatomic, strong) NSString *receipt;

@end

@implementation KDSCardListViewController

- (NSMutableArray<KDSPwdListModel *> *)cards
{
    if (!_cards)
    {
        _cards = [NSMutableArray array];
    }
    return _cards;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationTitleLabel.text = Localized(@"doorCard");
    self.lessCardView.hidden = YES;
    [self addlistView];
    self.lessCardView.frame = self.tableView.bounds;
    self.lessCardView.subviews.firstObject.frame = CGRectMake((kScreenWidth - 125) / 2, 138, 116, 105);
    self.lessCardView.subviews.lastObject.frame = CGRectMake((kScreenWidth - 320) / 2, CGRectGetMaxY(self.lessCardView.subviews.firstObject.frame) + 60, 300, 60);
    self.lessCardView.backgroundColor = self.view.backgroundColor;
    for (UIButton *btn in self.lessCardView.subviews)
    {
        if ([btn isKindOfClass:UIButton.class])
        {
            [btn setTitle:Localized(@"addCard") forState:UIControlStateNormal];
            break;
        }
    }
    [self addHeadView];
    [self.view bringSubviewToFront:self.lessCardView];
    if ([self.lock.device.is_admin boolValue])
    {
        [self setRightButton];
        [self.rightButton setImage:[UIImage imageNamed:@"添加"] forState:UIControlStateNormal];
    }
    [self.addCardBtn setTitle:Localized(@"addCard") forState:UIControlStateNormal];
    __weak typeof(self) weakSelf = self;
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf getCardPwdList];
    }];
    
    NSArray *cache = [[KDSDBManager sharedManager] queryPwdAttrWithBleName:self.lock.device.device_name type:4];
    !cache ?: [self.cards addObjectsFromArray:cache];
    [self getCardPwdList];
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
    [_tableView registerNib:[UINib nibWithNibName:@"KDSCardListTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"KDSCardListTableViewCell"];
    [self.view addSubview:_tableView];
    
}

-(void)addHeadView{
    KDSPwsTongbu *tongbuHeadView = [[KDSPwsTongbu alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth - 20, 67)];
    tongbuHeadView.layer.cornerRadius = 5;
    _tableView.tableHeaderView = tongbuHeadView;
    __weak typeof(self) weakSelf = self;
    tongbuHeadView.syncBtnClickBlock = ^(UIButton * _Nonnull sender) {
        [weakSelf syncCardsOnLock:sender];
    };
    self.syncView = tongbuHeadView;
}

///刷新表视图。调用此方法前请确保已经对数据源进行了更新。
- (void)reloadData
{
    if (!self.cards.count && self.lock.device.is_admin.boolValue)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.lessCardView.hidden = NO;
            self.tableView.tableHeaderView = self.lessCardView;
            [self.tableView.tableHeaderView addSubview:self.syncView];
        });
    }
    else
    {
        self.lessCardView.hidden = YES;
        self.tableView.tableHeaderView = self.syncView;
    }
    [self.cards sortUsingComparator:^NSComparisonResult(KDSPwdListModel *_Nonnull obj1, KDSPwdListModel *_Nonnull obj2) {
        return obj1.num.intValue > obj2.num.intValue;
    }];
    [self.tableView reloadData];
}

#pragma UITableViewDelegate,UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.cards.count;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    KDSCardDetailViewController * CVC = [[KDSCardDetailViewController alloc] init];
    CVC.lock = self.lock;
    CVC.model = self.cards[indexPath.row];
    CVC.cardHasBeenDeletedBlock = ^(KDSPwdListModel * _Nonnull model) {
        [self.cards removeObject:model];
        [self reloadData];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [[KDSDBManager sharedManager] deletePwdAttr:model bleName:self.lock.device.device_name];
        });
    };
    KDSCardListTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    CVC.cardInfoDidUpdateBlock = ^(KDSPwdListModel * _Nonnull model) {
        cell.name = model.nickName;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [[KDSDBManager sharedManager] insertPwdAttr:@[model] bleName:self.lock.device.device_name];
        });
    };
    [self.navigationController pushViewController:CVC animated:YES];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    KDSCardListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"KDSCardListTableViewCell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    KDSPwdListModel *m = self.cards[indexPath.row];
    cell.number = m.num.intValue;
    cell.name = m.nickName;
    cell.hideSeparator = indexPath.row == self.cards.count - 1;
    if (self.cards.count == 1)
    {
        cell.cornerType = 3;
    }
    else
    {
        cell.cornerType = indexPath.row==0 ? 1 : (indexPath.row == self.cards.count - 1 ? 2 : 0);
    }
    return cell;
}

#pragma mark - 控件等事件方法
-(void)navRightClick{
    KDSAddKeyVC *vc = [KDSAddKeyVC new];
    vc.lock = self.lock;
    vc.keyAddSuccessBlock = ^(KDSPwdListModel * _Nonnull model) {
        [self getCardPwdList];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

///同步锁中的卡片信息。
- (void)syncCardsOnLock:(UIButton *)sender
{
    if (!self.lock.bleTool.connectedPeripheral)
    {
        [MBProgressHUD showError:Localized(@"bleNotConnect")];
        return;
    }
    if (self.receipt) return;
    [MBProgressHUD showMessage:@"正在同步"];
//    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    hud.removeFromSuperViewOnHide = YES;
    __weak typeof(self) weakSelf = self;
    self.receipt = [self.lock.bleTool getAllUsersWithKeyType:KDSBleKeyTypeRFID completion:^(KDSBleError error, NSArray<KDSBleUserType *> * _Nullable users) {
//        [hud hide:YES];
        weakSelf.receipt = nil;
        if (error == KDSBleErrorSuccess)
        {
            NSMutableArray<KDSPwdListModel *> *models = [NSMutableArray arrayWithCapacity:users.count];
            for (KDSBleUserType *user in users)
            {
                KDSPwdListModel *m = [KDSPwdListModel new];
                m.num = [NSString stringWithFormat:@"%02lu", (unsigned long)user.userId];
                m.pwdType = KDSServerKeyTpyeCard;
                [models addObject:m];
            }
            
            //先删掉锁没有但服务器却保留有的信息。
            NSMutableArray *deleted = [NSMutableArray array];
            for (KDSPwdListModel *m in weakSelf.cards)
            {
                if (![models containsObject:m])
                {
                    [deleted addObject:m];
                }
            }
            [weakSelf deleteCards:deleted];
            
            //再添加锁有服务器却没有的。
            NSMutableArray *latest = [NSMutableArray array];
            for (KDSPwdListModel *m in models)
            {
                if (![weakSelf.cards containsObject:m])
                {
                    m.createTime = NSDate.date.timeIntervalSince1970;
                    [weakSelf.cards addObject:m];
                    [latest addObject:m];
                }
            }
            [weakSelf addCards:latest];
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                for (KDSPwdListModel *model in deleted)
                {
                    [[KDSDBManager sharedManager] deletePwdAttr:model bleName:weakSelf.lock.device.device_name];
                }
                [[KDSDBManager sharedManager] insertPwdAttr:latest bleName:weakSelf.lock.device.device_name];
            });

            [weakSelf.cards sortUsingComparator:^NSComparisonResult(KDSPwdListModel * obj1, KDSPwdListModel * obj2) {
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

///点击添加卡片按钮跳转添加卡片界面。
- (IBAction)clickAddCardButtonAddCard:(UIButton *)sender
{
    [self navRightClick];
}

#pragma mark - 网络请求方法。
///获取卡片列表
- (void)getCardPwdList
{
    [[KDSHttpManager sharedManager] getBlePwdListWithUid:[KDSUserManager sharedManager].user.uid bleName:self.lock.device.device_name pwdType:KDSServerKeyTpyeCard success:^(NSArray<KDSPwdListModel *> * _Nonnull pwdlistArray) {
        
        [self.cards removeAllObjects];
        [self.cards addObjectsFromArray:pwdlistArray];
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

///添加新的卡片。
- (void)addCards:(NSArray<KDSPwdListModel *> *)models
{
    if (models.count == 0) return;
    [[KDSHttpManager sharedManager] addBlePwds:models withUid:[KDSUserManager sharedManager].user.uid bleName:self.lock.device.device_name success:nil error:nil failure:nil];
}

///删除锁中没有的卡片。
- (void)deleteCards:(NSArray<KDSPwdListModel *> *)models
{
    if (models.count == 0) return;
    [[KDSHttpManager sharedManager] deleteBlePwd:models withUid:[KDSUserManager sharedManager].user.uid bleName:self.lock.device.device_name success:^{
        NSLog(@"删除卡片成功");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUD];
            //            [MBProgressHUD showSuccess:@"操作成功"];
            [self getCardPwdList];
        });
    } error:nil failure:nil];
}

@end
