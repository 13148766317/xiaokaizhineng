//
//  KDSBluetoothTool.m
//  BleTest
//
//  Created by zhaowz on 2017/6/8.
//  Copyright © 2017年 zhaowz. All rights reserved.
//


#import "KDSBluetoothTool.h"
#import "KDSBluetoothTool+Category.h"

NSString * const KDSBleDidDisconnectNotification = @"KDSBleDidDisconnectNotification";
NSString * const KDSLockDidOpenNotification = @"KDSLockDidOpenNotification";
NSString * const KDSLockDidCloseNotification = @"KDSLockDidCloseNotification";
NSString * const KDSLockUsersDidUpdateNotification = @"KDSLockUsersDidUpdateNotification";
NSString * const KDSLockSchedulesDidUpdateNotification = @"KDSLockSchedulesDidUpdateNotification";
NSString * const KDSLockAuthFailedNotification = @"KDSLockAuthFailedNotification";
NSString * const KDSLockDidAlarmNotification = @"KDSLockDidAlarmNotification";
NSString * const KDSLockDidReportNotification = @"KDSLockDidReportNotification";

@interface KDSBluetoothTool ()
@property (nonatomic, strong) NSMutableArray *searchArray;//扫描的设备
/**以下的特征值保存是为了适配新的蓝牙锁的*/
@property (nonatomic, strong) CBCharacteristic *batteryCharacteristic; //电量
@property (nonatomic, strong) CBCharacteristic *systemIDCharacteristic; //系统ID
@property (nonatomic, strong) CBCharacteristic *modelNumCharacteristic; //
@property (nonatomic, strong) CBCharacteristic *seriaNumCharacteristic; //
@property (nonatomic, strong) CBCharacteristic *firmwareCharacteristic; //锁型号
@property (nonatomic, strong) CBCharacteristic *hardwareCharacteristic; //硬件版本
@property (nonatomic, strong) CBCharacteristic *softwareCharacteristic; //软件版本
@property (nonatomic, strong) CBCharacteristic *mfrNameCharacteristic;  //生产商
///锁状态特征(FFF0服务FFF3特征)，在心跳定时器中读此特征来更新锁的状态。
@property (nonatomic, strong) CBCharacteristic *lockStateCharacteristic;
@property (nonatomic, strong) NSData *systemID;
/**传输序号,每次传输+1，到了255置为50 (为了区分心跳包 设置范围为50-255)*/
@property (nonatomic, assign) int tsn;
///心跳包tsn 1 - 49
@property (nonatomic, assign) NSInteger heartbeatTsn;
@property (nonatomic, strong) NSTimer *heartbeatTimer;

///当前正在搜索的用户id，应该小于锁能设置的最多密码数。初始化时=-1，如果在[0, maxUsers)之间，应该启动搜索。
@property (nonatomic, assign) NSInteger retrievingUserId;
///搜索到的用户类型数组。不管成功与否，每次回调执行时都应该添加一个对象进来。
@property (nonatomic, strong) NSMutableArray<KDSBleUserType *> *retrievedUsersArr;
///当前正在搜索的计划id，应该小于锁能设置的最大计划数。初始化时=-1，如果在[0, maxSchedules)之间，应该启动搜索
@property (nonatomic, assign) NSInteger retrievingScheduleId;
///搜索到的计划数组。不管成功与否，每次回调执行时都应该添加一个对象进来。
@property (nonatomic, strong) NSMutableArray<KDSBleScheduleModel *> *retrievedSchedulesArr;
///用于执行停止搜索蓝牙外设的block，在开始搜索外设时创建，10秒后执行。如果10秒不到又执行搜索外设，则先取消执行上一次创建的block。
@property (nonatomic, copy) dispatch_block_t stopScanPeripheralBlock;
///标记锁是否处于管理员模式。锁进入和退出管理员模式蓝牙会自动上报。
//@property (nonatomic, assign) BOOL onAdminMode;

@end

#pragma mark - Singleton
static KDSBluetoothTool *bleTool = nil;
@implementation KDSBluetoothTool

#define DeviceAdvDataPrefix         @"PLP"//飞利浦

#pragma mark - getter setter 初始化方法
/*Control判断是否加密
 Tsn 传输序号
 Check校验帧（累加和，校验数据是否出错）
 Cmd命令码（用来说明这条命令是用来干嘛的）
 */

//搜索到的设备
- (NSMutableArray *)searchArray{
    if (_searchArray == nil) {
        _searchArray = [NSMutableArray array];
    }
    return _searchArray;
}

- (NSMutableDictionary<NSString *,KDSBleTunnelTask *> *)tasksMDict
{
    if (_tasksMDict == nil)
    {
        _tasksMDict = [NSMutableDictionary dictionary];
    }
    return _tasksMDict;
}

- (NSDateFormatter *)dateFormatter
{
    if (_dateFormatter == nil)
    {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return _dateFormatter;
}

- (NSMutableArray<KDSBleUserType *> *)retrievedUsersArr
{
    if (_retrievedUsersArr == nil)
    {
        _retrievedUsersArr = [NSMutableArray array];
    }
    return _retrievedUsersArr;
}

- (NSArray<KDSBleUserType *> *)users
{
    NSMutableArray *arr = [NSMutableArray array];
    for (KDSBleUserType *user in self.retrievedUsersArr)
    {
        if (user.keyType != KDSBleKeyTypeInvalid) [arr addObject:user];
    }
    return arr.copy;
}

- (NSMutableArray<KDSBleScheduleModel *> *)retrievedSchedulesArr
{
    if (_retrievedSchedulesArr == nil)
    {
        _retrievedSchedulesArr = [NSMutableArray array];
    }
    return _retrievedSchedulesArr;
}

- (NSArray<KDSBleScheduleModel *> *)schedules
{
    NSMutableArray *arr = [NSMutableArray array];
    for (KDSBleScheduleModel *model in self.retrievedSchedulesArr)
    {
        if (model.keyType != KDSBleKeyTypeInvalid) [arr addObject:model];
    }
    return arr.copy;
}

- (instancetype)initWithVC:(id)viewController{
    if (self = [super init]) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _delegate = viewController;
        self.tsn = 50;
        self.isAdmin = NO;
        self.heartbeatTsn = 1;
        _dataM = [NSMutableData data];
        self.retrievingUserId = -1;
        self.retrievingScheduleId = -1;
    }
    return self;
}
- (instancetype)init{
    if (self = [super init]) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    return self;
}

- (void)setTsn:(int)tsn{
    tsn = tsn > 255 ? 50 : tsn;
    tsn = tsn < 50 ? 255 : tsn;
    _tsn = tsn;
}
- (void)setHeartbeatTsn:(NSInteger)heartbeatTsn{
    heartbeatTsn = heartbeatTsn < 1 ? 49 : heartbeatTsn;
    heartbeatTsn = heartbeatTsn > 49 ? 1 : heartbeatTsn;
    _heartbeatTsn = heartbeatTsn;
}
#pragma mark - 开始搜索蓝牙
- (void)beginScanForPeripherals{
    [self.searchArray removeAllObjects];
    //不过滤服务搜索蓝牙
    [_centralManager scanForPeripheralsWithServices:nil options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    if (self.stopScanPeripheralBlock)
    {
        dispatch_block_cancel(self.stopScanPeripheralBlock);
        self.stopScanPeripheralBlock = nil;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_block_t block = dispatch_block_create(DISPATCH_BLOCK_ASSIGN_CURRENT, ^{
        if (weakSelf.centralManager.isScanning) {
            [weakSelf stopScan];
        }
    });
    self.stopScanPeripheralBlock = block;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        block();
    });
}
#pragma mark - 停止扫描蓝牙
- (void)stopScanPeripherals{
    if (_centralManager.isScanning)
    {
        [self stopScan];
        [self.searchArray removeAllObjects];
    }
}

