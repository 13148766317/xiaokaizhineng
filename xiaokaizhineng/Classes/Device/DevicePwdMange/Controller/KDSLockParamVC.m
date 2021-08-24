//
//  KDSLockParamVC.m
//  xiaokaizhineng
//
//  Created by orange on 2019/2/14.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSLockParamVC.h"
#import "Masonry.h"
#import "KDSHttpManager+Ble.h"
#import "MBProgressHUD+MJ.h"
#import "KDSDFUViewController.h"

@interface KDSLockParamVC ()

///序列号子标签。
@property (nonatomic, weak) UILabel *snSLabel;
///型号子标签。
@property (nonatomic, weak) UILabel *modelSLabel;
///固件版本子标签。
@property (nonatomic, weak) UILabel *hardwareVerSLabel;
///蓝牙软件版本子标签。
@property (nonatomic, weak) UILabel *softwareVerSLabel;

@end

@implementation KDSLockParamVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationTitleLabel.text = Localized(@"deviceInfo");
    CGFloat labelHeight = 60;
    CGFloat separatorHeight = 0.5;
    UIView *containView = [[UIView alloc] init];
    containView.layer.cornerRadius = 5;
    containView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:containView];
    [containView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self.view).offset(10);
        make.right.equalTo(self.view).offset(-10);
        make.height.mas_equalTo(labelHeight * 4 + separatorHeight * 3);
    }];
    
    UILabel *snLabel = [self createLabelWithTitle:Localized(@"serialNumber") height:labelHeight];
    UILabel *modelLabel = [self createLabelWithTitle:Localized(@"deviceModel") height:labelHeight];
    UILabel *hardwareVerLabel = [self createLabelWithTitle:Localized(@"hardwareVersion") height:labelHeight];
    UILabel *softwareVerLabel = [self createLabelWithTitle:Localized(@"softwareVersion") height:labelHeight];
    
    [containView addSubview:snLabel];
    [containView addSubview:modelLabel];
    [containView addSubview:hardwareVerLabel];
    [containView addSubview:softwareVerLabel];
    
    CBPeripheral *peripheral = self.lock.bleTool.connectedPeripheral;
    NSString * softwareStr;
    if ([peripheral.softwareVer containsString:@"-"]) {
        softwareStr = [peripheral.softwareVer componentsSeparatedByString:@"-"].firstObject;
    }else{
        softwareStr = peripheral.softwareVer;
    }
    UILabel *snSLabel = [self createSublabelWithSubtitle:peripheral.serialNumber height:labelHeight];
    UILabel *modelSLabel = [self createSublabelWithSubtitle:peripheral.lockModelType height:labelHeight];
    UILabel *hardwareVerSLabel = [self createSublabelWithSubtitle:peripheral.hardwareVer height:labelHeight];
    UILabel *softwareVerSLabel = [self createSublabelWithSubtitle:softwareStr height:labelHeight];
    
    UIImageView *softwareVerImgV = [self createArrowImgView];
    [containView addSubview:softwareVerImgV];
    
    softwareVerSLabel.userInteractionEnabled=YES;
    UITapGestureRecognizer *labelTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(softwareVerSLabelTouchUpInside:)];
    [softwareVerSLabel addGestureRecognizer:labelTapGestureRecognizer];
    
    [containView addSubview:snSLabel];
    [containView addSubview:modelSLabel];
    [containView addSubview:hardwareVerSLabel];
    [containView addSubview:softwareVerSLabel];
    self.snSLabel = snSLabel;
    self.modelSLabel = modelSLabel;
    self.hardwareVerSLabel = hardwareVerSLabel;
    self.softwareVerSLabel = softwareVerSLabel;
    
    UIView *separator1 = [self createSeparatorView];
    UIView *separator2 = [self createSeparatorView];
    UIView *separator3 = [self createSeparatorView];
    [containView addSubview:separator1];
    [containView addSubview:separator2];
    [containView addSubview:separator3];
    
    [snLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(containView);
        make.left.equalTo(containView).offset(13);
        make.height.mas_equalTo(labelHeight);
    }];
    [snSLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(containView);
        make.right.equalTo(containView).offset(-24);
        make.height.mas_equalTo(labelHeight);
    }];
    [separator1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(containView).offset(13);
        make.right.equalTo(containView).offset(-13);
        make.top.equalTo(snLabel.mas_bottom);
        make.height.mas_equalTo(separatorHeight);
    }];
    
    [modelLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(separator1.mas_bottom);
        make.left.equalTo(containView).offset(13);
        make.height.mas_equalTo(labelHeight);
    }];
    [modelSLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(separator1.mas_bottom);
        make.right.equalTo(containView).offset(-24);
        make.height.mas_equalTo(labelHeight);
    }];
    [separator2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.height.equalTo(separator1);
        make.top.equalTo(modelLabel.mas_bottom);
    }];
    
    [hardwareVerLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(separator2.mas_bottom);
        make.left.equalTo(containView).offset(13);
        make.height.mas_equalTo(labelHeight);
    }];
    [hardwareVerSLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(separator2.mas_bottom);
        make.right.equalTo(containView).offset(-24);
        make.height.mas_equalTo(labelHeight);
    }];
    [separator3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.height.equalTo(separator1);
        make.top.equalTo(hardwareVerLabel.mas_bottom);
    }];
    
    [softwareVerLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(separator3.mas_bottom);
        make.left.equalTo(containView).offset(13);
        make.height.mas_equalTo(labelHeight);
    }];
    [softwareVerSLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(separator3.mas_bottom);
        make.right.equalTo(containView).offset(-24);
        make.height.mas_equalTo(labelHeight);
    }];
    [softwareVerImgV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(softwareVerSLabel);
        make.right.equalTo(containView).offset(-10);
    }];
    
}

