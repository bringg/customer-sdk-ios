//
//  BringgCustomer.m
//  BringgTracking
//
//  Created by Ilya Kalinin on 3/9/15.
//  Copyright (c) 2015 Ilya Kalinin. All rights reserved.
//

#import "BringgCustomer.h"

#import "AFNetworking.h"

#define DEFINE_SHARED_INSTANCE_USING_BLOCK(block) \
static dispatch_once_t pred = 0; \
__strong static id _sharedObject = nil; \
dispatch_once(&pred, ^{ \
_sharedObject = block(); \
}); \
return _sharedObject;

#define BCRealtimeServer @"realtime.bringg.com"

#define BCSuccessKey @"status"
#define BCMessageKey @"message"
#define BCNameKey @"name"
#define BCPhoneKey @"phone"
#define BCConfirmationCodeKey @"confirmation_code"
#define BCMerchantIdKey @"merchant_id"
#define BCDeveloperTokenKey @"developer_access_token"
#define BCCustomerTokenKey @"access_token"
#define BCRatingTokenKey @"rating_token"
#define BCTokenKey @"token"
#define BCRatingKey @"rating"

#define BCRESTSignInPath @"/api/customer/sign_in"   //method: POST; phone, name, confirmation_code, merchant_id, dev_access_token
#define BCRESTSharedLocationPath @"/api/shared/"    //+uuid
#define BCRESTRatingPath @"/api/rate/"              //+uuid


@interface BringgCustomer ()
@property (nonatomic, strong) NSString *developerToken;
@property (nonatomic, strong) NSString *customerToken;
@property (nonatomic, strong) NSString *merchantId;

- (void)shareLocationWithShareUUID:(NSString *)uuid completionHandler:(void (^)(BOOL success, NSString *ratingToken, NSError *error))completionHandler;

@end

@implementation BringgCustomer

+ (id)sharedInstance {
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
        
    });
}

- (id)init {
    if (self = [super init]) {
        
    }
    return self;
    
}

- (void)dealloc {
    
}

#pragma mark - Setters

- (void)setDeveloperToken:(NSString *)developerToken {
    _developerToken = developerToken;
    
}

#pragma mark - Status

- (BOOL)isSignedIn {
    return self.customerToken ? YES : NO;
    
}

#pragma mark - Actions

- (void)shareLocationWithShareUUID:(NSString *)uuid completionHandler:(void (^)(BOOL success, NSString *ratingToken, NSError *error))completionHandler {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:3];
    if (self.developerToken) {
        [params setObject:self.developerToken forKey:BCDeveloperTokenKey];
        
    }
    if (self.customerToken) {
        [params setObject:self.customerToken forKey:BCCustomerTokenKey];
        
    }
    if (self.merchantId) {
        [params setObject:self.merchantId forKey:BCMerchantIdKey];
        
    }
    //NSLog(@"shareLocation %@ %@ %@", self.developerToken, self.customerToken, self.merchantId);
    NSString *url = [NSString stringWithFormat:@"http://%@%@%@", BCRealtimeServer, BCRESTSharedLocationPath, uuid];
    //NSLog(@"%@", url);
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        BOOL result = NO;
        NSError *error;
        NSString *ratingToken;
        //NSLog(@"%@", responseObject);
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            id success = [responseObject objectForKey:BCSuccessKey];
            id token = [responseObject objectForKey:BCRatingTokenKey];
            if ([success isKindOfClass:[NSString class]] &&
                [success isEqualToString:@"ok"] &&
                [token isKindOfClass:[NSString class]]) {
                result = YES;
                ratingToken = token;
                
            } else {
                id message = [responseObject objectForKey:BCMessageKey];
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
            completionHandler(result, ratingToken, error);
            
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completionHandler) {
            completionHandler(NO, nil, error);
            
        }
    }];
}

- (void)rateWithRating:(NSUInteger)rating shareUUID:(NSString *)uuid completionHandler:(void (^)(BOOL success, NSError *error))completionHandler {
    [self shareLocationWithShareUUID:uuid completionHandler:^(BOOL success, NSString *ratingToken, NSError *error) {
        if (success) {
            NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:5];
            if (self.developerToken) {
                [params setObject:self.developerToken forKey:BCDeveloperTokenKey];
                
            }
            if (self.customerToken) {
                [params setObject:self.customerToken forKey:BCCustomerTokenKey];
                
            }
            if (self.merchantId) {
                [params setObject:self.merchantId forKey:BCMerchantIdKey];
                
            }
            if (ratingToken) {
                [params setObject:ratingToken forKey:BCTokenKey];
                
            }
            if (rating) {
                [params setObject:@(rating) forKey:BCRatingKey];
                
            }
            //NSLog(@"rate %@ %@ %@ %@ %@", self.developerToken, self.customerToken, self.merchantId, @(rating), ratingToken);
            NSString *url = [NSString stringWithFormat:@"http://%@%@%@", BCRealtimeServer, BCRESTRatingPath, uuid];
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
                        id message = [responseObject objectForKey:BCMessageKey];
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

- (void)signInWithName:(NSString *)name phone:(NSString *)phone confirmationCode:(NSString *)confirmationCode merchantId:(NSString *)merchantId
     completionHandler:(void (^)(BOOL success, NSString *customerToken, NSError *error))completionHandler {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:5];
    if (self.developerToken) {
        [params setObject:self.developerToken forKey:BCDeveloperTokenKey];
        
    }
    if (name) {
        [params setObject:name forKey:BCNameKey];
        
    }
    if (name) {
        [params setObject:phone forKey:BCPhoneKey];
        
    }
    if (confirmationCode) {
        [params setObject:confirmationCode forKey:BCConfirmationCodeKey];
        
    }
    if (merchantId) {
        [params setObject:merchantId forKey:BCMerchantIdKey];
        
    }
    NSString *url = [NSString stringWithFormat:@"http://%@%@", BCRealtimeServer, BCRESTSignInPath];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        BOOL result = NO;
        NSError *error;
        //NSLog(@"%@", responseObject);
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            id success = [responseObject objectForKey:BCSuccessKey];
            id token = [responseObject objectForKey:BCCustomerTokenKey];
            if ([success isKindOfClass:[NSString class]] &&
                [success isEqualToString:@"ok"] &&
                [token isKindOfClass:[NSString class]]) {
                result = YES;
                self.customerToken = token;
                self.merchantId = merchantId;
                
            } else {
                id message = [responseObject objectForKey:BCMessageKey];
                if ([message isKindOfClass:[NSString class]]) {
                    error = [NSError errorWithDomain:@"BringgCustomer" code:0
                                                     userInfo:@{NSLocalizedDescriptionKey: message,
                                                                NSLocalizedRecoverySuggestionErrorKey: message}];
                    
                } else {
                    error = [NSError errorWithDomain:@"BringgCustomer" code:0
                                            userInfo:@{NSLocalizedDescriptionKey: @"Undefined Error",
                                                       NSLocalizedRecoverySuggestionErrorKey: @"Undefined Error"}];
                    
                }
                self.customerToken = nil;
                
            }
        }
        if (completionHandler) {
            completionHandler(result, self.customerToken, error);
            
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"signIn failed");
        self.customerToken = nil;
        if (completionHandler) {
            completionHandler(NO, nil, error);
            
        }
    }];
}

@end
