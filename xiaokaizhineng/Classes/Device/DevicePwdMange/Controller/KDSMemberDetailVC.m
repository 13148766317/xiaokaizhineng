//
//  KDSMemberDetailVC.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/18.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSMemberDetailVC.h"
#import "KDSHttpManager+User.h"
#import "MBProgressHUD+MJ.h"
#import "UIView+Extension.h"

@interface KDSMemberDetailVC ()
@property (weak, nonatomic) IBOutlet UIView *nameView;
@property (weak, nonatomic) IBOutlet UIView *timeView;
///被授权用户名称标签
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
///编辑按钮左边的被授权用户名称标签。
@property (weak, nonatomic) IBOutlet UILabel *eNameLabel;
///编辑按钮。
@property (weak, nonatomic) IBOutlet UIButton *editBtn;
///授权时间标签。
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;


@end

@implementation KDSMemberDetailVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationTitleLabel.text = @"用户详情";
    [self setRightButton];
    [self.rightButton setImage:[UIImage imageNamed:@"删除"] forState:UIControlStateNormal];
    [self setUI];
    [self.editBtn setImage:[UIImage imageNamed:@"写名字"] forState:UIControlStateNormal];
    self.nameLabel.text = self.eNameLabel.text = self.member.unickname ?: self.member.uname;
    self.lock.bleTool.dateFormatter.dateFormat = @"yyyy/MM/dd HH:mm";
    NSString *date = [self.lock.bleTool.dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.member.createTime]];
    self.timeLabel.text = [Localized(@"authorizationTime") stringByAppendingFormat:@": %@", date];
}
-(void)setUI{
    self.nameView.layer.shadowColor = KDSRGBColor(0xdd, 0xdd, 0xdd).CGColor;
    self.nameView.layer.shadowOffset = CGSizeMake(3, 3);
    self.nameView.layer.shadowOpacity = 1.0;
    self.nameView.clipsToBounds = NO;
    
    self.timeView.layer.shadowColor = KDSRGBColor(0xdd, 0xdd, 0xdd).CGColor;
    self.timeView.layer.shadowOffset = CGSizeMake(3, 3);
    self.timeView.layer.shadowOpacity = 1.0;
    self.timeView.clipsToBounds = NO;
}
-(void)navRightClick{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:Localized(@"tips") message:Localized(@"ensureDeleteAuthMember?") preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:Localized(@"cancel") style:UIAlertActionStyleCancel handler:nil];
    __weak typeof(self) weakSelf = self;
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        MBProgressHUD *hud = [MBProgressHUD showMessage:Localized(@"deleting...")];
        [[KDSHttpManager sharedManager] deleteAuthorizedUser:weakSelf.member withUid:[KDSUserManager sharedManager].user.uid device:weakSelf.lock.device success:^{
            [hud hide:NO];
            [MBProgressHUD showSuccess:Localized(@"deleteSuccess")];
            !weakSelf.memberHasBeenDeleteBlock ?: weakSelf.memberHasBeenDeleteBlock(weakSelf.member);
            [weakSelf.navigationController popViewControllerAnimated:YES];
        } error:^(NSError * _Nonnull error) {
            [hud hide:NO];
            [MBProgressHUD showError:[NSString stringWithFormat:@"%@: %ld", Localized(@"deleteFailed"), (long)error.code]];
        } failure:^(NSError * _Nonnull error) {
            [hud hide:NO];
            [MBProgressHUD showError:[NSString stringWithFormat:@"%@，%@", Localized(@"deleteFailed"), error.localizedDescription]];
        }];
        
    }];
    [ac addAction:okAction];
    [ac addAction:cancelAction];
    [self presentViewController:ac animated:YES completion:nil];
}

///点击编辑按钮弹出对话框修改昵称。
- (IBAction)clickEditBtnAlterMemberNickname:(UIButton *)sender
{
     __weak typeof(self) weakSelf = self;
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:Localized(@"inputNewNickname") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        
        textField.textAlignment = NSTextAlignmentCenter;
        textField.textColor = KDSRGBColor(0x10, 0x10, 0x10);
        textField.font = [UIFont systemFontOfSize:13];
        [textField addTarget:weakSelf action:@selector(textFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:Localized(@"cancel") style:UIAlertActionStyleCancel handler:nil];
    
   
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *text = ac.textFields.firstObject.text;
        if (!text.length || [text isEqualToString:weakSelf.member.unickname]) return;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakSelf.view animated:YES];
        hud.removeFromSuperViewOnHide = YES;
        NSString *name = weakSelf.member.unickname;
        weakSelf.member.unickname = text;
        [[KDSHttpManager sharedManager] updateAuthorizedUserNickname:weakSelf.member success:^{
            [hud hide:NO];
            weakSelf.nameLabel.text = weakSelf.eNameLabel.text = text;
            [MBProgressHUD showSuccess:Localized(@"modifySuccess")];
        } error:^(NSError * _Nonnull error) {
            [hud hide:NO];
            [MBProgressHUD showError:[NSString stringWithFormat:@"error: %ld", (long)error.localizedDescription]];
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.member.unickname = name;
        } failure:^(NSError * _Nonnull error) {
            [hud hide:NO];
            [MBProgressHUD showError:error.localizedDescription];
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.member.unickname = name;
        }];
    }];
    [ac addAction:cancelAction];
    [ac addAction:okAction];
    [self presentViewController:ac animated:YES completion:nil];
}

///家庭成员昵称文本框，限制文本长度小于16，如大于取值到16，切提示
- (void)textFieldTextDidChange:(UITextField *)sender
{
    [sender trimTextToLength:-1];
}

@end
