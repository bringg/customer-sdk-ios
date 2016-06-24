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

#import "AFNetworking.h"


#define BCRealtimeServer @"realtime-api.bringg.com"

#define BCSuccessKey @"success"
#define BCSuccessAlternateKey @"status"
#define BCMessageKey @"message"
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
#define API_PATH_SHARED_LOCATION @"/api/shared/%@/location/"
#define API_PATH_ORDER @"/api/customer/task/%@" // method: GET ; task id
#define API_PATH_ORDER_CREATE @"/api/customer/task/create" // method: POST
#define API_PATH_RATE @"/api/rate/%@" // method: POST; shared_location_uuid, rating token, rating
#define API_PATH_WATCH_ORDER @"/api/shared/orders/%@/" //method: GET; order_uuid
#define API_PATH_GET_ORDER @"/api/watch/shared/%@/" //method: GET; shared_location_uuid, order_uuid

//PRIVATE
#define API_PATH_REQUEST_CONFIRMATION @"/api/customer/confirmation/request" //method:Post ;merchant_id, phone


#define HTTP_FORMAT @"http://%@"
#define HTTPS_FORMAT @"https://%@"



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
        self.sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
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

- (nonnull NSString *)getServerURLWithMethod:(NSString * _Nonnull)method path:(NSString * _Nonnull * _Nonnull)path {
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
    
    // if path for some reason contains the server? remove it from the string
    if ([*path rangeOfString:server].location != NSNotFound) {
        *path = [*path stringByReplacingOccurrencesOfString:server withString:@""];
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

- (NSOperation * _Nullable)httpRequestWithMethod:(NSString * _Nonnull)method
                                  path:(NSString *_Nonnull)path
                                params:(NSDictionary * _Nullable)params
                     completionHandler:(nullable GGNetworkResponseHandler)completionHandler{
    
    
#ifdef DEBUG
     NSLog(@"%@,  path: %@",  method, path);
#endif
    
   
    
    NSString *server = [self getServerURLWithMethod:method path:&path];
    
    
   
    
    NSURL *CTSURL = [NSURL URLWithString:server];
    AFHTTPSessionManager *sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:CTSURL sessionConfiguration:self.sessionConfiguration];
    
    sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    sessionManager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
    sessionManager.responseSerializer.acceptableContentTypes =  [sessionManager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
    
    
    
    NSError *jsonError;
    NSMutableURLRequest *jsonRequest = [sessionManager.requestSerializer requestWithMethod:method URLString:[NSString stringWithFormat:@"%@%@",sessionManager.baseURL,path] parameters:params error:&jsonError];
    jsonRequest.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    
    
    if (jsonError) {
        NSLog(@" error creating json request in %s : %@", __PRETTY_FUNCTION__, jsonError);
    }
    
    
    // set the headers of the request
    [[self authenticationHeaders] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [jsonRequest setValue:obj forHTTPHeaderField:key];
        
    }];
    
    AFHTTPRequestOperation *jsonOperation = [[AFHTTPRequestOperation alloc] initWithRequest:jsonRequest];
    jsonOperation.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
    jsonOperation.responseSerializer.acceptableContentTypes = [jsonOperation.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
    
    [jsonOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        //
        
        BOOL result = NO;
        NSError *error;
        
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            
            // there are two params that represent success
            id success = [responseObject objectForKey:BCSuccessKey];
            
            // if it's "success" then then check for valid data (should be bool)
            if (success && [success isKindOfClass:[NSNumber class]]) {
                
                result = [success boolValue];

            }
            
            // check if there is another success params to indicate response status
            if (!result) {
                
                // "status" could also represent a succesfull call - status here will be a string
                id status = [responseObject objectForKey:BCSuccessAlternateKey];
                
                // check if status field is valid and if success
                if ([status isKindOfClass:[NSString class]] &&
                    [status isEqualToString:@"ok"]) {
                    
                    result = YES;
                    
                } else {
                    
                    // for sure we have a failed response - both success params tests failed
                    
                    id message = [responseObject objectForKey:BCMessageKey];
                    
                    
                    // some times the success key is part of a legitimate response object - so no message will exits
                    // but other data will be present so we should conisder it
                    
                    if ([message isKindOfClass:[NSString class]]) {
                        error = [NSError errorWithDomain:@"BringgHTTPClient" code:0
                                                userInfo:@{NSLocalizedDescriptionKey: message,
                                                           NSLocalizedRecoverySuggestionErrorKey: message}];
                        
                    } else {
                        
                        // check if there is other data
                        if (!message && [[responseObject allKeys] count] > 1) {
                            
                            // the response is legit
                            result = YES;
                        }else{
                            error = [NSError errorWithDomain:@"BringgHTTPClient" code:0
                                                    userInfo:@{NSLocalizedDescriptionKey: @"Undefined Error",
                                                               NSLocalizedRecoverySuggestionErrorKey: @"Undefined Error"}];
                        }
                        
                        
                        
                        
                    }
                }
            }
            
           
        }
        
 
        NSLog(@"GOT HTTP SUCCESS For Path %@:", path);
 
       
        // update last date
        self.lastEventDate = [NSDate date];
        
        if (completionHandler) {
            completionHandler(result, responseObject, error);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
#if DEBUG
        NSLog(@"GOT HTTP ERROR (%@) For Path %@:", error, path);
#endif
        
        if (completionHandler) {
            
            if (error && error.code >= 500 && error.code < 600) {
                
                NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
                [info setObject:@"server temporarily unavailable, please try again later." forKey:NSLocalizedDescriptionKey];
                
                NSError *newError = [NSError errorWithDomain:error.domain code:error.code userInfo:info];
                completionHandler(NO, nil, newError);
                
            }else{
                completionHandler(NO, nil, error);
            }
            
            
        }
    }];
    
    return jsonOperation;
    
    
    
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

- (NSOperationQueue *)serviceOperationQueue {
    if (!_serviceOperationQueue) {
        _serviceOperationQueue = [[NSOperationQueue alloc] init];
        _serviceOperationQueue.name = @"BringgHttp Queue";
        _serviceOperationQueue.maxConcurrentOperationCount = 1; //one for now
        
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
    [self.serviceOperationQueue addOperation:
     [self httpRequestWithMethod:BCRESTMethodPost
                            path:API_PATH_SIGN_IN
                          params:params
               completionHandler:^(BOOL success, id JSON, NSError *error) {
                   
                   GGCustomer *customer = nil;
                                                           
                   if (success) customer = [[GGCustomer alloc] initWithData:[JSON objectForKey:PARAM_CUSTOMER] ];
            
                   // if customer doesnt have an access token treet this as an error
                   if (customer && (!customer.customerToken || [customer.customerToken isEqualToString:@""])) {
                       // token invalid report error
                       if (completionHandler) {

                           NSError *responseError = [NSError errorWithDomain:@"SDKDomain" code:0 userInfo:@{NSLocalizedDescriptionKey:@"Unknown error"}];
                           
                           completionHandler(NO, nil, nil, responseError);
                       }
                       
                       weakSelf.customer = nil;
                       
                       return ;
                   }
                   
                   
                   weakSelf.customer = customer;
                   
                   if (completionHandler) {
                       completionHandler(success, JSON, customer, error);
                   }
                                                           
        //
    }]];
 
}

-(void)watchOrderByOrderUUID:(NSString * _Nonnull)orderUUID
                      extras:(NSDictionary * _Nullable)extras
       withCompletionHandler:(nullable GGOrderResponseHandler)completionHandler{
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [self addAuthinticationToParams:&params];
    
    [params setObject:orderUUID forKey:PARAM_ORDER_UUID];
    
    if (extras) {
        [self injectCustomExtras:extras toParams:&params];
    }
    
    [self.serviceOperationQueue addOperation:
     [self httpRequestWithMethod:BCRESTMethodGet
                            path:[NSString stringWithFormat:API_PATH_WATCH_ORDER, orderUUID]
                          params:params
               completionHandler:^(BOOL success, id JSON, NSError *error) {
                   
                   GGOrder *order = nil;
                   
                   NSDictionary *orderUpdateData = [JSON objectForKey:@"order_update"];
                   
                   if (!orderUpdateData && !error) {
                       NSError *responseError = [NSError errorWithDomain:@"SDKDomain" code:0 userInfo:@{NSLocalizedDescriptionKey:@"Unknown error"}];
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
               }]];

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
    
    [self.serviceOperationQueue addOperation:
     [self httpRequestWithMethod:BCRESTMethodPost
                            path:ratingURL//[NSString stringWithFormat:API_PATH_RATE,sharedLocationUUID]
                          params:params
               completionHandler:^(BOOL success, id JSON, NSError *error) {
                   
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
               }]];
}


- (void)sendFindMeRequestWithFindMeConfiguration:(nonnull GGFindMe *)findmeConfig latitude:(double)lat longitude:(double)lng  withCompletionHandler:(nullable GGActionResponseHandler)completionHandler{
    
    // validate data
    if (!findmeConfig || ![findmeConfig canSendFindMe]) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:@"BringgData" code:GGErrorTypeActionNotAllowed userInfo:@{NSLocalizedDescriptionKey:@"current find request is not allowed"}]);
        }
        
        return;
    }
    
    // validate coordinates
    if (![GGBringgUtils isValidCoordinatesWithLat:lat lng:lng]) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:@"BringgData" code:GGErrorTypeActionNotAllowed userInfo:@{NSLocalizedDescriptionKey:@"coordinates values are invalid"}]);
        }
        
        return;
    }
    
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"position":@{@"lat":@(lat), @"lng":@(lng)}, @"find_me_token":findmeConfig.token}];
    
    // inject authentication params
     [self addAuthinticationToParams:&params];
    
    // find
    [self.serviceOperationQueue addOperation:
     [self httpRequestWithMethod:BCRESTMethodPost
                            path:findmeConfig.url
                          params:params
               completionHandler:^(BOOL success, id JSON, NSError *error) {
                   
                   if (completionHandler) {
                       completionHandler(success, error);
                   }
                   //
               }]];
}

