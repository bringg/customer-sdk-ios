//
//  BringgCustomer.m
//  BringgTracking
//
//  Created by Matan Poreh on 3/9/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//



#import "GGHTTPClientManager.h"
#import "GGHTTPClientManager_Private.h"


#import "GGNetworkUtils.h"


#define BCRealtimeServer @"realtime2-api.bringg.com"


#define BCNameKey @"name"
#define BCConfirmationCodeKey @"confirmation_code"
#define BCDeveloperTokenKey @"developer_access_token"

#define BCRatingTokenKey @"token"
#define BCRatingKey @"rating"


#define BCRESTMethodPost @"POST"
#define BCRESTMethodGet @"GET"
#define BCRESTMethodPut @"PUT"
#define BCRESTMethodDelete @"DELETE"

#define API_PATH_SIGN_IN @"/api/customer/sign_in"//method: POST; phone, name, confirmation_code, merchant_id, dev_access_token
#define API_PATH_SHARED_LOCATION @"/shared/%@/location/"
#define API_PATH_ORDER @"/api/customer/task/%@" // method: GET ; task id
#define API_PATH_ORDER_CREATE @"/api/customer/task/create" // method: POST
#define API_PATH_RATE @"/api/rate/%@" // method: POST; shared_location_uuid, rating token, rating
#define API_PATH_WATCH_ORDER @"/shared/orders/%@/" //method: GET; order_uuid
#define API_PATH_GET_ORDER @"/watch/shared/%@/" //method: GET; shared_location_uuid, order_uuid

//PRIVATE
#define API_PATH_REQUEST_CONFIRMATION @"/api/customer/confirmation/request" //method:Post ;merchant_id, phone


#define HTTP_FORMAT @"http://%@"
#define HTTPS_FORMAT @"https://%@"

@interface GGHTTPClientManager ()<NSURLSessionDelegate>

@end


@implementation GGHTTPClientManager



+ (id)manager{
    
    // get a manager object without the dev token
    return [self managerWithDeveloperToken:nil];
}

+ (id)managerWithDeveloperToken:(NSString *)developerToken{
   
    static GGHTTPClientManager *sharedObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // init the tracker
        sharedObject = [[self alloc] init];
        
        // set the developer token
        sharedObject->_developerToken = developerToken;
        
        // by default set the manager to use ssl
        sharedObject->_useSSL = YES;
        
    });
    
    return sharedObject;
}



-(id)init{
    
    if (self = [super init]) {
        
    }
    return self;
}

- (void)setDeveloperToken:(NSString *)devToken{
    _developerToken = devToken;
}


- (void)dealloc {
    
}



#pragma mark - Helpers

- (NSDictionary * _Nonnull)authenticationHeaders{
    
    NSMutableDictionary *retval = @{@"CLIENT": @"BRINGG SDK iOS",
                                    @"CLIENT-VERSION": SDK_VERSION}.mutableCopy;
    
    if (self.customHeaders) {
        [retval addEntriesFromDictionary:self.customHeaders];
    }
    
    return retval;
 
}

- (nonnull NSString *)getServerURL{
    NSString *server;
    
    if (self.delegate) {
        server = [self.delegate hostDomainForClientManager:self];
    }
    
    if (!server || [server length] == 0) {
        server = BCRealtimeServer;
    }
    
    
    // remove current prefix
    if ([server hasPrefix:HTTPS_FORMAT]) {
        server = [server stringByReplacingOccurrencesOfString:HTTPS_FORMAT withString:@""];
    }
    
    if ([server hasPrefix:HTTP_FORMAT]) {
        server = [server stringByReplacingOccurrencesOfString:HTTP_FORMAT withString:@""];
    }
    
    // add prefix according to ssl flag
    if (![server hasPrefix:@"http://"] && ![server hasPrefix:@"https://"]) {
        
        
        if (self.useSSL) {
             server = [NSString stringWithFormat:HTTPS_FORMAT, server];
        }else{
            server = [NSString stringWithFormat:HTTP_FORMAT, server];
        }
        
 
    }

    return server;
    
}

-(void)injectCustomExtras:(NSDictionary *)extras toParams:(NSMutableDictionary *__autoreleasing __nonnull*)params{
    
    [extras enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        //check if value is not NSNull
        if (![obj isKindOfClass:[NSNull class]]) {
            [*params setObject:obj forKey:key];
        }else{
            
            // value is NSNull check if key already exists in params
            // if so we should remove it
            if ([*params objectForKey:key]) {
                [*params removeObjectForKey:key];
            }
        }
    }];
}

 
- (NSURLSessionDataTask * _Nullable)httpRequestWithMethod:(NSString * _Nonnull)method
                                  path:(NSString *_Nonnull)path
                                params:(NSDictionary * _Nullable)params
                     completionHandler:(nullable GGNetworkResponseHandler)completionHandler{
    
    
#ifdef DEBUG
     NSLog(@"%@,  path: %@",  method, path);
#endif
    
   
    // get the server of the request
    NSString *server = [self getServerURL];
    
    
    // create a data task with the intended request
    NSURLSessionDataTask *dataTask = [GGNetworkUtils httpRequestWithSession:self.session
                                                                     server:server
                                                                     method:method
                                                                       path:path
                                                                     
                                                                     params:params
                                                          completionHandler:completionHandler];
    
    if (dataTask) {
        
        NSLog(@"executing request %@,  path: %@",  method, path);
        
        // run the task now
        [dataTask resume];
    }
    
    
    return dataTask;
}

