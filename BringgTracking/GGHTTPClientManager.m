//
//  BringgCustomer.m
//  BringgTracking
//
//  Created by Ilya Kalinin on 3/9/15.
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
#define API_PATH_SHARED_LOCATION @"/api/shared/%@"
#define API_PATH_ORDER @"/api/customer/task/%@" // method: GET ; task id
#define API_PATH_ORDER_CREATE @"/api/customer/task/create" // method: POST
#define API_PATH_RATE @"/api/rate/%@" // method: POST; shared_location_uuid, rating token, rating

//PRIVATE
#define API_PATH_REQUEST_CONFIRMATION @"/api/customer/confirmation/request" //method:Post ;merchant_id, phone


#define HTTP_FORMAT @"http://%@"

@interface GGHTTPClientManager ()

@property (nonatomic, strong) NSOperationQueue *serviceOperationQueue;
@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;

-(void)addAuthinticationToParams:(NSMutableDictionary **)params;

@end

@implementation GGHTTPClientManager

+ (id)sharedInstance {
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] initClient];
        
    });
}

- (id) initClient{
    if (self = [super init]) {
        self.sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    }
    return self;
}

-(id)init{
    
    // we want to prevent the developer from using normal intializers
    // the http manager class should only be used as a singelton
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the class GGHTTPClientManager. Please use class method initializer"
                                 userInfo:nil];
    
    return self;
}


- (void)dealloc {
    
}

#pragma mark - Setters

- (void)setDeveloperToken:(NSString *)developerToken {
    _developerToken = developerToken;
    
}

#pragma mark - Helpers

- (NSString *)getServerURLWithMethod:(NSString *)method path:(NSString *)path {
    NSString *server;
    
    server = BCRealtimeServer;
    
    if (![server hasPrefix:@"http://"] && ![server hasPrefix:@"https://"]) {
        
        
#ifdef USE_SSL
        server = [NSString stringWithFormat:HTTP_FORMAT, server];
#else
        server = [NSString stringWithFormat:HTTP_FORMAT, server];
#endif
        
    }
    
    
    return server;
    
}

-(void)addAuthinticationToParams:(NSMutableDictionary **)params{
    NSAssert([*params isKindOfClass:[NSMutableDictionary class]], @"http paras must be mutable");
    
    [*params setObject:_developerToken forKey:BCDeveloperTokenKey];
    [*params setObject:_customer.customerToken forKey:BCCustomerTokenKey];
    [*params setObject:_customer.merchantId forKey:BCMerchantIdKey];
}

- (NSOperation *)httpRequestWithMethod:(NSString *)method
                                  path:(NSString *)path
                                params:(NSDictionary *)params
                     completionHandler:(void (^)(BOOL success, id JSON, NSError *error))completionHandler{
    
    
    NSLog(@"%@, params: %@ & path: %@",  method, params, path);
    NSString *server = [self getServerURLWithMethod:method path:path];
    
    NSURL *CTSURL = [NSURL URLWithString:server];
    AFHTTPSessionManager *sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:CTSURL sessionConfiguration:self.sessionConfiguration];
    sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    sessionManager.responseSerializer.acceptableContentTypes = [sessionManager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
    
    
    NSError *jsonError;
    NSMutableURLRequest *jsonRequest = [sessionManager.requestSerializer requestWithMethod:method URLString:[NSString stringWithFormat:@"%@%@",sessionManager.baseURL,path] parameters:params error:&jsonError];
    
    
    if (jsonError) {
        NSLog(@" error creating json request in %s : %@", __PRETTY_FUNCTION__, jsonError);
    }
    
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
        
       
        if (completionHandler) {
            completionHandler(result, responseObject, error);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        if (completionHandler) {
            completionHandler(NO, nil, error);
        }
    }];
    
    return jsonOperation;
    
    
    
}

#pragma mark - Status

