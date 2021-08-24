//
//  KDSPwdListViewController.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/11.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSPwdListViewController.h"
#import "KDSPwsTongbu.h"
#import "KDSPwdListTableViewCell.h"
#import "KDSPwdEditViewController.h"
#import "KDSAddPwdViewController.h"
#import "KDSHttpManager+Ble.h"
#import "MBProgressHUD+MJ.h"
#import "KDSAddPwdSuccesVC.h"
#import "MJRefresh.h"
#import "KDSDBManager.h"

@interface KDSPwdListViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UIView *pwdLessView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<KDSPwdListModel *> *listArray;
///管理密钥错误对应的字典，键是错误码，值是错误信息。
@property (nonatomic, readonly) NSDictionary<NSNumber *, NSString *> *errorMsgDict;
///添加密码按钮
@property (weak, nonatomic) IBOutlet UIButton *addPWBtn;
@property (nonatomic, strong)NSMutableArray *addArray;
///自定义同步视图。
@property (nonatomic, strong) KDSPwsTongbu *syncView;@end

@implementation KDSPwdListViewController
- (NSMutableArray<KDSPwdListModel *> *)listArray
{
    if (!_listArray)
    {
        _listArray = [NSMutableArray array];
    }
    return _listArray;
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    [self loadfromServeceForDevUserList];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationTitleLabel.text = Localized(@"password");
    self.pwdLessView.hidden = YES;
    [self addlistView];
    [self addHeadView];
    [self setRightButton];
    [self.view bringSubviewToFront:self.pwdLessView];
    [self.rightButton setImage:[UIImage imageNamed:@"添加"] forState:UIControlStateNormal];
    self.pwdLessView.backgroundColor = self.view.backgroundColor;
    self.pwdLessView.frame = self.tableView.bounds;
    self.pwdLessView.subviews.firstObject.frame = CGRectMake((kScreenWidth - 125) / 2, 138, 116, 105);
    self.pwdLessView.subviews.lastObject.frame = CGRectMake((kScreenWidth - 320) / 2, CGRectGetMaxY(self.pwdLessView.subviews.firstObject.frame) + 60, 300, 60);
    [self.addPWBtn setTitle:Localized(@"AddaPassword") forState:UIControlStateNormal];
    if ([self.lock.device.is_admin boolValue])
    {
        [self setRightButton];
        [self.rightButton setImage:[UIImage imageNamed:@"添加"] forState:UIControlStateNormal];
    }
}
//- (void)dealloc
//{
//    [self.lock.bleTool cancelTaskWithReceipt:self.receipt];
//}
-(void)addlistView{
    __weak typeof(self) weakSelf = self;
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(10, 0, kScreenWidth-20, kScreenHeight - kStatusBarHeight - kNavBarHeight) style:UITableViewStylePlain];
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.rowHeight = 60;
    _tableView.tableFooterView = [[UIView alloc] init];
    _tableView.layer.cornerRadius = 5;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_tableView registerNib:[UINib nibWithNibName:@"KDSPwdListTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"KDSPwdListTableViewCell"];
    _tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf loadfromServeceForDevUserList];
    }];
    [self.view addSubview:_tableView];
}

///添加密码
- (IBAction)clickAddPwd:(id)sender {
    KDSAddPwdViewController * AVC = [[KDSAddPwdViewController alloc] init];
    AVC.lock = self.lock;
    [self.navigationController pushViewController:AVC animated:YES];
}