- (void)stopScan
{
    [self.centralManager stopScan];
    if ([self.delegate respondsToSelector:@selector(centralManagerDidStopScan:)])
    {
        [self.delegate centralManagerDidStopScan:self.centralManager];
    }
}
#pragma mark - 开始连接蓝牙
- (void)beginConnectPeripheral:(CBPeripheral *)peripheral{

    //1.是相同的连接就返回
    if ([_connectedPeripheral.advDataLocalName isEqualToString:peripheral.advDataLocalName] || !peripheral) {

        return;
    }
    //2.不是连接相同的设备,就先断开.之前的设备,然后重新li
    if (_connectedPeripheral.state == CBPeripheralStateConnected && ![_connectedPeripheral.advDataLocalName isEqualToString:peripheral.advDataLocalName]) {

        [self.centralManager cancelPeripheralConnection:_connectedPeripheral];
    }
    if (peripheral.state==CBPeripheralStateConnected) {
        KDSLog(@"当前的设备是连接状态。先断开连接");

        [self.centralManager cancelPeripheralConnection:peripheral];
    }
    [self.centralManager connectPeripheral:peripheral options:nil];
}
#pragma mark - 断开连接蓝牙设备
- (void)endConnectPeripheral:(CBPeripheral *)peripheral{
    if (peripheral.state == CBPeripheralStateConnected) {
        [self.centralManager cancelPeripheralConnection:peripheral];
        self.pwd1 = nil;
        self.pwd2 = nil;
    }
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    if ([_delegate respondsToSelector:@selector(discoverManagerDidUpdateState:)]) {
        [_delegate discoverManagerDidUpdateState:central];
    }
    if (central.state == CBPeripheralManagerStatePoweredOn) {
        //蓝牙打开，开始搜索设备
        [self beginScanForPeripherals];
    }else{
        KDSLog(@"请打开手机蓝牙");
        self.pwd3 = nil;
        if ([_delegate respondsToSelector:@selector(didDisConnectPeripheral:)] && _connectedPeripheral) {

            [_delegate didDisConnectPeripheral:_connectedPeripheral];
            _connectedPeripheral = nil;
            _connectedPeripheralWithIdentifier = nil;
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
    KDSLog(@"===name:%@ localName:%@ uuid:%@",peripheral.name,advertisementData[@"kCBAdvDataLocalName"],peripheral.identifier.UUIDString);
    //解析广播包中的kCBAdvDataLocalName 区分凯迪仕的设备
    NSString *key = CBAdvertisementDataLocalNameKey;

//    if (([advertisementData[key] hasPrefix:@"XK"] && [advertisementData[key] length] == 14) || ([advertisementData[key] hasPrefix:@"XiaoKai"]  && [advertisementData[key] length] == 19) || [advertisementData[key] containsString:@"Bootloader"] || [advertisementData[key] hasPrefix:@"KDS"]) {

       if (([advertisementData[key] hasPrefix:@"XK"] && [advertisementData[key] length] == 14) || ([advertisementData[key] hasPrefix:@"XiaoKai"]  && [advertisementData[key] length] == 19 )|| [advertisementData[key] containsString:@"Bootloader"]) {
        //⚠️如果要搜索其他抬头的蓝牙，记得提交代码的时候恢复原样

        if ([self.searchArray containsObject:peripheral]) {
            return;
        }
        [self.searchArray addObject:peripheral];
        KDSLog(@"\n外围设备===peripheral:%@\n广播数据==== advertisementData:%@ ",peripheral,advertisementData);
        //将广播包中的数据与外设绑定
        peripheral.advDataLocalName = advertisementData[key];
        if ([peripheral.name hasPrefix:@"KDS"] || [peripheral.name hasPrefix:@"KdsLock"] || [peripheral.name hasPrefix:@"XK"]|| [peripheral.name hasPrefix:@"ORG"]) {
            peripheral.isNewDevice = NO;
        }else{
            peripheral.isNewDevice = YES;
        }
        if ([_delegate respondsToSelector:@selector(didDiscoverPeripheral:)]) {
            [_delegate didDiscoverPeripheral:peripheral];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    self.tsn = 50;
    self.heartbeatTsn = 1;
    _connectedPeripheral = peripheral;
    _connectedPeripheralWithIdentifier = peripheral.identifier;
   //判断创建的字符串内容是否以某个字符开始
    if ([peripheral.name hasPrefix:@"KDS"] || [peripheral.name hasPrefix:@"KdsLock"]) {
        peripheral.isNewDevice = NO;
    }else{
        peripheral.isNewDevice = YES;
        
        NSInteger allLenth =peripheral.advDataLocalName.length;
        //取出mac码
        NSString *orgStr = [peripheral.advDataLocalName substringFromIndex:allLenth-12];
        NSData *password1 = [orgStr dataUsingEncoding:NSASCIIStringEncoding];
        //这个是测试版蓝牙使用的，和服务器返回的不一样，正式产品不能使用这个值做鉴权密码。
        self.pwd1 = [self convertFromDataToHexStr:password1];
        
    }
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
    if ([_delegate respondsToSelector:@selector(didConnectPeripheral:)]) {
        [_delegate didConnectPeripheral:peripheral];
    }
    [self stopScan];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    KDSLog(@"连接蓝牙失败:%@",error);
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    KDSLog(@"断开蓝牙%@ error:%@",peripheral.name,error);
    [[NSNotificationCenter defaultCenter] postNotificationName:KDSBleDidDisconnectNotification object:nil userInfo:@{@"peripheral" : peripheral}];
    _connectedPeripheral = nil;
    _connectedPeripheralWithIdentifier = nil;
    if (peripheral.isNewDevice) {
        self.pwd3 = nil;
//        self.onAdminMode = NO;
        [_heartbeatTimer invalidate];
        _heartbeatTimer = nil;
    }
    if ([_delegate respondsToSelector:@selector(didDisConnectPeripheral:)]) {
        [_delegate didDisConnectPeripheral:peripheral];
    }
}

#pragma mark - CBPeripheralDelegate
///只要扫描到服务就会调用
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        for (CBService *sevice in peripheral.services) {
            KDSLog(@"sevice:%@",sevice.UUID.UUIDString);
            [peripheral discoverCharacteristics:nil forService:sevice];//订阅服务下面所有的特征
        }
    });
}
///只要扫描到特征就会调用
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (error){
        KDSLog(@"获取服务:%@的特征失败: %@", service.UUID, error);
        return;
    }
    UInt64 uuid = [self coverFromHexStrToInt:service.UUID.UUIDString];
    KDSBleService serviceType = (KDSBleService)uuid;
    switch (serviceType)
    {
        case KDSBleServiceModule:
            for (CBCharacteristic *characteristic in service.characteristics) {
                KDSLog(@"读的服务-模块信息 (电量 pwd3):severUUId:%@====charUUId:%@",service.UUID.UUIDString,characteristic.UUID.UUIDString);
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                if ([characteristic.UUID.UUIDString isEqualToString:batteryDUUID]) {
                    [peripheral readValueForCharacteristic:characteristic];
                    //电量特征值
                    _batteryCharacteristic = characteristic;
                }
            }
            break;
            
        case KDSBleServiceDevice:
            for (CBCharacteristic *characteristic in service.characteristics) {
                KDSLog(@"读的服务-BLE设备信息参数:severUUId:%@====charUUId:%@",service.UUID.UUIDString,characteristic.UUID.UUIDString);
                //监听characteristic值变化
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                if ([characteristic.UUID.UUIDString isEqualToString:systemIDUUID]) {
                    _systemIDCharacteristic = characteristic;
                    [peripheral readValueForCharacteristic:characteristic];
                }
                else if ([characteristic.UUID.UUIDString isEqualToString:modelNumUUID]) {
                    [peripheral readValueForCharacteristic:characteristic];
                    _modelNumCharacteristic = characteristic;
                }
                else if ([characteristic.UUID.UUIDString isEqualToString:seriaLNumUUID]) {
                    _seriaNumCharacteristic = characteristic;
                }
                else if ([characteristic.UUID.UUIDString isEqualToString:firmwareUUID]) {
                    _firmwareCharacteristic = characteristic;
                    [peripheral readValueForCharacteristic:characteristic];
                }
                else if ([characteristic.UUID.UUIDString isEqualToString:hardwareUUID]) {
                    _hardwareCharacteristic = characteristic;
                    [peripheral readValueForCharacteristic:characteristic];
                }
                else if ([characteristic.UUID.UUIDString isEqualToString:mfrNameUUID]) {
                    _mfrNameCharacteristic = characteristic;
                }
                else if ([characteristic.UUID.UUIDString isEqualToString:softwareUUID]) {
                    _softwareCharacteristic = characteristic;
                    [peripheral readValueForCharacteristic:characteristic];
                }
            }
            break;
            
        case KDSBleServiceLock:
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                if ([characteristic.UUID.UUIDString isEqualToString:kLockStateUUID])
                {
                    self.lockStateCharacteristic = characteristic;
                }
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                [peripheral readValueForCharacteristic:characteristic];
            }
            break;
            
        case KDSBleServiceApp2BleTunnel:
            for (CBCharacteristic *characteristic in service.characteristics) {
                //charUUId:FFE9 这个时候可以与蓝牙设备交互 记录此时的characteristic
                KDSLog(@"读的服务-APP-->BLE数据通道severUUId:%@====charUUId:%@",service.UUID.UUIDString,characteristic.UUID.UUIDString);
                //主动去读取一次外围设备的消息
                [peripheral readValueForCharacteristic:characteristic];
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                self.writeCharacteristic = characteristic;
                if (_delegate && [_delegate respondsToSelector:@selector(didReceiveWriteCharacteristic)]) {
                    [_delegate didReceiveWriteCharacteristic];
                }
                if (self.connectedPeripheral.isNewDevice) {
                    //获取SystemID
                    [self getDeviceInfoWithDevType:DeviceInfoSystemID];
                    //获取SN码
                    [self getDeviceInfoWithDevType:DeviceInfoSerialNum];
                    //发送心跳包
                    [self createHeartbeatTimer];
                }
            }
            break;
            
        case KDSBleServiceBle2AppTunnel:
            for (CBCharacteristic *characteristic in service.characteristics) {
                KDSLog(@"读的服务-BLE-->APP数据通道:severUUId:%@====charUUId:%@",service.UUID.UUIDString,characteristic.UUID.UUIDString);
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            }
            break;
            
        default:
            break;
    }
    ///检测到P6方案 - DFU启动服务
    if ([service.UUID.UUIDString isEqualToString: DFUResetServiceUUID]) {
        KDSLog(@"--{Kaadas}--DFU启动服务=%@", service.UUID.UUIDString);
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID.UUIDString isEqualToString:DFUResetServiceCharacteristicStartOrResetUUID]&&![peripheral.advDataLocalName containsString:@"Bootloader"]) {
                KDSLog(@"--{Kaadas}--DFU启动服务的特征");
                self.DFUCharacteristic = characteristic;
                //                KDSLog(@"--{Kaadas}--查找到DFU特征值3=%@,self=%@",self.OADCharacteristic,self);
                if (peripheral.isNewDevice && _delegate && [_delegate respondsToSelector:@selector(didGetOTACharacteristic)]) {
                    //                    KDSLog(@"--{Kaadas}--检测到DFU启动服务=%@,_delegate=%@",self.OADCharacteristic,_delegate);
                    //                    [_delegate didGetOTACharacteristic];
                }
            }
        }
    }
    ///检测到P6方案 - DFU服务
    if ([service.UUID.UUIDString isEqualToString: KDSDFUService]) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            KDSLog(@"--{Kaadas}--DFU服务=%@",service.UUID.UUIDString);
            //            KDSLog(@"--{Kaadas}--peripheral.services=%@",peripheral.services);
            if ([characteristic.UUID.UUIDString isEqualToString:KDSDFUServiceCharacteristicCommand]) {
                KDSLog(@"--{Kaadas}--DFU服务下的特征=%@",KDSDFUServiceCharacteristicCommand);
                //                KDSLog(@"--{Kaadas}--查找到DFU特征值3=%@,self=%@",self.OADCharacteristic,self);
                self.DFUTransImageCharacteristic = characteristic;
                KDSLog(@"--{Kaadas}--_delegate=DFUViewController=%@",_delegate);
                if ( _delegate && [_delegate respondsToSelector:@selector(startDFUProcess)]) {
                    KDSLog(@"--{Kaadas}--startDFUProcess");
                    [_delegate startDFUProcess];
                }else if( _delegate && [_delegate respondsToSelector:@selector(hasInBootload)]){
                    [_delegate hasInBootload];
                }else{
                    [self.centralManager cancelPeripheralConnection:_connectedPeripheral];
                }
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    //    [peripheral readValueForCharacteristic:characteristic];//读取所有的特征值
}
#pragma mark 接收特征的数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
//    NSLog(@"--{XiaoKai}--接收特征的数据=%@",characteristic.value);
    if (error) return;
    if (!peripheral.isNewDevice)
    {
        [self dealWithReceiveOldBleModelData:characteristic.value];
        return;
    }
    NSString *uuid = characteristic.UUID.UUIDString;
    if ([uuid isEqualToString:batteryDUUID]) {//电量信息
        NSData *batteryData = characteristic.value;
        u_int8_t tt;
        [batteryData getBytes:&tt length:sizeof(tt)];
        int elct = tt;//0-100
        peripheral.power = elct;
        if ([_delegate respondsToSelector:@selector(didReceiveDeviceElctInfo:)]) {
            [_delegate didReceiveDeviceElctInfo:elct];
        }
    }
    else if ([uuid isEqualToString:seriaLNumUUID]) {//SN
        peripheral.serialNumber = characteristic.value.jk_UTF8String;
        if (_delegate && [_delegate respondsToSelector:@selector(didGetDeviceSN:)]) {
            [_delegate didGetDeviceSN:characteristic.value.jk_UTF8String];
        }
    }
    else if ([uuid isEqualToString:systemIDUUID]){//System ID
        //获取systemId
        _systemID = characteristic.value;
        NSString *systemIDStr = [self convertFromDataToHexStr:_systemID];
        if (!systemIDStr || strtol(systemIDStr.UTF8String, NULL, 16) == 0) {
            _systemID = [self getSystemIDWithMacAddress:peripheral];
        }
        if (peripheral.isNewDevice && [_delegate respondsToSelector:@selector(didGetSystemID:)]) {
            [_delegate didGetSystemID:peripheral];
        }
    }
    else if ([uuid isEqualToString:hardwareUUID])
    {
        peripheral.hardwareVer = characteristic.value.jk_UTF8String;
    }
    else if ([uuid isEqualToString:softwareUUID]){//softwareUUID
        //获取softwareUUID
        NSData *softwareData = characteristic.value;
        peripheral.softwareVer = softwareData.jk_UTF8String;
        if (peripheral.isNewDevice && _delegate && [_delegate respondsToSelector:@selector(didGetSoftwareWithPeripheral: softwareData:)]) {
            [_delegate didGetSoftwareWithPeripheral:peripheral softwareData:softwareData.jk_UTF8String];
        }
    }
    else if ([uuid isEqualToString:firmwareUUID])
    {
        NSString *model = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        self.connectedPeripheral.lockModelType = model;
        if ([self.delegate respondsToSelector:@selector(peripheral:didUpdateValueForCharacteristicOfLockModel:)])
        {
            [self.delegate peripheral:peripheral didUpdateValueForCharacteristicOfLockModel:model];
        }
    }
    else if ([uuid isEqualToString:modelNumUUID])
    {
        self.connectedPeripheral.lockModelNumber = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    }
    else if ([uuid isEqualToString:bleToAppDUUID]){//模块向App发送数据通道
        if (characteristic.value.length == 16) {
            NSData *pwd1Data = [characteristic.value subdataWithRange:NSMakeRange(0, 12)];
            NSData *pwd = [self convertHexStrToData:self.pwd1];
            if ([pwd1Data.description isEqualToString: pwd.description]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:KDSLockAuthFailedNotification object:nil userInfo:nil];
            }
            return;
        }
        if (characteristic.value.length < 20) {return;/**数据丢包了 */ }
        //新设备数据的处理
        [self dealWithNewDeviceReceiveData:characteristic.value];
    }
    else if ([uuid isEqualToString:kLockStateUUID])//锁状态
    {
        peripheral.isAutoMode = ((*(int*)(characteristic.value.bytes)) >> 7) & 0x01;
//        self.onAdminMode = ((*(int*)(characteristic.value.bytes)) >> 7) & 0x01;
//        self.onAdminMode = NO;
        if ([self.delegate respondsToSelector:@selector(peripheral:didUpdateValueForCharacteristicOfLockState:)])
        {
            [self.delegate peripheral:peripheral didUpdateValueForCharacteristicOfLockState:characteristic.value];
        }
    }
    else if ([uuid isEqualToString:kLockVolumeUUID])//音量
    {
        peripheral.volume = *(char*)(characteristic.value.bytes);
    }
    else if ([uuid isEqualToString:kLockLanguageUUID])//语言
    {
        peripheral.language = @((char*)(characteristic.value.bytes));
    }
}
///发送消息的回调
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        KDSLog(@"向蓝牙设备:%@ 发送数据:%@ 失败:%@",peripheral.advDataLocalName,characteristic.value,error);
    }else{
        //        KDSLog(@"向蓝牙设备:%@发送数据成功 value:(%@)date :%@",peripheral,characteristic.value,[self getcurretenDate]);
    }
}

- (NSData *)getSystemIDWithMacAddress:(CBPeripheral *)peripheral{
    NSInteger allLenth = peripheral.advDataLocalName.length;
    NSString *orgStr = [peripheral.advDataLocalName substringFromIndex:allLenth-12];
    NSData *orignData = [self convertHexStrToData:orgStr];
    NSData *data0 = [orignData subdataWithRange:NSMakeRange(0, 1)];
    NSData *data1 = [orignData subdataWithRange:NSMakeRange(1, 1)];
    NSData *data2 = [orignData subdataWithRange:NSMakeRange(2, 1)];
    NSData *data3 = [orignData subdataWithRange:NSMakeRange(3, 1)];
    NSData *data4 = [orignData subdataWithRange:NSMakeRange(4, 1)];
    NSData *data5 = [orignData subdataWithRange:NSMakeRange(5, 1)];
    Byte middleByte[2] =  {0x00,0x00};//2个字节
    NSData *middleData = [NSData dataWithBytes:middleByte length:sizeof(middleByte)];
    NSMutableData *systemData = [NSMutableData data];
    [systemData appendData:data5];
    [systemData appendData:data4];
    [systemData appendData:data3];
    [systemData appendData:middleData];
    [systemData appendData:data2];
    [systemData appendData:data1];
    [systemData appendData:data0];
    return systemData.copy;
}

#pragma mark - 发送心跳包
- (void)createHeartbeatTimer{
    if (self.heartbeatTimer==nil) {
        //重复每3秒发送一次心跳包
        self.heartbeatTimer = [NSTimer timerWithTimeInterval:3 target:self selector:@selector(sendHeartbeatdata) userInfo:nil repeats:YES];
         [[NSRunLoop currentRunLoop] addTimer:self.heartbeatTimer forMode:NSRunLoopCommonModes];
    }
    [self.heartbeatTimer fire];
}

