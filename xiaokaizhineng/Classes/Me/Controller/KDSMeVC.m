//
//  KDSMeVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/22.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSMeVC.h"
#import "Masonry.h"
#import "KDSMeTableViewCell.h"
#import "KDSDBManager.h"
#import "KDSHttpManager+User.h"
#import "KDSPersonalProfileVC.h"
#import "KDSSystemMsgVC.h"
#import "KDSSecuritySettingVC.h"
#import "KDSFAQViewController.h"
#import "KDSSystemSettingVC.h"
#import "KDSAboutVC.h"

@interface KDSMeVC () <UITableViewDataSource, UITableViewDelegate>

///顶部背景视图。
@property (nonatomic, strong) UIImageView *bgImageView;
///头像按钮。
@property (nonatomic, strong) UIButton *avatarBtn;
///昵称标签。
@property (nonatomic, strong) UILabel *nicknameLabel;

@end

@implementation KDSMeVC

#pragma mark - 生命周期方法。

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    CGFloat bgImageViewHeight = kScreenWidth / 375.0 * 224;
    self.bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"个人中心bg"]];
    [self.view addSubview:self.bgImageView];
    [self.bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(bgImageViewHeight);
    }];
    
    self.avatarBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    KDSDBManager *dbMgr = [KDSDBManager sharedManager];
    NSData *imgData = [dbMgr queryUserAvatarData];
    UIImage *img = imgData ? [[UIImage alloc] initWithData:imgData] : [UIImage imageNamed:@"头像-默认"];
    [self.avatarBtn setImage:img forState:UIControlStateNormal];
    [self.avatarBtn setImage:img forState:UIControlStateHighlighted];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 90, 90) cornerRadius:45];
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.path = path.CGPath;
    self.avatarBtn.layer.mask = layer;
    [self.avatarBtn addTarget:self action:@selector(clickAvatarBtnViewAndModifyPersonalProfile:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.avatarBtn];
    [self.avatarBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset((bgImageViewHeight - 99) / 2);
        make.centerX.equalTo(self.view);
        make.width.height.mas_equalTo(90);
    }];
    
    self.nicknameLabel = [[UILabel alloc] init];
    KDSUserManager *userMgr = [KDSUserManager sharedManager];
    self.nicknameLabel.text = userMgr.userNickname ?: userMgr.user.name;
    self.nicknameLabel.textAlignment = NSTextAlignmentCenter;
    self.nicknameLabel.textColor = UIColor.whiteColor;
    self.nicknameLabel.font = [UIFont systemFontOfSize:17];
    [self.view addSubview:self.nicknameLabel];
    [self.nicknameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.avatarBtn.mas_bottom).offset(9);
        make.left.right.equalTo(self.view);
        make.height.mas_lessThanOrEqualTo(18);
    }];
    
    CGFloat height = kScreenHeight - bgImageViewHeight + 19 - 20 - self.tabBarController.tabBar.bounds.size.height;
    CGFloat rowHeight = (height - 10.0) / 5 > 70 ? 70 : ceil((height - 10.0) / 5);
    [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bgImageView.mas_bottom).offset(-19);
        make.left.equalTo(self.view).offset(10);
        make.right.equalTo(self.view).offset(-10);
        make.height.mas_equalTo(rowHeight * 5 + 10);
    }];
    self.tableView.rowHeight = rowHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.bounces = NO;
    self.tableView.layer.cornerRadius = 5;
    [self.view bringSubviewToFront:self.tableView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(localeLanguageDidChange:) name:KDSLocaleLanguageDidChangeNotification object:nil];
    [self getUserNickname];
    [self getUserAvatar];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSData *imgData = [[KDSDBManager sharedManager] queryUserAvatarData];
    UIImage *img = imgData ? [[UIImage alloc] initWithData:imgData] : [UIImage imageNamed:@"头像-默认"];
    [self.avatarBtn setImage:img forState:UIControlStateNormal];
    [self.avatarBtn setImage:img forState:UIControlStateHighlighted];
    if (!imgData) [self getUserAvatar];
    KDSUserManager *userMgr = [KDSUserManager sharedManager];
    self.nicknameLabel.text = [[KDSDBManager sharedManager] queryUserNickname] ?: userMgr.user.name;
}

