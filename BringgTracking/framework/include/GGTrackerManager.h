//
//  BringgTracker.h
//  BringgTrackingService
//
//  Created by Ilya Kalinin on 12/16/14.
//  Copyright (c) 2014 Ilya Kalinin. All rights reserved.
//

#import <Foundation/Foundation.h>

 
#import "BringgGlobals.h"

@class GGRealTimeMontior;
@class GGHTTPClientManager;
@class GGSharedLocation;
@class GGOrder;
@class GGDriver;
@class GGRating;
@class GGCustomer;

@protocol RealTimeDelegate <NSObject>
- (void)trackerDidConnect;
- (void)trackerDidDisconnectWithError:(NSError *)error;

@end



@interface GGTrackerManager : NSObject

@property (nonatomic, readonly) GGRealTimeMontior * liveMonitor;
@property (nonatomic, getter=customer) GGCustomer *appCustomer;


/**
 *  return an initialized tracker singelton after
 *  @warning make sure the singleton is already intiialized before using this accessor
 *  @return the tracker singelton
 */
+ (id)tracker;

/**
 *  creates a singelton Bringg Tracker object
 *  @warning call this method only when obtained valid customer access token and developer access token
 *  @param customerToken a valid customer access token
 *  @param devToken      a valid developer access token
 *  @param delegate      a delegate object to recive notification from the Bringg tracker object
 *
 *  @return the Bringg Tracker singelton
 */
+ (id)trackerWithCustomerToken:(NSString *)customerToken andDeveloperToken:(NSString *)devToken andDelegate:(id <RealTimeDelegate>)delegate;

/**
 *  set the developer token for the singelton
 *  @warning it is prefered to init the singelton with a developer token instead of using this method
 *  @param devToken
 */
- (void)setDeveloperToken:(NSString *)devToken;


/**
 *  set the developer token for the singelton
 *  @warning it is prefered to init the singelton with a a delegate instead of using this method
 *  @param delegate an object conforming to RealTimeDelegate
 */
- (void)setRealTimeDelegate:(id <RealTimeDelegate>)delegate;

/**
 *  tells the tracker to connect to the real time update service asscosiated with the tracker
 */
- (void)connect;

/**
 *  tells the tracker to disconnect from the real time update service asscosiated with the tracker
 */
- (void)disconnect;


/**
 *  updates the tracker with a Customer object
 *  @warning Customer objects are obtained via performing sign in operations with the GGHTTPClientManager.h
 *  @param customer the Customer object representing the logged in customer
 */
- (void)setCustomer:(GGCustomer *)customer;



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
 *  tell if a specific order is being watched
 *
 *  @param uuid uuid of order in question
 *
 *  @return BOOL
 */
- (BOOL)isWatchingOrderWithUUID:(NSString *)uuid;

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
- (BOOL)isWatchingDriverWithUUID:(NSString *)uuid;

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
- (BOOL)isWatchingWaypointWithWaypointId:(NSNumber *)waypointId;


// track actions
/**
 *  asks the real time service to start tracking a specific order
 *
 *  @param uuid     uuid of order
 *  @param delegate object to recieve order callbacks
 *  @see OrderDelegate
 */
- (void)startWatchingOrderWithUUID:(NSString *)uuid
                          delegate:(id <OrderDelegate>)delegate;

/**
 *  asks the real time service to start tracking a specific driver
 *
 *  @param uuid      uuid of driver
 *  @param shareUUID uuid of shared location object associated with a specific order
 *  @param delegate  object to recieve driver callbacks
 *  @see DriverDelegate
 */
- (void)startWatchingDriverWithUUID:(NSString *)uuid
                          shareUUID:(NSString *)shareUUID
                           delegate:(id <DriverDelegate>)delegate;

/**
 *  asks the real time service to start tracking a specific waypoint
 *
 *  @param waypointId id of waypoint
 *  @param delegate   object to recieve waypoint callbacks
 *  @see WaypointDelegate
 */
- (void)startWatchingWaypointWithWaypointId:(NSNumber *)waypointId
                                   delegate:(id <WaypointDelegate>)delegate;


/**
 *  stops tracking a specific order
 *
 *  @param uuid uuid of order
 */
- (void)stopWatchingOrderWithUUID:(NSString *)uuid;

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
- (void)stopWatchingDriverWithUUID:(NSString *)uuid
                         shareUUID:(NSString *)shareUUID;
/**
 *  stops watching all drivers
 */
- (void)stopWatchingAllDrivers;

/**
 *  stops tracking a specific waypoint
 *
 *  @param waypointId id of waypoint
 */
- (void)stopWatchingWaypointWithWaypointId:(NSNumber *)waypointId;

/**
 *  stops tracking all waypoints
 */
- (void)stopWatchingAllWaypoints;
@end
