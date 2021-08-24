//
//  KDSDeviceVC.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/1/24.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSDeviceVC.h"
#import "KDSDeviceTableViewCell.h"
#import "KDSDeviceInfoViewController.h"
#import "KDSDeviceModelListTableVC.h"
#import "MBProgressHUD+MJ.h"

@interface KDSDeviceVC ()<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *naviBarViewHeight;
@property (weak, nonatomic) IBOutlet UIView *naviBarView;
@property (weak, nonatomic) IBOutlet UILabel *naviTitleLab;
@property (nonatomic, strong) UITableView *deviceListTableView;
@property (weak, nonatomic) IBOutlet UIButton *buyBtn;
@end

@implementation KDSDeviceVC

- (void)viewDidLoad {
    [super viewDidLoad];

    self.naviBarViewHeight.constant = kNavBarHeight+kStatusBarHeight;
    [self addDeviceListTableView];
    self.naviTitleLab.text = Localized(@"mydevice");
    [self.buyBtn setTitle:Localized(@"Gobuyit") forState:UIControlStateNormal];
    // Do any additional setup after loading the view from its nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localeLanguageDidChange:) name:KDSLocaleLanguageDidChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    if ([KDSUserManager sharedManager].locks.count == 0) {
        self.deviceListTableView.hidden = YES;
    }else{
        self.deviceListTableView.hidden = NO;
        [self.deviceListTableView reloadData];
    }
    self.naviBarView.hidden = NO;
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    self.naviBarView.hidden = YES;
}
- (void)addDeviceListTableView{
    _deviceListTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.naviBarViewHeight.constant,kScreenWidth, kScreenHeight-self.naviBarViewHeight.constant-self.tabBarController.tabBar.bounds.size.height) style:UITableViewStylePlain];
    _deviceListTableView.backgroundColor = KDSRGBColor(249, 249, 249);
    //取消分隔线
    _deviceListTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_deviceListTableView];
    _deviceListTableView.dataSource = self;
    _deviceListTableView.delegate = self;
    _deviceListTableView.tableHeaderView = [[UIView alloc] init];
    [_deviceListTableView registerNib:[UINib nibWithNibName:@"KDSDeviceTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"KDSDeviceTableViewCell"];
}
- (IBAction)buyItClick:(id)sender {
    NSLog(@"点击了购买按钮");
    NSURL *url = [NSURL URLWithString:[@"http://" stringByAppendingString:@"www.xiaokai.com"]];
    if ([[UIApplication sharedApplication] canOpenURL:url])
    {
        [[UIApplication sharedApplication] openURL:url];
    }
}
-(NSInteger)getRandomNumber:(NSInteger)from to:(NSInteger)to
{
    return (NSInteger)(from + (arc4random() % (to-from + 1)));
}
- (IBAction)addclicked:(id)sender {
    KDSDeviceModelListTableVC *vc = [[KDSDeviceModelListTableVC alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - 通知。
///收到更改了本地语言的通知，刷新页面。
- (void)localeLanguageDidChange:(NSNotification *)noti
{
    [self.deviceListTableView reloadData];
}

#pragma mark - <UITableViewDataSource,UITableViewDelegate>
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
   
    return [KDSUserManager sharedManager].locks.count;
}
- (CGFloat )tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    //    return 310;
    return 162;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
     KDSDeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"KDSDeviceTableViewCell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    KDSLock *lock = [KDSUserManager sharedManager].locks[indexPath.row];
    
    //lock.device.model = @"T5S";
    cell.power = lock.bleTool.connectedPeripheral ? lock.bleTool.connectedPeripheral.power : -1;
    cell.device = lock.device;
    cell.backgroundColor = [UIColor whiteColor];
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    KDSLock *lock = [KDSUserManager sharedManager].locks[indexPath.row];
    KDSDeviceInfoViewController *infoVC= [[KDSDeviceInfoViewController alloc] init];

    infoVC.hidesBottomBarWhenPushed = YES;
    infoVC.lock = lock;
    [self.navigationController pushViewController:infoVC animated:YES];
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
