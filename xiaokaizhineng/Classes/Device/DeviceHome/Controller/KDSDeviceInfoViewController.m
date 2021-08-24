//
//  KDSDeviceInfoViewController.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/1/25.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSDeviceInfoViewController.h"
#import "UIView+BlockGesture.h"
#import "KDSPwdListViewController.h"
#import "KDSLockMoreSettingVC.h"
#import "KDSAddTempPwdViewController.h"
#import "KDSFingerprintManaViewController.h"
#import "KDSCardListViewController.h"
#import "KDSFamilyMemberlistVC.h"
#import "Masonry.h"
#import "KDSTemPwdlistdViewController.h"
#import "MBProgressHUD+MJ.h"
#import "KDSLockParamVC.h"

@interface KDSDeviceInfoViewController ()

///型号小图片视图。
@property (weak, nonatomic) IBOutlet UIImageView *smallModelIV;
///型号小图片左约束。X5(15)和T5(小图+型号居中)图片的左约束不一致。
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *smallModelIVLeftConstrain;
///型号小图片宽度约束。X5(8)和T5(12)图片的宽度不一致。
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *smallModelIVWidthConstrain;
///型号标签。
@property (weak, nonatomic) IBOutlet UILabel *modelLabel;
///手/自动上锁标签，X5才有这个功能。
@property (weak, nonatomic) IBOutlet UILabel *autoLabel;
///型号大图片视图。
@property (weak, nonatomic) IBOutlet UIImageView *bigModelIV;
///状态提示标签。
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
///电量图片视图。
@property (weak, nonatomic) IBOutlet UIImageView *powerIV;
///电量标签。
@property (weak, nonatomic) IBOutlet UILabel *powerLabel;
///指纹标签。
@property (weak, nonatomic) IBOutlet UILabel *fpLabel;
///卡片图片视图。
@property (weak, nonatomic) IBOutlet UIImageView *cardIV;
///卡片标签。
@property (weak, nonatomic) IBOutlet UILabel *cardLabel;
///家庭成员图片视图。
@property (weak, nonatomic) IBOutlet UIImageView *familyIV;
///家庭成员标签。
@property (weak, nonatomic) IBOutlet UILabel *familyLabel;
///更多图片视图。
@property (weak, nonatomic) IBOutlet UIImageView *moreIV;
///更多标签。
@property (weak, nonatomic) IBOutlet UIView *deviceControlView;
///更多按钮
@property (weak, nonatomic) IBOutlet UILabel *moreLabel;
///密码按钮
@property (weak, nonatomic) IBOutlet UIView *pwdView;
///临时密码按钮
@property (weak, nonatomic) IBOutlet UIView *tempPwdView;
///指纹按钮
@property (weak, nonatomic) IBOutlet UIView *fingerPrintView;
///卡片按钮
@property (weak, nonatomic) IBOutlet UIView *cardView;
///家庭成员按钮
@property (weak, nonatomic) IBOutlet UIView *familyMemberView;
@property (weak, nonatomic) IBOutlet UILabel *pwdLab;
@property (weak, nonatomic) IBOutlet UILabel *temPwdLab;
///当用户是授权的时候展示的设备信息视图
@property (weak, nonatomic) IBOutlet UIView *setMsgView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIImageView *setDeviceImageView;
@property (weak, nonatomic) IBOutlet UILabel *deviceMsgLabel;
@property (weak, nonatomic) IBOutlet UIImageView *rightArrowImageView;

@end