- (void)sendHeartbeatdata{
    
    if (!self.connectedPeripheral.lockModelType)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.connectedPeripheral readValueForCharacteristic:self.firmwareCharacteristic];
        });
    }
    if (!self.connectedPeripheral.lockModelNumber)
    {
        int interval = self.connectedPeripheral.lockModelType ? 2 : 4;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.connectedPeripheral readValueForCharacteristic:self.modelNumCharacteristic];
        });
    }
    
    BOOL needRetrieveUser = -1<self.retrievingUserId && self.retrievingUserId<self.connectedPeripheral.maxUsers;
    BOOL needRetrieveSchedule = -1<self.retrievingScheduleId && self.retrievingScheduleId<5;
    if ((needRetrieveUser || needRetrieveSchedule) && self.pwd3)
    {
        if (needRetrieveUser)
        {
            [self retrieveUsers];
        }
        if (needRetrieveSchedule)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((needRetrieveUser ? 2 : 0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self retrieveSchedules];
            });
        }
        return;
    }
    
    if (self.lockStateCharacteristic)
    {
        [self.connectedPeripheral readValueForCharacteristic:self.lockStateCharacteristic];
    }
    self.heartbeatTsn ++;
    Byte bytePayload[16] = {0xFF, 0};
    NSData *payloadData = [[NSData alloc] initWithBytes:bytePayload length:sizeof(bytePayload)];
    Byte byteHeader[] = {0x00,self.heartbeatTsn,0xff,0xAA};
    NSData *headerData = [[NSData alloc] initWithBytes:byteHeader length:sizeof(byteHeader)];
    NSMutableData *senderData = [NSMutableData data];
    [senderData appendData:headerData];
    [senderData appendData:payloadData];
    if (self.writeCharacteristic && self.connectedPeripheral ) {
        //KDSLog(@"%ld %@发送了心跳包:%@ ",self.heartbeatTsn,[self getcurretenDate],senderData);
        [self.connectedPeripheral writeValue:senderData forCharacteristic:self.writeCharacteristic type:0];
    }
}
- (void)pauseTimer{
    self.heartbeatTimer.fireDate = [NSDate dateWithTimeIntervalSinceNow:3];
}
///处理模块发来的数据
- (void)dealWithNewDeviceReceiveData:(NSData *)data{
    
    const unsigned char* bytes = (const unsigned char*)data.bytes;
    int tsn = bytes[1];
    u_int8_t control = bytes[0];
    u_int8_t check1 = bytes[2];
    NSData *decryptData = data;
    if (control != 0) {//心跳包没有加密？
//        KDSLog(@"加密了");
        decryptData =  [self getAes256_decryptDataWithOriginData:data];
    }
    NSData *header = [self getHeaderDataWithPayloadData:[decryptData subdataWithRange:NSMakeRange(4, 16)] cmdByte:0 withTsn:tsn];
    u_int8_t check2 = ((const unsigned char*)header.bytes)[2];
    if (check1 == check2) {
//                KDSLog(@"校验正确=%@",decryptData)
        [self dealCheckSuccessWithDecryptData:decryptData];
    }else{
        KDSLog(@"校验出错")
    }
    
}
///处理校验正确之后的数据
- (void)dealCheckSuccessWithDecryptData:(NSData *)decryptData{
//    KDSLog(@"处理校验正确之后的数据------%@",decryptData);
    const unsigned char *bytes = (const unsigned char *)decryptData.bytes;
    unsigned char transferSerialNumber = bytes[1];
    unsigned char cmd = bytes[3];
    unsigned char status = bytes[4];
    if (cmd==0 && transferSerialNumber<50) return;//心跳包确认帧。
    if (cmd!=0 && !(cmd==KDSBleTunnelOrderEncrypt && status==1 && !self.isBinding)) {
        //只有收到pwd2和退网指令的时候 根据需要是否发送确认帧 其他cmd非0（对模块执行了任何操作)都要发
        [self sendConfirmDataToBleDevice:(int)transferSerialNumber];
    }
    NSString *receipt = @(transferSerialNumber).stringValue;
    //如果是app主动发送命令，那么队列里会有记录，根据tsn值执行相应的命令就行。
    KDSBleTunnelTask *task = self.tasksMDict[receipt];
    if (task /*&& (cmd == 0 || (cmd != 0 && cmd == task.order))*/)
    {
        [self handleTask:task withData:decryptData];
        return;
    }
    
    KDSBleTunnelOrder order = (KDSBleTunnelOrder)cmd;
    switch (order) {
        case KDSBleTunnelOrderEncrypt:
            if (status == 1 && self.isBinding)//收到锁发送过来的入网(绑定)指令，可以在返回数据中提取pwd2
            {
                self.pwd2 = [decryptData subdataWithRange:NSMakeRange(5, 4)];
                [self sendResponseInOrOutNet:(int)transferSerialNumber];
                if ([_delegate respondsToSelector:@selector(didReceiveInNetOrOutNetCommand:)])
                {
                    [_delegate didReceiveInNetOrOutNetCommand:YES];
                }
                sleep(0.2);
                [self authenticationWithPwd1:self.pwd1 pwd2:self.pwd2 completion:nil];
            }
            else if (status == 2)//收到pwd3，连接且鉴权成功。
            {
                self.pwd3 = [decryptData subdataWithRange:NSMakeRange(5, 4)];
                self.isBinding = YES;
                NSLog(@"self.isBinding = YES");
                [self updateLockClock:nil];
            }
            else if (status == 3)//收到退网(重置)指令。
            {
                [self sendResponseInOrOutNet:(int)transferSerialNumber];
                if ([_delegate respondsToSelector:@selector(didReceiveInNetOrOutNetCommand:)]) {
                    [_delegate didReceiveInNetOrOutNetCommand:NO];
                }
            }
            break;
            
        case KDSBleTunnelOrderLockOperate:
            if (status == 1 && bytes[5] != 9) {//9是模式设置，此种情况下不可能有开锁和关锁。
                if (bytes[6] == 1 || bytes[6] == 0x0d) {//关锁
                    [[NSNotificationCenter defaultCenter] postNotificationName:KDSLockDidCloseNotification object:nil userInfo:@{@"peripheral" : self.connectedPeripheral}];
                }else if (bytes[6] == 2 || bytes[6] == 0x0e){//开锁
                    //2.6版本 开锁成功之后 这个方法会调用两次
                    [[NSNotificationCenter defaultCenter] postNotificationName:KDSLockDidOpenNotification object:nil userInfo:@{@"peripheral" : self.connectedPeripheral}];
                }
            }
            else
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:KDSLockDidReportNotification object:nil userInfo:@{@"peripheral":self.connectedPeripheral, @"data":decryptData}];
                if (bytes[5] == 9)
                {
//                    self.onAdminMode = (bytes[6] >> 3) & 0x1;
//                    self.onAdminMode = NO;
                    self.connectedPeripheral.isAutoMode = (bytes[6] >> 4) & 0x1;
                }
            }
            break;
            
        case KDSBleTunnelOrderZero:
            if (status == (NSInteger)KDSBleErrorNotAuth)
            {
                KDSLog(@"没有鉴权");
                self.pwd3 = nil;
                [[NSNotificationCenter defaultCenter] postNotificationName:KDSLockAuthFailedNotification object:nil userInfo:@{@"peripheral":self.connectedPeripheral, @"code":@(status)}];
            }
            break;
            
        case KDSBleTunnelOrderAlarm:
            [[NSNotificationCenter defaultCenter] postNotificationName:KDSLockDidAlarmNotification object:nil userInfo:@{@"peripheral":self.connectedPeripheral, @"data":decryptData}];
            break;
            
        default:
            break;
    }
}

/**
 *@abstract 当主动发送的任务收到回复时，根据返回的数据处理任务。
 *@param task app向蓝牙发送的任务。
 *@param data 蓝牙返回的解密数据。
 */
- (void)handleTask:(KDSBleTunnelTask *)task withData:(NSData *)data
{
    task.taskResendBlock = nil;
    const unsigned char *bytes = (const unsigned char *)data.bytes;
    unsigned char cmd = bytes[3];
    int checksum = bytes[2];
    if (cmd == 0)
    {
        //cmd=0时，是查询任务确认帧(校验码为0)不处理，或者失败了(校验码不为0)。
        if ((checksum == 0 && task.isQueryTask) || bytes[4] == (int)KDSBleErrorPending) return;
        void (^block)(NSData *data) = task.bleReplyBlock;
        self.tasksMDict[task.receipt] = nil;
        !block ?: block(data);
        return;
    }
    switch (task.order) {
        case KDSBleTunnelOrderGetUnlockRecord://查询记录有多次返回，不能直接执行block。
        case KDSBleTunnelOrderGetAlarmRecord:
            [self dealRecordData:data task:task];
            break;
            
        case KDSBleTunnelOrderGetSN:
        {
            NSMutableData *container = task.attrs[@"container"];
            if (bytes[5] == 0)
            {
                if (!container.length)
                {
                    [container appendData:data];
                }
                else//如果先收到第二段数据
                {
                    NSData *existed = [NSData dataWithData:container];
                    [container replaceBytesInRange:NSMakeRange(0, existed.length) withBytes:data.bytes length:data.length];
                    [container appendData:existed];
                }
            }
            else
            {
                [container appendData:[data subdataWithRange:NSMakeRange(6, 3)]];
            }
            if (container.length > 20)
            {
                void (^block)(NSData *data) = task.bleReplyBlock;
                self.tasksMDict[task.receipt] = nil;
                !block ?: block(container.copy);
            }
        }
            break;
            
        case KDSBleTunnelOrderGetOpRec:
            [self dealOpRecData:data task:task];
            break;
            
        default:
        {
            void (^block)(NSData *data) = task.bleReplyBlock;
            self.tasksMDict[task.receipt] = nil;
            !block ?: block(data);
        }
            break;
    }
}

/**
 *@abstract 从蓝牙返回的开锁/报警记录数据中提取开锁/报警记录。
 *@param data 蓝牙返回的开锁/报警记录数据。
 *@param task 待处理的任务，由于发送任务时设置了任务的attrs属性，因此这里需要提取isAll、group、index和container属性值。
 */
-(void)dealRecordData:(NSData *)data task:(KDSBleTunnelTask *)task
{
    const unsigned char* bytes = data.bytes;
    int total = 0, current = 0;
    id obj = nil;
    if (task.order == KDSBleTunnelOrderGetUnlockRecord)
    {
        if (bytes[8] != 2) return;//不是开锁
        KDSBleUnlockRecord *record = [[KDSBleUnlockRecord alloc] initWithData:data];
        unsigned seconds = *((unsigned *)(bytes + 10));//系统刚好是小端，所以这里的值不用再转换了。
        seconds -= [[NSTimeZone localTimeZone] secondsFromGMT];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:seconds + FixedTime];
        self.dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        record.unlockDate = [self.dateFormatter stringFromDate:date];
        total = record.total;
        current = record.current;
        obj = record;
    }
    else if (task.order == KDSBleTunnelOrderGetAlarmRecord)
    {
        KDSBleAlarmRecord *record = [[KDSBleAlarmRecord alloc] initWithData:data];
        unsigned seconds = *((unsigned *)(bytes + 10));//系统刚好是小端，所以这里的值不用再转换了。
        seconds -= [[NSTimeZone localTimeZone] secondsFromGMT];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:seconds + FixedTime];
        self.dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        record.date = [self.dateFormatter stringFromDate:date];
        total = record.total;
        current = record.current;
        obj = record;
    }
    else
    {
        return;
    }
    
    NSMutableDictionary *attrs = (NSMutableDictionary *)task.attrs;
    BOOL isAll = [attrs[@"isAll"] boolValue];
    int group = [attrs[@"group"] intValue];
    NSMutableArray *container = attrs[@"container"];
    if (isAll || group>=0) task.fireSeconds = 5;
    /*BOOL contain = NO;
    for (id record in container)
    {
        if ([record respondsToSelector:@selector(current)] && [record current] == current)
        {
            contain = YES;
            break;
        }
    }
    if (obj && !contain && total != 0) [container addObject:obj];*///返回的载荷current会不同，但其它都相同。
    if (total != 0 && ![container containsObject:obj])
    {
        [container addObject:obj];
    }
    if (isAll || group>=0)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
        task.bleReplyBlock(container);
#pragma clang disgnostic pop
        if (total == 0 && container.count == 0)
        {
            void (^block)(NSData *data) = task.bleReplyBlock;
            self.tasksMDict[task.receipt] = nil;
            !block ?: block((NSData *)container);
        }
        else if (task.timeout < 300)//对于获取多条记录来说，默认的20秒可能有点少。
        {
            task.timeout = 300;
        }
    }
    else//获取单条记录
    {
        void (^block)(NSData *data) = task.bleReplyBlock;
        self.tasksMDict[task.receipt] = nil;
        !block ?: block((NSData *)container);
    }
}

/**
 *@abstract 从蓝牙返回的操作记录数据中提取操作记录。数据接收完毕或每接收10条数据执行一次任务的回调。
 *@param data 蓝牙返回的操作记录数据。
 *@param task 待处理的任务，由于发送任务时设置了任务的attrs属性，因此这里需要提取container属性值。
 */
-(void)dealOpRecData:(NSData *)data task:(KDSBleTunnelTask *)task
{
    const unsigned char* bytes = data.bytes;
    NSLog(@"~~~~~%@", data);
    KDSBleOpRec *rec = [[KDSBleOpRec alloc] initWithData:data];
    unsigned seconds = *((unsigned *)(bytes + 13));//系统刚好是小端，所以这里的值不用再转换了。
    if (seconds != 0xffffffff)
    {
        seconds -= [[NSTimeZone localTimeZone] secondsFromGMT];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:seconds + FixedTime];
        self.dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        rec.date = [self.dateFormatter stringFromDate:date];
    }
    NSMutableArray *container = task.attrs[@"container"];
    if (rec.niketotal && ![container containsObject:rec])
    {
        //启动数据超时定时器后，停止任务超时定时器，等待数据接收间隔超时后结束任务。
        task.fireSeconds = 3;
        if (task.timeout < INT_MAX)
        {
            task.timeout = INT_MAX;
        }
        [container addObject:rec];
        NSUInteger count = container.count;
        if (count % 10 == 0)
        {
            !task.bleReplyBlock ?: task.bleReplyBlock((NSData *)container);
        }
        int fidx = [task.attrs[@"fromIndex"] intValue];
        int tidx = [task.attrs[@"toIndex"] intValue];
        if (count == tidx-fidx+1 || count == rec.niketotal || count == (rec.niketotal-fidx+1))
        {
            //当接收到的数据满足结束判定条件时，0.1秒后执行数据间隙超时定时器，回调判断container有数据，也可视为数据收发已经完毕。
            task.fireSeconds = 0.1;
        }
    }
    else
    {
        if (container.count == 0)
        {
            void (^block)(NSData *data) = task.bleReplyBlock;
            self.tasksMDict[task.receipt] = nil;
            //当没有操作记录执行回调时，可判断为数据收发已经完毕。如果首条获取到的数据就有问题(不该为0却为0)，那么这里逻辑就不对。
            !block ?: block((NSData *)container);
        }
    }
    
}

#pragma mark - 新模块发送确认帧
- (void)sendConfirmDataToBleDevice:(NSInteger)tsn{
    if (tsn != 0) {
//        [self pauseTimer];
        Byte conformByte[] = {0x00,tsn,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,};
        NSData *conformData = [[NSData alloc] initWithBytes:conformByte length:sizeof(conformByte)];
        if (self.writeCharacteristic && self.connectedPeripheral ) {///设备已经连接且要写入特征
//            KDSLog(@"发送了确认帧:%@ %@",conformData,getcurretenDate);
            [self.connectedPeripheral writeValue:conformData forCharacteristic:self.writeCharacteristic type:0];
        }
        return;
    }
    [self sendConfirmDataToOldBleDevice];
}

