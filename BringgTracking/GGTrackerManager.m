//
//  BringgTracker.m
//  BringgTracking
//
//  Created by Ilya Kalinin on 12/16/14.
//  Copyright (c) 2014 Ilya Kalinin. All rights reserved.
//

#import "GGTrackerManager.h"
#import "GGClientAppManager.h"
#import "GGClientAppManager_Private.h"

#import "GGRealTimeMontior.h"


#import "GGCustomer.h"
#import "GGSharedLocation.h"
#import "GGDriver.h"
#import "GGOrder.h"
#import "GGRating.h"

#import "BringgGlobals.h"



#import "AFNetworking.h"





#define BTSuccessKey @"status"
#define BTMessageKey @"message"
#define BTPhoneKey @"phone"
#define BTConfirmationCodeKey @"confirmation_code"
#define BTMerchantIdKey @"merchant_id"
#define BTDeveloperTokenKey @"developer_access_token"
#define BTCustomerTokenKey @"access_token"
#define BTCustomerPhoneKey @"phone"
#define BTTokenKey @"token"
#define BTRatingKey @"rating"

#define BTRESTSharedLocationPath @"/api/shared/"    //+uuid
#define BTRESTRatingPath @"/api/rate/"              //+uuid
#define BTRESTOrderPath @"/api/customer/task/"      //+id

 



@interface GGTrackerManager ()


@property (nonatomic, strong) GGClientAppManager *customerManager;
@property (nonatomic, strong) NSString *customerToken;
@property (nonatomic, strong) NSString *developerToken;
@property (nonatomic, strong) NSMutableArray *orders;
@property (nonatomic, strong) NSMutableArray *locations;

@property (nonatomic, strong) NSTimer *orderPollingTimer;
@property (nonatomic, strong) NSTimer *driverPollingTimer;



- (void)shareLocationWithShareUUID:(NSString *)uuid completionHandler:(void (^)(BOOL success, GGSharedLocation *location, NSError *error))completionHandler;
- (void)orderWithOrderID:(NSNumber *)orderID completionHandler:(void (^)(BOOL success, GGOrder *order, NSError *error))completionHandler;

- (void)startOrderPolling;
- (void)stopOrderPolling;
- (void)startDriverPolling;
- (void)stopDriverPolling;

- (void)orderPolling:(NSTimer *)timer;
- (void)driverPolling:(NSTimer *)timer;

@end

@implementation GGTrackerManager

@synthesize liveMonitor = _liveMonitor;

+ (id)sharedInstance {
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
        
    });
}

- (id)init {
    if (self = [super init]) {
        
        
        // setup the realtime manager
        _liveMonitor = [GGRealTimeMontior sharedInstance];
 
        
    }
    return self;
    
}

- (void)dealloc {
    
}



#pragma mark - Setters

- (void)setConnectionDelegate:(id <RealTimeDelegate>)delegate {
    [self.liveMonitor setRealTimeConnectionDelegate:delegate];
    
}

- (void)setCustomerManager:(GGClientAppManager *)customer {
    _customerManager = customer;
    
}



#pragma mark - Polling

- (void)startOrderPolling {
    self.orderPollingTimer = [NSTimer scheduledTimerWithTimeInterval:20.0
                                                              target:self
                                                            selector:@selector(orderPolling:)
                                                            userInfo:nil
                                                             repeats:YES];
    
}

- (void)stopOrderPolling {
    [self.orderPollingTimer invalidate];
    self.orderPollingTimer = nil;
    
}

- (void)startDriverPolling {
    self.driverPollingTimer = [NSTimer scheduledTimerWithTimeInterval:20.0
                                                              target:self
                                                             selector:@selector(driverPolling:)
                                                            userInfo:nil
                                                             repeats:YES];
    
}

- (void)stopDriverPolling {
    [self.driverPollingTimer invalidate];
    self.driverPollingTimer = nil;
    
}



- (void)driverPolling:(NSTimer *)timer {
    [self shareLocationWithShareUUID:nil completionHandler:^(BOOL success, GGSharedLocation *location, NSError *error) {
        if (success) {
            
            
        }
    }];
}

