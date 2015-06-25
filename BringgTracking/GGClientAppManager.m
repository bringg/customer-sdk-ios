//
//  BringgCustomer.m
//  BringgTracking
//
//  Created by Ilya Kalinin on 3/9/15.
//  Copyright (c) 2015 Ilya Kalinin. All rights reserved.
//

#import "GGClientAppManager.h"
#import "GGClientAppManager_Private.h"
#import "GGCustomer.h"

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
#define BCConfirmationCodeKey @"confirmation_code"
#define BCDeveloperTokenKey @"developer_access_token"
#define BCDeveloperTokenKey @"developer_access_token"

#define BCRatingTokenKey @"rating_token"
#define BCRatingKey @"rating"

#define BCRESTSignInPath @"/api/customer/sign_in"   //method: POST; phone, name, confirmation_code, merchant_id, dev_access_token

@implementation GGClientAppManager

+ (id)sharedInstance {
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
        
    });
}

- (id)init {
    if (self = [super init]) {
        // do nothing
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
    return self.customer ? YES : NO;
    
}

#pragma mark - Actions

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
    
    //NSLog(@"params %@", params);
    NSString *url = [NSString stringWithFormat:@"http://%@%@", BCRealtimeServer, BCRESTSignInPath];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        BOOL result = NO;
        NSError *error;
        
        GGCustomer *customer = nil;
        
        //NSLog(@"%@", responseObject);
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            id success = [responseObject objectForKey:BCSuccessKey];
            id token = [responseObject objectForKey:BCCustomerTokenKey];
            if ([success isKindOfClass:[NSString class]] &&
                [success isEqualToString:@"ok"] &&
                [token isKindOfClass:[NSString class]]) {
                result = YES;
                
//                NSDictionary *customerData = @{BCCustomerTokenKey : token,
//                                               BCDeveloperTokenKey: self.developerToken,
//                                               BCMerchantIdKey : merchantId,
//                                               BCPhoneKey : phone,
//                                               BCNameKey : name};
                
                customer = [[GGCustomer alloc] initWithData:responseObject];
                
                
                
            } else {
                id message = [responseObject objectForKey:BCMessageKey];
                if ([message isKindOfClass:[NSString class]]) {
                    error = [NSError errorWithDomain:@"GGClientAppManager" code:0
                                                     userInfo:@{NSLocalizedDescriptionKey: message,
                                                                NSLocalizedRecoverySuggestionErrorKey: message}];
                    
                } else {
                    error = [NSError errorWithDomain:@"GGClientAppManager" code:0
                                            userInfo:@{NSLocalizedDescriptionKey: @"Undefined Error",
                                                       NSLocalizedRecoverySuggestionErrorKey: @"Undefined Error"}];
                    
                }
               
                
            }
        }
        
        self.customer = customer;
        
        if (completionHandler) {
            completionHandler(result, customer, error);
            
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"signIn failed");
        self.customer = nil;
        if (completionHandler) {
            completionHandler(NO, nil, error);
            
        }
    }];
}

@end