-(void)addHeadView{
    KDSPwsTongbu *tongbuHeadView = [[KDSPwsTongbu alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth- 20, 67)];
    _tableView.tableHeaderView = tongbuHeadView;
    __weak typeof(self) weakSelf = self;
    tongbuHeadView.syncBtnClickBlock = ^(UIButton * _Nonnull sender) {
        [weakSelf getAllUsersFromeLock];
    };
    tongbuHeadView.titleLab.text = Localized(@"PWDSynchronize");
    tongbuHeadView.layer.cornerRadius = 5;
    self.syncView = tongbuHeadView;
}
///刷新表视图。调用此方法前请确保已经对数据源进行了更新。
- (void)reloadData
{
    if (!self.listArray.count && self.lock.device.is_admin.boolValue)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.pwdLessView.hidden = NO;
            self.tableView.tableHeaderView = self.pwdLessView;
            [self.tableView.tableHeaderView addSubview:self.syncView];
        });
    }
    else
    {
        self.pwdLessView.hidden = YES;
        self.tableView.tableHeaderView = self.syncView;
    }
    [self.tableView reloadData];
}
#pragma UITableViewDelegate,UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.listArray.count;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    KDSPwdListTableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    KDSPwdEditViewController * EVC = [[KDSPwdEditViewController alloc] init];
    EVC.schedulStr = cell.timeLab.text;
    EVC.pwdModel = self.listArray[indexPath.row];
    
    EVC.lock = self.lock;
    [self.navigationController pushViewController:EVC animated:YES];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    KDSPwdListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"KDSPwdListTableViewCell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell setValueWithPwdListModel:[self.listArray objectAtIndex:indexPath.row]];
    return cell;
}

-(void)navRightClick{
    KDSAddPwdViewController * AVC = [[KDSAddPwdViewController alloc] init];
    AVC.lock = self.lock;
    [self.navigationController pushViewController:AVC animated:YES];
}
#pragma mark 从网络加载用户列表
-(void)loadfromServeceForDevUserList{
    KDSLog(@"从网络加载用户列表");
    [[KDSHttpManager sharedManager] getBlePwdListWithUid:[KDSUserManager sharedManager].user.uid bleName:self.lock.device.device_name pwdType:(KDSServerKeyTpye)KDSServerKeyTpyePIN success:^(NSArray<KDSPwdListModel *> * _Nonnull pwdlistArray) {
        self.tableView.mj_header.state = MJRefreshStateIdle;
        [self.listArray removeAllObjects];
        for (KDSPwdListModel*pwdListModel in pwdlistArray) {
//            if (pwdListModel.nickName.length) {//除掉没有昵称的数据
                pwdListModel.pwdType = KDSServerKeyTpyePIN;
                [self.listArray addObject:pwdListModel];
//            }
        }
        // 排序key, 某个对象的属性名称，是否升序, YES-升序, NO-降序
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"num" ascending:YES];
        // 排序结果
        self.lock.existPwdArray = [self.listArray sortedArrayUsingDescriptors:[NSMutableArray arrayWithObject:sortDescriptor]];
        self.listArray = [[NSMutableArray alloc] initWithArray:self.lock.existPwdArray];
        NSLog(@"密码列表为self.listArray = %@",self.listArray);
        [self reloadData];
    } error:^(NSError * _Nonnull error) {
        self.tableView.mj_header.state = MJRefreshStateIdle;
        [MBProgressHUD showError:[NSString stringWithFormat:@"%@",error.localizedDescription]];
        NSLog(@"sss");
    } failure:^(NSError * _Nonnull failure) {
        self.tableView.mj_header.state = MJRefreshStateIdle;
        [MBProgressHUD showError:[NSString stringWithFormat:@"%@",failure.localizedDescription]];
    }];
    
}
#pragma mark 添加用户到服务器
- (void)addNewUserToSeversWithUid:(nullable KDSPwdListModel*)pwdListModel{
    if (!pwdListModel) return;
    NSArray *pwdlistarray = [[NSArray alloc] initWithObjects:pwdListModel, nil];
    [[KDSHttpManager sharedManager] addNewUserToSeversWithGuest:[KDSUserManager sharedManager].user.uid bleName:self.lock.device.device_name pwdarray:pwdlistarray success:^(NSString * _Nonnull timeStr) {
        [MBProgressHUD hideHUD];
        if (self.addArray.count == 1) {
//            [MBProgressHUD showSuccess:Localized(@"同步成功")];
        }
//        [self loadfromServeceForDevUserList];
    } error:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUD];
        NSLog(@"添加失败哦2%@",error.localizedDescription);
//        [MBProgressHUD showError:[Localized(@"saveFailed") stringByAppendingString:error.localizedDescription]];
    } failure:^(NSError * _Nonnull failure) {
        [MBProgressHUD hideHUD];
//        NSLog(@"添加失败哦2%@",failure.localizedDescription);
//        [MBProgressHUD showError:[Localized(@"saveFailed") stringByAppendingString:failure.localizedDescription]];
    }];
}
- (IBAction)tongbuClick:(id)sender {
    [self getAllUsersFromeLock];
}

