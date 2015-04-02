//
//  BringgCustomer.h
//  BringgTracking
//
//  Created by Ilya Kalinin on 3/9/15.
//  Copyright (c) 2015 Ilya Kalinin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BringgCustomer : NSObject

+ (id)sharedInstance;

- (void)setDeveloperToken:(NSString *)developerToken;

- (BOOL)isSignedIn;
- (void)signInWithName:(NSString *)name phone:(NSString *)phone confirmationCode:(NSString *)confirmationCode merchantId:(NSString *)merchantId
     completionHandler:(void (^)(BOOL success, NSString *customerToken, NSError *error))completionHandler;
- (void)rateWithRating:(NSUInteger)rating shareUUID:(NSString *)uuid completionHandler:(void (^)(BOOL success, NSError *error))completionHandler;

@end