#pragma mark - 数制、字符串等相互间的转换
- (NSString*)convertFromDataToHexStr:(NSData *)data{
    if ([data isKindOfClass:NSString.class]) return (NSString *)data;
    if (![data isKindOfClass:NSData.class]) return @"";
    const unsigned char* dataBuffer = (const unsigned char*)[data bytes];
    NSUInteger dataLength = [data length];
    NSMutableString* hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for(int i = 0; i < dataLength; i++){
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    }
    return [NSString stringWithString:hexString];
}

- (NSString *)hexStringTransWithSmallAndBig:(NSString *)string{
    NSString *str1 = [string substringWithRange:NSMakeRange(0, 2)];
    NSString *str2= [string substringWithRange:NSMakeRange(2, 2)];
    NSString *str3= [string substringWithRange:NSMakeRange(4, 2)];
    NSString *str4= [string substringWithRange:NSMakeRange(6, 2)];
    return [NSString stringWithFormat:@"%@%@%@%@",str4,str3,str2,str1];;
}

//十进制进制数转十六进制字符串
-(NSString*)convertIntTohexStr:(int)num{
    return [NSString stringWithFormat:@"%x", num];
}
/** 16进制字符串转10进制数 */
- (UInt64)coverFromHexStrToInt:(NSString *)hexStr{
    UInt64 mac1 =  strtoul([hexStr UTF8String], 0, 16);
    return mac1;
}

/**
 *@abstract 将顺序包含yyyyMMddHHmmss(例如2019年01月17日13:27:30)信息的字符串提取为统一的格式。如果缺省会默认为字符'0'。
 *@param date 要提取的日期字符串。
 *@return 格式为yyyyMMddHHmmss的日期字符串。
 */
- (NSString *)extractDateString:(NSString *)date
{
    if (!date || date.length != strlen(date.UTF8String) || date.length != 14)
    {
        char dateC[15] = {48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48};
        int i = 0;
        NSString *sub = nil;
        for (NSUInteger j = 0; j < date.length; ++j)
        {
            sub = [date substringWithRange:NSMakeRange(j, 1)];
            if (strlen(sub.UTF8String) != 1 || sub.UTF8String[0] < 48 || sub.UTF8String[0] > 57) continue;
            dateC[i++] = sub.UTF8String[0];
        }
        dateC[14] = 0;
        date = @(dateC);
    }
    return date;
}

#pragma mark - 发送收到 入网/退网 确认帧
- (void)sendResponseInOrOutNet:(int)tsn{
    if (_connectedPeripheral.isNewDevice) {
        [self sendConfirmDataToBleDevice:tsn];
        return;
    }
    [self sendReveiveInNetOrOutNetDatToOldBleDevice];
}
#pragma mark - 发送 入网/退网成功 确认帧
- (void)sendInOrOutNetSuccessFrame{
    if (!self.connectedPeripheral.isNewDevice) {
        //新的模块不需要发送 入退网成功的确认帧 只需要在收到pdw2的时候发送即可
        //旧的模块是与App在服务器中绑定成功之后发送
        [self oldBleModelSendInNetSuccessDada];
    }
}

#pragma mark - 原始数据通过aes256加密
- (NSData *)getAes256_encryptDataWithOrigin:(NSData *)data{
    NSData *pwd1Data = [self convertHexStrToData:self.pwd1];
    NSMutableData *keyData = [NSMutableData data];
    [keyData appendData:pwd1Data];
    [keyData appendData:self.pwd3];
//    KDSLog(@"发送的原始数据:%@ 时间:%@",data,[self getcurretenDate]);
    NSData *encryptData = [[data subdataWithRange:NSMakeRange(4, 16)] aes256_encryptData:keyData];
    NSMutableData *sendData = [NSMutableData data];
    [sendData appendData:[data subdataWithRange:NSMakeRange(0, 4)]];
    [sendData appendData:encryptData];
    return sendData.copy;
}
#pragma mark - 获取解密数据
///解密数据，绑定/重置时只能使用密码1+4字节都为0的NSData解密(即密码2必须为nil)；鉴权时只能使用密码1+密码2解密(即密码3必须为nil)；鉴权成功获取密码3后只能使用密码1+密码3解密；否则解密的数据都不正确。
- (NSData *)getAes256_decryptDataWithOriginData:(NSData *)data{
    NSMutableData *keyData = [NSMutableData data];
    NSData *key1Data = [self convertHexStrToData:_pwd1];
    [keyData appendData:key1Data];
    if (self.pwd2 == nil) {//解密pwd2
        Byte behindByte[] = {0x00,0x00,0x00,0x00};
        NSData *behindData= [NSData dataWithBytes:behindByte length:sizeof(behindByte)];
        [keyData appendData:behindData];
        KDSLog(@"keyData1:%@",keyData);
        
    }else if(self.pwd2 && self.pwd3 == nil){//解密pwd3
        [keyData appendData:self.pwd2];
        KDSLog(@"keyData2:%@",keyData);
    }
    else if(self.pwd2 && self.pwd3){//建立通道以后 解密数据
        [keyData appendData:self.pwd3];
//        KDSLog(@"keyData3:%@",keyData);
    }
//    KDSLog(@"收到的原始数据:%@",data);
    NSData *resultData = [[data subdataWithRange:NSMakeRange(4, 16)] aes256_decryptData:keyData];
    NSMutableData *decryptData = [NSMutableData data];
    [decryptData appendData:[data subdataWithRange:NSMakeRange(0, 4)]];
    [decryptData appendData:resultData];
//    KDSLog(@"收到的解密后数据%@",decryptData);
    return decryptData.copy;
}
#pragma mark - 获取设备信息
- (void)getDeviceInfoWithDevType:(DeviceInfo)type{
    if (_connectedPeripheral == nil) return;
    
    switch (type) {
        case DeviceInfoSystemID:
            if(_systemIDCharacteristic)[_connectedPeripheral readValueForCharacteristic:_systemIDCharacteristic];
            break;
        case DeviceInfoModelNum:
            if(_modelNumCharacteristic)[_connectedPeripheral readValueForCharacteristic:_modelNumCharacteristic];
            break;
        case DeviceInfoSerialNum:
            if(_seriaNumCharacteristic)[_connectedPeripheral readValueForCharacteristic:_seriaNumCharacteristic];
            break;
        case DeviceInfoFirmWare:
            if(_firmwareCharacteristic)[_connectedPeripheral readValueForCharacteristic:_firmwareCharacteristic];
            break;
        case DeviceInfoHardware:
            if(_hardwareCharacteristic)[_connectedPeripheral readValueForCharacteristic:_hardwareCharacteristic];
            break;
        case DeviceInfoSoftware:
            if(_softwareCharacteristic)[_connectedPeripheral readValueForCharacteristic:_softwareCharacteristic];
            break;
        case DeviceInfoMfrName:
            if(_mfrNameCharacteristic)[_connectedPeripheral readValueForCharacteristic:_mfrNameCharacteristic];
            break;
        case DeviceInfoBattery:
            if(_batteryCharacteristic)[_connectedPeripheral readValueForCharacteristic:_batteryCharacteristic];
            break;
        default:
            break;
    }
}
#pragma mark - 获取电量
- (void)getDeviceElectric{
    if (_writeCharacteristic == nil) return;
    KDSLog(@"connectedPeripheral.name:%@",_connectedPeripheral.name);
    if (self.connectedPeripheral.isNewDevice) {
        KDSLog(@"新设备获取电量")
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self getDeviceInfoWithDevType:DeviceInfoBattery];
        });
    }else{
        [self oldBleModelbeginGetElectric];
    }
}

#pragma mark - 字符串前面自动补充字符串方法
- (NSString*)characterStringMainString:(NSString*)MainString AddDigit:(int)AddDigit AddString:(NSString*)AddString{
    NSString*ret = [[NSString alloc]init];
    ret = MainString;
    for(int y =0;y < (AddDigit - MainString.length) ;y++ ){
        ret = [NSString stringWithFormat:@"%@%@",AddString,ret];
    }
    return ret;
}

#pragma mark - 通过payload和cmd 发送指令
- (void)sendDataWithPayLoadData:(NSData *)payloadData andCmdByte:(int)cmd withTsn:(int)tsn isNotSendAgein:(BOOL)isNotSendAgin{
    if (!self.connectedPeripheral.isNewDevice || !self.pwd1 || !self.pwd3) return;
    [self pauseTimer];
    //发送新命令的时候，如果已在队列中的命令被标记了重发就取消重发，免得锁蓝牙处理混乱。
    for (KDSBleTunnelTask *task in self.tasksMDict.allValues)
    {
        task.taskResendBlock = nil;
    }
    //    NSData *payloadData  = [[NSData alloc] initWithBytes:payLoadByte length:16];
    NSData *headerData = [self getHeaderDataWithPayloadData:payloadData cmdByte:cmd withTsn:tsn];
    NSMutableData *sendData = [NSMutableData data];
    [sendData appendData:headerData];
    [sendData appendData:payloadData];
    if (cmd == KDSBleTunnelOrderGetOpRec) {
        NSLog(@"~~~~~send %@", sendData);
    }
    NSData *resultData = [self getAes256_encryptDataWithOrigin:sendData];
    if (resultData && _connectedPeripheral && _writeCharacteristic){
        [_connectedPeripheral writeValue:resultData forCharacteristic:self.writeCharacteristic type:0];
    }else if (!_connectedPeripheral||!_writeCharacteristic){

    }
    
    __weak typeof(self) weakSelf = self;
    if (!isNotSendAgin && !self.tasksMDict[@(tsn).stringValue].taskResendBlock)
    {
        self.tasksMDict[@(tsn).stringValue].taskResendBlock = ^{
            
            if (resultData && weakSelf.connectedPeripheral && weakSelf.writeCharacteristic)
            {
                [weakSelf pauseTimer];
                [weakSelf.connectedPeripheral writeValue:resultData forCharacteristic:weakSelf.writeCharacteristic type:0];
            }
            
        };
    }
}
#pragma mark - 通过payloadData和Cmd 获取header
- (NSData *)getHeaderDataWithPayloadData:(NSData *)payloadData cmdByte:(int )cmd withTsn:(int)tsn{
    Byte  *byteArray = (Byte *)[payloadData bytes];
    long vData = 0;
    for (int i = 0; i<payloadData.length; i++) {
        vData = vData +byteArray[i];
    }
    long check = (vData & 0x00ff );//取最低位&ff00表示取高位
    Byte HeaderByte[4];
    HeaderByte[0] = 0x01;
    HeaderByte[1] = tsn;
    HeaderByte[2] = check;
    HeaderByte[3] = cmd;
    NSData *HeaderData  = [[NSData alloc] initWithBytes:HeaderByte length:4];
    return HeaderData;
}

-(void)dealloc{
    [self.heartbeatTimer invalidate];
    self.heartbeatTimer=nil;
}

#pragma mark - 内部使用的蓝牙命令相关方法
static void onAdminMode(void(^*block)(void))
{
    (*block)();
}
/**
 *@abstract 根据命令类型创建一个任务。任务成功创建后，会自动添加到当前队列中。
 *@param orderType 命令类型。
 *@note 如果新创建的命令的tsn和当前队列中的命令的tsn有重复，则会删除上一个重复tsn的命令，然后把当前命令加入队列中。即旧命令会失效。
 *@return 命令对象。如果连续的tsn包含相同的命令则会返回空，否则返回的命令已设置好tsn和order属性。如果有正在进行的鉴权命令，返回鉴权命令，即必须等待鉴权命令完成才能进行其它操作。
 */
- (nullable KDSBleTunnelTask *)createTask:(KDSBleTunnelOrder)orderType
{
//    if (self.onAdminMode)
//    {
//        void(^block)(void) __attribute__((cleanup(onAdminMode), unused)) = self.onAdminModeBlock ?: (^(){});
//    }
    KDSBleTunnelTask *task = self.tasksMDict[@(self.tsn).stringValue];
    if (task.order == orderType) { return nil; }
    for (KDSBleTunnelTask *task in self.tasksMDict.allValues)
    {
        if (task.order == KDSBleTunnelOrderAuth)
        {
            return nil;
        }
    }
    task = [KDSBleTunnelTask new];
    self.tsn++;
    task.tsn = self.tsn;
    task.order = orderType;
    self.tasksMDict[@(self.tsn).stringValue] = task;
    return task;
}

/**
 *@abstract 发送蓝牙只回复成功与否的命令。仅使用pwd1和pwd3加密的新蓝牙协议用，一般用于非查询命令。
 *@param order 要发送的命令。
 *@param payload 命令的有效数据，请确保是合法的16字节且填充0的数据。
 *@param completion 超时或者收到蓝牙回复后执行的回调，error参考KDSBleError，data为蓝牙返回的数据，如果超时则为空。
 *@return 返回任务的凭证，如果任务还未执行，可以根据此凭证从队列中删除该任务。
 */
- (NSString *)sendOrder:(KDSBleTunnelOrder)order payload:(const unsigned char [])payload completion:(nullable void(^)(KDSBleError error, NSData * __nullable data))completion
{
    KDSBleTunnelTask *task = [self createTask:order];
    if (!task)
    {
        !completion ?: completion(KDSBleErrorDuplOrAuthenticating, nil);
        return @(self.tsn).stringValue;
    }
    NSString *receipt = task.receipt;
//    if (self.onAdminMode)
//    {
//        self.tasksMDict[receipt] = nil;
//        !completion ?: completion(KDSBleErrorAdminMode, nil);
//        return receipt;
//    }
    __weak typeof(self) weakSelf = self;
    task.bleReplyBlock = ^(NSData * _Nullable data) {
        weakSelf.tasksMDict[receipt] = nil;
        const unsigned char *bytes = data.bytes;//bytes[4]是执行结果。
        !completion ?: completion(!data ? KDSBleErrorNoReply : (KDSBleError)bytes[4], data);
    };
    NSData *payloadData  = [[NSData alloc] initWithBytes:payload length:16];
    [self sendDataWithPayLoadData:payloadData andCmdByte:(int)task.order withTsn:(int)task.tsn isNotSendAgein:NO];
    return receipt;
}