///创建一个左边显示的标签。
- (UILabel *)createLabelWithTitle:(NSString *)title height:(CGFloat)height
{
    UILabel *label = [[UILabel alloc] init];
    label.textColor = KDSRGBColor(0x2b, 0x2f, 0x50);
    label.font = [UIFont systemFontOfSize:12];
    label.text = title;
//    label.backgroundColor = UIColor.yellowColor;
    CGSize size = [title sizeWithAttributes:@{NSFontAttributeName : label.font}];
    label.bounds = CGRectMake(0, 0, ceil(size.width), height);
    return label;
}

///创建一个右边显示的子标签。
- (UILabel *)createSublabelWithSubtitle:(NSString *)subtitle height:(CGFloat)height
{
    UILabel *label = [[UILabel alloc] init];
    label.textColor = KDSRGBColor(0xc2, 0xc2, 0xc2);
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:12];
    label.text = subtitle;
//    label.backgroundColor = UIColor.redColor;
    CGSize size = [subtitle sizeWithAttributes:@{NSFontAttributeName : label.font}];
    label.bounds = CGRectMake(0, 0, ceil(size.width), height);
    return label;
}
-(UIImageView *)createArrowImgView{
    UIImage *img = [UIImage imageNamed:@"right"];
    UIImageView *imgV = [[UIImageView alloc] init];
    imgV.image = img;
    imgV.contentMode = UIViewContentModeScaleAspectFit;
    return imgV;
}

///创建一条分隔线。
- (UIView *)createSeparatorView
{
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = KDSRGBColor(0xf0, 0xf0, 0xf0);
    return view;
}
#pragma mark -lab点击事件
-(void)softwareVerSLabelTouchUpInside:(UITapGestureRecognizer *)recognizer{
    UILabel *label=(UILabel*)recognizer.view;
    NSLog(@"%@被点击了",label.text);
    if (self.lock.bleTool.isBinding) {
        
        if(self.lock.bleTool.connectedPeripheral.power < 20){
            [MBProgressHUD showError:Localized(@"low power cannot OTA")];
            return;
        }
        //蓝牙本地固件版本号
        NSString *softwareRev = [self parseBluetoothVersion];
        
        if ([self.lock.device.peripheralId isEqualToString:self.lock.bleTool.connectedPeripheral.identifier.UUIDString]
            &&[self.lock.device.deviceSN isEqualToString:self.lock.bleTool.connectedPeripheral.serialNumber]
            &&[self.lock.device.softwareVersion isEqualToString:softwareRev]) {
            //蓝牙连接上才检查固件
            [self checkBleOTA];
        }else{
            //服务器无蓝牙UUID，需要更新服务器上蓝牙的UUID
            [self updateSoftwareVersion];
        }
    }
    else{
        [MBProgressHUD showError:Localized(@"bleNotConnect")];
    }
    
}

