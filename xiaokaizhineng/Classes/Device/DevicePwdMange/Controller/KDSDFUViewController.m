//
//  KDSDFUViewController.m
//  xiaokaizhineng
//
//  Created by wzr on 2019/8/8.
//  Copyright © 2019 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSDFUViewController.h"
#import "KDSBreakpointDownload.h"
#import "MBProgressHUD+MJ.h"
#import "KDSBluetoothTool.h"
#import "OTAFileParser.h"
#import "Utilities.h"
#import "BootLoaderServiceModel.h"
#import "CyCBManager.h"
#import "KDSHttpManager.h"
#import "NSTimer+KDSBlock.h"


#define WRITE_WITH_RESP_MAX_DATA_SIZE   133
#define WRITE_NO_RESP_MAX_DATA_SIZE   300

// 获取Documents目录路径
#define PATHDOCUMNT  [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]

@interface KDSDFUViewController ()<BreakpointDownloadDelegate,KDSBluetoothToolDelegate>
{
    BootLoaderServiceModel *bootloaderModel;
    
    NSMutableArray *currentRowDataArray;
    uint32_t currentRowDataAddress;
    uint32_t currentRowDataCRC32;
    
    BOOL isBootloaderCharacteristicFound, isWritingFile1;
    int currentRowNumber, currentIndex;
    int maxDataSize;
    
    NSArray *firmwareFileList, *fileRowDataArray;
    NSDictionary *fileHeaderDict;
    NSDictionary *appInfoDict;
    
}

@property(nonatomic,copy)NSString * binFileName;

@end

@implementation KDSDFUViewController

-(void)navBackClick{
    KDSLog(@"--{Kaadas}--点击返回");
    if (_startUpgradingBtn.enabled) {
        self.lock.bleTool.isBinding = NO;//断开蓝牙前，把标志位置为NO
        [self.lock.bleTool.centralManager cancelPeripheralConnection: self.lock.bleTool.connectedPeripheral];
        [self.navigationController popViewControllerAnimated:YES];
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = Localized(@"锁DFU升级");
    self.navigationTitleLabel.text = Localized(@"Lock OTA upgrade");
    //OTA前先断开蓝牙
    if (!_isBootLoadModel) {
        self.lock.bleTool.isBinding = NO;//断开蓝牙前，把标志位置为NO
        [self.lock.bleTool.centralManager cancelPeripheralConnection: self.lock.bleTool.connectedPeripheral];
    }
    _currentProgressView.progress = 0.01;
    //下载进度 通知
    ///设置下载代理
    [KDSBreakpointDownload manager].delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadEventNotification:) name:KDSBreakpointDownloadEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkReachabilityStatusDidChange:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopOTA) name:@"OTAStateNotify" object:nil];
    // Do any additional setup after loading the view from its nib.
}


#pragma mark 按钮点击事件
- (IBAction)startUpgrading:(id)sender {
    NSLog(@"--00--00--startUpgrading");
    //检测固件并下载
    self.Psoc6DFUCurrentStatus.text = Localized(@"正在升级,请勿操作...");
    [self checkBinWithUpdateURL];
}
-(void)checkBinWithUpdateURL{
    //获取固件文件名
//    NSString *fileName = [[NSUserDefaults standardUserDefaults] objectForKey:BluetoothBin] ;
//    //     获取Documents目录路径
//    NSString *docDir = PATHDOCUMNT;
//    //    文件名，一般跟服务器端的文件名一致
//    NSString *file = [docDir stringByAppendingPathComponent:fileName];
//    // 创建NSFileManager
//    NSFileManager *fileManager = [NSFileManager defaultManager];
    //判断文件是否存在
    //    if([fileManager fileExistsAtPath:file]){
    //        NSLog(@"--{Kaadas}--文件存在");
    ////        [self connectBLE];
    //    }
    //    else{
    //本地未保存最新固件
    [self startDownloadWithUpdateURL];
    //    }
}
-(void)startDownloadWithUpdateURL{
    _icon1Img.highlighted = YES;
    [[KDSBreakpointDownload manager] startDownloadWithURL:self.url];
}
///连接蓝牙
//-(void)connectBLE{
//    NSLog(@"--00--00--连接蓝牙=%@",_dev.peripheral);
//    [self.bluetoothTool.centralManager connectPeripheral:_dev.peripheral options:nil];
//}
///进入DFU升级流程
-(void)DFUProcess{
    KDSLog(@"--{Kaadas}--resetDFU");
    if (self.lock.bleTool.connectedPeripheral) {
        [self.lock.bleTool resetDFU:self.lock.bleTool.connectedPeripheral];
    }else{
        [MBProgressHUD showError:Localized(@"bleNotConnect")];
        _startUpgradingBtn.enabled = YES;
        [self.navigationController popViewControllerAnimated:YES];
        
    }
    _icon2Img.highlighted = YES;
}