/**
 *@abstract 获取锁中保存的开锁、报警记录。该方法不保证能获取完整的记录。旧蓝牙只获取全部记录。
 *@param order 命令，查看开锁记录或者报警记录之一。
 *@param isAll 是否获取全部记录，如是，会忽略group和index参数。新蓝牙每获取到20条记录会执行一次回调。
 *@param group 单组记录索引，从0开始，如果超出0~9范围会忽略此参数，否则会忽略index参数。
 *@param index 单条记录索引，从0开始，超出0~199范围会忽略。
 *@param completion 每获取到20整数倍的记录时执行的回调。如果error成功，records返回记录，否则为nil。；如果records不为空且元素个数为0表示锁中没有开锁记录；如果records为空表示任务失败了；finished为YES时表示获取操作已结束。
 *@return 返回任务的凭证，如果任务还未执行，可以根据此凭证从队列中删除该任务。
 */
- (NSString *)internalGetRecordWithOrder:(KDSBleTunnelOrder)order isAll:(BOOL)isAll orAtGroup:(int)group orAtIndex:(int)index completion:(nullable void(^)(BOOL finished, KDSBleError error, NSArray * __nullable records))completion
{
    __weak typeof(self) weakSelf = self;
    if (_connectedPeripheral.isNewDevice || !self.connectedPeripheral) {//新蓝牙模块，为空是希望创建了任务执行定时器
        KDSBleTunnelTask *task = [self createTask:order];
//        if (!task)
//        {
//            !completion ?: completion(YES, self.onAdminMode ? KDSBleErrorAdminMode : KDSBleErrorDuplOrAuthenticating, nil);
//            return @(self.tsn).stringValue;
//        }
        NSString *receipt = task.receipt;
        NSMutableArray *container = [NSMutableArray array];//保存记录的数组。
        task.attrs = @{@"isAll":@(isAll), @"group":@(group), @"index":@(index), @"container":container, @"isComplete":@(NO)};
        //这里约定做个特殊的处理，获取完成后，将container传给参数data
        task.bleReplyBlock = ^(NSData * _Nullable data) {
            if (![data isKindOfClass:NSArray.class])
            {
                weakSelf.tasksMDict[receipt] = nil;
                const Byte *bytes = data.bytes;
                KDSBleError err = bytes ? (KDSBleError)bytes[4] : KDSBleErrorNoReply;
                err = container.count ? KDSBleErrorSuccess : err;
                NSArray *arr = container.count ? container.copy : nil;
                !completion ?: completion(YES, err, arr);
                return;
            }
            
            /*[container sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                if ([obj1 isKindOfClass:[KDSBleUnlockRecord class]])
                {
                    return [(KDSBleUnlockRecord *)obj1 current] > [(KDSBleUnlockRecord *)obj2 current] ? NSOrderedDescending : NSOrderedAscending;
                }
                else if ([obj1 isKindOfClass:[KDSBleAlarmRecord class]])
                {
                    return [(KDSBleAlarmRecord *)obj1 current] > [(KDSBleAlarmRecord *)obj2 current] ? NSOrderedDescending : NSOrderedAscending;
                }
                return NSOrderedAscending;
            }];*/
            if (((NSArray *)data).count == 0 && container.count == 0)
            {
                !completion ?: completion(YES, KDSBleErrorSuccess, container.copy);
            }
            else if (container.count % 20 == 0)
            {
                !completion ?: completion(NO, KDSBleErrorSuccess, container.copy);
            }
        };
        Byte payloadByte[16] = {0};
        if (isAll)
        {
            payloadByte[0] = 1;
            payloadByte[1] = 200;
            task.timeout = 300;
        }
        else if (0 <= group && group < 10)
        {
            payloadByte[0] = group * 20;
            payloadByte[1] = (group + 1) * 20;
            task.timeout = 300;
        }
        else if (0 <= index && index < 200)
        {
            payloadByte[0] = payloadByte[1] = index;
            task.timeout = 10;
        }
        else
        {
            !completion ?: completion(YES, KDSBleErrorFailure, nil);
            return @"0";
        }
        NSData *payloadData = [NSData dataWithBytes:payloadByte length:sizeof(payloadByte)];
        [self sendDataWithPayLoadData:payloadData andCmdByte:(int)task.order withTsn:(int)task.tsn isNotSendAgein:NO];
        return receipt;
    }
    //旧的蓝牙模块，读取的是全部记录。
    if (order != KDSBleTunnelOrderGetUnlockRecord)
    {
        !completion ?: completion(YES, KDSBleErrorUnsupportAttr, nil);
        return @"";
    }
    KDSBleTunnelTask *task = [KDSBleTunnelTask new];
    task.command = KDSBleOldCommandUnlockRecord;
    if (self.tasksMDict[task.receipt] != nil) return task.receipt;
    NSString *receipt = task.receipt;
    task.attrs = @{@"container" : [NSMutableArray array]};
    task.bleReplyBlock = ^(NSData * _Nullable data) {
        weakSelf.tasksMDict[receipt] = nil;
        !completion ?: completion(YES, data ? KDSBleErrorSuccess : KDSBleErrorNoReply, data ? (NSArray *)data : nil);
    };
    self.tasksMDict[task.receipt] = task;
    [self oldBleModelSendGetHistoryRecoryOrder];
    return receipt;
}

///发送命令查询用户类型，有结果返回时通知外界。
- (void)retrieveUsers
{
    if (self.retrievingUserId >= self.connectedPeripheral.maxUsers) return;
    __weak typeof(self) weakSelf = self;
    self.tsn += 1;
    [self getUserTypeWithId:@(self.retrievingUserId).stringValue KeyType:KDSBleKeyTypePIN completion:^(KDSBleError error, KDSBleUserType * _Nullable user) {
        if (error != KDSBleErrorSuccess)
        {
            [weakSelf.retrievedUsersArr addObject:[KDSBleUserType new]];
            return;
        }
        [weakSelf.retrievedUsersArr addObject:user];
        [[NSNotificationCenter defaultCenter] postNotificationName:KDSLockUsersDidUpdateNotification object:nil userInfo:@{@"users" : weakSelf.users}];
    }];
    self.retrievingUserId += 1;
}

///发送命令查询用户计划，有结果返回时通知外界。
- (void)retrieveSchedules
{
    if (self.retrievingScheduleId >= 5) return;
    __weak typeof(self) weakSelf = self;
    self.tsn += 1;
    [self getScheduleWithScheduleId:(int)self.retrievingScheduleId completion:^(KDSBleError error, KDSBleScheduleModel * _Nullable model) {
        if (error != KDSBleErrorSuccess)
        {
            [weakSelf.retrievedSchedulesArr addObject:model];
            [[NSNotificationCenter defaultCenter] postNotificationName:KDSLockSchedulesDidUpdateNotification object:nil userInfo:@{@"schedules" : weakSelf.schedules}];
        }
    }];
    self.retrievingScheduleId++;
}

/**
 *@abstract 递归获取记录。测试发现更换获取记录命令时，蓝牙一开始经常返回失败。暂时用于递归获取单组记录。
 *@param indexes 要获取的记录的索引数组。
 *@param times 递归次数，方法外调用时一般将此值设置为0，失败递归不超过4次。
 *@param order 记录类型。
 *@param container 初始时必须是一个包含0个对象的可变数组，用来保存获取到的记录。
 *@param completion 获取完成的回调，如果获取到所有索引的记录后会执行此回调，此回调的参数等于传入的container。
 */
- (void)recursiveGetRecordAtIndexes:(NSArray<NSNumber *> *)indexes times:(int)times order:(KDSBleTunnelOrder)order container:(NSMutableArray *)container completion:(void (^)(BOOL finished, KDSBleError error, NSArray * _Nonnull container))completion
{
    if (indexes.count == 0 || times > 4)
    {
        !completion ?: completion(YES, KDSBleErrorSuccess, container);
        return;
    }
    NSMutableArray<NSNumber *> *losses = [NSMutableArray arrayWithArray:indexes];
    __weak typeof(self) weakSelf = self;
    NSMutableArray<NSNumber *> *groups = nil;
    //if (losses.count > 5)
    {
        groups = [NSMutableArray array];//统计丢失的数据分在多少组。
        for (NSNumber *n in losses)
        {
            int group = n.intValue / 20;
            if (![groups containsObject:@(group)]) [groups addObject:@(group)];
        }
    }
    [self internalGetRecordWithOrder:order isAll:NO orAtGroup:groups ? groups.firstObject.intValue : -1 orAtIndex:groups ? -1 : losses.firstObject.intValue completion:^(BOOL finished, KDSBleError error, NSArray * _Nullable records) {
        if (records.count && [records.lastObject respondsToSelector:@selector(current)] && [losses containsObject:@([records.lastObject current])])
        {
            [container addObject:records.lastObject];
            [losses removeObject:@([records.lastObject current])];
            if (losses.count && times != 4 ) completion(NO, KDSBleErrorSuccess, container);
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            int _times = error==KDSBleErrorSuccess ? 0 : times + 1;
            [weakSelf recursiveGetRecordAtIndexes:losses times:_times order:order container:container completion:completion];
        });
    }];
}

/**
 *@abstract 递归获取全部记录。
 *@param times 递归次数，方法外调用时一般将此值设置为0，失败递归不超过4次。
 *@param order 记录类型。
 *@param container 初始时必须是一个包含0个对象的可变数组，用来保存获取到的记录。
 *@param completion 获取完成的回调，如果获取到所有索引的记录后会执行此回调，此回调的参数等于传入的container。如果finished为YES，递归结束。
 *@return 返回任务的凭证，如果任务还未执行，可以根据此凭证从队列中删除该任务。
 */
- (NSString *)recursiveGetAllRecords:(int)times order:(KDSBleTunnelOrder)order container:(NSMutableArray *)container completion:(void (^)(BOOL finished, KDSBleError error, NSArray * _Nonnull container))completion
{
    int total = 200;
    if ([container.firstObject respondsToSelector:@selector(total)])
    {
        total = [container.firstObject total];
    }
    if (total == container.count || times > 4)
    {
        [container sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            if ([obj1 respondsToSelector:@selector(current)] && [obj2 respondsToSelector:@selector(current)])
            {
                return [obj1 current] > [obj2 current] ? NSOrderedDescending : NSOrderedAscending;
            }
            return NSOrderedSame;
        }];
        !completion ?: completion(YES, KDSBleErrorSuccess, container);
        return @"";
    }
    __weak typeof(self) weakSelf = self;
    return [self internalGetRecordWithOrder:order isAll:YES orAtGroup:-1 orAtIndex:-1 completion:^(BOOL finished, KDSBleError error, NSArray * _Nullable records) {
        for (id record in records)
        {
            if ([record respondsToSelector:@selector(current)])
            {
                BOOL contain = NO;
                for (id rec in container)
                {
                    if ([rec respondsToSelector:@selector(current)] && [rec current] == [record current])
                    {
                        contain = YES;
                        break;
                    }
                }
                if (!contain)
                {
                    [container addObject:record];
                }
            }
        }
        if (finished)
        {
            if (total != container.count)
            {
                !completion ?: completion(NO, error, container);
            }
            else if (error == KDSBleErrorSuccess && records && records.count == 0)
            {
                !completion ?: completion(YES, error, records);
                return;
            }
            [weakSelf recursiveGetAllRecords:times + 1 order:order container:container completion:completion];
        }
        /*else if (container.count == 0 && !records)//这个条件是第一次发送命令蓝牙就超时没有回复
        {
            !completion ?: completion(YES, error, container);
        }*/
        else
        {
            !completion ?: completion(NO, error, container);
        }
    }];
}

/**
 *@abstract 递归获取全部操作记录。从0编号开始获取。
 *@param times 递归次数，方法外调用时一般将此值设置为0，失败递归不超过3次。
 *@param fidx 开始编号，不能大于500.
 *@param tidx 结束编号，不能大于500.
 *@param container 初始时必须是一个包含0个对象的可变数组，用来保存获取到的记录。
 *@param completion 成功时，获取到数据执行的回调，每10条或数据传输完毕会执行一次回调，此回调的参数等于传入的container；失败时，则首次递归就失败了。如果finished为YES，递归结束。
 *@return 返回任务的凭证，如果任务还未执行，可以根据此凭证从队列中删除该任务。
 */
- (NSString *)recursiveGetOpRecords:(int)times fromIndex:(int)fidx toIndex:(int)tidx container:(NSMutableArray<KDSBleOpRec *> *)container completion:(void (^)(BOOL finished, KDSBleError error, NSArray<KDSBleOpRec *> * _Nonnull container))completion
{
    if ((container.count && (container.firstObject.niketotal==container.count || container.firstObject.niketotal==tidx+1)) || times>=3)
    {
        !completion ?: completion(YES, KDSBleErrorSuccess, container);
        return @"";
    }
//    if (self.onAdminMode)
//    {
//        !completion ?: completion(YES, KDSBleErrorAdminMode, container);
//        return @"";
//    }
    __weak typeof(self) weakSelf = self;
    KDSBleTunnelTask *task = [self createTask:KDSBleTunnelOrderGetOpRec];
    if (!task)
    {
        !completion ?: completion(YES, KDSBleErrorDuplOrAuthenticating, container);
        return @"";
    }
    NSMutableArray<NSNumber *> *groups = nil;
    if (container.firstObject && container.firstObject.niketotal > 20)
    {
        groups = [NSMutableArray arrayWithCapacity:25];
        NSMutableArray<NSNumber *> *losses = [NSMutableArray array];
        for (int i = 0; i < container.firstObject.niketotal; ++i)
        {
            [losses addObject:@(i)];
        }
        for (KDSBleOpRec *rec in container)
        {
            if ([losses containsObject:@(rec.nikecurrent)]) [losses removeObject:@(rec.nikecurrent)];
        }
        for (NSNumber *loss in losses)
        {
            NSNumber *group = @(loss.intValue / 20);
            if (![groups containsObject:group]) [groups addObject:group];
        }
    }
    if (groups && groups.count < 25)
    {
        fidx = groups.firstObject.intValue * 20; tidx = fidx + 20;
    }
    task.attrs = @{@"container" : container, @"fromIndex":@(fidx), @"toIndex":@(tidx)};
    NSString *receipt = task.receipt;
    task.bleReplyBlock = ^(NSData * _Nullable data) {
        if (![data isKindOfClass:NSArray.class])
        {//获取操作记录时，如果超时则data为nil，否则最后一个记录获取完5秒后还没有新的记录代表蓝牙数据传输完毕。
            weakSelf.tasksMDict[receipt] = nil;
            const Byte *bytes = data.bytes;
            KDSBleError err = bytes ? (KDSBleError)bytes[4] : KDSBleErrorNoReply;
            err = container.count ? KDSBleErrorSuccess : err;
            if (err == KDSBleErrorSuccess)
            {
                [weakSelf recursiveGetOpRecords:times + 1 fromIndex:fidx toIndex:tidx container:container completion:completion];
            }
            else
            {
                !completion ?: completion(YES, err, container);
            }
            return;
        }
        if (container.count == 0)
        {
            !completion ?: completion(YES, KDSBleErrorSuccess, container);
            return;
        }
        [container sortUsingComparator:^NSComparisonResult(KDSBleOpRec *  _Nonnull obj1, KDSBleOpRec *  _Nonnull obj2) {
            return obj1.nikecurrent > obj2.nikecurrent;
        }];//考虑数据量大时的排序
        !completion ?: completion(NO, KDSBleErrorSuccess, container);
    };
    char payload[16] = {1, 3, fidx & 0xff, (fidx>>8) & 0xff, tidx & 0xff, (tidx>>8) & 0xff, 0};
    NSData *data = [[NSData alloc] initWithBytes:payload length:16];
    [self sendDataWithPayLoadData:data andCmdByte:(int)task.order withTsn:(int)task.tsn isNotSendAgein:NO];
    return receipt;
}


