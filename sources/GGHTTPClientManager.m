//
//  BringgCustomer.m
//  BringgTracking
//
//  Created by Matan Poreh on 3/9/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//



#import "GGHTTPClientManager.h"
#import "GGHTTPClientManager_Private.h"
#import "GGCustomer.h"
#import "GGOrder.h"
#import "GGDriver.h"
#import "GGSharedLocation.h"
#import "GGRating.h"
#import "GGorderBuilder.h"
#import "BringgGlobals.h"
#import "GGNetworkUtils.h"
#import "GGBringgUtils.h"


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
#define API_PATH_ORDER_UUID @"/shared/orders/%@/" //method: GET; order_uuid
#define API_PATH_WATCH_ORDER @"/watch/shared/%@/" //method: GET; shared_location_uuid,  params - order_uuid

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
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(hostDomainForClientManager:)]) {
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
    
    if (!self.useSSL) {
        
        server = [server stringByReplacingOccurrencesOfString:@"3000" withString:@"3030"];
        
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

-(void)addAuthinticationToParams:(NSMutableDictionary *__autoreleasing __nonnull*)params{
    NSAssert([*params isKindOfClass:[NSMutableDictionary class]], @"params must be mutable");
    
    if (_developerToken) {
         [*params setObject:_developerToken forKey:BCDeveloperTokenKey];
    }
   
    NSString *auth = [_customer getAuthIdentifier];
    
    
    if (_customer && auth) {
        [*params setObject:_customer.customerToken forKey:PARAM_ACCESS_TOKEN];
        [*params setObject:_customer.merchantId forKey:PARAM_MERCHANT_ID];
        if (auth) [*params setObject:auth forKey:PARAM_PHONE];
    }
    
}

 
- (NSURLSessionDataTask * _Nullable)httpRequestWithMethod:(NSString * _Nonnull)method
                                  path:(NSString *_Nonnull)path
                                params:(NSDictionary * _Nullable)params
                     completionHandler:(nullable GGNetworkResponseHandler)completionHandler{
        
    // get the server of the request
    NSString *server = [self getServerURL];
    NSString *parsedPath = path;
    
     //path might sometime include full url. in those cases break the path to server and url
    BOOL isFullPath = NO;
    isFullPath = [GGNetworkUtils isFullPath:path];
    
    if (isFullPath) {
        
        [GGNetworkUtils parseFullPath:path toServer:&server relativePath:&parsedPath];
        
        // make sure parse was valid
        if (!server || !parsedPath) {
            //bad parse
            return nil;
        }
        
    }
    
    
    // create a data task with the intended request
    NSURLSessionDataTask *dataTask = [GGNetworkUtils httpRequestWithSession:self.session
                                                                     server:server
                                                                     method:method
                                                                       path:parsedPath
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

- (BOOL)isSignedIn {
    return self.customer ? YES : NO;
    
}


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


- (void)useCustomer:(GGCustomer * _Nullable)customer{
    self.customer = customer;
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
        _session = [NSURLSession sessionWithConfiguration:self.sessionConfiguration delegate:self delegateQueue:self.serviceOperationQueue];//];
    }
    
    return _session;
}


- (NSOperationQueue *)serviceOperationQueue {
    if (!_serviceOperationQueue) {
        _serviceOperationQueue = [[NSOperationQueue alloc] init];
        _serviceOperationQueue.name = @"BringgHttp Queue";
        _serviceOperationQueue.maxConcurrentOperationCount = 1; //one for now - serial
        
    }
    return _serviceOperationQueue;
    
}

- (BOOL)hasPhone{
    return _customer && _customer.phone;
}
- (BOOL)hasMerchantId{
    return _customer && _customer.merchantId;
}

- (nullable GGCustomer *)signedInCustomer{
    return _customer;
}

#pragma mark - HTTP Actions

- (void)signInWithName:(NSString * _Nullable)name
                 phone:(NSString * _Nullable)phone
                 email:(NSString * _Nullable)email
              password:(NSString * _Nullable)password
      confirmationCode:(NSString * _Nullable)confirmationCode
            merchantId:(NSString * _Nonnull)merchantId
                extras:(NSDictionary * _Nullable)extras
     completionHandler:(nullable GGCustomerResponseHandler)completionHandler {
    
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
                  self.lastEventDate = [NSDate date];
                  
                  GGCustomer *customer = nil;
                  
                  if (success) customer = [[GGCustomer alloc] initWithData:[JSON objectForKey:PARAM_CUSTOMER] ];
                  
                  // if customer doesnt have an access token treat this as an error
                  if (customer && (!customer.customerToken || [customer.customerToken isEqualToString:@""])) {
                      
                      // check if json has access token response
                      
                      NSString *ct = [GGBringgUtils stringFromJSON:JSON[@"access_token"] defaultTo:nil] ;
                      
                      if (ct) {
                          customer.customerToken = ct;
                      }else{
                          // token invalid report error
                          if (completionHandler) {
                              
                              NSError *responseError = [NSError errorWithDomain:kSDKDomainData code:GGErrorTypeMissing userInfo:@{NSLocalizedDescriptionKey:@"missing valid customer access token"}];
                              
                              completionHandler(NO, nil, nil, responseError);
                          }
                          
                          weakSelf.customer = nil;
                          
                           return ;
                      }

                  }
                  
                  
                  weakSelf.customer = customer;
                  
                  if (completionHandler) {
                      completionHandler(success, JSON, customer, error);
                  }
                  
                  //
              }];
 
}

- (void)watchOrderByOrderUUID:(NSString * _Nonnull)orderUUID
                       extras:(NSDictionary * _Nullable)extras
        withCompletionHandler:(nullable GGOrderResponseHandler)completionHandler {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [self addAuthinticationToParams:&params];
    
    if (extras) {
        [self injectCustomExtras:extras toParams:&params];
    }
    
    [self httpRequestWithMethod:BCRESTMethodGet
                           path:[NSString stringWithFormat:API_PATH_ORDER_UUID, orderUUID]
                         params:params
              completionHandler:^(BOOL success, id JSON, NSError *error) {
                  
                  // update last date
                  self.lastEventDate = [NSDate date];
                  
                  GGOrder *order = nil;
                  
                  NSDictionary *orderUpdateData = [JSON objectForKey:@"order_update"];
                  
                  if (!orderUpdateData && !error) {
                      NSError *responseError = [NSError errorWithDomain:kSDKDomainResponse code:GGErrorTypeMissing userInfo:@{NSLocalizedDescriptionKey:@"response does not contain valid order data"}];
                      if (completionHandler) {
                          completionHandler(NO , JSON, order, responseError);
                      }
                  }else{
                      if (success && orderUpdateData) {
                          
                          order = [[GGOrder alloc] initOrderWithData:orderUpdateData];
                          
                      }
                      
                      if (completionHandler) {
                          completionHandler(success, JSON, order, error);
                      }
                  }
                  
                  //
              }];
}


- (void)rate:(int)rating
   withToken:(NSString * _Nonnull)ratingToken
   ratingURL:(NSString *_Nonnull)ratingURL
      extras:(NSDictionary * _Nullable)extras
withCompletionHandler:(nullable GGRatingResponseHandler)completionHandler{
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    [params setObject:@(rating) forKey:BCRatingKey];
    [params setObject:ratingToken forKey:BCRatingTokenKey];
    
 
    [self addAuthinticationToParams:&params];
    
    if (extras) {
        [self injectCustomExtras:extras toParams:&params];
    }
    
    
     [self httpRequestWithMethod:BCRESTMethodPost
                            path:ratingURL//[NSString stringWithFormat:API_PATH_RATE,sharedLocationUUID]
                          params:params
               completionHandler:^(BOOL success, id JSON, NSError *error) {
                   
                   // update last date
                   self.lastEventDate = [NSDate date];
                   
                   GGRating *rating = nil;
                   
                   if (success) {
                       rating = [[GGRating alloc] initWithRatingToken:ratingToken];
                       [rating setRatingMessage:[GGBringgUtils stringFromJSON:[JSON objectForKey:BCMessageKey] defaultTo:nil]];
                       [rating rate:(int)[GGBringgUtils integerFromJSON:[JSON objectForKey:@"rating"] defaultTo:0]];
                   }
                   
                   if (completionHandler) {
                       completionHandler(success, JSON, rating, error);
                   }
                   //
               }];
}


- (void)sendFindMeRequestWithFindMeConfiguration:(nonnull GGFindMe *)findmeConfig latitude:(double)lat longitude:(double)lng  withCompletionHandler:(nullable GGActionResponseHandler)completionHandler{
    
    // validate data
    if (!findmeConfig || ![findmeConfig canSendFindMe]) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:kSDKDomainData code:GGErrorTypeActionNotAllowed userInfo:@{NSLocalizedDescriptionKey:@"current find request is not allowed"}]);
        }
        
        return;
    }
    
    // validate coordinates
    if (![GGBringgUtils isValidCoordinatesWithLat:lat lng:lng]) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:kSDKDomainData code:GGErrorTypeActionNotAllowed userInfo:@{NSLocalizedDescriptionKey:@"coordinates values are invalid"}]);
        }
        
        return;
    }
    
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"position":@{@"coords":@{@"latitude":@(lat), @"longitude":@(lng)}}, @"find_me_token":findmeConfig.token}];
    
    // inject authentication params
     [self addAuthinticationToParams:&params];
    
    // find
   
     [self httpRequestWithMethod:BCRESTMethodPost
                            path:findmeConfig.url
                          params:params
               completionHandler:^(BOOL success, id JSON, NSError *error) {
                   
                   // update last date
                   self.lastEventDate = [NSDate date];
                   
                   if (completionHandler) {
                       completionHandler(success, error);
                   }
                   //
               }];
}

