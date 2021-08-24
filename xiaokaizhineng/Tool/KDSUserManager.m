//
//  KDSUserManager.m
//  xiaokaizhineng
//
//  Created by orange on 2019/1/25.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSUserManager.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

NSString * const KDSLockHasBeenDeletedNotification = @"KDSLockHasBeenDeletedNotification";
NSString * const KDSLockHasBeenAddedNotification = @"KDSLockHasBeenAddedNotification";
NSString * const KDSLogoutNotification = @"KDSLogoutNotification";

@interface KDSUserManager ()

///记录报警数据的数组，每个对象为字典，字典的key保存蓝牙名称，value保存蓝牙返回的报警数据。
@property (nonatomic, strong) NSMutableArray<NSDictionary<NSString *, NSData *> *> *alarms;
///轮询报警数据的定时器。当有报警数据添加时就会启动该定时器，当报警数据处理完毕时应该销毁该定时器。
@property (nonatomic, strong) NSTimer *alarmTimer;
///报警标签的背景视图。
@property (nonatomic, strong) UIView *bgView;
///报警标签，展示报警信息。
@property (nonatomic, strong) UILabel *alarmLabel;

@end

@implementation KDSUserManager

+ (instancetype)sharedManager
{

    static KDSUserManager *_manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[KDSUserManager alloc] init];
    });
    return _manager;
}

#pragma mark - 懒加载
- (NSMutableArray<KDSLock *> *)locks
{
    if (!_locks)
    {
        _locks = [NSMutableArray array];
    }
    return _locks;
}
- (NSMutableArray *)weekSelectArray
{
    if (!_weekSelectArray)
    {
        _weekSelectArray = [NSMutableArray array];
    }
    return _weekSelectArray;
}
- (NSMutableArray<NSDictionary<NSString *,NSData *> *> *)alarms
{
    if (!_alarms)
    {
        _alarms = [NSMutableArray array];
    }
    return _alarms;
}

- (NSTimer *)alarmTimer
{
    if (!_alarmTimer)
    {
        _alarmTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(alarmTimerHandleAlarm:) userInfo:nil repeats:YES];
    }
    return _alarmTimer;
}

- (UIView *)bgView
{
    if (!_bgView)
    {
        _bgView = [[UIView alloc] initWithFrame:CGRectMake(0, -(kStatusBarHeight + kNavBarHeight), kScreenWidth, kStatusBarHeight + kNavBarHeight)];
        _bgView.backgroundColor = UIColor.lightGrayColor;
        [_bgView addSubview:self.alarmLabel];
    }
    return _bgView;
}

- (UILabel *)alarmLabel
{
    if (!_alarmLabel)
    {
        _alarmLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, kStatusBarHeight, kScreenWidth - 40, kNavBarHeight)];
        _alarmLabel.numberOfLines = 0;
    }
    return _alarmLabel;
}