#pragma mark - 对外接口
#pragma mark  蓝牙功能部分
- (NSString *)authenticationWithPwd1:(NSString *)pwd1 pwd2:(id)pwd2 completion:(nullable void(^)(KDSBleError error))completion
{
    KDSBleTunnelTask *task = [self createTask:KDSBleTunnelOrderAuth];
    if (!task)
    {
        !completion ?: completion(KDSBleErrorDuplOrAuthenticating);
        return @(self.tsn).stringValue;
    }
    NSString *receipt = task.receipt;
    __weak typeof(self) weakSelf = self;
    task.bleReplyBlock = ^(NSData * _Nullable data) {
        if (!data)
        {
            weakSelf.tasksMDict[receipt] = nil;
            !completion ?: completion(KDSBleErrorNoReply);
            return;
        }
        const unsigned char *bytes = data.bytes;
        if (bytes[4] != 0 && weakSelf.pwd1)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:KDSLockAuthFailedNotification object:nil userInfo:@{@"peripheral":weakSelf.connectedPeripheral, @"code":@(bytes[4])}];
            weakSelf.pwd3 = nil;
        }
        if (!weakSelf.pwd1)//如果密码为空，有可能是绑定时还没有获取密码就已经操作绑定，此时应该获取一下序列号。
        {
            [weakSelf getDeviceInfoWithDevType:DeviceInfoSerialNum];
        }
        //0成功，1失败，0x7e未绑定(pwd2为空)，0x91鉴权内容不正确，0x9A重复，0xC0硬件错误，0xC2校验错误(一般是pwd2被修改)
        //payload的第一个字节是执行结果。
        !completion ?: completion((KDSBleError)bytes[4]);
    };
    
    NSData *pwd1Data = [self convertHexStrToData:pwd1];
    NSData *pwd2Data = pwd2;
    if ([pwd2 isKindOfClass:[NSString class]])
    {
        pwd2Data = [self convertHexStrToData:(NSString *)pwd2];
        self.pwd2 = pwd2Data;
    }
    self.pwd1 = pwd1;
    NSMutableData *keyData = [NSMutableData data];
    [keyData appendData:pwd1Data];
    [keyData appendData:pwd2Data];
    Byte payload[16] = {0};
    for (int i = 0; i < self.systemID.length; ++i)
    {
        payload[i] = ((Byte *)self.systemID.bytes)[i];
    }
    NSData *payloadData = [[NSData alloc] initWithBytes:payload length:16];
    //包头
    NSData *headerData = [self getHeaderDataWithPayloadData:payloadData cmdByte:(int)task.order withTsn:(int)task.tsn];
    //加密的数据，使用pwd1+pwd2加密系统id
    NSData *encryptData = [payloadData aes256_encryptData:keyData];
    //发送的数据
    NSMutableData *sendConnectData = [NSMutableData data];
    [sendConnectData appendData:headerData];
    [sendConnectData appendData:encryptData];
    if (self.writeCharacteristic && self.connectedPeripheral) {
        [self.connectedPeripheral writeValue:sendConnectData forCharacteristic:self.writeCharacteristic type:0];
    }
    return receipt;
}

- (void)startRetrieveUsersAndSchedules
{
    [self.retrievedUsersArr removeAllObjects];
    self.retrievingUserId = 0;
    //[self.retrievedSchedulesArr removeAllObjects];
    //self.retrievingScheduleId = 0;
}

- (NSString *)getAllUsersWithKeyType:(KDSBleKeyType)keyType completion:(void (^)(KDSBleError, NSArray<KDSBleUserType *> * _Nullable))completion
{
    Byte payload[16] = {(char)keyType, 0};
    //这个命令每条数据最多能包含100条密匙信息，超过100条密匙信息，会分开多条数据返回，这里暂时不考虑此种情况。
    return [self sendOrder:KDSBleTunnelOrderSyncKey payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {
        const unsigned char *bytes = data.bytes;
        if (!data || bytes[3] != (int)KDSBleTunnelOrderSyncKey)
        {
            KDSBleError err = !data ? KDSBleErrorNoReply : (bytes[4] == 0 ? KDSBleErrorFailure : (KDSBleError)bytes[4]);
            !completion ?: completion(err, nil);
            return;
        }
        int total = bytes[6];
        //把密匙信息占用的字节数以及位都提取出来。
        int totalBytes = ceil(bytes[6] / 8.0);
        const unsigned char *infos = bytes + 7;
        NSMutableArray<NSNumber *> *bits = [NSMutableArray arrayWithCapacity:totalBytes * 8];
        while (totalBytes)
        {
            for (char i = 7, c = *infos; i > -1; --i)
            {
                [bits addObject:@((c >> i) & 0x1)];
            }
            totalBytes--;
            infos++;
        }
        NSMutableArray<KDSBleUserType *> *users = [NSMutableArray arrayWithCapacity:total];
        for (int j = 0; j < bits.count; ++j)
        {
            if (!bits[j].intValue || bytes[5] != (int)keyType) continue;
            KDSBleUserType *user = [KDSBleUserType new];
            user.keyType = (KDSBleKeyType)bytes[5];
            user.userId = j;
            [users addObject:user];
        }
        !completion ?: completion(KDSBleErrorSuccess, users);
    }];
}

- (NSString *)updateLockClock:(nullable void (^)(KDSBleError))completion
{
    if (!self.isAdmin)
    {
        !completion ?: completion(KDSBleErrorNoReply);
        return @"";
    }
    // 得到当前时间（世界标准时间 UTC/GMT）
    NSDate *date = [NSDate date];
    // 设置系统时区为本地时区
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    // 计算本地时区与 GMT 时区的时间差
    NSInteger interval = [zone secondsFromGMT];
    //得到本地时间
    date = [date dateByAddingTimeInterval:interval];
    //本地时间距离1970年的时间
    NSTimeInterval time=[date timeIntervalSince1970];
    long long int timeTo2000 = (long long int)time - FixedTime;
    Byte payload[16] = {3, 4, 0};
    payload[2] = timeTo2000 & 0xff;
    payload[3] = (timeTo2000 >> 8) & 0xff;
    payload[4] = (timeTo2000 >> 16) & 0xff;
    payload[5] = (timeTo2000 >> 24) & 0xff;
    return [self sendOrder:KDSBleTunnelOrderUpdateLockParam payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {
        !completion ?: completion(error);
    }];
}

- (NSString *)setLockLanguage:(NSString *)language completion:(void (^)(KDSBleError))completion
{
    Byte payload[16] = {1, 2, language.UTF8String[0], language.UTF8String[1], 0};
    return [self sendOrder:KDSBleTunnelOrderUpdateLockParam payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {
        !completion ?: completion(error);
    }];
}

- (NSString *)setLockVolume:(int)volume completion:(void (^)(KDSBleError))completion
{
    Byte payload[16] = {2, 1, volume, 0};
    return [self sendOrder:KDSBleTunnelOrderUpdateLockParam payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {
        !completion ?: completion(error);
    }];
}

- (NSString *)setLockAutoLockStatus:(int)status completion:(nullable void(^)(KDSBleError error))completion
{
    Byte payload[16] = {4, 1, status, 0};
    return [self sendOrder:KDSBleTunnelOrderUpdateLockParam payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {
        !completion ?: completion(error);
    }];
}

- (NSString *)setLockLockInsideStatus:(int)status completion:(nullable void(^)(KDSBleError error))completion
{
    Byte payload[16] = {5, 1, status, 0};
    return [self sendOrder:KDSBleTunnelOrderUpdateLockParam payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {
        !completion ?: completion(error);
    }];
}

- (NSString *)setLockAwayHomeStatus:(int)status completion:(nullable void(^)(KDSBleError error))completion
{
    Byte payload[16] = {6, 1, status, 0};
    return [self sendOrder:KDSBleTunnelOrderUpdateLockParam payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {
        !completion ?: completion(error);
    }];
}

- (NSString *)setLockBleStatus:(int)status completion:(nullable void(^)(KDSBleError error))completion
{
    Byte payload[16] = {7, 1, status, 0};
    return [self sendOrder:KDSBleTunnelOrderUpdateLockParam payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {
        !completion ?: completion(error);
    }];
}

- (NSString *)setLockSecurityModeStatus:(int)status completion:(nullable void(^)(KDSBleError error))completion
{
    Byte payload[16] = {8, 1, status, 0};
    return [self sendOrder:KDSBleTunnelOrderUpdateLockParam payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {
        !completion ?: completion(error);
    }];
}

- (NSString *)operateLockWithPwd:(NSString *)pwd actionType:(KDSBleLockControl)action keyType:(KDSBleLockControl)key completion:(nullable void(^)(KDSBleError error, CBPeripheral * __nullable peripheral))completion
{
    __weak typeof(self) weakSelf = self;
    if (_connectedPeripheral.isNewDevice || !self.connectedPeripheral)
    {
        key = self.connectedPeripheral.unlockPIN ? key : KDSBleLockControlKeyAPP;
        Byte payload[16] = {0};
        payload[0] = (char)action;//Action
        payload[1] = (char)key;//CodeType
        payload[2] = 0x00;//UserID，保留
        if (key != KDSBleLockControlKeyAPP)
        {
            payload[3] = pwd.length;//密码长度
            //第4个字节开始是密码，每一个字节保存一位密码。
            for (int i = 0; i< pwd.length; i++)
            {
                payload[i + 4] = pwd.UTF8String[i];
            }
        }
        return [self sendOrder:KDSBleTunnelOrderControl payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {
            if (error == KDSBleErrorSuccess) [weakSelf getDeviceElectric];
            !completion ?: completion(error, error==KDSBleErrorSuccess ? weakSelf.connectedPeripheral : nil);
        }];
    }
    else
    {
        //这里旧模块暂时只考虑开锁功能
        if (action != KDSBleLockControlActionUnlock) return @"0";
        KDSBleTunnelTask *task = [[KDSBleTunnelTask alloc] init];
        task.command = KDSBleOldCommandLockStatus;//开锁发的是C2命令，结果却是通过B1返回，这协议是要上天？
        NSString *receipt = task.receipt;
        task.bleReplyBlock = ^(NSData * _Nullable data) {
            if (!data)
            {
                weakSelf.tasksMDict[receipt] = nil;
                !completion ?: completion(KDSBleErrorNoReply, nil);
                return;
            }
            const unsigned char *bytes = data.bytes;
            !completion ?: completion(bytes[5]==0x01 ? KDSBleErrorSuccess : KDSBleErrorFailure, weakSelf.connectedPeripheral);
        };
        self.tasksMDict[receipt] = task;
        [self oldBleModelbeginOpenLock];
        return receipt;
    }
}

- (NSString *)getUnlockRecordAtGroup:(int)group completion:(void (^)(KDSBleError, NSArray<KDSBleUnlockRecord *> * _Nullable))completion
{
    if (group < 0 || group > 9)
    {
        !completion ?: completion(KDSBleErrorInvalidField, nil);
        return @"0";
    }
    __weak typeof(self) weakSelf = self;
    return [self internalGetRecordWithOrder:KDSBleTunnelOrderGetUnlockRecord isAll:NO orAtGroup:group orAtIndex:-1 completion:^(BOOL finished, KDSBleError error, NSArray * _Nullable records) {
        if (error != KDSBleErrorSuccess)
        {
            !completion ?: completion(error, nil);
            return;
        }
        if (!finished) return;
        //如果没有获取完全部记录，判断哪些编号的没有获取到。这是第一次缺失的记录。
        NSMutableArray<NSNumber *> *losses = [NSMutableArray array];
        int index = group * 20;
        for (KDSBleUnlockRecord *record in records)
        {
            if (record.current != index)
            {
                for (int j = index; j < record.current; ++j)
                {
                    [losses addObject:@(j)];
                    index++;
                }
                index++;
                continue;
            }
            index++;
        }
        NSMutableArray<KDSBleUnlockRecord *> *mRecords = [NSMutableArray arrayWithArray:records];
        [weakSelf recursiveGetRecordAtIndexes:losses times:0 order:KDSBleTunnelOrderGetUnlockRecord container:mRecords completion:^(BOOL finished, KDSBleError error, NSArray * _Nonnull container) {
            if (finished && completion)
            {
                completion(KDSBleErrorSuccess, container.copy);
            }
        }];
    }];
}

- (NSString *)getAllUnlockRecord:(void (^)(BOOL, KDSBleError, NSArray<KDSBleUnlockRecord *> * _Nullable))completion
{
    void(^__block completion_)(BOOL, KDSBleError, NSArray<KDSBleUnlockRecord *> * _Nullable) = completion;
    NSMutableArray *container = [NSMutableArray array];
    return [self recursiveGetAllRecords:0 order:KDSBleTunnelOrderGetUnlockRecord container:container completion:^(BOOL finished, KDSBleError error, NSArray * _Nonnull container) {
        !completion_ ?: completion_(finished, error, container.copy);
        if (finished)
        {
            completion_ = nil;
        }
    }];
}