#warning TODO - add Order method to header once server is ready
- (void)addOrderWith:(GGOrderBuilder *)orderBuilder withCompletionHandler:(void (^)(BOOL success, GGOrder *order, NSError *error))completionHandler{
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:orderBuilder.orderData];
    [self addAuthinticationToParams:&params];
    
    
     [self httpRequestWithMethod:BCRESTMethodPost
                            path:API_PATH_ORDER_CREATE
                          params:params
               completionHandler:^(BOOL success, id JSON, NSError *error) {
                   
                   // update last date
                   self.lastEventDate = [NSDate date];
                   
#warning TODO analytize response
                  
                   GGOrder *order = nil;
                   if (success) order = [[GGOrder alloc] initOrderWithData:[JSON objectForKey:@"task"]];
                   
                   if (completionHandler) {
                       completionHandler(success, order, error);
                   }
                   //
               }];
}

#pragma mark - HTTP GETTERS

- (void)getOrderByID:(NSUInteger)orderId
              extras:(NSDictionary * _Nullable)extras
withCompletionHandler:(nullable GGOrderResponseHandler)completionHandler{
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [self addAuthinticationToParams:&params];
    
    
    if (extras) {
        [self injectCustomExtras:extras toParams:&params];
    }
    
   
     [self httpRequestWithMethod:BCRESTMethodGet
                            path:[NSString stringWithFormat:API_PATH_ORDER, @(orderId)]
                          params:params
               completionHandler:^(BOOL success, id JSON, NSError *error) {
                   
                   // update last date
                   self.lastEventDate = [NSDate date];
                   
                   GGOrder *order = nil;
                   
                   if (success) order = [[GGOrder alloc] initOrderWithData:JSON];
                   
                   if (completionHandler) {
                       completionHandler(success, JSON, order, error);
                   }
        //
    }];
    
}