#pragma mark 从锁中同步用户密码
-(void)getAllUsersFromeLock{
    [MBProgressHUD showMessage:@"正在同步"];
    __weak typeof(self) weakSelf = self;
    [self.lock.bleTool getAllUsersWithKeyType:KDSBleKeyTypePIN completion:^(KDSBleError error, NSArray<KDSBleUserType *> * _Nullable users) {
        NSLog(@"锁中存在普通密码 %lu组",users.count);
        if (error == KDSBleErrorSuccess /*&& users.count*/)
        {
            NSMutableArray<KDSPwdListModel *> *models = [NSMutableArray arrayWithCapacity:users.count];
            for (KDSBleUserType *user in users)
            {
                if (user.userId > 4) continue;
                KDSPwdListModel *m = [KDSPwdListModel new];
                m.nickName = m.num = [NSString stringWithFormat:@"%02lu", (unsigned long)user.userId];
                m.pwdType = KDSServerKeyTpyePIN;
                [models addObject:m];
            }
            
            //删掉锁没有但服务器却保留有的信息。
            NSMutableArray *deleted = [NSMutableArray array];
            for (KDSPwdListModel *m in weakSelf.listArray)
            {
                if (![models containsObject:m])
                {
                    [deleted addObject:m];
                }
            }
            [weakSelf deletePwdToServer:deleted];
            
            //添加锁有服务器却没有的。
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
            [weakSelf uploadAddModeToServer:latest];
            
           
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                for (KDSPwdListModel *model in models)
                {
                    [[KDSDBManager sharedManager] deletePwdAttr:model bleName:weakSelf.lock.device.device_name];
                }
                [[KDSDBManager sharedManager] insertPwdAttr:latest bleName:weakSelf.lock.device.device_name];
            });
        }
        else
        {
            [weakSelf.listArray removeAllObjects];
            [weakSelf reloadData];
        }
    }];
}

