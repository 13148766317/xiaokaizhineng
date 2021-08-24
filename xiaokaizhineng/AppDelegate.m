//
//  AppDelegate.m
//  xiaokaizhineng
//
//  Created by orange on 2019/1/14.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "AppDelegate.h"
#import "KDSLoginVC.h"
#import "IQKeyboardManager.h"
#import "KDSTool.h"
#import "KDSNavigationController.h"
#import "KDSTabBarController.h"
#import "KDSHttpManager.h"
#import "KDSDBManager.h"
#import "KDSSecurityAuthenticationVC.h"
#import "KDSTutorialVC.h"
#import "WXApi.h"
#import "MBProgressHUD+MJ.h"
#import <Bugly/Bugly.h>

@interface AppDelegate ()<WXApiDelegate>

@end

@implementation AppDelegate

#pragma mark - UIApplicationDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    [KDSTool setLanguage:nil];
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
//    为了避免push和pop时导航条出现的黑块，给window设置一个背景色
    self.window.backgroundColor = [UIColor whiteColor];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginTokenExpired:) name:KDSHttpTokenExpiredNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logout:) name:KDSLogoutNotification object:nil];
    
    [IQKeyboardManager sharedManager].enable = YES;
    [IQKeyboardManager sharedManager].shouldResignOnTouchOutside = YES;
    [IQKeyboardManager sharedManager].enableAutoToolbar = NO;
    
    if (@available(iOS 11.0, *)) {
        UIScrollView.appearance.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        UITableView.appearance.estimatedRowHeight = 0;
        UITableView.appearance.estimatedSectionHeaderHeight = 0;
        UITableView.appearance.estimatedSectionFooterHeight = 0;
    }
    //向微信注册
    [WXApi registerApp:@"wx073373a05e563cf8"];
    //bugly注册
    [Bugly startWithAppId:@"88cb363b8c"];
    //监听网络状态
    [self monitorNetWork];
    //iOS 12.1 tabBar跳动的问题
    [UITabBar appearance].translucent = NO;
    //UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
    //[application registerUserNotificationSettings:settings];
    //[self setRootViewController];
    [self applicationWillEnterForeground:application];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)monitorNetWork{
    AFNetworkReachabilityManager *afNetworkReachabilityManager = [AFNetworkReachabilityManager sharedManager];
    //        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(afNetworkStatusChanged:) name:AFNetworkingReachabilityDidChangeNotification object:nil];//这个可以放在需要侦听的页面
    [afNetworkReachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusNotReachable:{
                KDSLog(@"网络状态：当前手机断网了-%@",@(status) );
                [KDSUserManager sharedManager].netWorkIsAvailable = NO;
                [MBProgressHUD showError:Localized(@"networkNotAvailable")];
                break;
            }
            case AFNetworkReachabilityStatusReachableViaWiFi:{
                KDSLog(@"网络状态：通过WIFI连接-%@",@(status));
                [KDSUserManager sharedManager].netWorkIsAvailable = YES;
                break;
            }
            case AFNetworkReachabilityStatusReachableViaWWAN:{
                KDSLog(@"网络状态：通过手机网络连接-%@",@(status) );
                [KDSUserManager sharedManager].netWorkIsAvailable = YES;
                break;
            }
            default:
                break;
        }
    }];
    [afNetworkReachabilityManager startMonitoring];  //开启网络监视器；
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return  [WXApi handleOpenURL:url delegate:self];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [WXApi handleOpenURL:url delegate:self];
}
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    KDSDBManager *manager = [KDSTool getDefaultLoginAccount].length ? [KDSDBManager sharedManager] : nil;
    UIViewController *vc = self.window.rootViewController;
    if (!vc && [manager queryUser].token.length==0)
    {
        [self setRootViewController];
        return;
    }
    if ([vc isKindOfClass:UINavigationController.class])/**登录页面的导航控制器*/
    {
        return;
    }
    //剩下的有3种情况：1、根控制器是登录后的UITabBarController；2、APP刚启动，根控制器为nil；3、根控制器是安全验证控制器。
    BOOL after = [manager queryAuthenticationState];
    if (!after)
    {
        NSDate *date = [manager queryUserAuthDate];
        after = !date ?: (date.timeIntervalSinceNow<-60 || date.timeIntervalSinceNow>=0);//1分钟后
        if (after)
        {
            [manager updateAuthenticationState:YES];
        }
    }
    BOOL tEnable = [manager queryUserTouchIDState];
    BOOL gEnagle = [manager queryUserGesturePwdState];
    if ([vc isKindOfClass:UITabBarController.class])
    {
        vc = ((UITabBarController *)vc).selectedViewController;
        while (vc.presentedViewController)
        {
            vc = vc.presentedViewController;
        }
    }
    after = [vc isKindOfClass:KDSSecurityAuthenticationVC.class]/**已经是验证控制器*/ ? NO : after;
    if ((tEnable || gEnagle) && after)
    {
        KDSSecurityAuthenticationVC *savc = [KDSSecurityAuthenticationVC new];
        savc.finishBlock = ^(BOOL success) {
            vc ?: [self setRootViewController];
        };
        UIAlertController *ac = nil;
        while ([vc isKindOfClass:UIAlertController.class])//alert弹框验证完毕后会移动到左上角。
        {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-pointer-types"
            ac = vc;
#pragma clang diagnostic pop
            vc = vc.presentingViewController;
            [ac dismissViewControllerAnimated:NO completion:nil];
        }
        vc ? [vc presentViewController:savc animated:NO completion:nil] : (void)(self.window.rootViewController = savc);
    }
    else if (!vc)//没有满足安全验证条件且刚启动时
    {
        [self setRootViewController];
    }
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    //applicationWillEnterForeground:
    
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
#pragma mark - WeChat回调处理
// 如果第三方程序向微信发送了sendReq的请求，那么onResp会被回调。sendReq请求调用后，会切到微信终端程序界面
- (void)onResp:(BaseResp *)resp
{
    NSLog(@"回调处理");
    
    // 处理 分享请求 回调
    if ([resp isKindOfClass:[SendMessageToWXResp class]]) {
        switch (resp.errCode) {
            case WXSuccess:
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示"
                                                                message:@"分享成功!"
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil, nil];
                [alert show];
            }
                break;
                
            default:
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示"
                                                                message:@"分享失败!"
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil, nil];
                [alert show];
            }
                break;
        }
    }
}