- (BOOL)isSignedIn {
    return self.customer ? YES : NO;
    
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

#pragma mark - HTTP Actions

- (void)signInWithName:(NSString *)name
                 phone:(NSString *)phone
      confirmationCode:(NSString *)confirmationCode
            merchantId:(NSString *)merchantId
     completionHandler:(void (^)(BOOL success, GGCustomer *customer, NSError *error))completionHandler {
    
    // build params for sign in
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:5];
    if (self.developerToken) {
        [params setObject:self.developerToken forKey:BCDeveloperTokenKey];
        
    }
    if (name) {
        
        [params setObject:name forKey:BCNameKey];
        
        
    }
    if (phone) {
        [params setObject:phone forKey:BCPhoneKey];
        
    }
    if (confirmationCode) {
        [params setObject:confirmationCode forKey:BCConfirmationCodeKey];
        
    }
    if (merchantId) {
        [params setObject:merchantId forKey:BCMerchantIdKey];
        
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
            
                   weakSelf.customer = customer;
                   
                   if (completionHandler) {
                       completionHandler(success, customer, error);
                   }
                                                           
        //
    }]];
 
}

- (void)rate:(int)rating withToken:(NSString *)ratingToken forSharedLocationUUID:(NSString *)sharedLocationUUID withCompletionHandler:(void (^)(BOOL success, GGRating *rating, NSError *error))completionHandler{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    [params setObject:@(rating) forKey:BCRatingKey];
    [params setObject:ratingToken forKey:BCRatingTokenKey];
    
 
    [self addAuthinticationToParams:&params];
    
    [self.serviceOperationQueue addOperation:
     [self httpRequestWithMethod:BCRESTMethodPost
                            path:[NSString stringWithFormat:API_PATH_RATE,sharedLocationUUID]
                          params:params
               completionHandler:^(BOOL success, id JSON, NSError *error) {
                   
                   GGRating *rating = nil;
                   
                   if (success) {
                       rating = [[GGRating alloc] initWithRatingToken:ratingToken];
                       [rating setRatingMessage:[JSON objectForKey:BCMessageKey]];
                       [rating rate:[[JSON objectForKey:@"rating"] intValue]];
                   }
                   
                   if (completionHandler) {
                       completionHandler(success, rating, error);
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

- (void)getOrderByID:(NSUInteger)orderId withCompletionHandler:(void (^)(BOOL success, GGOrder *order, NSError *error))completionHandler{
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [self addAuthinticationToParams:&params];
    [params setObject:_customer.phone forKey:BCPhoneKey];
    
    [self.serviceOperationQueue addOperation:
     [self httpRequestWithMethod:BCRESTMethodGet
                            path:[NSString stringWithFormat:API_PATH_ORDER, @(orderId)]
                          params:params
               completionHandler:^(BOOL success, id JSON, NSError *error) {
                   
                   GGOrder *order = nil;
                   
                   if (success) order = [[GGOrder alloc] initOrderWithData:JSON];
                   
                   if (completionHandler) {
                       completionHandler(success, order, error);
                   }
        //
    }]];
    
}

- (void)getSharedLocationByUUID:(NSString *)sharedLocationUUID withCompletionHandler:(void (^)(BOOL success, GGSharedLocation *sharedLocation, NSError *error))completionHandler{
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [self addAuthinticationToParams:&params];
    
    [self.serviceOperationQueue addOperation:
     [self httpRequestWithMethod:BCRESTMethodGet
                            path:[NSString stringWithFormat:API_PATH_SHARED_LOCATION, sharedLocationUUID]
                          params:params
               completionHandler:^(BOOL success, id JSON, NSError *error) {
                   
                   GGSharedLocation *sharedLocation = nil;
                   
                   if (success) sharedLocation = [[GGSharedLocation alloc] initWithData:JSON];
                   
                   if (completionHandler) {
                       completionHandler(success, sharedLocation, error);
                   }
                   //
               }]];
}



@end
