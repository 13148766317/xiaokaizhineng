//
//  KDSFamilyMemberlistVC.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/18.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSFamilyMemberlistVC.h"
#import "KDSFamilyMemberTableViewCell.h"
#import "KDSAddMemberVC.h"
#import "KDSMemberDetailVC.h"
#import "KDSHttpManager+User.h"
#import "MJRefresh.h"
#import "MBProgressHUD+MJ.h"
#import "KDSDBManager.h"

@interface KDSFamilyMemberlistVC ()<UITableViewDataSource,UITableViewDelegate>
///暂无家庭成员的显示的view
@property (weak, nonatomic) IBOutlet UIView *lessMemberView;
@property (nonatomic, strong) UITableView *tableView;
///已添加的被授权成员账号。
@property (nonatomic, strong) NSMutableArray<KDSAuthMember *> *members;

@end

@implementation KDSFamilyMemberlistVC

- (NSMutableArray<KDSAuthMember *> *)members
{
    if (!_members)
    {
        _members = [NSMutableArray array];
    }
    return _members;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationTitleLabel.text = Localized(@"familyMember");
    self.lessMemberView.backgroundColor = self.view.backgroundColor;
    self.lessMemberView.frame = self.tableView.frame;
    self.lessMemberView.subviews.firstObject.frame = CGRectMake((kScreenWidth - 125) / 2, 138, 116, 105);
    self.lessMemberView.subviews.lastObject.frame = CGRectMake((kScreenWidth - 320) / 2, CGRectGetMaxY(self.lessMemberView.subviews.firstObject.frame) + 60, 300, 60);
    NSArray *members = [[KDSDBManager sharedManager] queryUserAuthMembers];
    if (members)
    {
        [self.members addObjectsFromArray:members];
    }
    [self addlistView];
    if ([self.lock.device.is_admin boolValue])
    {
        [self setRightButton];
        [self.rightButton setImage:[UIImage imageNamed:@"添加"] forState:UIControlStateNormal];
        self.rightButton.hidden = YES;
    }
    [self appDidBecomeActive:nil];
    self.tableView.tableHeaderView = self.lessMemberView;
    [self showTableViewHeaderView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self getAuthorizedUsers];
    
}

-(void)hiddenTableViewHeaderView{
    self.lessMemberView.backgroundColor = [UIColor clearColor];
    self.lessMemberView.frame = CGRectZero;
    self.lessMemberView.subviews.firstObject.frame = CGRectZero;
    self.lessMemberView.subviews.lastObject.frame = CGRectZero;
    self.tableView.tableHeaderView.hidden = YES;
    self.rightButton.hidden = NO;
}
-(void)showTableViewHeaderView{
    self.lessMemberView.backgroundColor = self.view.backgroundColor;
    self.lessMemberView.frame = self.tableView.frame;
    self.lessMemberView.subviews.firstObject.frame = CGRectMake((kScreenWidth - 125) / 2, 138, 116, 105);
    self.lessMemberView.subviews.lastObject.frame = CGRectMake((kScreenWidth - 320) / 2, CGRectGetMaxY(self.lessMemberView.subviews.firstObject.frame) + 60, 300, 60);
    self.tableView.tableHeaderView.hidden = NO;
    self.rightButton.hidden = YES;
}
- (void)reloadData
{
    if (!self.members.count && self.lock.device.is_admin.boolValue)
    {
        [self showTableViewHeaderView];
    }
    else
    {
        [self hiddenTableViewHeaderView];
    }
    [self.tableView reloadData];
}

-(void)addlistView{
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(10, 10, kScreenWidth-20, kScreenHeight - kStatusBarHeight - kNavBarHeight - 10) style:UITableViewStylePlain];
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.rowHeight = 60;
    _tableView.tableFooterView = [[UIView alloc] init];
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.layer.cornerRadius = 5;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    __weak typeof(self) weakSelf = self;
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf appDidBecomeActive:nil];
    }];
    [_tableView registerNib:[UINib nibWithNibName:@"KDSFamilyMemberTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"KDSFamilyMemberTableViewCell"];
    [self.view addSubview:_tableView];
    
}

#pragma mark - 通知
///APP被激活时重新请求数据刷新页面。viewDidLoad、下拉刷新时也调用了此方法，此时参数noti为空。
- (void)appDidBecomeActive:(NSNotification *)noti
{
    [self getAuthorizedUsers];
}
///获取被授权的用户
-(void)getAuthorizedUsers{
    [[KDSHttpManager sharedManager] getAuthorizedUsersWithUid:[KDSUserManager sharedManager].user.uid bleName:self.lock.device.device_name success:^(NSArray<KDSAuthMember *> * _Nullable members) {
        [self.members removeAllObjects];
        [self.members addObjectsFromArray:members];
        [self.tableView reloadData];
        self.tableView.mj_header.state = MJRefreshStateIdle;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [[KDSDBManager sharedManager] updateUserAuthMembers:members];
        });
        [self reloadData];
        
    } error:^(NSError * _Nonnull error) {
        self.tableView.mj_header.state = MJRefreshStateIdle;
        if (!self.members.count)
        {
            [MBProgressHUD showError:[NSString stringWithFormat:@"error: %ld", (long)error]];
        }
        [self reloadData];
    } failure:^(NSError * _Nonnull error) {
        self.tableView.mj_header.state = MJRefreshStateIdle;
        if (!self.members.count)
        {
            [MBProgressHUD showError:[NSString stringWithFormat:@"%@: %ld", error.localizedDescription, (long)error.localizedDescription]];
        }
        [self reloadData];
    }];
}
#pragma mark -  UITableViewDelegate,UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.members.count;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    KDSMemberDetailVC * MVC = [[KDSMemberDetailVC alloc] init];
    MVC.lock = self.lock;
    MVC.member = self.members[indexPath.row];
    __weak typeof(self) weakSelf = self;
    MVC.memberHasBeenDeleteBlock = ^(KDSAuthMember * _Nonnull member) {
        [weakSelf.members removeObject:member];
        [weakSelf.tableView reloadData];
    };
    [self.navigationController pushViewController:MVC animated:YES];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    KDSFamilyMemberTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"KDSFamilyMemberTableViewCell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.member = self.members[indexPath.row];
    cell.number = indexPath.row;
    cell.hideSeparator = indexPath.row == self.members.count - 1;
    if (self.members.count == 1)
    {
        cell.cornerType = 3;
    }
    else
    {
        cell.cornerType = indexPath.row==0 ? 1 : (indexPath.row == self.members.count - 1 ? 2 : 0);
    }
    return cell;
}

-(void)navRightClick{
    [self addFamilyMemBer];
}
- (IBAction)addMemBerClick:(id)sender {
    [self addFamilyMemBer];
    
}

-(void)addFamilyMemBer
{
    if (self.members.count >= 10)
    {
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:Localized(@"tips") message:Localized(@"moreThanOrEqualTo10Members") preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:Localized(@"fine") style:UIAlertActionStyleDefault handler:nil];
        [ac addAction:okAction];
        [self presentViewController:ac animated:YES completion:nil];
        return;
    }
    KDSAddMemberVC *addVC = [[KDSAddMemberVC alloc] init];
    addVC.lock = self.lock;
    addVC.memberDidAddBlock = ^(KDSAuthMember * _Nonnull member) {
        [self.members addObject:member];
        [self getAuthorizedUsers];
        [self.tableView reloadData];
    };
    [self.navigationController pushViewController:addVC animated:YES];
}



@end