#warning TODO - add Order method to header once server is ready
- (void)addOrderWith:(GGOrderBuilder *)orderBuilder withCompletionHandler:(void (^)(BOOL success, GGOrder *order, NSError *error))completionHandler{
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:orderBuilder.orderData];
    [self addAuthinticationToParams:&params];
    
    [self.serviceOperationQueue addOperation:
     [self httpRequestWithMethod:BCRESTMethodPost
                            path:API_PATH_ORDER_CREATE
                          params:params
               completionHandler:^(BOOL success, id JSON, NSError *error) {
                   
#warning TODO analytize response
                  
                   GGOrder *order = nil;
                   if (success) order = [[GGOrder alloc] initOrderWithData:[JSON objectForKey:@"task"]];
                   
                   if (completionHandler) {
                       completionHandler(success, order, error);
                   }
                   //
               }]];
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
    
    [self.serviceOperationQueue addOperation:
     [self httpRequestWithMethod:BCRESTMethodGet
                            path:[NSString stringWithFormat:API_PATH_ORDER, @(orderId)]
                          params:params
               completionHandler:^(BOOL success, id JSON, NSError *error) {
                   
                   GGOrder *order = nil;
                   
                   if (success) order = [[GGOrder alloc] initOrderWithData:JSON];
                   
                   if (completionHandler) {
                       completionHandler(success, JSON, order, error);
                   }
        //
    }]];
    
}