#pragma mark BreakpointDownloadDelegate
-(void)breakpointDownloadDone{
    _line1Img.highlighted = YES;
    KDSLog(@"--00--00--==下载完成bin文件成功");
    //重连
    if (self.lock.bleTool.connectedPeripheral) {
        [self.lock.bleTool.centralManager connectPeripheral:self.lock.bleTool.connectedPeripheral options:nil];
    }else{
        [MBProgressHUD showError:Localized(@"bleNotConnect")];
        _startUpgradingBtn.enabled = YES;
        [self.navigationController popViewControllerAnimated:YES];
    }
    
}
#pragma mark - KDSBluetoothDelegate
//解析bin文件
-(void)startDFUProcess{
    if (!_line2Img.highlighted) {
        return;
    }
    _icon3Img.highlighted = YES;
    //获取固件文件名
    NSString *fileName = [[NSUserDefaults standardUserDefaults] objectForKey:BluetoothBin] ;
    // 获取Documents目录路径
    NSString *docDir = PATHDOCUMNT;
    //文件名，一般跟服务器端的文件名一致
    NSString *file = [docDir stringByAppendingPathComponent:fileName];
    // 创建NSFileManager
    NSFileManager *fileManager = [NSFileManager defaultManager];
    __weak typeof(self) weakSelf = self;
    if (self.lock.bleTool.connectedPeripheral.state == CBPeripheralStateConnected) {
        OTAFileParser *fileParser = [OTAFileParser new];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            ///开始解析固件
            [fileParser parseFirmwareFileWithName_v1:fileName path:docDir onFinish:^(NSMutableDictionary *header, NSDictionary *appInfo, NSArray *rowData, NSError *error) {
                if(error) {
                    NSLog(@"--{Kaadas}--OTAError");
                    [MBProgressHUD showError:error.localizedDescription];
                    
                } else if (header && rowData) {
                    NSLog(@"--{Kaadas}--header && rowData");
                    ///固件头，App检验固件？
                    NSLog(@"--{Kaadas}--header==%@",header);
                    ///固件大小和写flash地址
                    NSLog(@"--{Kaadas}--appInfo==%@",appInfo);
                    ///Address行地址，CRC32：行检验值，DataArrays：包数据
                    NSLog(@"--{Kaadas}--rowData==%@",rowData);
                    
                    self->fileHeaderDict = header;
                    self->appInfoDict = appInfo;
                    self->fileRowDataArray = rowData;
                    [self initializeFileTransfer_v1];
                }
            }];
        });
    }
}

