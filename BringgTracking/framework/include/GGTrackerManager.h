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

@protocol RealTimeDelegate <NSObject>

/**
 *  notifies delegate that a socket connection has been made
 */
- (void)trackerDidConnect;

/**
 *  notifies the delegate that the tracker has disconnected the socket connection w/o and error
 *  @usage the tracker manager handles connection recoveries by its own if network allows it. so this notifications is just to give the delegete a change to updates its own model to whatever he desiers
 *  @param error an error describing connection error (might be nill if forced)
 */
- (void)trackerDidDisconnectWithError:(NSError * _Nullable)error;

@optional

/**
 *  asks the delegate for a custom domain host for the tracker manager.
 *  if no domain is provided the tracker manager will resolve to its default
 *
 *  @param trackerManager the tracker manager request
 *
 *  @return the domain to connect the tracker manager
 */
-(NSString * _Nullable)hostDomainForTrackerManager:(GGTrackerManager *_Nonnull)trackerManager;

@end



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
 *
 *  @return BOOL
 */
- (BOOL)isWatchingWaypointWithWaypointId:(NSNumber *_Nonnull)waypointId;


// track actions
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
 *  @param delegate   object to recieve waypoint callbacks
 *  @see WaypointDelegate
 */
- (void)startWatchingWaypointWithWaypointId:(NSNumber *_Nonnull)waypointId
                                   delegate:(id <WaypointDelegate> _Nullable)delegate;


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
 */
- (void)stopWatchingWaypointWithWaypointId:(NSNumber * _Nonnull)waypointId;

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
