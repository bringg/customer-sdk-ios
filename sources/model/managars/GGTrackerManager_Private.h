//
//  GGTrackerManager_Private.h
//  BringgTracking
//
//  Created by Matan on 01/11/2015.
//  Copyright © 2015 Matan Poreh. All rights reserved.
//

#import "GGTrackerManager.h"
#import "BringgGlobals.h"
#import "GGRealTimeMontior+Private.h"
#import "GGHTTPClientManager_Private.h"
#import "BringgPrivates.h"


#define MAX_CONNECTION_RETRIES 5

@interface GGTrackerManager()

@property (nonatomic, getter=isSecuredConnection) BOOL  useSSL;
@property (nonatomic, assign) BOOL shouldReconnect;

@property (nonatomic, strong) NSString * _Nullable customerToken;

@property (nonatomic, strong) NSMutableSet * _Nonnull polledOrders;
@property (nonatomic, strong) NSMutableSet * _Nonnull polledLocations;
@property (nonatomic, strong) NSTimer * _Nullable orderPollingTimer;
@property (nonatomic, strong) NSTimer * _Nullable locationPollingTimer;
@property (nonatomic, strong) NSTimer * _Nullable eventPollingTimer;


@property (nullable, nonatomic, weak) id<RealTimeDelegate> trackerRealtimeDelegate;
@property (nullable, nonatomic, weak) id<PrivateClientConnectionDelegate> connectionDelegate;

@property (nullable, nonatomic, weak) GGHTTPClientManager *httpManager;

@property (nonatomic, assign) NSUInteger numConnectionAttempts;


/**
 *  uses REST api to start watching an order
 *
 *  @param orderUUID         uuid of order
 *  @param completionHandler handle response callback
 */
- (void)startRESTWatchingOrderByOrderUUID:(NSString * _Nonnull)orderUUID
                                shareUUID:(NSString * _Nullable)shareUUID
                    withCompletionHandler:(nullable GGOrderResponseHandler)completionHandler;

/**
 *  gets an initial data of watched order
 *
 *  @usage                  use to get order when no shared uuid exists
 *  @param shareUUID         share uuid
 *  @param completionHandler handle response callback
 */
-(void)getWatchedOrderByShareUUID:(NSString * _Nonnull)shareUUID
                        orderUUID:(NSString * _Nonnull)orderUUID
            withCompletionHandler:(nullable GGOrderResponseHandler)completionHandler;




/**
 *  the timer event handler to check if too much time passed between realtime events
 *
 *  @param timer the timer
 */
- (void)eventPolling:(NSTimer *_Nonnull)timer;

/**
 *  the timer event handler for order polling
 *
 *  @param timer the timer
 */
- (void)orderPolling:(NSTimer *_Nonnull)timer;

/**
 *  the timer event handler for location polling
 *
 *  @param timer the timer
 */
- (void)locationPolling:(NSTimer *_Nonnull)timer;


/**
 *  tries to poll information for a specific order
 *
 *  @param activeOrder the order to poll data for
 */
- (void)pollForOrder:(nonnull GGOrder * )activeOrder;


/**
 *  tries to poll location for a specific order
 *
 *  @param activeOrder the order to poll data for
 */
- (void)pollForLocation:(nonnull GGOrder *)activeOrder;

/**
 *  due to REST polling notify order delegates that an order has updated
 *
 *  @param orderUUID uuid of updated order
 */
- (void)notifyRESTUpdateForOrderWithUUID:(NSString * _Nonnull)orderUUID;
/**
 *  due to REST polling notify driver delegates that a driver location has updated
 *
 *  @param driverUUID uuid of updated driver
 *  @param shareUUID  shared uuid of updated related location
 */
- (void)notifyRESTUpdateForDriverWithUUID:(NSString *_Nonnull)driverUUID andSharedUUID:(NSString *_Nonnull)shareUUID;


/**
 *  notifies a change in the find me configuration for a specific order
 *
 *  @param orderUUID uuid of order
 */
- (void)notifyRESTFindMeUpdatedForOrderWithUUID:(NSString * _Nonnull)orderUUID;


/**
 *  disconnectes the real time
 */
- (void)disconnectFromRealTimeUpdates;


/**
 *  restarts the real time socket connection and also reviceves all watched objects
 */
- (void)restartLiveMonitor;

/**
 *  configures all polling timers
 */
- (void)configurePollingTimers;


/**
 *  restart all polling timers
 */
- (void)resetPollingTimers;

/**
 *  stops any polling actions
 */
- (void)stopPolling;


/**
 *  tries tp revive any previously watched orders
 */
- (void)reviveWatchedOrders;

/**
 *  tries tp revive any previously watched drivers
 */
- (void)reviveWatchedDrivers;


/**
 *  tries tp revive any previously watched waypoints
 */
- (void)reviveWatchedWaypoints;

/**
 *  startes order polling
 */
- (void)startOrderPolling;

/**
 *  starts location polling
 */
- (void)startLocationPolling;


/**
 *  check if tracker can/allowed to poll for orders
 *
 *  @return BOOL
 */
- (BOOL)canPollForOrders;

/**
 *  check if tracker can/allowed to poll for locations
 *
 *  @return BOOL
 */
- (BOOL)canPollForLocations;





@end