#pragma mark - 控件等事件方法。
///点击头像按钮跳转查看和修改个人资料。
- (void)clickAvatarBtnViewAndModifyPersonalProfile:(UIButton *)sender
{
    KDSPersonalProfileVC *vc = [KDSPersonalProfileVC new];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - 通知。
///收到更改了本地语言的通知，刷新页面。
- (void)localeLanguageDidChange:(NSNotification *)noti
{
    [self.tableView reloadData];
}

#pragma mark - 网络请求方法。
///获取用户昵称，刷新界面和更新数据库。
- (void)getUserNickname
{
    KDSUserManager *userMgr = [KDSUserManager sharedManager];
    KDSDBManager *dbMgr = [KDSDBManager sharedManager];
    [[KDSHttpManager sharedManager] getUserNicknameWithUid:userMgr.user.uid success:^(NSString * _Nullable nickname) {
        !nickname ?: (void)((void)(self.nicknameLabel.text = nickname), [dbMgr updateUserNickname:nickname]);
    } error:nil failure:nil];
}

///获取用户头像，刷新界面和更新数据库。
- (void)getUserAvatar
{
    KDSUserManager *userMgr = [KDSUserManager sharedManager];
    KDSDBManager *dbMgr = [KDSDBManager sharedManager];
    [[KDSHttpManager sharedManager] getUserAvatarImageWithUid:userMgr.user.uid success:^(UIImage * _Nullable image) {
        if (image)
        {
            [self.avatarBtn setImage:image forState:UIControlStateNormal];
            [self.avatarBtn setImage:image forState:UIControlStateHighlighted];
            CGImageAlphaInfo info = CGImageGetAlphaInfo(image.CGImage);
            if (info==kCGImageAlphaNone || info==kCGImageAlphaNoneSkipLast || info==kCGImageAlphaNoneSkipFirst)
            {
                [dbMgr updateUserAvatarData:UIImageJPEGRepresentation(image, 1.0)];
            }
            else
            {
                [dbMgr updateUserAvatarData:UIImagePNGRepresentation(image)];
            }
        }
    } error:nil failure:nil];
}


#pragma mark - UITableViewDataSource, UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? 1 : 4;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return section == 0 ? 10 : 0.001;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *view = [UIView new];
    view.backgroundColor = KDSRGBColor(249, 249, 249);
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseId = NSStringFromClass([self class]);
    KDSMeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if (!cell)
    {
        cell = [[KDSMeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
    }
    if (indexPath.section == 0)
    {
        cell.imgName = @"消息";
        cell.title = Localized(@"message");
        cell.cornerType = 3;
        cell.hideSeparator = YES;
    }
    else
    {
        NSArray *imgNames = @[@"安全设置", @"常见问题", @"系统设置", @"关于小凯"];
        NSArray *titles = @[Localized(@"securitySetting"), Localized(@"FAQ"), Localized(@"systemSetting"), Localized(@"aboutXiaokai")];
        cell.imgName = imgNames[indexPath.row];
        cell.title = titles[indexPath.row];
        cell.cornerType = indexPath.row==0 ? 1 : (indexPath.row==3 ? 2 : 0);
        cell.hideSeparator = indexPath.row == 3;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        KDSSystemMsgVC *vc = [[KDSSystemMsgVC alloc] init];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else
    {
        if (indexPath.row == 0)//安全设置
        {
            KDSSecuritySettingVC *vc = [KDSSecuritySettingVC new];
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
        else if (indexPath.row == 1)//常见问题
        {
            KDSFAQViewController *vc = [KDSFAQViewController new];
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
        else if (indexPath.row == 2)//系统设置
        {
            KDSSystemSettingVC *vc = [KDSSystemSettingVC new];
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
        else//关于小凯
        {
            KDSAboutVC *vc = [KDSAboutVC new];
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

@end
