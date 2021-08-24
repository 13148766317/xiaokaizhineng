//
//  KDSFingerprintDetailVC.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/2/18.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSFingerprintDetailVC.h"
#import "MBProgressHUD+MJ.h"
#import "KDSHttpManager+Ble.h"
#import "UIView+Extension.h"

@interface KDSFingerprintDetailVC ()
@property (weak, nonatomic) IBOutlet UIView *nameView;
@property (weak, nonatomic) IBOutlet UIView *timeView;
///被授权账号名称标签。
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
///编辑按钮左边的被授权账号名称标签。
@property (weak, nonatomic) IBOutlet UILabel *eNameLabel;
///授权时间标签。
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;


@end

@implementation KDSFingerprintDetailVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationTitleLabel.text = Localized(@"fingerprintDetails");
    [self setRightButton];
    [self.rightButton setImage:[UIImage imageNamed:@"删除"] forState:UIControlStateNormal];
    [self setUI];
    self.lock.bleTool.dateFormatter.dateFormat = @"yyyy/MM/dd HH:mm";
    NSString *date = [self.lock.bleTool.dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.model.createTime]];
    self.nameLabel.text = self.eNameLabel.text = self.model.nickName ?: self.model.num;
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

#pragma mark - 控件等事件方法。
-(void)navRightClick{
    if (!self.lock.bleTool.connectedPeripheral)
    {
        [MBProgressHUD showError:Localized(@"bleNotConnect")];
        return;
    }
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:Localized(@"tips") message:Localized(@"ensureDeleteFingerprint?") preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:Localized(@"cancel") style:UIAlertActionStyleCancel handler:nil];
    __weak typeof(self) weakSelf = self;
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        MBProgressHUD *hud = [MBProgressHUD showMessage:@"正在删除"];
        [weakSelf.lock.bleTool manageKeyWithPwd:@"" userId:weakSelf.model.num action:KDSBleKeyManageActionDelete keyType:KDSBleKeyTypeFingerprint completion:^(KDSBleError error) {
            if (error == KDSBleErrorSuccess)
            {
                [hud hide:NO];
                [MBProgressHUD showSuccess:@"删除成功"];
                !weakSelf.fpHasBeenDeletedBlock ?: weakSelf.fpHasBeenDeletedBlock(weakSelf.model);
                [weakSelf.navigationController popViewControllerAnimated:YES];
                [[KDSHttpManager sharedManager] deleteBlePwd:@[weakSelf.model] withUid:[KDSUserManager sharedManager].user.uid bleName:weakSelf.lock.device.device_name success:nil error:nil failure:nil];
            }
            else
            {
                [hud hide:NO];
                [MBProgressHUD showError:Localized(@"deleteFailed")];
            }
        }];
        
    }];
    [ac addAction:okAction];
    [ac addAction:cancelAction];
    [self presentViewController:ac animated:YES completion:nil];
}

//MARK:点击编辑按钮修改指纹昵称。
- (IBAction)clickEditBtnAlterFingerprintNickname:(UIButton *)sender
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
        if (!text.length || [text isEqualToString:weakSelf.model.nickName]) return;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:weakSelf.view animated:YES];
        hud.removeFromSuperViewOnHide = YES;
        NSString *name = weakSelf.model.nickName;
        weakSelf.model.nickName = ac.textFields.firstObject.text;
        [[KDSHttpManager sharedManager] setBlePwd:weakSelf.model withUid:[KDSUserManager sharedManager].user.uid bleName:weakSelf.lock.device.device_name success:^{
            [hud hide:NO];
            weakSelf.nameLabel.text = weakSelf.eNameLabel.text = text;
            [MBProgressHUD showSuccess:Localized(@"modifySuccess")];
            !weakSelf.fpInfoDidUpdateBlock ?: weakSelf.fpInfoDidUpdateBlock(weakSelf.model);
        } error:^(NSError * _Nonnull error) {
            [hud hide:NO];
            [MBProgressHUD showError:[NSString stringWithFormat:@"error: %ld", (long)error.localizedDescription]];
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.model.nickName = name;
        } failure:^(NSError * _Nonnull error) {
            [hud hide:NO];
            [MBProgressHUD showError:error.localizedDescription];
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.model.nickName = name;
        }];
        
    }];
    [ac addAction:cancelAction];
    [ac addAction:okAction];
    [self presentViewController:ac animated:YES completion:nil];
}
  ///指纹名称文本输入框，限制文本长度小于16，大于16取值到16且提示
- (void)textFieldTextDidChange:(UITextField *)sender
{
    [sender trimTextToLength:-1];
}

@end
