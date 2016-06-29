//
//  BringgTracker.h
//  BringgTrackingService
//
//  Created by Matan Poreh on 12/16/14.
//  Copyright (c) 2014 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>

 
#import "BringgGlobals.h"
#import "GGRealTimeMontior.h"

@class GGRealTimeMontior;
@class GGHTTPClientManager;
@class GGSharedLocation;
@class GGOrder;
@class GGDriver;
@class GGRating;
@class GGCustomer;
@class GGTrackerManager;


@interface GGTrackerManager : NSObject <RealTimeDelegate, GGRealTimeMonitorConnectionDelegate>

@property (nonatomic, readonly) GGRealTimeMontior * _Nullable liveMonitor;
@property (nonatomic, getter=customer) GGCustomer * _Nullable appCustomer;


/**
 *  creates if needed and returns an initialized tracker singelton
 *  @return the tracker singelton
 */
+ (nonnull id)tracker;


/**
 *  creates if needed an singelton Bringg Tracker object
 *  @warning call this method only when obtained valid customer access token and developer access token
 *  @param customerToken a valid customer access token
 *  @param devToken      a valid developer access token
 *  @param delegate      a delegate object to recive notification from the Bringg tracker object
 *  @param httpManager   an http manager that will do the polling for the tracker
 *
 *  @return the Bringg Tracker singelton
 */
+ (nonnull id)trackerWithCustomerToken:(NSString * _Nullable)customerToken andDeveloperToken:(NSString *_Nullable)devToken andDelegate:(id <RealTimeDelegate> _Nullable)delegate andHTTPManager:(GGHTTPClientManager * _Nullable)httpManager;

/**
 *  set the developer token for the singelton
 *  @param devToken
 */
- (void)setDeveloperToken:(NSString * _Nullable)devToken;

/**
 *  set the httpManager that will be used to poll data for the tracker
 *
 *  @param httpManager GGHTTPManager
 */
- (void)setHTTPManager:(GGHTTPClientManager * _Nullable)httpManager;

/**
 *  sets the delegate to receieve real time updates
 *
 *  @param delegate a delegate confirming to RealTimeDelegate protocol
 */
- (void)setRealTimeDelegate:(id <RealTimeDelegate> _Nullable)delegate;


/**
 *  tells the tracker to connect to the real time update service asscosiated with the tracker
 *
 *  @param useSecure should use SSL connection or not
 */
- (void)connectUsingSecureConnection:(BOOL)useSecure;


/**
 *  sets should the tracket automaticaly reconnect when expereincing disconnections
 *  @usage defaults to YES
 *  @param shouldAutoReconnect BOOL
 */
- (void)setShouldAutoReconnect:(BOOL)shouldAutoReconnect;

/**
 *  tells the tracker to disconnect from the real time update service asscosiated with the tracker
 */
- (void)disconnect;


/**
 *  updates the tracker with a Customer object
 *  @warning Customer objects are obtained via performing sign in operations with the GGHTTPClientManager.h
 *  @param customer the Customer object representing the logged in customer
 */
- (void)setCustomer:(GGCustomer * _Nullable)customer;



// status checks


/**
 *  test of tracker is connected to the real time update service
 *
 *  @return BOOL
 */
- (BOOL)isConnected;

/**
 *  tell if any orders are being watched
 *
 *  @return BOOL
 */
- (BOOL)isWatchingOrders;


/**
 *  checks if the tracker is supporting polling
 *  @usage to support polling the tracker needs an http manager that holds a customer object (for authentication)
 *  @return BOOL
 */
- (BOOL)isPollingSupported;

/**
 *  tell if a specific order is being watched
 *
 *  @param uuid uuid of order in question
 *
 *  @return BOOL
 */
- (BOOL)isWatchingOrderWithUUID:(NSString *_Nonnull)uuid;

/**
 *  tell if a specific order is being watched
 *
 *  @param compoundUUID compound uuid of order in question
 *
 *  @return BOOL
 */
- (BOOL)isWatchingOrderWithCompoundUUID:(NSString *_Nonnull)compoundUUID;

/**
 *  tell if any drivers are being watched
 *
 *  @return BOOL
 */
- (BOOL)isWatchingDrivers;

/**
 *  tell if a specific driver is being watched
 *
 *  @param uuid uuid of driver
 *
 *  @return BOOL
 */
- (BOOL)isWatchingDriverWithUUID:(NSString *_Nonnull)uuid andShareUUID:(NSString *_Nonnull)shareUUID;

