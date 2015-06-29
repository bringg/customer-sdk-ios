//
//  BringgCustomer.h
//  BringgTracking
//
//  Created by Ilya Kalinin on 3/9/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GGCustomer;
@class GGOrder;
@class GGSharedLocation;
@class GGDriver;
@class GGRating;
@class GGOrderBuilder;

@interface GGHTTPClientManager : NSObject

+ (id)sharedInstance;

- (void)setDeveloperToken:(NSString *)developerToken;


- (void)signInWithName:(NSString *)name
                 phone:(NSString *)phone
      confirmationCode:(NSString *)confirmationCode
            merchantId:(NSString *)merchantId
     completionHandler:(void (^)(BOOL success, GGCustomer *customer, NSError *error))completionHandler;


- (void)getOrderByID:(NSUInteger)orderId withCompletionHandler:(void (^)(BOOL success, GGOrder *order, NSError *error))completionHandler;

- (void)getSharedLocationByID:(NSUInteger)sharedLocationId withCompletionHandler:(void (^)(BOOL success, GGSharedLocation *sharedLocation, NSError *error))completionHandler;

- (void)rate:(int)rating withToken:(NSString *)ratingToken forSharedUUID:(NSString *)sharedUUID withCompletionHandler:(void (^)(BOOL success, GGRating *rating, NSError *error))completionHandler;

- (void)addOrderWith:(GGOrderBuilder *)orderBuilder withCompletionHandler:(void (^)(BOOL success, GGOrder *order, NSError *error))completionHandler;

- (BOOL)isSignedIn;
- (BOOL)hasPhone;
- (BOOL)hasMerchantId;

@end