- (void)getOrderByUUID:(NSString * _Nonnull)orderUUID
         withShareUUID:(NSString * _Nonnull)shareUUID
                extras:(NSDictionary * _Nullable)extras
 withCompletionHandler:(nullable GGOrderResponseHandler)completionHandler{
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [self addAuthinticationToParams:&params];
    
    [params setObject:orderUUID forKey:PARAM_ORDER_UUID];
    
    if (extras) {
        [self injectCustomExtras:extras toParams:&params];
    }
    
    [self.serviceOperationQueue addOperation:
     [self httpRequestWithMethod:BCRESTMethodGet
                            path:[NSString stringWithFormat:API_PATH_GET_ORDER, shareUUID]
                          params:params
               completionHandler:^(BOOL success, id JSON, NSError *error) {
                   
                   GGOrder *order = nil;
                   
                   NSDictionary *orderUpdateData = [JSON objectForKey:@"order_update"];
                   
                   if (!orderUpdateData && !error) {
                        NSError *responseError = [NSError errorWithDomain:@"SDKDomain" code:0 userInfo:@{NSLocalizedDescriptionKey:@"Unknown error"}];
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
               }]];

}

- (void)getSharedLocationByUUID:(NSString * _Nonnull)sharedLocationUUID
                         extras:(NSDictionary * _Nullable)extras
          withCompletionHandler:(nullable GGSharedLocationResponseHandler)completionHandler{
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [self addAuthinticationToParams:&params];
    
    if (extras) {
        [self injectCustomExtras:extras toParams:&params];
    }
    
    [self.serviceOperationQueue addOperation:
     [self httpRequestWithMethod:BCRESTMethodGet
                            path:[NSString stringWithFormat:API_PATH_SHARED_LOCATION, sharedLocationUUID]
                          params:params
               completionHandler:^(BOOL success, id JSON, NSError *error) {
                   
                   GGSharedLocation *sharedLocation = nil;
                   
                   if (success) sharedLocation = [[GGSharedLocation alloc] initWithData:JSON];
                   
                   if (completionHandler) {
                       completionHandler(success, JSON, sharedLocation, error);
                   }
                   //
               }]];
}



@end
