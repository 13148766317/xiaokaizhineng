//
//  KDSHttpManager.m
//  xiaokaizhineng
//
//  Created by orange on 2019/1/21.
//  Copyright © 2019年 shenzhen kaadas intelligent technology. All rights reserved.
//

#import "KDSHttpManager.h"

NSString * const KDSHttpTokenExpiredNotification = @"KDSHttpTokenExpiredNotification";

@implementation KDSHttpManager

+ (instancetype)sharedManager
{
    static KDSHttpManager *_manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[KDSHttpManager alloc] init];
    });
    return _manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        if (_afManager == nil)
        {
            _afManager = [AFHTTPSessionManager manager];
            _afManager.requestSerializer = [AFJSONRequestSerializer serializer];
            //设置返回格式
            _afManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html",@"text/json",@"text/javascript", @"text/plain",@"image/jpeg",@"image/png",@"image/jpg",nil];
            [_afManager.requestSerializer setValue:[KDSTool getIphoneType] forHTTPHeaderField:@"phoneName"];
            _afManager.securityPolicy = [self customSecurityPolicy];
            //超时时间
            [_afManager.requestSerializer setTimeoutInterval:20.f];
        }
    }
    return self;
}

-(void)createResErrorWithCode:(NSInteger)code{
    NSString *domain = @"请求返回错误";
    NSString *desc = [KDSHttpResOption httpResponseLocalizeWithCode:code];
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:desc };
    self.resError = [NSError errorWithDomain:domain
                                         code:code
                                     userInfo:userInfo];
    
}
- (void)setToken:(NSString *)token
{
    _token = token;
    if (token)
    {
        [self.afManager.requestSerializer setValue:token forHTTPHeaderField:@"token"];
    }
}

- (AFSecurityPolicy *)customSecurityPolicy {
    //先导入证书
    NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"server" ofType:@"p12"];
    //证书的路径
    NSData *certData = [NSData dataWithContentsOfFile:cerPath];
    // AFSSLPinningModeNone 使用证书验证模式
    //这个模式表示不做SSL pinning，
    //只跟浏览器一样在系统的信任机构列表里验证服务端返回的证书。若证书是信任机构签发的就会通过，若是自己服务器生成的证书就不会通过。
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    NSSet *certificateSet  = [[NSSet alloc] initWithObjects:certData, nil];
    [securityPolicy setPinnedCertificates:certificateSet];
    //validatesDomainName 是否需要验证域名，默认为YES；
    //    securityPolicy.validatesDomainName = YES; // 关键语句1
    //假如证书的域名与你请求的域名不一致，需把该项设置为NO；如设成NO的话，即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险，建议打开。
    //置为NO，主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册通配符的域名*.google.com，但这个还是比较贵的。
    //如置为NO，建议自己添加对应域名的校验逻辑。
    securityPolicy.validatesDomainName = NO; // 关键语句1
    // allowInvalidCertificates 是否允许无效证书（也就是自建的证书），默认为NO
    //    securityPolicy.allowInvalidCertificates = NO; // 关键语句2
    // 如果是需要验证自建证书，需要设置为YES
    securityPolicy.allowInvalidCertificates = YES; // 关键语句2
    return securityPolicy;
}

- (NSMutableDictionary *)filteredDictionaryWithDictionary:(NSDictionary *)dictionary
{
    if (![dictionary isKindOfClass:NSDictionary.class]) return [NSMutableDictionary dictionary];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    for (NSString *key in dict.allKeys)
    {
        if ([dict[key] isKindOfClass:NSNull.class]) dict[key] = nil;
    }
    return dict;
}

- (NSURLSessionDataTask *)GET:(NSString *)URLString parameters:(id)parameters success:(void (^)(id _Nullable))success error:(void (^)(NSError * _Nonnull))errorBlock failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure
{
    if (![NSURL URLWithString:URLString].scheme)
    {
        URLString = [kBaseURL stringByAppendingString:URLString];
    }
    if (![NSURL URLWithString:URLString])
    {
        URLString = [URLString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    }
    return [self.afManager GET:URLString parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self parseObject:responseObject success:^(id  _Nullable data) {
            !success ?: success(data);
        } error:^(NSError *error) {
            !errorBlock ?: errorBlock(error);
        }];
    } failure:failure];
}

- (NSURLSessionDataTask *)POST:(NSString *)URLString parameters:(id)parameters success:(void (^)(id _Nullable))success error:(void (^)(NSError * _Nonnull))errorBlock failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure
{
    if (![NSURL URLWithString:URLString].scheme)
    {
        URLString = [kBaseURL stringByAppendingString:URLString];
    }
    if (![NSURL URLWithString:URLString])
    {
        URLString = [URLString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    }
    return [self.afManager POST:URLString parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self parseObject:responseObject success:^(id  _Nullable data) {
            !success ?: success(data);
            NSLog(@"responseObject===%@",responseObject);
        } error:^(NSError *error) {
            if (error) {
                [self createResErrorWithCode:error.code];
                !errorBlock ?: errorBlock(self.resError);
            }
        }];
    } failure:failure];
}

/**
 *@abstract 从服务器返回的解析完毕的字典中提取code、data和msg字段。

 *@param obj 解析对象。
 *@param success 成功回调，参数是data字段，如果没有也可能为空。
 *@param error 失败回调。
 */
- (void)parseObject:(NSDictionary *)obj success:(nullable void (^)(id _Nullable data))success error:(void (^)(NSError *error))error
{
    if (![obj isKindOfClass:[NSDictionary class]])
    {
        error([NSError errorWithDomain:@"返回值不正确" code:(NSInteger)KDSHttpErrorReturnValueIncorrect userInfo:nil]);
        return;
    }
    NSInteger code = [obj[@"code"] isKindOfClass:NSString.class] ? [obj[@"code"] intValue] : (NSInteger)KDSHttpErrorReturnValueIncorrect;
    ![obj[@"nowTime"] isKindOfClass:NSNumber.class] ?: (void)(_serverTime = [obj[@"nowTime"] doubleValue]);
    if (code == 200)
    {
        success(obj[@"data"]);
    }
    else if (code == 444)
    {//failure的状态码401也表示token过期。
        [[NSNotificationCenter defaultCenter] postNotificationName:KDSHttpTokenExpiredNotification object:nil];
    }
    else
    {
        error([NSError errorWithDomain:[obj[@"msg"] isKindOfClass:NSString.class] ? obj[@"msg"] : @"未知错误" code:code userInfo:nil]);
    }
}

@end