#pragma mark - Status



- (BOOL)isWaitingTooLongForHTTPEvent{
    if (!self.lastEventDate) return NO;
    
    NSTimeInterval timeSinceHTTPEvent = fabs([[NSDate date] timeIntervalSinceDate:self.lastEventDate]);
    
    return (timeSinceHTTPEvent >= MAX_WITHOUT_POLLING_SEC);
}

#pragma mark - Setters
- (void)useSecuredConnection:(BOOL)isSecured{
    self.useSSL = isSecured;
}

- (void)setCustomAuthenticationHeaders:(NSDictionary * _Nullable)headers{
    self.customHeaders = headers;
}




#pragma mark - Getters


- (NSURLSessionConfiguration *)sessionConfiguration{
    if (!_sessionConfiguration) {
        _sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _sessionConfiguration.HTTPAdditionalHeaders = [self authenticationHeaders];
    }
    
    return _sessionConfiguration;
}

- (NSURLSession *)session{
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:self.sessionConfiguration delegate:self delegateQueue:self.serviceOperationQueue];
    }
    
    return _session;
}

- (nonnull NSURLSession *)factorySDKSession{
    
    return [NSURLSession sessionWithConfiguration:self.sessionConfiguration delegate:self delegateQueue:self.serviceOperationQueue];
}


- (NSOperationQueue *)serviceOperationQueue {
    if (!_serviceOperationQueue) {
        _serviceOperationQueue = [[NSOperationQueue alloc] init];
        _serviceOperationQueue.name = @"BringgHttp Queue";
        _serviceOperationQueue.maxConcurrentOperationCount = 1; //one for now - serial
        
    }
    return _serviceOperationQueue;
    
}


#pragma mark - HTTP Actions

- (void)signInWithName:(NSString * _Nullable)name
                 phone:(NSString * _Nullable)phone
                 email:(NSString * _Nullable)email
              password:(NSString * _Nullable)password
      confirmationCode:(NSString * _Nullable)confirmationCode
            merchantId:(NSString * _Nonnull)merchantId
                extras:(NSDictionary * _Nullable)extras
     completionHandler:(nullable GGNetworkResponseHandler)completionHandler {
    
    // build params for sign in
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:5];
    if (self.developerToken) {
        [params setObject:self.developerToken forKey:BCDeveloperTokenKey];
        
    }
    if (name && name.length > 0) {
        
        [params setObject:name forKey:PARAM_NAME];

    }
    
    if (phone && phone.length > 0) {
        [params setObject:phone forKey:PARAM_PHONE];
        
    }
    if (confirmationCode && confirmationCode.length > 0) {
        [params setObject:confirmationCode forKey:BCConfirmationCodeKey];
        
    }
    
    
    if (email && email.length > 0) {
        [params setObject:email forKey:PARAM_EMAIL];
        
    }
    
    if (password && password.length > 0) {
        [params setObject:password forKey:@"password"];
        
    }

    if (merchantId) {
        [params setObject:merchantId forKey:PARAM_MERCHANT_ID];
        
    }
    
    if (extras) {
        [self injectCustomExtras:extras toParams:&params];
    }
    
    __weak __typeof(&*self)weakSelf = self;
    
    // tell the operation Q to do the sign in operation
    [self httpRequestWithMethod:BCRESTMethodPost
                           path:API_PATH_SIGN_IN
                         params:params
              completionHandler:^(BOOL success, id JSON, NSError *error) {
                  
                  // update last date
                  weakSelf.lastEventDate = [NSDate date];
                  
                  
                  //
                  if (completionHandler) {
                      completionHandler(success, JSON, error);
                  }
              }];
 
}


- (void)getOrderByID:(NSUInteger)orderId
              params:(NSDictionary * __nonnull)params
withCompletionHandler:(nullable GGNetworkResponseHandler)completionHandler{
    
     __weak __typeof(&*self)weakSelf = self;
    [self httpRequestWithMethod:BCRESTMethodGet
                           path:[NSString stringWithFormat:API_PATH_ORDER, @(orderId)]
                         params:params
              completionHandler:^(BOOL success, id JSON, NSError *error) {
                  
                  // update last date
                  weakSelf.lastEventDate = [NSDate date];
 
                  //
                  if (completionHandler) {
                      completionHandler(success, JSON, error);
                  }

                  //
              }];
    
}

- (void)getOrderByUUID:(NSString * _Nonnull)orderUUID
                params:(NSDictionary * __nonnull)iparams
 withCompletionHandler:(nullable GGNetworkResponseHandler)completionHandler{
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:iparams];
    
    [params setObject:orderUUID forKey:PARAM_ORDER_UUID];
    
    
    __weak __typeof(&*self)weakSelf = self;

    [self httpRequestWithMethod:BCRESTMethodGet
                           path:[NSString stringWithFormat:API_PATH_WATCH_ORDER, orderUUID]
                         params:params
              completionHandler:^(BOOL success, id JSON, NSError *error) {
                  
                  // update last date
                  weakSelf.lastEventDate = [NSDate date];
                  
                  //
                  if (completionHandler) {
                      completionHandler(success, JSON, error);
                  }
                  
                  //
              }];
    
}



//MARK: - Session Delegate
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler{
    
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);

    NSLog(@"session received challange %@", challenge);
}


- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error{
    
    NSLog(@"session invalidated with %@", error ?: @"no error");
}

@end