/**鉴权成功，进入OTA升级流程 */
- (void)didAuthenticationSuccess{
    KDSLog(@"--00--00--进入OTA升级流程");
    //进入DFU升级流程
    [self DFUProcess];
}
/**检测手机蓝牙状态*/
- (void)discoverManagerDidUpdateState:(CBCentralManager *)central{
    if (@available(iOS 10.0, *)) {
        if (central.state != CBManagerStatePoweredOn)
        {
            [MBProgressHUD showError:Localized(@"请打开手机蓝牙")];
        }
    } else {
        // Fallback on earlier versions
    }
}
/**发现蓝牙设备*/
- (void)didDiscoverPeripheral:(CBPeripheral *)peripheral{
    //如果是需要解绑/绑定的设备，那么去连接它
    if (peripheral.identifier == self.peripheralWithIdentifier
        // && [peripheral.advDataLocalName containsString:@"Bootloader"]
        ) {
        //如果发现的设备和传过来的名称一致，连接蓝牙
        //KDSLog(@"--00--00--发现设备==%@",peripheral);
        KDSLog(@"--00--00--发现设备==00==%@",peripheral.advDataLocalName );
        [self.bluetoothTool beginConnectPeripheral:peripheral];
    }
}
/**连接上蓝牙设备*/
- (void)didConnectPeripheral:(CBPeripheral *)peripheral{
    KDSLog(@"--{Kaadas}--连接上蓝牙设备");
    if (peripheral.identifier == self.lock.bleTool.connectedPeripheralWithIdentifier) {
        NSLog(@"--{Kaadas}--相等");
        if (self.lock.bleTool.isBinding&&_icon1Img.highlighted&&_line1Img.highlighted) {
            NSLog(@"--{Kaadas}--鉴权完成和下载完成");
            [self DFUProcess];
        }
        if (self.lock.bleTool.isBinding&&_icon1Img.highlighted&&_line1Img.highlighted&&_icon2Img.highlighted) {
            NSLog(@"--{Kaadas}--进入升级状态DFU");
            _line2Img.highlighted = YES;
            self.countdown = 15;
            //做个超时15s，第3点没亮
            __weak typeof(self) weakSelf = self;
            NSTimer *timer = [NSTimer kdsScheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
                if (weakSelf.countdown < 0 || !weakSelf)
                {
                    [timer invalidate];
                    weakSelf.countdown = 15;
                    if(!weakSelf.line3Img.highlighted){
                        [self otaFail];
                    }
                    return;
                }
                weakSelf.countdown--;
                NSLog(@"--{Kaadas}--countdown=%ld",(long)weakSelf.countdown);
            }];
            [timer fire];
        }
        if (_isBootLoadModel) {
            _icon2Img.highlighted = YES;
            _line2Img.highlighted = YES;
        }
    }
    else{
        NSLog(@"--{Kaadas}--不相等");
    }
}

/**断开连接蓝牙设备*/
- (void)didDisConnectPeripheral:(CBPeripheral *_Nonnull)peripheral{
    KDSLog(@"--{Kaadas}--断开蓝牙设备");
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive){//应用程序运行在前台,目前接收事件。
        if (_icon4Img.highlighted) {
            KDSLog(@"--{Kaadas}--升级完成完成状态图%@",peripheral);
            return;
        }
        if (_icon3Img.highlighted) {
            KDSLog(@"--{Kaadas}--正在升级状态图，%@",peripheral);
            [MBProgressHUD showError:Localized(@"bleNotConnect")];
            _startUpgradingBtn.enabled = YES;
            [self.navigationController popViewControllerAnimated:YES];
            return;
        }
        if (_icon2Img.highlighted) {
            KDSLog(@"--{Kaadas}--进入升级状态=%@",peripheral);
            //若不是升级完成则重连
            [self.lock.bleTool.centralManager connectPeripheral:peripheral options:nil];
            return;
        }
        if (_icon1Img.highlighted && _line1Img.highlighted) {
            KDSLog(@"--{Kaadas}--准备进入升级状态=%@",peripheral);
            [self.lock.bleTool.centralManager connectPeripheral:peripheral options:nil];
            return;
        }
    }
    else {
        if (_icon1Img.highlighted) {
            //已开始升级
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

#pragma mark - OTA Upgrade
/*!
 *  @method initializeFileTransfer_v1
 *
 *  @discussion Method to begin file transter (CYACD2)
 *
 */
-(void) initializeFileTransfer_v1 {
    ///初始化BootLoaderServiceModel
    [self initServiceModel];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self->isBootloaderCharacteristicFound) {
            self->currentIndex = 0;
            [self registerForBootloaderCharacteristicNotifications_v1];
            self->bootloaderModel.fileVersion = [[self->fileHeaderDict objectForKey:FILE_VERSION] integerValue];
            // Set checksum type
            if ([[self->fileHeaderDict objectForKey:CHECKSUM_TYPE] integerValue]) {
                [self->bootloaderModel setCheckSumType:CRC_16];
            } else {
                [self->bootloaderModel setCheckSumType:CHECK_SUM];
            }
            [self sendEnterBootloaderCmd];
        }
        else{
            [self initServiceModel];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self->isBootloaderCharacteristicFound) {
                    self->currentIndex = 0;
                    [self registerForBootloaderCharacteristicNotifications_v1];
                    self->bootloaderModel.fileVersion = [[self->fileHeaderDict objectForKey:FILE_VERSION] integerValue];
                    // Set checksum type
                    if ([[self->fileHeaderDict objectForKey:CHECKSUM_TYPE] integerValue]) {
                        [self->bootloaderModel setCheckSumType:CRC_16];
                    } else {
                        [self->bootloaderModel setCheckSumType:CHECK_SUM];
                    }
                    [self sendEnterBootloaderCmd];
                }
                else{
                    [self otaFail];
                }
            });
        }
    });
}