- (NSString *)getUnlockRecordAtIndex:(int)index completion:(void (^)(KDSBleError, KDSBleUnlockRecord * _Nullable))completion
{
    if (self.connectedPeripheral && !self.connectedPeripheral.isNewDevice) return @"0";//不支持
    return [self internalGetRecordWithOrder:KDSBleTunnelOrderGetUnlockRecord isAll:NO orAtGroup:-1 orAtIndex:index completion:^(BOOL finished, KDSBleError error, NSArray<KDSBleUnlockRecord *> * _Nullable records) {
        !completion ?: completion(error, records.firstObject);
    }];
}

- (NSString *)updateUnlockRecordAfterData:(NSString *)data completion:(void (^)(BOOL, KDSBleError, NSArray<KDSBleUnlockRecord *> * _Nullable))completion
{
    data = data.length<12 ? @"0000000000000" : [data substringFromIndex:12];//cmd后的数据
    void(^__block completion_)(BOOL, KDSBleError, NSArray<KDSBleUnlockRecord *> * _Nullable) = completion;
    //从效率上说先请求第一组记录，如果没有或者记录已上传过，则处理第一组记录后结束。这里的逻辑是假定开锁数据都是唯一的。
    return [self getUnlockRecordAtGroup:0 completion:^(KDSBleError error, NSArray<KDSBleUnlockRecord *> * _Nullable records) {
        if (!records.count)
        {
            !completion_ ?: completion_(YES, error, records);
            completion_ = nil;
            return;
        }
        
        BOOL after = ![data isEqualToString:[records.firstObject.hexString substringFromIndex:12]];
        if (!after)
        {
            !completion_ ?: completion_(YES, error, [NSArray array]);
            completion_ = nil;
            return;
        }
        
        after = YES;
        NSMutableArray<KDSBleUnlockRecord *> *mRecords = [NSMutableArray array];
        for (KDSBleUnlockRecord *record in records)
        {
            [mRecords addObject:record];
            if ([data isEqualToString:[record.hexString substringFromIndex:12]])
            {
                after = NO;
                break;
            }
        }
        if (!after || records.firstObject.total == records.count)
        {
            //到这儿开始，只有第一组有新数据没有上传
            !completion_ ?: completion_(YES, error, mRecords.copy);
            completion_ = nil;
            return;
        }
        !completion_ ?: completion_(NO, error, records);
        [self getAllUnlockRecord:completion_];
    }];
}

- (NSString *)setUserTypeWithId:(NSString *)userId KeyType:(KDSBleKeyType)keyType userType:(KDSBleSetUserType)userType completion:(nullable void (^)(KDSBleError))completion
{
    Byte payload[16] = {(char)keyType, userId.intValue, (char)userType, 0};
    return [self sendOrder:KDSBleTunnelOrderSetUserType payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {
        !completion ?: completion(error);
    }];
}

- (NSString *)getUserTypeWithId:(NSString *)userId KeyType:(KDSBleKeyType)keyType completion:(void (^)(KDSBleError, KDSBleUserType * _Nullable))completion
{
    NSLog(@"getUserTypeWithId");
    Byte payload[16] = {(char)keyType, userId.intValue, 0};
    return [self sendOrder:KDSBleTunnelOrderGetUserType payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {//这是查询命令，不能根据error参数判断成功与否。
        const unsigned char *bytes = data.bytes;
        if (!data || bytes[3] == 0)
        {
            KDSBleError err = !data ? KDSBleErrorNoReply : (bytes[4] == 0 ? KDSBleErrorFailure : (KDSBleError)bytes[4]);
            !completion ?: completion(err, nil);
            return;
        }
        KDSBleError err = bytes[5] == userId.intValue ? KDSBleErrorSuccess : KDSBleErrorFailure;
        err = bytes[6] == 0xff ? KDSBleErrorLockTimeout : err;
        KDSBleUserType *user = [KDSBleUserType new];
        user.keyType = (KDSBleKeyType)bytes[4];
        user.userId = bytes[5];
        user.userType = (KDSBleSetUserType)bytes[6];
        !completion ?: completion(err, err == KDSBleErrorSuccess ? user : nil);
    }];
}

- (NSString *)scheduleYMDWithScheduleId:(int)scheduleId userId:(int)userId keyType:(KDSBleKeyType)keyType begin:(NSString *)begin end:(NSString *)end completion:(nullable void(^)(KDSBleError error))completion
{
    begin = [self extractDateString:begin];
    end = [self extractDateString:end];
    self.dateFormatter.dateFormat = @"yyyyMMddHHmmss";
    NSDate *beginDate = [self.dateFormatter dateFromString:begin];
    NSDate *endDate = [self.dateFormatter dateFromString:end];
    NSInteger secondsFromGMT = [NSTimeZone systemTimeZone].secondsFromGMT;
    //距2000年1月1日0时0分0秒的秒数
    unsigned beginSec = (unsigned)(beginDate.timeIntervalSince1970 + secondsFromGMT - FixedTime);
    unsigned endSec = (unsigned)(endDate.timeIntervalSince1970 + secondsFromGMT - FixedTime);
    scheduleId = scheduleId > KDSMaxScheduleId ? KDSMaxScheduleId : scheduleId;
    Byte payload[16] = {0};
    payload[0] = (char)(scheduleId);
    payload[1] = userId;
    payload[2] = (char)keyType;
    //3~6起始日期，小端
    payload[3] = beginSec & 0xff;
    payload[4] = (beginSec >> 8) & 0xff;
    payload[5] = (beginSec >> 16) & 0xff;
    payload[6] = (beginSec >> 24) & 0xff;
    //7~10结束日期，小端
    payload[7] = endSec & 0xff;
    payload[8] = (endSec >> 8) & 0xff;
    payload[9] = (endSec >> 16) & 0xff;
    payload[10] = (endSec >> 24) & 0xff;
    return [self sendOrder:KDSBleTunnelOrderSetYMD payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {
        !completion ?: completion(error);
    }];
}

- (NSString *)getYMDScheduleWithScheduleId:(int)scheduleId completion:(void (^)(KDSBleError, KDSBleYMDModel * _Nullable))completion
{
    scheduleId = scheduleId > KDSMaxScheduleId ? KDSMaxScheduleId : scheduleId;
    Byte payload[16] = {scheduleId, 0};
    return [self sendOrder:KDSBleTunnelOrderGetYMD payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {//这是查询命令，不能根据error参数判断成功与否。
        const unsigned char *bytes = data.bytes;
        //蓝牙不区分年月日和周计划，为了区别，根据协议这里判断这3个字节是不是都为0，如果都为0则表示这是一个周计划。
        if (!data || bytes[3] == 0 || (bytes[12] == bytes[13] && bytes[13] == bytes[14] && bytes[12] == 0))
        {
            KDSBleError err = !data ? KDSBleErrorNoReply : (bytes[4] == 0 ? KDSBleErrorFailure : (KDSBleError)bytes[4]);
            !completion ?: completion(err, nil);
            return;
        }
        NSInteger secondsFromGMT = [NSTimeZone systemTimeZone].secondsFromGMT;
        uint32_t beginTime = (unsigned)(*((uint32_t *)(bytes + 7)) - secondsFromGMT);//系统是小端
        uint32_t endTime = (unsigned)(*((uint32_t *)(bytes + 11)) - secondsFromGMT);
        KDSBleError err = (bytes[4] == scheduleId && beginTime <= endTime) ? KDSBleErrorSuccess : KDSBleErrorFailure;
        KDSBleYMDModel *model = [KDSBleYMDModel new];
        model.scheduleId = bytes[4];
        model.userId = bytes[5];
        model.keyType = (KDSBleKeyType)bytes[6];
        model.beginTime = beginTime;
        model.endTime = endTime;
        !completion ?: completion(err, err == KDSBleErrorSuccess ? model : nil);
    }];
}

- (NSString *)deleteYMD:(int)scheduleId completion:(void (^)(KDSBleError))completion
{
    scheduleId = scheduleId > KDSMaxScheduleId ? KDSMaxScheduleId : scheduleId;
    Byte payload[16] = {scheduleId, 0};
    return [self sendOrder:KDSBleTunnelOrderDeleteYMD payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {
        !completion ?: completion(error);
    }];
}

- (NSString *)scheduleWeeklyWithScheduleId:(int)scheduleId userId:(int)userId keyType:(KDSBleKeyType)keyType weekMask:(int)mask beginHour:(int)beginHour beginMin:(int)beginMin endHour:(int)endHour endMin:(int)endMin completion:(void (^)(KDSBleError))completion
{
    scheduleId = scheduleId > KDSMaxScheduleId ? KDSMaxScheduleId : scheduleId;
    Byte payload[16] = {scheduleId, (char)keyType, userId, mask, beginHour, beginMin, endHour, endMin, 0};
    return [self sendOrder:KDSBleTunnelOrderSetWeekly payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {
        !completion ?: completion(error);
    }];
}

- (NSString *)getWeeklyScheduleWithScheduleId:(int)scheduleId completion:(void (^)(KDSBleError, KDSBleWeeklyModel * _Nullable))completion
{
    scheduleId = scheduleId > KDSMaxScheduleId ? KDSMaxScheduleId : scheduleId;
    Byte payload[16] = {(char)(scheduleId), 0};
    return [self sendOrder:KDSBleTunnelOrderGetWeekly payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {//这是查询命令，不能根据error参数判断成功与否。
        const unsigned char *bytes = data.bytes;
        //蓝牙不区分年月日和周计划，为了区别，根据协议这里判断这3个字节是不是都为0，如果否则表示这是一个年月日计划。
        if (!data || bytes[3] == 0 || !(bytes[12] == bytes[13] && bytes[13] == bytes[14] && bytes[12] == 0))
        {
            KDSBleError err = !data ? KDSBleErrorNoReply : (bytes[4] == 0 ? KDSBleErrorFailure : (KDSBleError)bytes[4]);
            !completion ?: completion(err, nil);
            return;
        }
        KDSBleWeeklyModel *model = [KDSBleWeeklyModel new];
        model.scheduleId = bytes[4];
        model.userId = bytes[5];
        model.keyType = (KDSBleKeyType)bytes[6];
        model.mask = bytes[7];
        model.beginHour = bytes[8];
        model.beginMin = bytes[9];
        model.endHour = bytes[10];
        model.endMin = bytes[11];
        BOOL result = bytes[4] == scheduleId;
        result = result && (bytes[10] > bytes[8] || (bytes[10] == bytes[8] && bytes[11] >= bytes[9]));
        !completion ?: completion(result ? KDSBleErrorSuccess : KDSBleErrorFailure, result ? model : nil);
    }];
}

- (NSString *)deleteWeekly:(int)scheduleId completion:(void (^)(KDSBleError))completion
{
    scheduleId = scheduleId > KDSMaxScheduleId ? KDSMaxScheduleId : scheduleId;
    Byte payload[16] = {(char)(scheduleId), 0};
    return [self sendOrder:KDSBleTunnelOrderDeleteWeekly payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {
        !completion ?: completion(error);
    }];
}

- (NSString *)getScheduleWithScheduleId:(int)scheduleId completion:(void (^)(KDSBleError, KDSBleScheduleModel * _Nullable))completion
{
    scheduleId = scheduleId > KDSMaxScheduleId ? KDSMaxScheduleId : scheduleId;
    Byte payload[16] = {scheduleId, 0};
    return [self sendOrder:KDSBleTunnelOrderGetWeekly payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {//这是查询命令，不能根据error参数判断成功与否。
        const unsigned char *bytes = data.bytes;
        //蓝牙不区分年月日和周计划，为了区别，根据协议这里判断这3个字节是不是都为0，如果否则表示这是一个年月日计划。
        if (!data)
        {
            !completion ?: completion(error, nil);
            return;
        }
        if (bytes[12] == bytes[13] && bytes[13] == bytes[14] && bytes[12] == 0)
        {
            KDSBleWeeklyModel *model = [KDSBleWeeklyModel new];
            model.scheduleId = bytes[4];
            model.userId = bytes[5];
            model.keyType = (KDSBleKeyType)bytes[6];
            model.mask = bytes[7];
            model.beginHour = bytes[8];
            model.beginMin = bytes[9];
            model.endHour = bytes[10];
            model.endMin = bytes[11];
            BOOL result = bytes[4] == scheduleId;
            result = result && (bytes[10] > bytes[8] || (bytes[10] == bytes[8] && bytes[11] >= bytes[9]));
            !completion ?: completion(result ? KDSBleErrorSuccess : KDSBleErrorFailure, result ? model : nil);
        }
        else
        {
            NSInteger secondsFromGMT = [NSTimeZone systemTimeZone].secondsFromGMT;
            uint32_t beginTime = (unsigned)(*((uint32_t *)(bytes + 7)) - secondsFromGMT);//系统是小端
            uint32_t endTime = (unsigned)(*((uint32_t *)(bytes + 11)) - secondsFromGMT);
            KDSBleError err = (bytes[4] == scheduleId && beginTime <= endTime) ? KDSBleErrorSuccess : KDSBleErrorFailure;
            KDSBleYMDModel *model = [KDSBleYMDModel new];
            model.scheduleId = bytes[4];
            model.userId = bytes[5];
            model.keyType = (KDSBleKeyType)bytes[6];
            model.beginTime = beginTime;
            model.endTime = endTime;
            !completion ?: completion(err, err == KDSBleErrorSuccess ? model : nil);
        }
    }];
}

