//
//  KDSTemPwdlistdViewController.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/3/8.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSTemPwdlistdViewController.h"
#import "KDSAddTempPwdViewController.h"
#import "KDSPwsTongbu.h"
#import "KDSPwdListTableViewCell.h"
#import "KDSTempPwdDetailVC.h"
#import "KDSHttpManager+Ble.h"
#import "MBProgressHUD+MJ.h"
#import "MJRefresh.h"

@interface KDSTemPwdlistdViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UIView *pwdLessView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<KDSPwdListModel *> *listArray;
///管理密钥错误对应的字典，键是错误码，值是错误信息。
@property (nonatomic, readonly) NSDictionary<NSNumber *, NSString *> *errorMsgDict;
@property (weak, nonatomic) IBOutlet UIButton *addTemPwdBtn;
///自定义同步视图。
@property (nonatomic, strong) KDSPwsTongbu *syncView;
@end

@implementation KDSTemPwdlistdViewController
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
    [self.addTemPwdBtn setTitle:Localized(@"AddaPassword") forState:UIControlStateNormal];
    self.navigationTitleLabel.text = Localized(@"temporarypassword");
    self.pwdLessView.hidden = YES;
    [self addlistView];
    [self addHeadView];
    [self setRightButton];
    self.pwdLessView.frame = self.tableView.bounds;
    self.pwdLessView.subviews.firstObject.frame = CGRectMake((kScreenWidth - 125) / 2, 138, 116, 105);
    self.pwdLessView.subviews.lastObject.frame = CGRectMake((kScreenWidth - 320) / 2, CGRectGetMaxY(self.pwdLessView.subviews.firstObject.frame) + 60, 300, 60);
    self.pwdLessView.backgroundColor = self.view.backgroundColor;
    [self.rightButton setImage:[UIImage imageNamed:@"添加"] forState:UIControlStateNormal];
    [self.view bringSubviewToFront:self.pwdLessView];
    if ([self.lock.device.is_admin boolValue])
    {
        [self setRightButton];
        [self.rightButton setImage:[UIImage imageNamed:@"添加"] forState:UIControlStateNormal];
    }
    // Do any additional setup after loading the view from its nib.
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:4];
    for (int i = 0; i < 4; ++i)
    {
        KDSPwdListModel *m = [KDSPwdListModel new];
        m.pwdType = KDSServerKeyTpyePIN;
    }
}
- (IBAction)addClick:(id)sender {
    KDSAddTempPwdViewController * AVC = [[KDSAddTempPwdViewController alloc] init];
    AVC.lock = self.lock;
    [self.navigationController pushViewController:AVC animated:YES];
}
-(void)addlistView{
    __weak typeof(self) weakSelf = self;
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(10, 0, kScreenWidth-20, kScreenHeight) style:UITableViewStylePlain];
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.rowHeight = 60;
    _tableView.tableFooterView = [[UIView alloc] init];
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.layer.cornerRadius = 5;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_tableView registerNib:[UINib nibWithNibName:@"KDSPwdListTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"KDSPwdListTableViewCell"];
    _tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf loadfromServeceForDevUserList];
    }];
    [self.view addSubview:_tableView];
    
}
-(void)addHeadView{
    KDSPwsTongbu *tongbuHeadView = [[KDSPwsTongbu alloc]initWithFrame:CGRectMake(0, 0, kScreenWidth-20, 67)];
    _tableView.tableHeaderView = tongbuHeadView;
    __weak typeof(self) weakSelf = self;
    tongbuHeadView.syncBtnClickBlock = ^(UIButton * _Nonnull sender) {
        NSLog(@"0000000000");
        [weakSelf getAllUsersFromeLock];
    };
    tongbuHeadView.titleLab.text = Localized(@"PWDSynchronize");
    tongbuHeadView.layer.cornerRadius = 5;
    self.syncView = tongbuHeadView;
}
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
    KDSTempPwdDetailVC * EVC = [[KDSTempPwdDetailVC alloc] init];
    EVC.pwdModel = self.listArray[indexPath.row];
    EVC.lock = self.lock;
    [self.navigationController pushViewController:EVC animated:YES];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    KDSPwdListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"KDSPwdListTableViewCell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.timeLab.hidden = YES;
    cell.numLabTopConstraint.constant = 22;
    [cell setValueWithPwdListModel:[self.listArray objectAtIndex:indexPath.row]];
    return cell;
}
- (IBAction)tongbuClick:(id)sender {
    [self getAllUsersFromeLock];
}
-(void)navRightClick{
    KDSAddTempPwdViewController * AVC = [[KDSAddTempPwdViewController alloc] init];
    AVC.lock = self.lock;
    [self.navigationController pushViewController:AVC animated:YES];
}
#pragma mark 从网络加载用户列表
-(void)loadfromServeceForDevUserList{
    KDSLog(@"从网络加载用户列表");
    [[KDSHttpManager sharedManager] getBlePwdListWithUid:[KDSUserManager sharedManager].user.uid bleName:self.lock.device.device_name pwdType:(KDSServerKeyTpye)KDSServerKeyTpyeTempPIN success:^(NSArray<KDSPwdListModel *> * _Nonnull pwdlistArray) {
        [self.listArray removeAllObjects];
        for (KDSPwdListModel*pwdListModel in pwdlistArray) {
//            if (pwdListModel.nickName.length) {//除掉没有昵称的数据
                pwdListModel.pwdType = KDSServerKeyTpyeTempPIN;
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
        self.tableView.mj_header.state = MJRefreshStateIdle;
    } error:^(NSError * _Nonnull error) {
        self.tableView.mj_header.state = MJRefreshStateIdle;
        [MBProgressHUD showError:[NSString stringWithFormat:@"%@",error.localizedDescription]];
        NSLog(@"sss");
    } failure:^(NSError * _Nonnull failure) {
        self.tableView.mj_header.state = MJRefreshStateIdle;
        [MBProgressHUD showError:[NSString stringWithFormat:@"%@",failure.localizedDescription]];
        NSLog(@"www");
    }];
}
#pragma mark 从锁中同步用户密码
-(void)getAllUsersFromeLock{
    [MBProgressHUD showMessage:@"正在同步"];
    [self.lock.bleTool getAllUsersWithKeyType:KDSBleKeyTypePIN completion:^(KDSBleError error, NSArray<KDSBleUserType *> * _Nullable users) {
        NSLog(@"锁中存在用户密码 %lu组",users.count);
       
        //删除服务器存在，锁中不存在的密码
        NSMutableArray *deleteArray = [[NSMutableArray alloc] init];
        for (KDSPwdListModel *model in self.listArray)
        {
            BOOL contain = NO;
            for (KDSBleUserType *user in users)
            {
                if (model.num.intValue == user.userId)
                {
                    contain = YES;
                    break;
                }
            }
            if (!contain)
            {
                if (model.num.intValue > 4 && model.num.intValue <9) {
                    model.pwdType = KDSServerKeyTpyeTempPIN;
                    [deleteArray addObject:model];
                }
            }
        }
        if (deleteArray.count != 0) {
            [self deletePwdToServer:deleteArray];
        }
        //添加服务器不存在，锁中存在的密码
        NSMutableArray *addPwdArray = [[NSMutableArray alloc] init];
        for (KDSBleUserType *user in users)
        {
            BOOL contain = NO;
            for (KDSPwdListModel *guest in self.listArray)
            {
                if (guest.num.intValue == user.userId)
                {
                    contain = YES;
                    break;
                }
            }
            if (!contain)
            {
                KDSPwdListModel *pwdModel = [[KDSPwdListModel alloc] init];
                NSLog(@"user.userId] = %lu",(unsigned long)user.userId);
                pwdModel.num = pwdModel.nickName = [NSString stringWithFormat:@"%02lu", (unsigned long)user.userId];
                //通过密码类型判断是否存在时间计划
                if (pwdModel.num.intValue > 4 && pwdModel.num.intValue <9) {
                    pwdModel.pwdType = KDSServerKeyTpyeTempPIN;
                    [addPwdArray addObject:pwdModel];
                    [self.listArray addObject:pwdModel];
                }
            }
        }
        NSLog(@"weakSelf.addArray = %lu个",addPwdArray.count);
        for (KDSPwdListModel *model in addPwdArray) {
            [self addNewUserToSevers:model];
        }
        [self reloadData];
        [MBProgressHUD hideHUD];
        [MBProgressHUD showSuccess:@"同步完成"];
    }];
}
#pragma mark 添加用户到服务器
- (void)addNewUserToSevers:(KDSPwdListModel*)pwdListModel{
    NSArray *pwdlistarray = [[NSArray alloc] initWithObjects:pwdListModel, nil];
    [[KDSHttpManager sharedManager] addNewUserToSeversWithGuest:[KDSUserManager sharedManager].user.uid bleName:self.lock.device.device_name pwdarray:pwdlistarray success:^(NSString * _Nonnull timeStr){
        [MBProgressHUD hideHUD];
//        [MBProgressHUD showSuccess:Localized(@"Addasuccess")];
        [self loadfromServeceForDevUserList];
    } error:^(NSError * _Nonnull error) {
        [MBProgressHUD hideHUD];
        NSLog(@"添加失败哦2%@",error.localizedDescription);
//        [MBProgressHUD showError:[Localized(@"saveFailed") stringByAppendingString:error.localizedDescription]];
    } failure:^(NSError * _Nonnull failure) {
        [MBProgressHUD hideHUD];
        NSLog(@"添加失败哦2%@",failure.localizedDescription);
//        [MBProgressHUD showError:[Localized(@"saveFailed") stringByAppendingString:failure.localizedDescription]];
    }];
}
#pragma mark 同步删除密码到服务器
- (void)deletePwdToServer:(NSMutableArray*)pwdListModelArray{
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
/*
#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