#pragma mark - Actions

- (void)orderWithOrderID:(NSNumber *)orderID completionHandler:(void (^)(BOOL success, GGOrder *order, NSError *error))completionHandler {
    
    
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:3];
    if (self.customerManager.developerToken) {
        [params setObject:self.customerManager.developerToken forKey:BTDeveloperTokenKey];
        
    }
    
    
    GGCustomer *customer = self.customerManager.customer;
    
    if (customer) {
        if (customer.customerToken) {
            [params setObject:customer.customerToken forKey:BTCustomerTokenKey];
            
        }
        if (customer.merchantId) {
            [params setObject:customer.merchantId forKey:BTMerchantIdKey];
            
        }
        if (customer.phone) {
            [params setObject:customer.phone forKey:BTCustomerPhoneKey];
            
        }
    }
    
    //NSLog(@"order params %@", params);
    NSString *url = [NSString stringWithFormat:@"http://%@%@%@", BTRealtimeServer, BTRESTOrderPath, orderID];
    NSLog(@"%@", url);
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        BOOL result = NO;
        NSError *error;
        
        GGOrder *order;
        
        //NSLog(@"response order %@", responseObject);
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            id success = [responseObject objectForKey:BTSuccessKey];
            
            if ([success isKindOfClass:[NSString class]] &&
                [success isEqualToString:@"ok"]) {
                
                result = YES;
                
                order = [[GGOrder alloc] initOrderWithData:responseObject];

            } else {
                id message = [responseObject objectForKey:BTMessageKey];
                if ([message isKindOfClass:[NSString class]]) {
                    error = [NSError errorWithDomain:@"BringgCustomer" code:0
                                            userInfo:@{NSLocalizedDescriptionKey: message,
                                                       NSLocalizedRecoverySuggestionErrorKey: message}];
                    
                } else {
                    error = [NSError errorWithDomain:@"BringgCustomer" code:0
                                            userInfo:@{NSLocalizedDescriptionKey: @"Undefined Error",
                                                       NSLocalizedRecoverySuggestionErrorKey: @"Undefined Error"}];
                    
                }
            }
        }
        if (completionHandler) {
            completionHandler(result, order, error);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completionHandler) {
            completionHandler(NO, nil, error);
            
        }
    }];

}

- (void)shareLocationWithShareUUID:(NSString *)uuid completionHandler:(void (^)(BOOL success, GGSharedLocation *sharedLocation, NSError *error))completionHandler {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:3];
    
     GGCustomer *customer = self.customerManager.customer;
    
    if (self.customerManager.developerToken) {
        [params setObject:self.customerManager.developerToken forKey:BTDeveloperTokenKey];
        
    }
    if (self.customerToken) {
        [params setObject:self.customerToken forKey:BTCustomerTokenKey];
        
    }
    if (customer.merchantId) {
        [params setObject:customer.merchantId forKey:BTMerchantIdKey];
        
    }
    //NSLog(@"shareLocation %@ %@ %@", self.customer.developerToken, self.customerToken, self.customer.merchantId);
    NSString *url = [NSString stringWithFormat:@"http://%@%@%@", BTRealtimeServer, BTRESTSharedLocationPath, uuid];
    NSLog(@"%@", url);
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        BOOL result = NO;
        NSError *error;
        //NSString *ratingToken;
        //NSLog(@"%@", responseObject);
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            id success = [responseObject objectForKey:BTSuccessKey];
            //id token = [responseObject objectForKey:BTRatingTokenKey];
            if ([success isKindOfClass:[NSString class]] &&
                [success isEqualToString:@"ok"] /*&&
                [token isKindOfClass:[NSString class]]*/) {
                result = YES;
                //ratingToken = token;
                
            } else {
                id message = [responseObject objectForKey:BTMessageKey];
                if ([message isKindOfClass:[NSString class]]) {
                    error = [NSError errorWithDomain:@"BringgCustomer" code:0
                                            userInfo:@{NSLocalizedDescriptionKey: message,
                                                       NSLocalizedRecoverySuggestionErrorKey: message}];
                    
                } else {
                    error = [NSError errorWithDomain:@"BringgCustomer" code:0
                                            userInfo:@{NSLocalizedDescriptionKey: @"Undefined Error",
                                                       NSLocalizedRecoverySuggestionErrorKey: @"Undefined Error"}];
                    
                }
            }
        }
        if (completionHandler) {
            completionHandler(result, responseObject, error);
            
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completionHandler) {
            completionHandler(NO, nil, error);
            
        }
    }];
}

