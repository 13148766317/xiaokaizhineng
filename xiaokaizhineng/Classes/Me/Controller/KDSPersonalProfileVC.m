//
//  KDSPersonalProfileVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/22.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSPersonalProfileVC.h"
#import "Masonry.h"
#import "KDSPersonalProfileCell.h"
#import "KDSDBManager.h"
#import "MBProgressHUD+MJ.h"
#import "KDSHttpManager+User.h"
#import "KDSModifyNicknameVC.h"
#import "KDSModifyPwdVC.h"

@interface KDSPersonalProfileVC () <UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@end

@implementation KDSPersonalProfileVC

#pragma mark - 生命周期方法。
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationTitleLabel.text = Localized(@"personalProfile");
    [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.view).offset(10);
        make.right.equalTo(self.view).offset(-10);
        make.height.mas_equalTo(240);
    }];
    self.tableView.layer.cornerRadius = 5;
    self.tableView.backgroundColor = UIColor.whiteColor;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 60;
    self.tableView.bounces = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

#pragma mark - 控件、手势等事件。
///弹选择图片方式的警告控制器出来时点击屏幕让控制器消失。
- (void)tapToRemoveAlertController:(UITapGestureRecognizer *)tap
{
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource, UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseId = NSStringFromClass([self class]);
    KDSPersonalProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if (!cell)
    {
        cell = [[KDSPersonalProfileCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
    }
    
    KDSUserManager *userMgr = [KDSUserManager sharedManager];
    if (indexPath.row == 0)//头像
    {
        cell.title = Localized(@"avatar");
        UIImage *image = cell.image;
        if (!image)
        {
            NSData *data = [[KDSDBManager sharedManager] queryUserAvatarData];
            image = data ? [[UIImage alloc] initWithData:data] : [UIImage imageNamed:@"头像-默认"];
        }
        cell.image = image;
    }
    else if (indexPath.row == 1)//昵称
    {
        cell.title = Localized(@"nickname");
        cell.nickname = userMgr.userNickname ?: userMgr.user.name;
    }
    else if (indexPath.row == 2)//账号
    {
        NSString *account = userMgr.user.name;
        BOOL isMail = [KDSTool isValidateEmail:account];
        cell.title = Localized(isMail ? @"email" : @"phoneNumber");
        cell.account = isMail ? account : [account stringByReplacingCharactersInRange:NSMakeRange(0, KDSTool.crc.length) withString:@""];
    }
    else//修改密码
    {
        cell.title = Localized(@"modifyPassword");
        cell.isPwdCell = YES;
    }
    cell.hideSeparator = indexPath.row == 3;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)//头像
    {
        __weak typeof(self) weakSelf = self;
        void (^block) (UIImagePickerControllerSourceType) = ^(UIImagePickerControllerSourceType type){
            UIImagePickerController *picker = [[UIImagePickerController alloc]init];
            picker.delegate = weakSelf;
            picker.sourceType = type;
            picker.allowsEditing = YES;
            if (type == UIImagePickerControllerSourceTypePhotoLibrary)
            {
                picker.navigationBar.translucent = NO;
            }
            [weakSelf presentViewController:picker animated:YES completion:nil];
        };
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *tackPhotoAction = [UIAlertAction actionWithTitle:Localized(@"takePhoto") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            block(UIImagePickerControllerSourceTypeCamera);
        }];
        UIAlertAction *photoAction = [UIAlertAction actionWithTitle:Localized(@"selectFromAlbum") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            block(UIImagePickerControllerSourceTypePhotoLibrary);
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:Localized(@"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        [tackPhotoAction setValue:[UIColor blackColor] forKey:@"titleTextColor"];
        [photoAction setValue:[UIColor blackColor] forKey:@"titleTextColor"];
        [alert addAction:photoAction];
        [alert addAction:tackPhotoAction];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:^{
            NSArray<UIView *> *views = [UIApplication sharedApplication].keyWindow.subviews;
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToRemoveAlertController:)];
            [views.lastObject.subviews.firstObject addGestureRecognizer:tap];
        }];
    }
    else if (indexPath.row == 1)//昵称
    {
        KDSModifyNicknameVC *vc = [[KDSModifyNicknameVC alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (indexPath.row == 2)//账号
    {
        
    }
    else//修改密码
    {
        KDSModifyPwdVC *vc = [[KDSModifyPwdVC alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - UIImagePickerControllerDelegate，拍照、取照片设置头像。
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info
{
    UIImage *image = info[UIImagePickerControllerEditedImage];
    __weak KDSPersonalProfileVC *weakSelf = self;
    [picker dismissViewControllerAnimated:YES completion:^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localized(@"ensureModifyAvatar?") message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
            hud.removeFromSuperViewOnHide = YES;
            [[KDSHttpManager sharedManager] setUserAvatarImage:image withUid:[KDSUserManager sharedManager].user.uid success:^{
                [[KDSDBManager sharedManager] updateUserAvatarData:UIImagePNGRepresentation(image)];
                KDSPersonalProfileCell *cell = [weakSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                cell.image = image;
                [hud hide:YES];
                [MBProgressHUD showSuccess:Localized(@"modifyAvatarSuccess")];
            } error:^(NSError * _Nonnull error) {
                [hud hide:YES];
                [MBProgressHUD showError:[Localized(@"modifyAvatarFailed") stringByAppendingFormat:@": %ld", (long)error.localizedDescription]];
            } failure:^(NSError * _Nonnull error) {
                [hud hide:YES];
                [MBProgressHUD showError:[Localized(@"modifyAvatarFailed") stringByAppendingFormat:@"，%@", error.localizedDescription]];
            }];
            
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:Localized(@"cancel") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alert addAction:cancelAction];
        [alert addAction:okAction];
        [weakSelf presentViewController:alert animated:YES completion:nil];
    }];
}

@end
