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
#define BCDevelopmentTokenKey @"developer_access_token"
#define BCCustomerTokeKey @"access_token"

#define BCRESTSignInPath @"/api/customer/sign_in"   //method: POST; phone, name, confirmation_code, merchant_id, dev_access_token

@interface BringgCustomer ()
@property (nonatomic, strong) NSString *developerToken;
@property (nonatomic, strong) NSString *customerToke;

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
    return self.customerToke ? YES : NO;
    
}

#pragma mark - Actions

- (void)signInWithName:(NSString *)name phone:(NSString *)phone confirmationCode:(NSString *)confirmationCode merchantId:(NSString *)merchantId
     completionHandler:(void (^)(BOOL success, NSString *customerToken, NSError *error))completionHandler {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:5];
    if (self.developerToken) {
        [params setObject:self.developerToken forKey:BCDevelopmentTokenKey];
        
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
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            id success = [responseObject objectForKey:BCSuccessKey];
            id token = [responseObject objectForKey:BCCustomerTokeKey];
            if ([success isKindOfClass:[NSString class]] &&
                [success isEqualToString:@"ok"] &&
                [token isKindOfClass:[NSString class]]) {
                result = YES;
                self.customerToke = token;
                
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
                self.customerToke = nil;
            }
        }
        if (completionHandler) {
            completionHandler(result, self.customerToke, error);
            
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        self.customerToke = nil;
        if (completionHandler) {
            completionHandler(NO, nil, error);
            
        }
    }];
}

@end