/*!
 *  @method initServiceModel
 *
 *  @discussion Method to initialize the bootloader model
 *
 */
-(void) initServiceModel
{
    if (!bootloaderModel)
    {
        //bootloaderModel = [[BootLoaderServiceModel alloc] initWithPeripheral:_dev.peripheral];
        bootloaderModel = [[BootLoaderServiceModel alloc] init];
    }
    [bootloaderModel discoverService:self.lock.bleTool.connectedPeripheral.services  peripheral:self.lock.bleTool.connectedPeripheral CharacteristicsWithCompletionHandler:^(BOOL success, NSError *error)
     {
         if (success)
         {
             NSLog(@"--{Kaadas}--发现DFU特征");
             self->isBootloaderCharacteristicFound = YES;
             if (self->bootloaderModel.isWriteWithoutResponseSupported)
             {
                 self->maxDataSize = WRITE_NO_RESP_MAX_DATA_SIZE;
             }
             else
             {
                 self->maxDataSize = WRITE_WITH_RESP_MAX_DATA_SIZE;
             }
         }
         else{
             NSLog(@"--{Kaadas}--没发现DFU特征");
         }
     }];
}

/*!
 *  @method handleCharacteristicUpdates_v1
 *
 *  @discussion Method to handle characteristic value updates
 *
 */
-(void) registerForBootloaderCharacteristicNotifications_v1
{
    [bootloaderModel enableNotificationForBootloaderCharacteristicAndSetNotificationHandler:^(NSError *error, id command, unsigned char otaError)
     {
         if (nil == error)
         {
             NSLog(@"--{Kaadas}--command=%@",command);
             NSLog(@"--{Kaadas}--otaError=%c",otaError);
             [self handleResponseForCommand_v1:command error:otaError];
         }
         else{
             NSLog(@"--{Kaadas}--error=%@",error);
             NSLog(@"--{Kaadas}--error.localizedDescription=%@",error.localizedDescription);
         }
     }];
}
- (void)sendEnterBootloaderCmd {
    NSDictionary *dataDict = [NSDictionary dictionaryWithObject:[fileHeaderDict objectForKey:PRODUCT_ID] forKey:PRODUCT_ID];
    NSData *data = [bootloaderModel createPacketWithCommandCode_v1:ENTER_BOOTLOADER dataLength:4 data:dataDict];
    [bootloaderModel writeCharacteristicValueWithData:data command:ENTER_BOOTLOADER];
}
/*!
 *  @method handleResponseForCommand_v1:error:
 *
 *  @discussion Method to handle the file tranfer with the response from the device
 *
 */
