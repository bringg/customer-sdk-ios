//
//  BringgCustomer.h
//  BringgTracking
//
//  Created by Matan Poreh on 3/9/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BringgGlobals.h"

@class GGCustomer;
@class GGOrder;
@class GGSharedLocation;
@class GGDriver;
@class GGRating;
@class GGOrderBuilder;
@class GGHTTPClientManager;
@class GGFindMe;



@protocol GGHTTPClientConnectionDelegate <NSObject>

@optional

/**
 *  asks the delegate for a custom domain host for the http manager.
 *  if no domain is provided the http manager will resolve to its default
 *
 *  @param clientManager the client manager request
 *
 *  @return the domain to connect the http manager
 */
-(NSString * _Nullable)hostDomainForClientManager:(GGHTTPClientManager *_Nonnull)clientManager;

@end

@interface GGHTTPClientManager : NSObject

@property (nullable, nonatomic, weak) id<GGHTTPClientConnectionDelegate> delegate;
@property (nullable, nonatomic, strong) NSDate *lastEventDate;


/**
 *  return an initialized http manager singelton
 *  @warning make sure the singleton is already intiialized before using this accessor
 *  @return the http manager singelton
 */
+ (nonnull id)manager;

/**
 *  get a singelton reference to the http client manager
 *  @param developerToken   the developer token acquired when registering as a developer in Bringg website
 *  @return the http manager singelton
 */
+ (nonnull id)managerWithDeveloperToken:(NSString *_Nullable)developerToken;

/**
 *  set the developer token for the singelton
 *  @warning it is prefered to init the singelton with a developer token instead of using this method
 *  @param devToken
 */
- (void)setDeveloperToken:(NSString * _Nullable)devToken;


/**
 *  tells the manager to use or not use HTTPS
 *  @usage default is set to YES
 *  @param isSecured BOOL
 */
- (void)useSecuredConnection:(BOOL)isSecured;


/**
 *  provides a customer object for the manager to use when authenticating  requests
 *
 *  @param customer GGCustomer
 */
- (void)useCustomer:(GGCustomer * _Nullable)customer;


/**
 *  adds custom http header fields for all requests
 *
 *  @param headers NSDictionary
 */
- (void)setCustomAuthenticationHeaders:(NSDictionary * _Nullable)headers;

/**
 *  perform a sign in request with a specific customers credentials
 *  @warning do not call this method before setting a valid developer token. also notice method call won't work without valid confirmation code and merchant Id
 *  @param name              name of customer (don't use email here)
 *  @param phone             phone number of customer
 *  @param confirmationCode  sms confirmation code
 *  @param merchantId        merchant id registered for the customer
 *  @param extras            additional arguments to add to the call
 *  @param completionHandler block to handle async service response
 */
- (void)signInWithName:(NSString * _Nullable)name
                 phone:(NSString * _Nullable)phone
                 email:(NSString * _Nullable)email
              password:(NSString * _Nullable)password
      confirmationCode:(NSString * _Nullable)confirmationCode
            merchantId:(NSString * _Nonnull)merchantId
                extras:(NSDictionary * _Nullable)extras
     completionHandler:(nullable GGCustomerResponseHandler)completionHandler;

/**
 *  retrieves an updated order object
 *  @warning the response Order object will have incomplete shared location object. to get the most updated location of an order you must use the tracker to track the order's driver
 *  @param extras            additional arguments to add to the call
 *  @param orderId           the Id of the order to be retrieved
 *  @param completionHandler block to handle async service response
 */
- (void)getOrderByID:(NSUInteger)orderId
              extras:(NSDictionary * _Nullable)extras
withCompletionHandler:(nullable GGOrderResponseHandler)completionHandler;


/**
 *  gets  data of an order this can be without the shared location object of an order (if its done or cancled, or not started yet(
 *
 *  @param shareUUID         share uuid
 *  @param orderUUID         order uuid
 *  @param extras            block to handle async service response
 *  @param completionHandler block to handle async service response
 */
- (void)getOrderByShareUUID:(NSString * _Nonnull)shareUUID
                  orderUUID:(NSString * _Nonnull)orderUUID
                     extras:(NSDictionary * _Nullable)extras
      withCompletionHandler:(nullable GGOrderResponseHandler)completionHandler;



/**
 *  send a find me request for an order
 *
 *  @param findmeConfig        findme configuration object holding token and url
 *  @param lat               latitude location
 *  @param lng               longitude location
 *  @param completionHandler remote handler
 */
- (void)sendFindMeRequestWithFindMeConfiguration:(nonnull GGFindMe *)findmeConfig latitude:(double)lat longitude:(double)lng  withCompletionHandler:(nullable GGActionResponseHandler)completionHandler;


/**
 *  this methods start a watch action on an order and in returns the data of a watched order by its uuid and shared uuid
 *
 *  @param orderUUID         order uuid
 *  @param extras            additional arguments to add to the call
 *  @param completionHandler block to handle async service response
 */
- (void)watchOrderByOrderUUID:(NSString * _Nonnull)orderUUID
                    shareUUID:(NSString * _Nullable)shareUUID
                       extras:(NSDictionary * _Nullable)extras
        withCompletionHandler:(nullable GGOrderResponseHandler)completionHandler;

/**
 *  get an updated shared location object from the service
 *
 *  @param sharedLocationUUID id of shared location object obtained from a specific order
 *  @param completionHandler  block to handle async service response
 */
- (void)getSharedLocationByUUID:(NSString * _Nonnull)sharedLocationUUID
                         extras:(NSDictionary * _Nullable)extras
          withCompletionHandler:(nullable GGSharedLocationResponseHandler)completionHandler;
 
/**
 *  send customer rating for a specific driver
 *
 *  @param rating            the rating of the driver must be between (1-5)

 *  @param ratingToken       token to validate rating request - obtained from a valid shared location object related to a specific driver

 *  @param ratingURL         rating url is provided with the shared location object responsible for the order
 *  @param completionHandler block to handle async service response
 */
- (void)rate:(int)rating
   withToken:(NSString * _Nonnull)ratingToken
   ratingURL:(NSString *_Nonnull)ratingURL
      extras:(NSDictionary * _Nullable)extras
withCompletionHandler:(nullable GGRatingResponseHandler)completionHandler;




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


/**
 *  retriesve the customer object of the signed in customer
 *
 *  @return GGCustomer
 */
- (nullable GGCustomer *)signedInCustomer;
 
@end
