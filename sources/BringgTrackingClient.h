//
//  BringgClient.h
//  BringgTracking
//
//  Created by Matan on 13/02/2017.
//  Copyright © 2017 Bringg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BringgGlobals.h"

@class GGCustomer, GGOrder;

@interface BringgTrackingClient : NSObject


/**
 creates the bringg tracking client singelton

 @param developerToken developer token as given by bringg platform
 @param delegate connection delegate to track connection status of tracking client
 @return singelton
 */
+ (nonnull instancetype)clientWithDeveloperToken:(nonnull NSString *)developerToken connectionDelegate:(nonnull id<RealTimeDelegate>)delegate;



//MARK: -- Connection

/**
 connects the tracking client to Bringg platform
 */
- (void)connect;

/**
 disconnects tracking.
 */
- (void)disconnect;


/**
 check if client is connected to Bringg platform

 @return BOOL
 */
- (BOOL)isConnected;

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
 *  tels if the customer is signed in
 *
 *  @return BOOL
 */
- (BOOL)isSignedIn;

/**
 *  retriesve the customer object of the signed in customer
 *
 *  @return GGCustomer
 */
- (nullable GGCustomer *)signedInCustomer;




//MARK: -- Tracking


/**
 *  starts watching an order using both order uuid and shared uuid
 *
 *  @param uuid       order uuid
 *  @param shareduuid shared uuid
 *  @param delegate   delegate
 *  @throws if invalid or missing either order UUID or shared UUID
 */
- (void)startWatchingOrderWithUUID:(NSString *_Nonnull)uuid
                        sharedUUID:(NSString *_Nonnull)shareduuid
                          delegate:(id <OrderDelegate> _Nullable)delegate;


/**
 *  starts watching an order using both order uuid and shared uuid
 *
 *  @param uuid       order uuid
 *  @param customerAccessToken customer access token
 *  @param delegate   delegate
 *  @throws if invalid or missing either order UUID or shared UUID
 */
- (void)startWatchingOrderWithUUID:(NSString *_Nonnull)uuid
               customerAccessToken:(NSString *_Nonnull)customerAccessToken
                          delegate:(id <OrderDelegate> _Nullable)delegate;


/**
 *  asks the real time service to start tracking a specific driver
 *
 *  @param uuid      uuid of driver
 *  @param shareUUID uuid of shared location object associated with a specific order
 *  @param delegate  object to recieve driver callbacks
 *  @see DriverDelegate
 */
- (void)startWatchingDriverWithUUID:(NSString *_Nonnull)uuid
                          shareUUID:(NSString *_Nonnull)shareduuid
                           delegate:(id <DriverDelegate> _Nullable)delegate;


/**
 *  asks the real time service to start tracking a specific driver
 *
 *  @param uuid      uuid of driver
 *  @param customerAccessToken  customer access token
 *  @param delegate  object to recieve driver callbacks
 *  @see DriverDelegate
 */
- (void)startWatchingDriverWithUUID:(NSString *_Nonnull)uuid
                customerAccessToken:(NSString *_Nonnull)customerAccessToken
                           delegate:(id <DriverDelegate> _Nullable)delegate;

/**
 *  asks the real time service to start tracking a specific waypoint
 *
 *  @param waypointId id of waypoint
 *  @param order uuid of of order handling the waypoint
 *  @param delegate   object to recieve waypoint callbacks
 *  @see WaypointDelegate
 */
- (void)startWatchingWaypointWithWaypointId:(NSNumber *_Nonnull)waypointId
                               andOrderUUID:(NSString * _Nonnull)orderUUID
                                   delegate:(id <WaypointDelegate> _Nullable)delegate;


/**
 *  sends a findme request for a specific order
 *
 *  @param uuid                 UUID of order
 *  @param lat                 latitude
 *  @param lng                 longitude
 *  @param completionHandler    callback handler
 */
- (void)sendFindMeRequestForOrderWithUUID:(NSString *_Nonnull)uuid
                                 latitude:(double)lat
                                longitude:(double)lng
                    withCompletionHandler:(nullable GGActionResponseHandler)completionHandler;


/**
 send customer rating for a specific order

 @param order order to rate
 @param rating rating for order's driver - must be between (1-5)
 @param completionHandler block to handle async service response
 */
- (void)rateOrder:(nonnull GGOrder *)order
       withRating:(int)rating
completionHandler:(nullable GGRatingResponseHandler)completionHandler;

/**
 *  stops tracking a specific order
 *
 *  @param uuid uuid of order
 */
- (void)stopWatchingOrderWithUUID:(NSString *_Nonnull)uuid;


/**
 *  stop watching all orders
 */
- (void)stopWatchingAllOrders;

/**
 *  stops tracking a specific driver
 *
 *  @param uuid      uuid of driver
 */
- (void)stopWatchingDriverWithUUID:(NSString *_Nonnull)uuid;

/**
 *  stops watching all drivers
 */
- (void)stopWatchingAllDrivers;

/**
 *  stops tracking a specific waypoint
 *
 *  @param waypointId id of waypoint
 *  @param orderUUID uuid of order with waypoint
 */
- (void)stopWatchingWaypointWithWaypointId:(NSNumber * _Nonnull)waypointId andOrderUUID:(NSString * _Nonnull)orderUUID;

/**
 *  stops tracking all waypoints
 */
- (void)stopWatchingAllWaypoints;


/**
 *  return an order matching a uuid
 *
 *  @param uuid order uuid to search
 *
 *  @return GGOrder
 */
- (nullable GGOrder *)orderWithUUID:(nonnull NSString *)uuid;

/**
 *  tell if a specific order is being watched
 *
 *  @param uuid uuid of order in question
 *
 *  @return BOOL
 */
- (BOOL)isWatchingOrderWithUUID:(NSString *_Nonnull)uuid;



/**
 *  return a driver matching a uuid
 *
 *  @param uuid driver uuid to search
 *
 *  @return GGDriver
 */
- (nullable GGDriver *)driverWithUUID:(nonnull NSString *)uuid;

/**
 *  tell if a specific driver is being watched
 *
 *  @param uuid uuid of driver
 *
 *  @return BOOL
 */
- (BOOL)isWatchingDriverWithUUID:(NSString *_Nonnull)uuid;


/**
 *  return a shared uuid object matching a driver uuid
 *
 *  @param uuid driver uuid to search by
 *
 *  @return NSString
 */
- (nullable NSString *)sharedUUIDForDriverUUID:(nonnull NSString*)driveruuid;

/**
 *  tell if a specific waypoint is being watched
 *
 *  @param waypointId id of waypoint
 *  @param orderUUID uuid of order
 *  @return BOOL
 */
- (BOOL)isWatchingWaypointWithWaypointId:(NSNumber *_Nonnull)waypointId andOrderUUID:(NSString * _Nonnull)orderUUID;

@end