-(void) handleResponseForCommand_v1:(id)command error:(unsigned char)error {
    if (SUCCESS == error) {
        if ([command isEqual:@(ENTER_BOOTLOADER)]) {
            // Compare Silicon ID and Silicon Rev string
            if ([[[fileHeaderDict objectForKey:SILICON_ID] lowercaseString] isEqualToString:bootloaderModel.siliconIDString] && [[fileHeaderDict objectForKey:SILICON_REV] isEqualToString:bootloaderModel.siliconRevString]) {
                /* Send SET_APP_METADATA command */
                uint8_t appID = [[fileHeaderDict objectForKey:APP_ID] unsignedCharValue];
                
                uint32_t appStart = 0xFFFFFFFF;
                uint32_t appSize = 0;
                
                if (appInfoDict) {
                    appStart = [appInfoDict[APPINFO_APP_START] unsignedIntValue];
                    appSize = [appInfoDict[APPINFO_APP_SIZE] unsignedIntValue];
                } else {
                    for (NSDictionary *rowDict in fileRowDataArray) {
                        if (RowTypeData == [[rowDict objectForKey:ROW_TYPE] unsignedCharValue]) {
                            uint32_t addr = [[rowDict objectForKey:ADDRESS] unsignedIntValue];
                            if (addr < appStart) {
                                appStart = addr;
                            }
                            appSize += [[rowDict objectForKey:DATA_LENGTH] unsignedIntValue];
                        }
                    }
                }
                NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedChar:appID], APP_ID, [NSNumber numberWithUnsignedInt:appStart], APP_META_APP_START, [NSNumber numberWithUnsignedInt:appSize], APP_META_APP_SIZE, nil];
                NSData *data = [bootloaderModel createPacketWithCommandCode_v1:SET_APP_METADATA dataLength:9 data:dataDict];
                [bootloaderModel writeCharacteristicValueWithData:data command:SET_APP_METADATA];
            } else {
                [self otaFail];
                //                [Utilities alertWithTitle:APP_NAME message:LOCALIZEDSTRING(@"OTASiliconIDMismatchMessage")];
                //                //Reset view in case of error
                //                [MBProgressHUD showError:LOCALIZEDSTRING(@"OTASiliconIDMismatchMessage")];
                //
            }
        } else if ([command isEqual:@(SET_APP_METADATA)]) {
            NSDictionary *rowDataDict = [fileRowDataArray objectAtIndex:currentIndex];
            if (RowTypeEiv == [[rowDataDict objectForKey:ROW_TYPE] unsignedCharValue]) {
                /* Send SET_EIV command */
                NSArray *dataArr = [rowDataDict objectForKey:DATA_ARRAY];
                NSDictionary * dataDict = [NSDictionary dictionaryWithObject:dataArr forKey:ROW_DATA];
                NSData *data = [bootloaderModel createPacketWithCommandCode_v1:SET_EIV dataLength:[dataArr count] data:dataDict];
                [bootloaderModel writeCharacteristicValueWithData:data command:SET_EIV];
            } else {
                //Process data row
                [self startProgrammingDataRowAtIndex_v1:currentIndex];
            }
        } else if ([command isEqual:@(SEND_DATA)]) {
            /* Send SEND_DATA/PROGRAM_DATA commands */
            if (bootloaderModel.isSendRowDataSuccess) {
                [self programDataRowAtIndex_v1:currentIndex];
            } else {
                [self otaFail];
                //                [Utilities alertWithTitle:APP_NAME message:LOCALIZEDSTRING(@"OTASendDataCommandFailed")];
            }
        } else if ([command isEqual:@(PROGRAM_DATA)] || [command isEqual:@(SET_EIV)]) {
            // Update progress and proceed to next row
            if (bootloaderModel.isProgramRowDataSuccess) {
                currentIndex++;
                _line3Img.highlighted = YES;
                
                float percentage = (float) currentIndex/fileRowDataArray.count;
                NSLog(@"--{Kaadas}--currentIndex==%d",currentIndex);
                NSLog(@"--{Kaadas}--fileRowDataArray.count==%lu",(unsigned long)fileRowDataArray.count);
                ///DFU传输镜像文件，从进度50%开始
                self.progress = 0.5+percentage/2;
                
                _Psoc6DFUTotalBlock.text = [NSString stringWithFormat:@"%lu",(unsigned long)fileRowDataArray.count];
                _Psoc6DFUCurrentBlock.text = [NSString stringWithFormat:@"%d",currentIndex];
    
                [UIView animateWithDuration:0.5 animations:^{
                    [self.view layoutIfNeeded];
                }];
                
                if (currentIndex < fileRowDataArray.count) {
                    NSDictionary * rowDataDict = [fileRowDataArray objectAtIndex:currentIndex];
                    if (RowTypeEiv == [[rowDataDict objectForKey:ROW_TYPE] unsignedCharValue]) {
                        /* Send SET_EIV command */
                        NSArray * dataArr = [rowDataDict objectForKey:DATA_ARRAY];
                        NSDictionary * dataDict = [NSDictionary dictionaryWithObject:dataArr forKey:ROW_DATA];
                        NSData * data = [bootloaderModel createPacketWithCommandCode_v1:SET_EIV dataLength:[dataArr count] data:dataDict];
                        [bootloaderModel writeCharacteristicValueWithData:data command:SET_EIV];
                    } else {
                        //Process data row (program next row)
                        [self startProgrammingDataRowAtIndex_v1:currentIndex];
                    }
                } else {
                    /* Send VERIFY_APP command */
                    uint8_t appID = [[fileHeaderDict objectForKey:APP_ID] unsignedCharValue];
                    NSDictionary * dataDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:appID] forKey:APP_ID];
                    NSData * data = [bootloaderModel createPacketWithCommandCode_v1:VERIFY_APP dataLength:1 data:dataDict];
                    [bootloaderModel writeCharacteristicValueWithData:data command:VERIFY_APP];
                }
            } else {
                [self otaFail];
                //                [Utilities alertWithTitle:APP_NAME message:LOCALIZEDSTRING(@"OTAWritingFailedMessage")];
                //                [MBProgressHUD showError:LOCALIZEDSTRING(@"OTAWritingFailedMessage")];
            }
        } else if ([command isEqual:@(VERIFY_APP)]) {
            if (bootloaderModel.isAppValid) {
                
                ///升级完成
                _icon4Img.highlighted = YES;
                self.lock.bleTool.isBinding = NO;//把标志位置为NO
                
                /* Send EXIT_BOOTLOADER command */
                NSData *exitBootloaderCommandData = [bootloaderModel createPacketWithCommandCode_v1:EXIT_BOOTLOADER dataLength:0 data:nil];
                [bootloaderModel writeCharacteristicValueWithData:exitBootloaderCommandData command:EXIT_BOOTLOADER];
                
                //                self.Psoc6DFUCurrentStatus.text = Localized(@"锁DFU升级成功");
                //获取固件文件名
                NSString *fileName = [[NSUserDefaults standardUserDefaults] objectForKey:BluetoothBin] ;
                // 获取Documents目录路径
                NSString *docDir = PATHDOCUMNT;
                // response.suggestedFilename ： 建议使用的文件名，一般跟服务器端的文件名一致
                NSString *file = [docDir stringByAppendingPathComponent:fileName];
                NSError *error = nil;
                
                // 创建NSFileManager
                NSFileManager *fileManager = [NSFileManager defaultManager];
                //判断文件是否存在
                if([fileManager fileExistsAtPath:file]){
                    //删除文件
                    [fileManager removeItemAtPath:file error:&error];
                }
                
                UIAlertController *OTAComoleteView = [UIAlertController alertControllerWithTitle:Localized(@"锁OTA升级成功")
                                                                                         message:nil
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
                                                                          
                                                                          if (self.lock.bleTool.connectedPeripheral) {
                                                                              [self.lock.bleTool.centralManager cancelPeripheralConnection:self.lock.bleTool.connectedPeripheral];
                                                                          }else{
                                                                              [MBProgressHUD showError:Localized(@"bleNotConnect")];
                                                                              self->_startUpgradingBtn.enabled = YES;
                                                                              [self.navigationController popViewControllerAnimated:YES];
                                                                          }
                                                                          ///OTA升级流程完成
                                                                          [self.navigationController popViewControllerAnimated:YES];
                                                                          
                                                                      }];
                
                [OTAComoleteView addAction:defaultAction];
                
                if (OTAComoleteView) {
                    /**
                     *提示用户OTA升级流程完成。
                     */
                    [self presentViewController:OTAComoleteView animated:YES completion:nil];
                }
                
                
            } else {
                [self otaFail];
                currentIndex = 0;
            }
        }
    } else {
        [self otaFail];
    }
}
/*!
 *  @method startProgrammingDataRowAtIndex_v1:
 *
 *  @discussion Method to write the firmware file data to the device
 *
 */