@implementation KDSDeviceInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
 
    [self viewAddClick];

    if ([self.lock.device.model containsString:@"X5S"])
    {
        self.smallModelIV.image = [UIImage imageNamed:@"型号-x5"];
        self.bigModelIV.image = [UIImage imageNamed:@"设备列表-X5"];
        self.modelLabel.text = [Localized(@"lockModel") stringByAppendingString:@": X5S"];
        self.autoLabel.hidden = NO;
        self.autoLabel.text = self.lock.bleTool.connectedPeripheral.isAutoMode ? Localized(@"autoModeOnDesc") : Localized(@"autoModeOffDesc");
        self.cardLabel.text = Localized(@"doorCard");
        self.familyLabel.text = Localized(@"familyMember");
        self.moreLabel.text = Localized(@"more");
    }else if ([self.lock.device.model containsString:@"X5"]){
        
        self.smallModelIV.image = [UIImage imageNamed:@"型号-x5"];
        self.bigModelIV.image = [UIImage imageNamed:@"设备列表-X5"];
        self.modelLabel.text = [Localized(@"lockModel") stringByAppendingString:@": X5"];
        self.autoLabel.hidden = NO;
        self.autoLabel.text = self.lock.bleTool.connectedPeripheral.isAutoMode ? Localized(@"autoModeOnDesc") : Localized(@"autoModeOffDesc");
        self.cardLabel.text = Localized(@"doorCard");
        self.familyLabel.text = Localized(@"familyMember");
        self.moreLabel.text = Localized(@"more");
        
    }else if ([self.lock.device.model containsString:@"T5S"]){
        self.smallModelIV.image = [UIImage imageNamed:@"deviceT5Small"];
        self.bigModelIV.image = [UIImage imageNamed:@"deviceModelT5S"];
        self.modelLabel.text = [Localized(@"lockModel") stringByAppendingString:@": T5S"];
        self.autoLabel.hidden = YES;
        CGFloat width = ceil([self.modelLabel.text sizeWithAttributes:@{NSFontAttributeName : self.modelLabel.font}].width);
        self.smallModelIVLeftConstrain.constant = (kScreenWidth - 20 - self.smallModelIV.image.size.width - 10 - width) / 2.0;
        self.smallModelIVWidthConstrain.constant = 12;
        //T5没有添加卡片功能
        self.cardIV.image = [UIImage imageNamed:@"家庭成员"];
        self.cardLabel.text = Localized(@"familyMember");
        self.familyIV.image = [UIImage imageNamed:@"更多"];
        self.familyLabel.text = Localized(@"more");
        self.moreIV.image = nil;
        self.moreLabel.text = @"";
    }
    else if ([self.lock.device.model containsString:@"T5"])
    {
        self.smallModelIV.image = [UIImage imageNamed:@"deviceT5Small"];
        self.bigModelIV.image = [UIImage imageNamed:@"设备列表-T5"];
        self.modelLabel.text = [Localized(@"lockModel") stringByAppendingString:@": T5"];
        self.autoLabel.hidden = YES;
        CGFloat width = ceil([self.modelLabel.text sizeWithAttributes:@{NSFontAttributeName : self.modelLabel.font}].width);
        self.smallModelIVLeftConstrain.constant = (kScreenWidth - 20 - self.smallModelIV.image.size.width - 10 - width) / 2.0;
        self.smallModelIVWidthConstrain.constant = 12;
        //T5没有添加卡片功能
        self.cardIV.image = [UIImage imageNamed:@"家庭成员"];
        self.cardLabel.text = Localized(@"familyMember");
        self.familyIV.image = [UIImage imageNamed:@"更多"];
        self.familyLabel.text = Localized(@"more");
        self.moreIV.image = nil;
        self.moreLabel.text = @"";
    }
    if (self.lock.device.model.length == 0) {///没有获取到设备类型
        self.bigModelIV.image = [UIImage imageNamed:@"设备列表-X5"];
    }
    self.pwdLab.text = Localized(@"password");
    self.temPwdLab.text = Localized(@"temporarypassword");
    self.fpLabel.text = Localized(@"fingerprint");
    NSDictionary *attr = @{NSFontAttributeName : self.fpLabel.font};
    [self.fpLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(ceil([self.fpLabel.text sizeWithAttributes:attr].height));
    }];
    [self.cardLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(ceil([self.cardLabel.text sizeWithAttributes:attr].height));
    }];
    [self.familyLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(ceil([self.familyLabel.text sizeWithAttributes:attr].height));
    }];
    [self.moreLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(ceil([self.moreLabel.text sizeWithAttributes:attr].height));
    }];
    ///加载的时候如果是被授权的锁则不显示锁的一些设置详情只显示设备信息
    if (!self.lock.device.is_admin.boolValue) {///普通用户
        self.deviceControlView.hidden = YES;
        self.setMsgView.hidden = NO;
        self.deviceMsgLabel.text = Localized(@"deviceInfo");
        self.deviceMsgLabel.font = [UIFont systemFontOfSize:14];
        self.deviceMsgLabel.textAlignment = NSTextAlignmentLeft;
        self.setMsgView.userInteractionEnabled = YES;
        self.setMsgView.layer.masksToBounds = YES;
        self.setMsgView.layer.cornerRadius = 5;
        self.rightArrowImageView.image = [UIImage imageNamed:@"right"];
        self.setDeviceImageView.image = [UIImage imageNamed:@"设备信息"];
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        [self.setMsgView addGestureRecognizer:tap];
        [self.topView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(10);
            make.left.mas_equalTo(10);
            make.right.mas_equalTo(-10);
            make.bottom.mas_equalTo(self.setMsgView.mas_top).offset(-10);
        }];
    }else{///管理员
        self.deviceControlView.hidden = NO;
        self.setMsgView.hidden = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lockDidReport:) name:KDSLockDidReportNotification object:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationTitleLabel.text = self.lock.name;
    self.stateLabel.text = !self.lock.bleTool.connectedPeripheral ? [Localized(@"lockOutOfScope") stringByReplacingOccurrencesOfString:@"\n" withString:@" "] : nil;
    int power = self.lock.bleTool.connectedPeripheral ? self.lock.bleTool.connectedPeripheral.power : -1;
    NSString *imgName = [KDSTool imageNameForPower:power];
    UIImage *image = [UIImage imageNamed:imgName];
    self.powerIV.image = image;
    NSString *text, *suffix;
    if (power < 0)
    {
        suffix = [NSString stringWithFormat:@"(%@)", Localized(@"none")];
        text = [NSString stringWithFormat:@"%@:%@", Localized(@"lockEnergy"), suffix];
    }
    else
    {
        suffix = [NSString stringWithFormat:@"(%@)", Localized(@"justNow")];
        text = [NSString stringWithFormat:@"%@:%d%%%@", Localized(@"lockEnergy"), power, suffix];
    }
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName:self.powerLabel.font, NSForegroundColorAttributeName:self.powerLabel.textColor}];
    [attrString addAttributes:@{NSForegroundColorAttributeName : KDSRGBColor(0x8c, 0x8c, 0x8c)} range:[text rangeOfString:suffix]];
    self.powerLabel.attributedText = attrString;
    CGSize size = [text sizeWithAttributes:@{NSFontAttributeName : self.powerLabel.font}];
    [self.powerIV mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.powerIV.superview).offset(-18);
        make.left.equalTo(self.view).offset((kScreenWidth - image.size.width - 5 - ceil(size.width)) / 2);
        make.size.mas_equalTo(image.size);
    }];
    [self.powerLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.powerIV);
        make.left.equalTo(self.powerIV.mas_right).offset(5);
        make.size.mas_equalTo((CGSize){ceil(size.width), ceil(size.height)});
    }];
    __weak typeof(self) weakSelf = self;
    [self.lock.bleTool getLockInfo:^(KDSBleError error, KDSBleLockInfoModel * _Nullable infoModel) {
        if (infoModel)
        {
            uint32_t state = infoModel.lockState;
            weakSelf.lock.bleTool.connectedPeripheral.isAutoMode = (state>>7) & 0x1;
            weakSelf.autoLabel.text = weakSelf.lock.bleTool.connectedPeripheral.isAutoMode ? Localized(@"autoModeOnDesc") : Localized(@"autoModeOffDesc");
        }
    }];
}

