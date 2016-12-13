//
//  GGRealTimeMontior+Private.h
//  BringgTracking
//
//  Created by Matan on 6/29/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import "GGRealTimeMontior.h"
#import "BringgGlobals.h"
#import "GGTrackerManager.h"
#import "Reachability.h"

@import SocketIO;

#define MAX_WITHOUT_REALTIME_SEC 240

#define EVENT_ORDER_UPDATE @"order update"
#define EVENT_ORDER_DONE @"order done"

#define EVENT_DRIVER_LOCATION_CHANGED @"location update"
#define EVENT_DRIVER_ACTIVITY_CHANGED @"activity change"

#define EVENT_WAY_POINT_ARRIVED @"way point arrived"
#define EVENT_WAY_POINT_DONE @"way point done"
#define EVENT_WAY_POINT_ETA_UPDATE @"way point eta updated"
#define EVENT_WAY_POINT_LOCATION @"way point location updated"

@class GGOrder, GGDriver, GGWaypoint;


@interface GGRealTimeMontior ()



@property (nonatomic, strong) NSString *developerToken;

@property (nonatomic, strong) NSMutableDictionary<NSString *, id<OrderDelegate>>  *orderDelegates;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<DriverDelegate>>  *driverDelegates;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<WaypointDelegate>> *waypointDelegates;
@property (nonatomic, strong) NSMutableDictionary<NSString *, GGDriver*>  *activeDrivers; // uuid for driver
@property (nonatomic, strong) NSMutableDictionary<NSString *, GGOrder*> *activeOrders; // uuid for order

@property (nonatomic, assign) BOOL doMonitoringOrders;
@property (nonatomic, assign) BOOL doMonitoringDrivers;
@property (nonatomic, assign) BOOL doMonitoringWaypoints;
@property (nonatomic, assign) BOOL connected;
@property (nonatomic, assign) BOOL useSSL;
@property (nonatomic, assign) BOOL wasManuallyConnected;

@property (nonatomic,strong) SocketIOClient *socketIO;
@property (nonatomic, copy) CompletionBlock socketIOConnectedBlock;
@property (nonatomic, weak) id<RealTimeDelegate> realtimeDelegate;
@property (nonatomic, weak) id<GGRealTimeMonitorConnectionDelegate> realtimeConnectionDelegate;



+ (id)sharedInstance;

- (void)setRealTimeConnectionDelegate:(id<RealTimeDelegate>) connectionDelegate;


- (void)setDeveloperToken:(NSString *)developerToken;

- (void)connect;
- (void)disconnect;

- (void)sendConnectionError:(NSError *)error;


- (void)sendWatchOrderWithOrderUUID:(NSString *)uuid completionHandler:(SocketResponseBlock)completionHandler ;

- (void)sendWatchOrderWithOrderUUID:(NSString *)uuid shareUUID:(NSString *)shareUUID completionHandler:(SocketResponseBlock)completionHandler;

- (void)sendWatchDriverWithDriverUUID:(NSString *)uuid shareUUID:(NSString *)shareUUID completionHandler:(SocketResponseBlock)completionHandler;

- (void)sendWatchWaypointWithWaypointId:(NSNumber *)waypointId andOrderUUID:(NSString *)orderUUID completionHandler:(SocketResponseBlock)completionHandler ;

- (BOOL)handleSocketIODidReceiveEvent:(NSString *)eventName withData:(NSDictionary *)eventData;

- (id<WaypointDelegate>)delegateForWaypointID:(NSNumber *)waypointId;

/**
 *  check if it has been too long since a socket event
 *
 *  @usage if no live monitor exists this will always return NO
 *  @return BOOL
 */
- (BOOL)isWaitingTooLongForSocketEvent;


/**
 *  checks if connection is active and that there has been a recent event
 *
 *  @return BOOL
 */
- (BOOL)isWorkingConnection;

@end