/**
 *  tell if any waypoints are being watched
 *
 *  @return BOOL
 */
- (BOOL)isWatchingWaypoints;

/**
 *  tell if a specific waypoint is being watched
 *
 *  @param waypointId id of waypoint
 *  @param orderUUID uuid of order
 *  @return BOOL
 */
- (BOOL)isWatchingWaypointWithWaypointId:(NSNumber *_Nonnull)waypointId andOrderUUID:(NSString * _Nonnull)orderUUID;

/**
 *  return an order matching a uuid
 *
 *  @param uuid order uuid to search
 *
 *  @return GGOrder
 */
- (nullable GGOrder *)orderWithUUID:(nonnull NSString *)uuid;

/**
 *  returns an order matching a compound uuid (combination of order uuid and shared location uuid)
 *
 *  @param compoundUUID compound order uuid
 *
 *  @return GGOrder
 */
- (nullable GGOrder *)orderWithCompoundUUID:(nonnull NSString *)compoundUUID;

//MARK: track actions

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
 *  sends a findme request for a specific order
 *
 *  @param compoundUUID      compound UUID of order
 *  @param lat                 latitude
 *  @param lng                 longitude
 *  @param completionHandler callback handler
 
 */
- (void)sendFindMeRequestForOrderWithCompoundUUID:(NSString *_Nonnull)compoundUUID
                                         latitude:(double)lat
                                        longitude:(double)lng withCompletionHandler:(nullable GGActionResponseHandler)completionHandler;

/**
 *  sends a findme request for a specific order
 *
 *  @param order             the order object
 *  @param lat                 latitude
 *  @param lng                 longitude
 *  @param completionHandler callback handler
 */
- (void)sendFindMeRequestForOrder:(nonnull GGOrder *)order
                         latitude:(double)lat
                        longitude:(double)lng
            withCompletionHandler:(nullable GGActionResponseHandler)completionHandler;

/**
 *  asks the real time service to start tracking a specific order
 *
 *  @param uuid     uuid of order
 *  @param delegate object to recieve order callbacks
 *  @see OrderDelegate
 */
- (void)startWatchingOrderWithUUID:(NSString *_Nonnull)uuid
                          delegate:(id <OrderDelegate> _Nullable)delegate;

/**
 *  asks the real time service to start tracking a specific order
 *  this method throws if not valid compound uuid
 *
 *  @param compoundUUID order compound uuid
 *  @param delegate object to recieve order callbacks
 *  @see OrderDelegate
 *  @throws exception if invalid compound uuid
 */
- (void)startWatchingOrderWithCompoundUUID:(NSString *_Nonnull)compoundUUID
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
                          shareUUID:(NSString *_Nonnull)shareUUID
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
 *  stops tracking a specific order
 *
 *  @param uuid uuid of order
 */
- (void)stopWatchingOrderWithUUID:(NSString *_Nonnull)uuid;

/**
 *  stops tracking a specific order
 *  this method will throw an exception if compoundUUID is invalid
 *
 *  @param compoundUUID compound uuid of order
 *  @throws exception if invalid compound uuid
 */
- (void)stopWatchingOrderWithCompoundUUID:(NSString *_Nonnull)compoundUUID;

/**
 *  stop watching all orders
 */
- (void)stopWatchingAllOrders;

/**
 *  stops tracking a specific driver
 *
 *  @param uuid      uuid of driver
 *  @param shareUUID uuid of shared location object associated with a specific order
 */
- (void)stopWatchingDriverWithUUID:(NSString *_Nonnull)uuid
                         shareUUID:(NSString *_Nullable)shareUUID;
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
 *  remove all delegates listening for order updates
 */
- (void)removeOrderDelegates;

/**
 *  remove all delegates listening for driver updates
 */
- (void)removeDriverDelegates;

/**
 *  clear all delegates listening for waypoint updates
 */
- (void)removeWaypointDelegates;

/**
 *  clear all delegates listening for updates
 */
- (void)removeAllDelegates;


/**
 *  get a list of monitored orders
 *
 *  @return a list of order uuid's
 */
- (NSArray * _Nullable)monitoredOrders;

/**
 *  get a list of monitored drivers
 *
 *  @return a list of driver uuid's
 */

- (NSArray * _Nullable)monitoredDrivers;

/**
 *  get a list of monitored waypoints
 *
 *  @return a list of waypoint id's
 */
- (NSArray * _Nullable)monitoredWaypoints;

@end