#pragma mark - 内部接口。
///报警定时器触发时，每执行一次处理第一个报警记录，然后将其从记录中删除，当报警记录处理完毕后销毁定时器。
- (void)alarmTimerHandleAlarm:(NSTimer *)timer
{
    NSDictionary<NSString *, NSData *> *dict = self.alarms.firstObject;
    NSData *data = dict.allValues.firstObject;
    const Byte *bytes = data.bytes;
    if (!bytes)
    {
        [UIView animateWithDuration:0.3 animations:^{
            CGRect frame = self.bgView.frame;
            frame.origin.y -= frame.size.height;
            self.bgView.frame = frame;
        } completion:^(BOOL finished) {
            
            [self.bgView removeFromSuperview];
            self.bgView = nil;
            self.alarmLabel = nil;
            
        }];
        [self.alarmTimer invalidate];
        self.alarmTimer = nil;
        return;
    }
    unsigned info = *(unsigned*)(bytes + 8);//00000000 00000000 00000000 0010 0110
    NSLog(@"info==%d",info);//132->1000 0100 84->0101 0100
    printf("\n");
    for (int i = 0; i < 32; ++i)
    {
        printf("%d", (info>>(31 - i)) & 0x1);
        if (i %4 == 0 && i > 0) printf("  ");
    }
    printf("\n");
    BOOL lowPower = info & 0x1;//低电量报警。
    BOOL locked = (info >> 1) & 0x1;//锁定报警。
    BOOL error3Times = (info >> 2) & 0x1;//3次错误报警。
    BOOL defence = (info >> 3) & 0x1;//布防报警。
    BOOL temperature = (info >> 4) & 0x1;//温度报警。
    BOOL force = (info >> 5) & 0x1;//胁迫报警。
    BOOL reset = (info >> 6) & 0x1;//恢复出厂设置报警。
    BOOL violence = (info >> 7) & 0x1;//暴力开锁报警。
    BOOL leave = (info >> 8) & 0x1;//钥匙遗落在锁上报警。
    BOOL security = (info >> 9) & 0x1;//安全模式报警。
    BOOL uncomplete = (info >> 12 || info >> 10) & 0x1;//未完全上锁报警。
    NSString *nickname = dict.allKeys.firstObject;
    for (KDSLock *lock in self.locks)
    {
        if ([lock.device.device_name isEqualToString:dict.allKeys.firstObject])
        {
            nickname = lock.device.device_nickname ?: lock.device.device_name;
        }
    }
    NSMutableString *mStr = [NSMutableString stringWithFormat:@"%@%@%@: ", Localized(@"lock"), nickname, Localized(@"alarm")];
    NSInteger length = mStr.length;
    !lowPower ?: [mStr appendString:Localized(@"lowPower")];
    !locked ?: [mStr appendFormat:@"%@%@", mStr.length>length ? @"; " : @"", Localized(@"systemLocked")];
    !error3Times ?: [mStr appendFormat:@"%@%@", mStr.length>length ? @"; " : @"", Localized(@"multiVerifyFail")];
    !defence ?: [mStr appendFormat:@"%@%@", mStr.length>length ? @"; " : @"", Localized(@"activeDefence")];
    !temperature ?: [mStr appendFormat:@"%@%@", mStr.length>length ? @"; " : @"",Localized(@"temperatureException")];
    !force ?: [mStr appendFormat:@"%@%@", mStr.length>length ? @"; " : @"", Localized(@"forceUnlock")];
    !reset ?: [mStr appendFormat:@"%@%@", mStr.length>length ? @"; " : @"", Localized(@"lockHasBeenReset")];
    !violence ?: [mStr appendFormat:@"%@%@", mStr.length>length ? @"; " : @"", Localized(@"violenceUnlock")];
    !leave ?: [mStr appendFormat:@"%@%@", mStr.length>length ? @"; " : @"", Localized(@"keyLeftInLock")];
    !security ?: [mStr appendFormat:@"%@%@", mStr.length>length ? @"; " : @"", Localized(@"securityModeOpen")];
    !uncomplete ?: [mStr appendFormat:@"%@%@", mStr.length>length ? @"; " : @"", Localized(@"lockUncomplete")];
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:mStr attributes:@{NSForegroundColorAttributeName : UIColor.redColor}];
    CGRect bounds = [mStr boundingRectWithSize:CGSizeMake(kScreenWidth - 40, kScreenHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:16]} context:nil];
    [attrStr addAttribute:NSForegroundColorAttributeName value:KDSRGBColor(0x2d, 0xd9, 0xba) range:[mStr rangeOfString:nickname]];
    [attrStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:bounds.size.height > kNavBarHeight ? 12 : 16] range:NSMakeRange(0, mStr.length)];
    self.alarmLabel.attributedText = attrStr;
    if (!self.bgView.superview)
    {
        [[UIApplication sharedApplication].keyWindow addSubview:self.bgView];
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.bgView.frame = self.bgView.bounds;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [UIView animateWithDuration:0.3 animations:^{
                CGRect frame = self.bgView.frame;
                frame.origin.y -= frame.size.height;
                self.bgView.frame = frame;
            } completion:^(BOOL finished) {
                if (self.alarms.count)
                {
                    [self.alarms removeObjectAtIndex:0];
                }
                if (!self.alarms.count)
                {
                    [self.bgView removeFromSuperview];
                    self.bgView = nil;
                    self.alarmLabel = nil;
                    [self.alarmTimer invalidate];
                    self.alarmTimer = nil;
                }
                
            }];
            
        });
    }];
}

#pragma mark - 对外接口。
- (void)addAlarmForLockWithBleName:(NSString *)bleName data:(NSData *)alarmData
{
    if (alarmData.length != 20) return;
    /*const Byte *bytes = alarmData.bytes;
    unsigned info = *(unsigned*)(bytes + 8);
    BOOL lowPower = info & 0x1;//低电量报警。
    BOOL attempt = (info >> 1) & 0x1;//试开报警。
    BOOL teardown = (info >> 2) & 0x1;//防拆报警。
    BOOL defence = (info >> 3) & 0x1;//布防报警。
    BOOL temperature = (info >> 4) & 0x1;//温度报警。
    BOOL force = (info >> 5) & 0x1;//胁迫报警。
    BOOL reset = (info >> 6) & 0x1;//恢复出厂设置报警。
    BOOL violence = (info >> 7) & 0x1;//暴力开锁报警。
    BOOL leave = (info >> 8) & 0x1;//钥匙遗落在锁上报警。
    BOOL security = (info >> 9) & 0x1;//安全模式报警。
    BOOL uncomplete = (info >> 10) & 0x1;//未完全上锁报警 。*/
    if (![KDSTool getNotificationOnForBle:bleName])
    {
        
    }
    [self.alarms addObject:@{bleName : alarmData}];
    if (!_alarmTimer)
    {
        self.alarmTimer.fireDate = NSDate.date;
    }
}

- (void)resetManager
{
    [_alarmTimer invalidate];
    _alarmTimer = nil;
    [_bgView removeFromSuperview];
    unsigned count = 0;
    Ivar *ivars = class_copyIvarList([self class], &count);
    for (unsigned i = 0; i < count; ++i)
    {
        object_setIvar(self, ivars[i], nil);
    }
    free(ivars);
}

@end
