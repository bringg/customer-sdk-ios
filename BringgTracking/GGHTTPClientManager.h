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


/**
 *  return an initialized http manager singelton
 *  @warning make sure the singleton is already intiialized before using this accessor
 *  @return the http manager singelton
 */
+ (id)manager;

/**
 *  get a singelton reference to the http client manager
 *  @param developerToken   the developer token acquired when registering as a developer in Bringg website
 *  @return the http manager singelton
 */
+ (id)managerWithDeveloperToken:(NSString *)developerToken;

/**
 *  set the developer token for the singelton
 *  @warning it is prefered to init the singelton with a developer token instead of using this method
 *  @param devToken
 */
- (void)setDeveloperToken:(NSString *)devToken;

/**
 *  perform a sign in request with a specific customers credentials
 *  @warning do not call this method before setting a valid developer token. also notice method call won't work without valid confirmation code and merchant Id
 *  @param name              name of customer (don't use email here)
 *  @param phone             phone number of customer
 *  @param confirmationCode  sms confirmation code
 *  @param merchantId        merchant id registered for the customer
 *  @param completionHandler block to handle async service response
 */
- (void)signInWithName:(NSString *)name
                 phone:(NSString *)phone
      confirmationCode:(NSString *)confirmationCode
            merchantId:(NSString *)merchantId
     completionHandler:(void (^)(BOOL success, GGCustomer *customer, NSError *error))completionHandler;

/**
 *  retrieves an updated order object
 *  @warning the response Order object will have incomplete shared location object. to get the most updated location of an order you must use the tracker to track the order's driver
 *  @param orderId           the Id of the order to be retrieved
 *  @param completionHandler block to handle async service response
 */
- (void)getOrderByID:(NSUInteger)orderId withCompletionHandler:(void (^)(BOOL success, GGOrder *order, NSError *error))completionHandler;

/**
 *  get an updated shared location object from the service
 *
 *  @param sharedLocationUUID id of shared location object obtained from a specific order
 *  @param completionHandler  block to handle async service response
 */
- (void)getSharedLocationByUUID:(NSString *)sharedLocationUUID withCompletionHandler:(void (^)(BOOL success, GGSharedLocation *sharedLocation, NSError *error))completionHandler;

/**
 *  send customer rating for a specific driver
 *
 *  @param rating             the rating of the driver must be between (1-5)
 *  @param ratingToken        token to validate rating request - obtained from a valid shared location object related to a specific driver
 *  @param sharedLocationUUID id of shared location object related to a specific driver
 *  @param completionHandler  block to handle async service response
 */
- (void)rate:(int)rating withToken:(NSString *)ratingToken forSharedLocationUUID:(NSString *)sharedLocationUUID withCompletionHandler:(void (^)(BOOL success, GGRating *rating, NSError *error))completionHandler;

/**
 *  tels if the customer is signed in
 *
 *  @return BOOL
 */
- (BOOL)isSignedIn;

/**
 *  tells if customer has a valid phone number data
 *
 *  @return BOOL
 */
- (BOOL)hasPhone;

/**
 *  tells if customer has a valid merchant Id
 *
 *  @return BOOL
 */
- (BOOL)hasMerchantId;

 
@end