-(void) startProgrammingDataRowAtIndex_v1:(int) index
{
    NSDictionary *rowDataDict = [fileRowDataArray objectAtIndex:index];
    //Write data using SEND_DATA/PROGRAM_ROW commands
    currentRowDataArray = [[rowDataDict objectForKey:DATA_ARRAY] mutableCopy];
    currentRowDataAddress = [[rowDataDict objectForKey:ADDRESS] unsignedIntValue];
    currentRowDataCRC32 = [[rowDataDict objectForKey:CRC_32] unsignedIntValue];
    [self programDataRowAtIndex_v1:index];
}
/*!
 *  @method programDataRowAtIndex_v1:
 *
 *  @discussion Method to write the data in a row
 *
 */
-(void) programDataRowAtIndex_v1:(int)index
{
    if (currentRowDataArray.count > maxDataSize)
    {
        NSDictionary * dataDict = [NSDictionary dictionaryWithObjectsAndKeys:[currentRowDataArray subarrayWithRange:NSMakeRange(0, maxDataSize)], ROW_DATA, nil];
        NSData * data = [bootloaderModel createPacketWithCommandCode_v1:SEND_DATA dataLength:maxDataSize data:dataDict];
        [bootloaderModel writeCharacteristicValueWithData:data command:SEND_DATA];
        [currentRowDataArray removeObjectsInRange:NSMakeRange(0, maxDataSize)];
    }
    else
    {
        //Last packet data
        NSDictionary * dataDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:currentRowDataAddress], ADDRESS, [NSNumber numberWithUnsignedInt:currentRowDataCRC32], CRC_32, currentRowDataArray, ROW_DATA, nil];
        NSData * data = [bootloaderModel createPacketWithCommandCode_v1:PROGRAM_DATA dataLength:(currentRowDataArray.count + 8) data:dataDict];
        [bootloaderModel writeCharacteristicValueWithData:data command:PROGRAM_DATA];
    }
}