#pragma mark - KDSBluetoothToolDelegate
- (void)didReceiveDeviceElctInfo:(int)elct
{
    CBPeripheral *peripheral = self.lock.bleTool.connectedPeripheral;
    self.snSLabel.text = peripheral.serialNumber;
    self.modelSLabel.text = peripheral.lockModelType;
    self.hardwareVerSLabel.text = peripheral.hardwareVer;
    self.softwareVerSLabel.text = peripheral.softwareVer;
}

#pragma mark 内部方法
/**
 解析蓝牙版本为存数字的字符串以便比较大小
 @return 蓝牙版本
 */
-(NSString *)parseBluetoothVersion{
    
    //截取出字符串后带了\u0000
    //NSString *bleVesion = [self.lock.bleTool.connectedPeripheral.softwareVer componentsSeparatedByString:@"-"].lastObject;
    NSString *bleVesion ;
    
    if (!self.lock.bleTool.connectedPeripheral.softwareVer.length) {
        bleVesion = [self.lock.device.softwareVersion componentsSeparatedByString:@"-"].firstObject;
    }else{
        bleVesion = [self.lock.bleTool.connectedPeripheral.softwareVer componentsSeparatedByString:@"-"].firstObject;
    }
    
    //去掉NSString中的\u0000
    if (bleVesion.length > 9) {
        //挽救K9S第一版本的字符串带\u0000错误
        bleVesion = [bleVesion substringToIndex:9];
    }
    //去掉NSString中的V
    bleVesion = [bleVesion stringByReplacingOccurrencesOfString:@"V" withString:@""];
    //带T为测试固件
    bleVesion = [bleVesion stringByReplacingOccurrencesOfString:@"T" withString:@""];
    
    return bleVesion;
}
//Unicode 转字符串
- (NSString *)replaceUnicode:(NSString *)unicodeStr
{
    NSString *tempStr1 = [unicodeStr stringByReplacingOccurrencesOfString:@"\\u"withString:@"\\U"];
    NSString *tempStr2 = [tempStr1 stringByReplacingOccurrencesOfString:@"\""withString:@"\\\""];
    NSString *tempStr3 = [[@"\""stringByAppendingString:tempStr2] stringByAppendingString:@"\""];
    NSData *tempData = [tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
    NSString* returnStr = [NSPropertyListSerialization propertyListWithData:tempData options:NSPropertyListImmutable format:NULL error:NULL];
    return [returnStr stringByReplacingOccurrencesOfString:@"\\r\\n"withString:@"\n"];
}
#pragma mark 网络请求
///检查蓝牙固件是否需要升级
- (void)checkBleOTA{
    
    //蓝牙本地固件版本号
    NSString *softwareRev = [self parseBluetoothVersion];
    
    NSString *deviceSN ;
    if (!self.lock.device.deviceSN.length) {
        deviceSN = self.lock.bleTool.connectedPeripheral.serialNumber ;
    }else{
        deviceSN = self.lock.device.deviceSN ;
    }
    if (!self.lock.device.is_admin.boolValue) {
        [MBProgressHUD showError:@"授权用户暂无升级权限"];
        return;
    }
    
    NSLog(@"--{Kaadas}--检查OTA的softwareRev:%@",softwareRev);
    NSLog(@"--{Kaadas}--检查OTA的deviceSN:%@",deviceSN);
    //    [self chooseOTASolution:@"http://47.106.94.189/otaFiles/1c63f74f2e6643578831f0f6e1412ca7?filename=S8C_FPC_A_cn2_OTA_M0_V1.01.015.cyacd2"];
    //    [self chooseOTASolution:@"http://47.106.94.189/otaFiles/6de26b8f0d8847a69eb83e8075168a95?filename=K9S_FPC_A_cn2_OTA_M0_T1.02.010.cyacd2"];
    [[KDSHttpManager sharedManager] checkBleOTAWithSerialNumber:deviceSN withCustomer:2 withVersion:softwareRev success:^(NSString *URL) {
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:Localized(@"tips") message:Localized(@"newImage") preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            //            NSLog(@"--{Kaadas}--URL==%@",URL);
            [self chooseOTASolution:URL];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:Localized(@"cancel") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            //            [self.lock.bleTool endConnectPeripheral:self.lock.bleTool.connectedPeripheral];
        }];
        [ac addAction:okAction];
        [ac addAction:cancelAction];
        [self presentViewController:ac animated:YES completion:nil];
        
    } error:^(NSError * _Nonnull error) {
        
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:Localized(@"Lock OTA upgrade") message:[NSString stringWithFormat:@"%@",error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [ac addAction:okAction];
        [self presentViewController:ac animated:YES completion:nil];
        
    } failure:^(NSError * _Nonnull error) {
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:Localized(@"Lock OTA upgrade") message:[NSString stringWithFormat:@"%@",error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [ac addAction:okAction];
        [self presentViewController:ac animated:YES completion:nil];
    }];
}
//修改设备固件版本
-(void)updateSoftwareVersion{
    
    NSString *softwareVer = self.lock.bleTool.connectedPeripheral.softwareVer;
    if (softwareVer.length > 9) {
        softwareVer = [self.lock.bleTool.connectedPeripheral.softwareVer substringWithRange:NSMakeRange(1,8)];
    }
    
    [[KDSHttpManager sharedManager] updateSoftwareVersion:softwareVer withDevname:self.lock.device.device_name withUser_id:[KDSUserManager sharedManager].user.uid withDeviceSN:self.lock.bleTool.connectedPeripheral.serialNumber withPeripheralId:self.lock.bleTool.connectedPeripheralWithIdentifier.UUIDString success:^{
        //蓝牙连接上才检查固件
        [self checkBleOTA];
        
    } error:^(NSError * _Nonnull error) {
        
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:Localized(@"NetworkCauseConnectionFailure") message:[NSString stringWithFormat:@"%@",error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [ac addAction:okAction];
        [self presentViewController:ac animated:YES completion:nil];
        
    } failure:^(NSError * _Nonnull error) {
        
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:Localized(@"NetworkCauseConnectionFailure") message:[NSString stringWithFormat:@"%@",error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [ac addAction:okAction];
        [self presentViewController:ac animated:YES completion:nil];
    }];
}
#pragma mark - 选择OTA升级方案
///根据OTA启动服务FFD0和1802，来选择TI、Psco6升级方案
-(void)chooseOTASolution:(NSString *)url{
    
    BOOL hasResetOTAServer = NO;
    for (CBService *service in self.lock.bleTool.connectedPeripheral.services) {
        //检测到OAD启动服务:FFD0 ---> TI方案
        KDSLog(@"--{Kaadas}--service.UUID==%@",service.UUID.UUIDString);
        //        if ([service.UUID.UUIDString isEqualToString: OADResetServiceUUID]) {
        //            KDSLog(@"--{Kaadas}--检测到OAD启动服务:FFD0->TI方案");
        //            KDSOADVC *otaVC = [[KDSOADVC alloc]init];
        //            otaVC.url = url;
        //            otaVC.lock = self.lock;
        //            hasResetOTAServer = YES;
        //            //            [self.lock.bleTool.centralManager cancelPeripheralConnection: self.lock.bleTool.connectedPeripheral];
        //            [self.navigationController pushViewController:otaVC animated:YES];
        //        }
        //        else
        if ([service.UUID.UUIDString isEqualToString: DFUResetServiceUUID]) {
            KDSLog(@"--{Kaadas}--检测到DFU启动服务:1802->P6方案");
            //检测到DFU启动服务:1802->P6方案
            KDSDFUViewController *dfuVC = [[KDSDFUViewController alloc]init];
            dfuVC.url = url;
            dfuVC.isBootLoadModel = YES;
            dfuVC.lock = self.lock;
            hasResetOTAServer = YES;
            //            [self.lock.bleTool.centralManager cancelPeripheralConnection: self.lock.bleTool.connectedPeripheral];
            [self.navigationController pushViewController:dfuVC animated:YES];
        }
    }
    //蓝牙升级服务未读取到
    hasResetOTAServer?:[MBProgressHUD showSuccess:@"蓝牙信息获取不完整，请稍后再试"];
}
@end