- (NSString *)manageKeyWithPwd:(NSString *)pwd userId:(NSString *)userId action:(KDSBleKeyManageAction)action keyType:(KDSBleKeyType)keyType completion:(void (^)(KDSBleError))completion
{
    if (action == KDSBleKeyManageActionAlter)
    {
        return [self manageKeyWithPwd:pwd userId:userId action:KDSBleKeyManageActionDelete keyType:keyType completion:^(KDSBleError error) {
            if (error != KDSBleErrorSuccess)
            {
                !completion ?: completion(error);
                return;
            }
            [self manageKeyWithPwd:pwd userId:userId action:KDSBleKeyManageActionSet keyType:keyType completion:^(KDSBleError error) {
                !completion ?: completion(error);
            }];
        }];
    }
    if (action == KDSBleKeyManageActionSet && keyType == KDSBleKeyTypeAdmin) userId = @"255";
    Byte payload[16] = {(char)action, (char)keyType, userId.intValue, pwd.length, 0};
    for (int i = 0; i < pwd.length; ++i)
    {
        payload[4 + i] = pwd.UTF8String[i];
    }
    NSString *receipt = [self sendOrder:KDSBleTunnelOrderKeyManage payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {
        !completion ?: completion(error);
    }];
    if ((keyType == KDSBleKeyTypeFingerprint || keyType == KDSBleKeyTypeRFID) && action == KDSBleKeyManageActionSet)
    {
        self.tasksMDict[receipt].timeout = 80;//设置指纹/卡片命令发送确认返回超时时间设为80秒。
    }
    return receipt;
}

- (NSString *)getLockInfo:(void (^)(KDSBleError, KDSBleLockInfoModel * _Nullable))completion
{
    Byte payload[16] = {1, 0};
    return [self sendOrder:KDSBleTunnelOrderGetLockInfo payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {
        const Byte *bytes = data.bytes;
        if (!bytes || bytes[3] != (int)KDSBleTunnelOrderGetLockInfo)
        {
            !completion ?: completion(error == KDSBleErrorSuccess ? KDSBleErrorFailure : error, nil);
            return;
        }
        KDSBleLockInfoModel *model = [KDSBleLockInfoModel new];
        model.lockFunc = *(uint32_t*)(bytes + 4);
        model.lockState = *(uint32_t*)(bytes + 8);
        model.volume = bytes[12] > 2 ? - 1 : bytes[12];
        model.language = [[NSString alloc] initWithBytes:bytes + 13 length:2 encoding:NSUTF8StringEncoding];
        model.power = bytes[15];
        unsigned seconds = *((unsigned *)(bytes + 16));//系统刚好是小端，所以这里的值不用再转换了。
        seconds -= [[NSTimeZone localTimeZone] secondsFromGMT];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:seconds + FixedTime];
        self.dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        model.time = [self.dateFormatter stringFromDate:date];
        !completion ?: completion(KDSBleErrorSuccess, model);
    }];
}

- (NSString *)bindBleWithManagerPassword:(NSString *)pwd completion:(void (^)(KDSBleError))completion
{
    NSAssert(pwd.length > 4 && pwd.length == strlen(pwd.UTF8String), @"传递的管理密码不正确");//没加区分数字
    Byte payload[16] = {pwd.length, 0};
    for (int i = 0; i < pwd.length; ++i)
    {
        payload[i + 1] = pwd.UTF8String[i];
    }
    for (NSUInteger j = pwd.length; j < 16; ++j)
    {
        payload[j] = arc4random() % 256;
    }
    return [self sendOrder:KDSBleTunnelOrderBind payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {
        
    }];
}

- (NSString *)getAllAlarmRecord:(void (^)(BOOL, KDSBleError, NSArray<KDSBleAlarmRecord *> * _Nullable))completion
{
    void(^__block completion_)(BOOL, KDSBleError, NSArray<KDSBleAlarmRecord *> * _Nullable) = completion;
    NSMutableArray *container = [NSMutableArray array];
    return [self recursiveGetAllRecords:0 order:KDSBleTunnelOrderGetAlarmRecord container:container completion:^(BOOL finished, KDSBleError error, NSArray * _Nonnull container) {
        !completion_ ?: completion_(finished, error, container.copy);
        if (finished)
        {
            completion_ = nil;
        }
    }];
}

- (NSString *)getAlarmRecordAtGroup:(int)group completion:(void (^)(KDSBleError, NSArray<KDSBleAlarmRecord *> * _Nullable))completion
{
    if (group < 0 || group > 9)
    {
        !completion ?: completion(KDSBleErrorInvalidField, nil);
        return @"0";
    }
    __weak typeof(self) weakSelf = self;
    return [self internalGetRecordWithOrder:KDSBleTunnelOrderGetAlarmRecord isAll:NO orAtGroup:group orAtIndex:-1 completion:^(BOOL finished, KDSBleError error, NSArray * _Nullable records) {
        if (error != KDSBleErrorSuccess)
        {
            !completion ?: completion(error, nil);
            return;
        }
        
        if (!finished) return;
        //如果没有获取完全部记录，判断哪些编号的没有获取到。这是第一次缺失的记录。
        NSMutableArray<NSNumber *> *losses = [NSMutableArray array];
        int index = group * 20;
        for (KDSBleAlarmRecord *record in records)
        {
            if (record.current != index)
            {
                for (int j = index; j < record.current; ++j)
                {
                    [losses addObject:@(j)];
                    index++;
                }
                index++;
                continue;
            }
            index++;
        }
        //由于并不是所有的锁都支持获取单条记录，这里的逻辑是，如果一次获取不完整，再继续获取，然后合并数据，最多3次。
        NSMutableArray<KDSBleAlarmRecord *> *mRecords = [NSMutableArray arrayWithArray:records];
        [weakSelf recursiveGetRecordAtIndexes:losses times:0 order:KDSBleTunnelOrderGetAlarmRecord container:mRecords completion:^(BOOL finished, KDSBleError error, NSArray * _Nonnull container) {
            if (finished && completion)
            {
                completion(KDSBleErrorSuccess, container.copy);
            }
        }];
    }];
}

- (NSString *)getAlarmRecordAtIndex:(int)index completion:(void (^)(KDSBleError, KDSBleAlarmRecord * _Nullable))completion
{
    return [self internalGetRecordWithOrder:KDSBleTunnelOrderGetAlarmRecord isAll:NO orAtGroup:-1 orAtIndex:index completion:^(BOOL finished, KDSBleError error, NSArray<KDSBleAlarmRecord *> * _Nullable records) {
        !completion ?: completion(error, records.firstObject);
    }];
}

- (NSString *)updateAlarmRecordAfterData:(NSString *)data completion:(void (^)(BOOL, KDSBleError, NSArray<KDSBleAlarmRecord *> * _Nullable))completion
{
    data = data.length<12 ? @"0000000000000" : [data substringFromIndex:12];//cmd后的数据
    void(^__block completion_)(BOOL, KDSBleError, NSArray<KDSBleAlarmRecord *> * _Nullable) = completion;
    //从效率上说先请求第一组记录，如果没有或者记录已上传过，则处理第一组记录后结束。这里的逻辑是假定报警数据都是唯一的。
    return [self getAlarmRecordAtGroup:0 completion:^(KDSBleError error, NSArray<KDSBleAlarmRecord *> * _Nullable records) {
        if (!records.count)
        {
            !completion_ ?: completion_(YES, error, records);
            completion_ = nil;
            return;
        }
        
        BOOL after = ![data isEqualToString:[records.firstObject.hexString substringFromIndex:12]];
        if (!after)
        {
            !completion_ ?: completion_(YES, error, [NSArray array]);
            completion_ = nil;
            return;
        }
        
        after = YES;
        NSMutableArray<KDSBleAlarmRecord *> *mRecords = [NSMutableArray array];
        for (KDSBleAlarmRecord *record in records)
        {
            [mRecords addObject:record];
            if ([data isEqualToString:[record.hexString substringFromIndex:12]])
            {
                after = NO;
                break;
            }
        }
        if (!after || records.firstObject.total == records.count)
        {
            //到这儿开始，只有第一组有新数据没有上传
            !completion_ ?: completion_(YES, error, mRecords.copy);
            completion_ = nil;
            return;
        }
        !completion_ ?: completion_(NO, error, records);
        for (KDSBleTunnelTask *task in self.tasksMDict.allValues)
        {
            NSLog(@"%ld", task.order);
        }
        [self getAllAlarmRecord:completion_];
    }];
}

- (NSString *)getSN:(void (^)(KDSBleError, NSString * _Nullable))completion
{
    KDSBleTunnelTask *task = [self createTask:KDSBleTunnelOrderGetSN];
//    if (!task)
//    {
//        !completion ?: completion(self.onAdminMode ? KDSBleErrorAdminMode : KDSBleErrorDuplOrAuthenticating, nil);
//        return @(self.tsn).stringValue;
//    }
    __weak typeof(self) weakSelf = self;
    NSString *receipt = task.receipt;
    //如果成功，前六个字节装头数据，七至二十三装序列号。
    task.attrs = @{@"container": [NSMutableData dataWithCapacity:17]};
    task.bleReplyBlock = ^(NSData * _Nullable data) {
        const unsigned char *bytes = data.bytes;
        weakSelf.tasksMDict[receipt] = nil;
        KDSBleError error = !data ? KDSBleErrorNoReply : (data.length == 20 ? (KDSBleError)bytes[4] : KDSBleErrorSuccess);
        !completion ?: completion(error, error == KDSBleErrorSuccess ? [[NSString alloc] initWithBytes:bytes + 6 length:17 encoding:NSUTF8StringEncoding] : nil);
    };
    Byte payload[16] = {0};
    [self sendDataWithPayLoadData:[[NSData alloc] initWithBytes:payload length:16] andCmdByte:(int)task.order withTsn:(int)task.tsn isNotSendAgein:NO];
    return receipt;
}

- (NSString *)getUnlockTimes:(void (^)(KDSBleError, int))completion
{
    Byte payload[16] = {0};
    return [self sendOrder:KDSBleTunnelOrderGetTimes payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {
        const Byte *bytes = data.bytes;
        if (!bytes)
        {
            !completion ?: completion(KDSBleErrorNoReply, -1);
            return;
        }
        KDSBleError err = bytes[3] == KDSBleTunnelOrderGetTimes ? KDSBleErrorSuccess : (KDSBleError)bytes[4];
        !completion ?: completion(err, err == KDSBleErrorSuccess ? *(unsigned*)(bytes+4) : -1);
    }];
}

- (NSString *)getLockParam:(int)type completion:(void (^)(KDSBleError, id _Nullable))completion
{
    Byte payload[16] = {type, 0};
    __weak typeof(self) weakSelf = self;
    return [self sendOrder:KDSBleTunnelOrderGetParam payload:payload completion:^(KDSBleError error, NSData * _Nullable data) {
        
        if (!completion) return;
        if (error != KDSBleErrorSuccess || !data)
        {
            completion(error, nil);
            return;
        }
        const uint8_t *bytes = data.bytes;
        //bytes[5] == type ??
        switch (type) {
            case 1:
                completion(error, [data subdataWithRange:NSMakeRange(6, 14)]);
                break;
            case 2:
            case 3:
            case 4:
            {
                NSString *value = @((const char*)bytes + 6);
                if (type == 2)
                {
                    NSRange range = [value rangeOfString:@"0"];
                    if (range.location != NSNotFound)
                    {
                        value = [value substringToIndex:range.location];
                    }
                    /*
                     if (weakSelf.connectedPeripheral.bleVersion > 2 && value.length > 2)
                     {
                     value = [value substringToIndex:value.length - 2];
                     }
                     */
                }
                completion(error, value);
            }
                break;
                
            case 5:
                completion(error, @(bytes[6]));
                break;
                
            default:
                completion(KDSBleErrorInvalidField, nil);//参数不正确
                break;
        }
    }];
}


- (NSString *)getOpRecAfterData:(NSString *)data completion:(void (^)(BOOL, KDSBleError, NSArray<KDSBleOpRec *> * _Nullable))completion
{
    int toIndex = data ? 20 : 500;
    NSMutableArray *container = [NSMutableArray array];
    __block void(^_completion)(BOOL, KDSBleError, NSArray *) = completion;
    __weak typeof(self) weakSelf = self;
    return [self recursiveGetOpRecords:0 fromIndex:0 toIndex:toIndex container:container completion:^(BOOL finished, KDSBleError error, NSArray<KDSBleOpRec *> * _Nonnull container) {
        if (!finished)
        {
            !_completion ?: _completion(NO, error, container.copy);
        }
        else
        {
            KDSBleOpRec *rec = [[KDSBleOpRec alloc] initWithHexString:data];
            BOOL after = rec && [container containsObject:rec];
            if (((data && !after) || data.length < 40) && container.count)
            {
                [weakSelf recursiveGetOpRecords:0 fromIndex:container.count==toIndex ? toIndex : 0 toIndex:500 container:container completion:^(BOOL finished, KDSBleError error, NSArray<KDSBleOpRec *> * _Nonnull container) {
                    if (!finished)
                    {
                        !_completion ?: _completion(NO, error, container.copy);
                    }
                    else
                    {
                        !_completion ?: _completion(YES, error, container.count ? container.copy : nil);
                        _completion = nil;
                    }
                }];
            }
            else
            {
                !_completion ?: _completion(YES, error, error==KDSBleErrorSuccess ? container.copy : nil);
                _completion = nil;
            }
        }
    }];
}

- (void)cancelTaskWithReceipt:(NSString *)receipt
{
    if (receipt.length == 0 || receipt.intValue == 0) return;
    self.tasksMDict[receipt].bleReplyBlock = nil;
    self.tasksMDict[receipt] = nil;
}

#pragma mark 其它对外接口
- (NSData *)convertHexStrToData:(NSString *)str{
    if (![str isKindOfClass:NSString.class] || [str length] == 0) {
        return [NSData data];
    }
    str = (str.length % 2 == 0) ? str : [@"0" stringByAppendingString:str];
    unsigned char bytes[str.length / 2];
    for (int i = 0; i < str.length; i += 2)
    {
        bytes[i / 2] = strtol([str substringWithRange:NSMakeRange(i, 2)].UTF8String, NULL, 16);
    }
    
    return [[NSData alloc] initWithBytes:bytes length:str.length / 2];
}
#pragma mark - 重启DFU服务
- (void)resetDFU:(CBPeripheral *)peripheral{
    ///对2A06写ASCII码01，重启DFU服务
    Byte byte[1];
    byte[0] = 1;//写入<01>启动DFU复位服务
    NSData *data = [NSData dataWithBytes:byte length:sizeof(byte)];
    
    NSLog(@"--00--00--data===%@,%@,%@",data,self.OADCharacteristic,self);
    ///对于P6平台的2A06，需要CBCharacteristicWriteWithoutResponse才能写入成功。
    [self.connectedPeripheral writeValue:data forCharacteristic:self.DFUCharacteristic type:CBCharacteristicWriteWithoutResponse];
}
@end