-(void)viewAddClick{
    __weak typeof(self) weakSelf = self;
    [self.pwdView addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
        if (!weakSelf.lock.device.is_admin.boolValue)
        {
            [MBProgressHUD showError:Localized(@"noAuthorization")];
            return;
        }
        KDSPwdListViewController *PVC = [[KDSPwdListViewController alloc] init];
        PVC.lock = weakSelf.lock;
        [weakSelf.navigationController pushViewController:PVC animated:YES];
    }];
    [self.tempPwdView addTapActionWithBlock:^(UIGestureRecognizer *gestureRecoginzer) {
        if (!weakSelf.lock.device.is_admin.boolValue)
        {
            [MBProgressHUD showError:Localized(@"noAuthorization")];
            return;
        }
         KDSTemPwdlistdViewController *TVC = [[KDSTemPwdlistdViewController alloc] init];
        TVC.lock = weakSelf.lock;
        [weakSelf.navigationController pushViewController:TVC animated:YES];
    }];
}

#pragma mark - 控件等事件方法。
///点击“更多”设置视图跳转更多设置界面。
- (IBAction)tapMoreSettingViewGotoMoreSetting:(UITapGestureRecognizer *)sender
{
    if (![self.lock.device.model containsString:@"X5"]) return;
    if (!self.lock.device.is_admin.boolValue)
    {
        [MBProgressHUD showError:Localized(@"noAuthorization")];
        return;
    }
    KDSLockMoreSettingVC *vc = [[KDSLockMoreSettingVC alloc] init];
    vc.lock = self.lock;
    [self.navigationController pushViewController:vc animated:YES];
}
-(void)tapAction:(UITapGestureRecognizer *)tap{
    KDSLockParamVC *vc = [[KDSLockParamVC alloc] init];
    vc.lock = self.lock;
    [self.navigationController pushViewController:vc animated:YES];
}
///点击添加家庭成员。
- (IBAction)tapFamilyMemberViewGotoAddMember:(UITapGestureRecognizer *)sender
{
    if (!self.lock.device.is_admin.boolValue)
    {
        [MBProgressHUD showError:Localized(@"noAuthorization")];
        return;
    }
    if ([self.lock.device.model containsString:@"X5"])
    {
        KDSFamilyMemberlistVC *FVC = [[KDSFamilyMemberlistVC alloc] init];
        FVC.lock = self.lock;
        [self.navigationController pushViewController:FVC animated:YES];
    }
    else
    {
        KDSLockMoreSettingVC *vc = [[KDSLockMoreSettingVC alloc] init];
        vc.lock = self.lock;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

///点击指纹查看/添加指纹。
- (IBAction)tapFingerprintViewGotoAddFingerprint:(UITapGestureRecognizer *)sender
{
    if (!self.lock.device.is_admin.boolValue)
    {
        [MBProgressHUD showError:Localized(@"noAuthorization")];
        return;
    }
    KDSFingerprintManaViewController *fpVC = [[KDSFingerprintManaViewController alloc] init];
    fpVC.lock = self.lock;
    [self.navigationController pushViewController:fpVC animated:YES];
}

///点击卡片查看/添加卡片
- (IBAction)tapCardViewGotoAddCard:(UITapGestureRecognizer *)sender
{
    if (!self.lock.device.is_admin.boolValue)
    {
        [MBProgressHUD showError:Localized(@"noAuthorization")];
        return;
    }
    if ([self.lock.device.model containsString:@"X5"])
    {
        KDSCardListViewController * CVC = [[KDSCardListViewController alloc] init];
        CVC.lock = self.lock;
        [self.navigationController pushViewController:CVC animated:YES];
    }
    else
    {
        KDSFamilyMemberlistVC *FVC = [[KDSFamilyMemberlistVC alloc] init];
        FVC.lock = self.lock;
        [self.navigationController pushViewController:FVC animated:YES];
    }
}

#pragma mark - 通知相关方法
///锁上报信息。
- (void)lockDidReport:(NSNotification *)noti
{
    CBPeripheral *peripheral = (CBPeripheral *)noti.userInfo[@"peripheral"];
    NSData *data = (NSData *)noti.userInfo[@"data"];
    if (peripheral != self.lock.bleTool.connectedPeripheral || data.length != 20) return;
    Byte *bytes = (Byte *)data.bytes;
    if (bytes[5] == 9)
    {
        self.autoLabel.text = ((bytes[6] >> 4) & 0x1) ? Localized(@"autoModeOnDesc") : Localized(@"autoModeOffDesc");
    }
}

#pragma mark - KDSBluetoothToolDelegate
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristicOfLockState:(NSData *)value
{
    self.autoLabel.text = self.lock.bleTool.connectedPeripheral.isAutoMode ? Localized(@"autoModeOnDesc") : Localized(@"autoModeOffDesc");
}

@end
