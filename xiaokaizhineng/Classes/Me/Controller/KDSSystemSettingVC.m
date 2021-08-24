//
//  KDSSystemSettingVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/22.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSSystemSettingVC.h"
#import "Masonry.h"
#import "KDSPersonalProfileCell.h"
#import "KDSLanguageSettingVC.h"
#import "KDSDBManager.h"
#import "KDSHttpManager.h"
#import "MBProgressHUD+MJ.h"
#import "KDSUserAgreementVC.h"
#import "KDSAuthHelpVC.h"

@interface KDSSystemSettingVC () <UITableViewDataSource, UITableViewDelegate>

///退出登录按钮。
@property (nonatomic, weak) UIButton *logoutBtn;

@end

@implementation KDSSystemSettingVC
#pragma mark - 生命周期方法。
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationTitleLabel.text = Localized(@"systemSetting");
    [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.view).offset(10);
        make.right.equalTo(self.view).offset(-10);
        make.height.mas_equalTo(240);
    }];
    self.tableView.layer.cornerRadius = 5;
    self.tableView.backgroundColor = UIColor.whiteColor;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.bounces = NO;
    
    UIButton *logoutBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [logoutBtn setTitle:Localized(@"logout") forState:UIControlStateNormal];
    [logoutBtn setTitle:Localized(@"logout") forState:UIControlStateHighlighted];
    [logoutBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    logoutBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    logoutBtn.layer.shadowOffset = CGSizeMake(3, 3);
    logoutBtn.layer.shadowColor = [UIColor colorWithRed:0x2d/255.0 green:0xd9/255.0 blue:0xba/255.0 alpha:0.3].CGColor;
    logoutBtn.layer.shadowOpacity = 1.0;
    logoutBtn.layer.cornerRadius = 30;
    logoutBtn.backgroundColor = KDSRGBColor(0x2d, 0xd9, 0xba);
    [logoutBtn addTarget:self action:@selector(clickLogoutBtnLogout:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:logoutBtn];
    self.logoutBtn = logoutBtn;
    [logoutBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-80);
        make.width.mas_equalTo(kScreenWidth < 375 ? (kScreenWidth - 76): 300);
        make.height.mas_equalTo(60);
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localeLanguageDidChange:) name:KDSLocaleLanguageDidChangeNotification object:nil];
}

#pragma mark - 控件等事件方法。
///点击退出登录按钮发送退出登录通知退出登录。
- (void)clickLogoutBtnLogout:(UIButton *)sender
{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:Localized(@"tips") message:Localized(@"ensureLogout?") preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:KDSLogoutNotification object:nil userInfo:nil];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:Localized(@"cancel") style:UIAlertActionStyleDefault handler:nil];
    [ac addAction:cancel];
    [ac addAction:ok];
    [self presentViewController:ac animated:YES completion:nil];
}

#pragma mark - 通知。
///收到更改了本地语言的通知，刷新页面。
- (void)localeLanguageDidChange:(NSNotification *)noti
{
    [self.tableView reloadData];
    self.navigationTitleLabel.text = Localized(@"systemSetting");
    [self.logoutBtn setTitle:Localized(@"logout") forState:UIControlStateNormal];
    [self.logoutBtn setTitle:Localized(@"logout") forState:UIControlStateHighlighted];
}

#pragma mark - 网络请求方法。
///检查应用的App Store版本。
- (void)checkAppStoreVersion
{
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://itunes.apple.com/lookup?id=1456716317"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
    req.HTTPMethod = @"GET";
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view];
            NSDictionary *dict;
            if (data != nil) {
                dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            }
            NSArray<NSDictionary *> *results = dict[@"results"];
            NSString *version = results.firstObject[@"version"];
            ///FIXME:这里compare判断需要特别注意版本号的设置，例如9.8.8和10.0.1会得到不希望的结果。
            if (!version.length || [version compare:KDSTool.appVersion]==NSOrderedAscending)
            {
                [MBProgressHUD showSuccess:Localized(@"latestVersion") toView:self.view];
                return;
            }
            BOOL same = [version isEqualToString:KDSTool.appVersion];
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:Localized(same ? @"appVersionIsNewest" : @"newVersionWhetherUpdate?") message:nil preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okOrUpdate = [UIAlertAction actionWithTitle:Localized(same ? @"ok" : @"update") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if (!same)
                {
                    NSString *protocol = @"itms-apps://itunes.apple.com/cn/app/id1456716317?mt=8";
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:protocol]];
                }
            }];
            if (!same)
            {
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:Localized(@"cancel") style:UIAlertActionStyleCancel handler:nil];
                [ac addAction:cancel];
            }
            [ac addAction:okOrUpdate];
            [self presentViewController:ac animated:YES completion:nil];
        });
        
    }];
    [task resume];
}

#pragma mark - UITableViewDataSource, UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.row==0 ? 0.001 : 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseId = NSStringFromClass([self class]);
    KDSPersonalProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if (!cell)
    {
        cell = [[KDSPersonalProfileCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
        cell.clipsToBounds = YES;
    }
    NSArray *titles = @[Localized(@"languageSetting"), Localized(@"versionNumber"), Localized(@"userAgreement"), Localized(@"helpLog"), Localized(@"clearCache")];
    cell.title = titles[indexPath.row];
    cell.nickname = indexPath.row==1 ? KDSTool.appVersion : nil;
    cell.hideSeparator = indexPath.row == 4;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row)
    {
        case 0://语言设置
        {
            KDSLanguageSettingVC *vc = [KDSLanguageSettingVC new];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        case 1://版本号
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            [self checkAppStoreVersion];
            break;
            
        case 2://用户协议
        {
            KDSUserAgreementVC *vc = [KDSUserAgreementVC new];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        case 3://帮助日志
        {
            KDSAuthHelpVC *vc = [KDSAuthHelpVC new];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        case 4://清理缓存
        {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.removeFromSuperViewOnHide = YES;
            hud.dimBackground = YES;
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [[KDSDBManager sharedManager] clearDiskCache];
                //如果没有缓存数据的时候，清除操作执行很快，这时直接隐藏hud没效果，因此延时1秒执行。
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [hud hide:NO];
                    [MBProgressHUD showSuccess:Localized(@"clearDiskCacheSuccess")];
                });
            });
            
        }
            break;
            
        default:
            break;
    }
}

@end