#pragma mark 获取用户密码类型
-(void)uploadAddModeToServer:(NSArray<KDSPwdListModel *> *)models{
//    if (models.count == 0)
//    {
//        [self loadfromServeceForDevUserList];
//        return;
//    }
    __weak typeof(self) weakSelf = self;
    NSMutableArray *models_ = [NSMutableArray arrayWithArray:models];
    KDSPwdListModel *pwdModel = models_.firstObject;
    [self.lock.bleTool getUserTypeWithId:pwdModel.num KeyType:KDSBleKeyTypePIN completion:^(KDSBleError error, KDSBleUserType * _Nullable user) {

        KDSBleSetUserType type = user.userType;
        if (type == KDSBleSetUserTypeForerver || type == KDSBleSetUserTypeOnce)
        {
            if (type == KDSBleSetUserTypeOnce){
                pwdModel.pwdType = KDSServerKeyTpyeTempPIN;
            }
            if (type == KDSBleSetUserTypeForerver) {
                pwdModel.type = KDSServerCycleTpyeForever;
            }
            NSLog(@"self.listArray.count = %lu",(unsigned long)self.listArray.count);
            [self.listArray enumerateObjectsUsingBlock:^(KDSPwdListModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.num == pwdModel.num) {
                    obj.type = pwdModel.type;
                    obj.pwdType = pwdModel.pwdType;
                    [self.listArray replaceObjectAtIndex:idx withObject:obj];
                    *stop = YES;
                }
            }];
            [weakSelf addNewUserToSeversWithUid:pwdModel];
            [models_ removeObject:pwdModel];
            if (models_.count != 0) {
                [weakSelf uploadAddModeToServer:models_];
            }else{
                [weakSelf reloadData];
                [MBProgressHUD hideHUD];
                [MBProgressHUD showSuccess:@"同步完成"];
            }
        }
        else if (type == KDSBleSetUserTypeSchedule)
        {
            [weakSelf.lock.bleTool getScheduleWithScheduleId:pwdModel.num.intValue completion:^(KDSBleError error, KDSBleScheduleModel * _Nullable model) {
                if ([model isKindOfClass:KDSBleYMDModel.class])
                {
                    KDSBleYMDModel *m = (KDSBleYMDModel *)model;
                    pwdModel.type = KDSServerCycleTpyePeriod;
                    pwdModel.startTime = @(m.beginTime + FixedTime).stringValue;
                    pwdModel.endTime = @(m.endTime + FixedTime).stringValue;
                }
                else if ([model isKindOfClass:KDSBleWeeklyModel.class])
                {
                    KDSBleWeeklyModel *m = (KDSBleWeeklyModel *)model;
                    pwdModel.type = KDSServerCycleTpyeCycle;
                    weakSelf.lock.bleTool.dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm";
                    pwdModel.startTime = @([weakSelf.lock.bleTool.dateFormatter dateFromString:[NSString stringWithFormat:@"2019-03-22 %02lu:%02lu", m.beginHour, m.beginMin]].timeIntervalSince1970).stringValue;
                    pwdModel.endTime = @([weakSelf.lock.bleTool.dateFormatter dateFromString:[NSString stringWithFormat:@"2019-03-22 %02lu:%02lu", m.endHour, m.endMin]].timeIntervalSince1970).stringValue;
                    NSMutableArray *items = [NSMutableArray arrayWithCapacity:7];
                    for (int i = 0; i < 7; ++i)
                    {
                        [items addObject:@((m.mask >> i) & 0x1).stringValue];
                    }
                    pwdModel.items = items.copy;
                }
                [self.listArray enumerateObjectsUsingBlock:^(KDSPwdListModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (obj.num == pwdModel.num) {
                        obj.type = pwdModel.type;
                        obj.startTime = pwdModel.startTime;
                        obj.endTime = pwdModel.endTime;
                        obj.items = pwdModel.items;
                        [self.listArray replaceObjectAtIndex:idx withObject:obj];
                        *stop = YES;
                    }
                }];
                if (model) [weakSelf addNewUserToSeversWithUid:pwdModel];
                [models_ removeObject:pwdModel];
                if (models_.count != 0) {
                    [weakSelf uploadAddModeToServer:models_];
                }else{
                    [weakSelf reloadData];
                    [MBProgressHUD hideHUD];
                    [MBProgressHUD showSuccess:@"同步完成"];
                }
            }];
        }
        else//其它忽略。
        {
            [models_ removeObject:pwdModel];
            if (models_.count != 0) {
                [weakSelf uploadAddModeToServer:models_];
            }
        }
    }];
}

#pragma mark 同步删除密码到服务器
- (void)deletePwdToServer:(NSMutableArray*)pwdListModelArray{
    if (pwdListModelArray.count == 0) return;
    [[KDSHttpManager sharedManager] deleteBlePwd:pwdListModelArray withUid:[KDSUserManager sharedManager].user.uid bleName:self.lock.device.device_name success:^{
        NSLog(@"删除密码成功");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUD];
//            [MBProgressHUD showSuccess:@"操作成功"];
            [self loadfromServeceForDevUserList];
        });
    } error:^(NSError * _Nonnull error) {
        NSLog(@"删除失败哦1");
//        [MBProgressHUD showError:[Localized(@"saveFailed") stringByAppendingFormat:@"%ld", (long)error.localizedDescription]];
    } failure:^(NSError * _Nonnull error) {
//        NSLog(@"删除失败哦2%@",error.localizedDescription);
//        [MBProgressHUD showError:[Localized(@"saveFailed") stringByAppendingString:error.localizedDescription]];
    }];
}
-(NSString *)transTotimeSp:(NSString *)time{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]]; //设置本地时区
    [dateFormatter setDateFormat:@"HH:mm"];
    NSDate *date = [dateFormatter dateFromString:time];
    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[date timeIntervalSince1970]];//时间戳
    return timeSp;
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