#pragma mark - 其它方法
/**
 *@abstract 设置应用窗口的根控制器。
 */
- (void)setRootViewController
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasFinishedTutorial"])
    {
        KDSTutorialVC *vc = [KDSTutorialVC new];
        vc.tutorialComplete = ^{
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasFinishedTutorial"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self setRootViewController];
        };
        self.window.rootViewController = vc;
        return;
    }
    NSString *account = [KDSTool getDefaultLoginAccount];
    if (account.length)
    {
        KDSUser *user = [[KDSDBManager sharedManager] queryUser];
        if (user.token.length)
        {
            [KDSUserManager sharedManager].user = user;
            [KDSUserManager sharedManager].userNickname = [[KDSDBManager sharedManager] queryUserNickname];
            [KDSHttpManager sharedManager].token = user.token;
            KDSTabBarController *tab = [KDSTabBarController new];
            self.window.rootViewController = tab;
            return;
        }
    }
    
    KDSLoginVC *loginVC = [KDSLoginVC new];
    KDSNavigationController *nav = [[KDSNavigationController alloc] initWithRootViewController:loginVC];
    self.window.rootViewController = nav;
}

#pragma mark - 通知
///登录token过期通知。
- (void)loginTokenExpired:(NSNotification *)noti
{
    //如果以后需要清空一些变量等，可以在这个方法执行。
    KDSUser *user = [KDSUserManager sharedManager].user;
    user.token = nil;
    [[KDSDBManager sharedManager] updateUser:user];
    [[KDSUserManager sharedManager] resetManager];
    [[KDSDBManager sharedManager] resetDatabase];
    [self setRootViewController];
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:Localized(@"tokenExpired") message:Localized(@"pleaseRelogin") preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:Localized(@"ok") style:UIAlertActionStyleDefault handler:nil];
    [ac addAction:action];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:ac animated:YES completion:nil];
}

///退出登录通知。
- (void)logout:(NSNotification *)noti
{
    //启动时安全验证页选择使用密码登录时，用户管理单例的user属性为空。
    KDSUser *user = [KDSUserManager sharedManager].user ?: [[KDSDBManager sharedManager] queryUser];
    user.token = nil;
    [[KDSDBManager sharedManager] updateUser:user];
    [[KDSDBManager sharedManager] resetDatabase];
    [[KDSUserManager sharedManager] resetManager];
    [self setRootViewController];
}

@end