- (void)rateWithRating:(NSUInteger)rating shareUUID:(NSString *)uuid completionHandler:(void (^)(BOOL success, NSError *error))completionHandler {
    
    
    [self shareLocationWithShareUUID:uuid completionHandler:^(BOOL success, GGSharedLocation *location, NSError *error) {
        
        if (success) {
            
            NSString *ratingToken = location.rating.token;
            NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:5];
            
            GGCustomer *customer = self.customerManager.customer;
            
            if (self.customerManager.developerToken) {
                [params setObject:self.customerManager.developerToken forKey:BTDeveloperTokenKey];
                
            }
            if (customer.customerToken) {
                [params setObject:self.customerToken forKey:BTCustomerTokenKey];
                
            }
            if (customer.merchantId) {
                [params setObject:customer.merchantId forKey:BTMerchantIdKey];
                
            }
            if (ratingToken) {
                [params setObject:ratingToken forKey:BTTokenKey];
                
            }
            if (rating) {
                [params setObject:@(rating) forKey:BTRatingKey];
                
            }
            //NSLog(@"rate params %@", params);
            NSString *url = [NSString stringWithFormat:@"http://%@%@%@", BTRealtimeServer, BTRESTRatingPath, uuid];
            AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
            [manager setRequestSerializer:[AFHTTPRequestSerializer serializer]];
            [manager.requestSerializer setTimeoutInterval:90.0];
            
            [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
                BOOL result = NO;
                NSError *error;
                //NSLog(@"%@", responseObject);
                if ([responseObject isKindOfClass:[NSDictionary class]]) {
                    id success = [responseObject objectForKey:@"success"];
                    if ([success isKindOfClass:[NSNumber class]] &&
                        [success isEqualToNumber:@(true)]) {
                        result = YES;
                        
                    } else {
                        id message = [responseObject objectForKey:BTMessageKey];
                        if ([message isKindOfClass:[NSString class]]) {
                            error = [NSError errorWithDomain:@"BringgCustomer" code:0
                                                    userInfo:@{NSLocalizedDescriptionKey: message,
                                                               NSLocalizedRecoverySuggestionErrorKey: message}];
                            
                        } else {
                            error = [NSError errorWithDomain:@"BringgCustomer" code:0
                                                    userInfo:@{NSLocalizedDescriptionKey: @"Undefined Error",
                                                               NSLocalizedRecoverySuggestionErrorKey: @"Undefined Error"}];
                            
                        }
                    }
                }
                if (completionHandler) {
                    completionHandler(result, error);
                    
                }
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (completionHandler) {
                    completionHandler(NO, error);
                    
                }
            }];
        } else {
            if (completionHandler) {
                completionHandler(NO, error);
                
            }
        }
    }];
}

- (void)connectWithCustomerToken:(NSString *)customerToken andDeveloperToken:(NSString *)devToken withCompletionHandler:(void (^)(BOOL success, GGRealTimeMontior __weak  *realTimeManager , NSError *error))completionHandler
{
    
    if (!customerToken || !devToken) {
        // send delegate an error
        NSString *message = @"Missing or incorrect tokens";
        NSError *error = [NSError errorWithDomain:@"GGTrackerManager"
                                             code:400
                                         userInfo:@{NSLocalizedDescriptionKey:message,NSLocalizedRecoverySuggestionErrorKey: message}];
        
        
        if (completionHandler) {
            completionHandler(NO, nil ,error);
        }
        
        return;
    }else{
        self.customerToken = customerToken;
        [self.liveMonitor setDeveloperToken:devToken];
        [self.liveMonitor connect];
        
        if (completionHandler) {
            completionHandler(YES, _liveMonitor ,nil);
        }
    }
    
    
    
}



@end