- (void)getOrderByShareUUID:(NSString * _Nonnull)shareUUID
                  orderUUID:(NSString * _Nonnull)orderUUID
                     extras:(NSDictionary * _Nullable)extras
      withCompletionHandler:(nullable GGOrderResponseHandler)completionHandler {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [self addAuthinticationToParams:&params];
    
    if (orderUUID) {
        [params setObject:orderUUID forKey:PARAM_ORDER_UUID];
    }
    
    if (extras) {
        [self injectCustomExtras:extras toParams:&params];
    }
    
    [self httpRequestWithMethod:BCRESTMethodGet
                           path:[NSString stringWithFormat:API_PATH_WATCH_ORDER, shareUUID]
                         params:params
              completionHandler:^(BOOL success, id JSON, NSError *error) {
                  
                  // update last date
                  self.lastEventDate = [NSDate date];
                  
                  GGOrder *order = nil;
                  
                  NSDictionary *orderUpdateData = [JSON objectForKey:@"order_update"];
                  
                  if (!orderUpdateData && !error) {
                      NSError *responseError = [NSError errorWithDomain:kSDKDomainResponse code:GGErrorTypeMissing userInfo:@{NSLocalizedDescriptionKey:@"response does not contain valid order data"}];
                      if (completionHandler) {
                          completionHandler(NO , JSON, order, responseError);
                      }
                  }else{
                      if (success && orderUpdateData) order = [[GGOrder alloc] initOrderWithData:orderUpdateData];
                      
                      if (completionHandler) {
                          completionHandler(success, JSON, order, error);
                      }
                  }
                  
                  
                  //
              }];
    
}


- (void)getSharedLocationByUUID:(NSString * _Nonnull)sharedLocationUUID
                         extras:(NSDictionary * _Nullable)extras
          withCompletionHandler:(nullable GGSharedLocationResponseHandler)completionHandler{
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [self addAuthinticationToParams:&params];
    
    if (extras) {
        [self injectCustomExtras:extras toParams:&params];
    }
    
    [self httpRequestWithMethod:BCRESTMethodGet
                           path:[NSString stringWithFormat:API_PATH_SHARED_LOCATION, sharedLocationUUID]
                         params:params
              completionHandler:^(BOOL success, id JSON, NSError *error) {
                  
                  // update last date
                  self.lastEventDate = [NSDate date];
                  
                  GGSharedLocation *sharedLocation = nil;
                  
                  if (success) sharedLocation = [[GGSharedLocation alloc] initWithData:JSON];
                  
                  if (completionHandler) {
                      completionHandler(success, JSON, sharedLocation, error);
                  }
                  //
              }];
}


//MARK: - Session Delegate
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler{
    
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);

   
}


- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error{
    
    NSLog(@"session invalidated with %@", error ?: @"no error");
}

@end