-(void)otaFail{
    UIAlertController *OTAView = [UIAlertController alertControllerWithTitle:Localized(@"升级失败")
                                                                     message:Localized(@"锁OTA升级失败，请重试？")
                                                              preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              
                                                              [self.navigationController popViewControllerAnimated:YES];
                                                              
                                                          }];
    
    [OTAView addAction:defaultAction];
    
    if (OTAView) {
        /**
         *提示用户是否需要OTA升级。
         */
        [self presentViewController:OTAView animated:YES completion:nil];
    }
}

#pragma mark - 内部方法
- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    if (_progress < 0.0) {
        _progress = 0.0;
    }
    if (_progress > 1.0) {
        _progress = 1.0;
    }
    _currentProgressView.progress = _progress;
    CGFloat width = self.currentProgressView.bounds.size.width;
    width *= _progress;
    if (width > self.currentProgressView.bounds.size.width) {
        width = self.currentProgressView.bounds.size.width;
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.progressViewImg.transform = CGAffineTransformMakeTranslation(width-self.progressViewImg.frame.size.width, 0);
        self.progressViewLabel.transform = CGAffineTransformMakeTranslation(width-self.progressViewLabel.frame.size.width, 0);
        self.progressViewLabel.text = [NSString stringWithFormat:@"%.0f%%",(self->_progress * 100.0)];
    }];
}
#pragma mark - 通知相关方法。
///下载进度事件通知。
- (void)downloadEventNotification:(NSNotification *)noti
{
    NSString *progress = noti.userInfo[@"progress"];
    KDSLog(@"--{Kaadas}--progress==%f",progress.doubleValue);
}
///网络状态改变的通知。当网络不可用时，会将网关、猫眼和网关锁的状态设置为离线后发出通知KDSDeviceSyncNotification
- (void)networkReachabilityStatusDidChange:(NSNotification *)noti
{
    NSNumber *number = noti.userInfo[AFNetworkingReachabilityNotificationStatusItem];
    AFNetworkReachabilityStatus status = number.integerValue;
    switch (status)
    {
            
        case AFNetworkReachabilityStatusReachableViaWWAN://2G,3G,4G...
        case AFNetworkReachabilityStatusReachableViaWiFi://wifi网络
            if(_icon1Img.highlighted&&!_line1Img.highlighted){
                //                [[KDSBreakpointDownload manager] resume];//恢复下载
            }
            break;
        default://未识别的网络/不可达的网络
            if(_icon1Img.highlighted&&!_line1Img.highlighted){
                //                [[KDSBreakpointDownload manager] pause];//暂停下载
            }
            break;
    }
}
-(void)stopOTA{
    self.lock.bleTool.isBinding = NO;//断开蓝牙前，把标志位置为NO
    [self.lock.bleTool.centralManager cancelPeripheralConnection: self.lock.bleTool.connectedPeripheral];
    
}

@end
