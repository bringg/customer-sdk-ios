//
//  GGRealTimeMontior+Private.h
//  BringgTracking
//
//  Created by Matan on 6/29/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import "GGRealTimeMontior.h"
#import <BringgTracking/BringgGlobals.h>
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



@property (nonnull, nonatomic, strong) NSString *developerToken;

@property (nonnull, nonatomic, strong) NSMutableDictionary<NSString *, id<OrderDelegate>>  *orderDelegates;
@property (nonnull, nonatomic, strong) NSMutableDictionary<NSString *, id<DriverDelegate>>  *driverDelegates;
@property (nonnull, nonatomic, strong) NSMutableDictionary<NSString *, id<WaypointDelegate>> *waypointDelegates;
@property (nonnull, nonatomic, strong) NSMutableDictionary<NSString *, GGDriver*>  *activeDrivers; // uuid for driver
@property (nonnull, nonatomic, strong) NSMutableDictionary<NSString *, GGOrder*> *activeOrders; // uuid for order

@property (nonatomic, assign) BOOL doMonitoringOrders;
@property (nonatomic, assign) BOOL doMonitoringDrivers;
@property (nonatomic, assign) BOOL doMonitoringWaypoints;
@property (nonatomic, assign) BOOL connected;
@property (nonatomic, assign) BOOL useSSL;
@property (nonatomic, assign) BOOL wasManuallyConnected;

@property (nonnull, nonatomic,strong) SocketIOClient *socketIO;
@property (nullable, nonatomic, copy) CompletionBlock socketIOConnectedBlock;
@property (nonatomic, weak) id<RealTimeDelegate> realtimeDelegate;
@property (nonatomic, weak) id<GGRealTimeMonitorConnectionDelegate> realtimeConnectionDelegate;



+ (nonnull id)sharedInstance;

- (void)setRealTimeConnectionDelegate:(nullable id<RealTimeDelegate>) connectionDelegate;


- (void)setDeveloperToken:(nonnull NSString *)developerToken;

- (void)connect;
- (void)disconnect;

- (void)sendConnectionError:(nonnull NSError *)error;



- (void)sendWatchOrderWithOrderUUID:(nonnull NSString *)uuid
              accessControlParamKey:(nonnull NSString *)accessControlParamKey
            accessControlParamValue:(nonnull NSString *)accessControlParamValue
                  completionHandler:(nullable SocketResponseBlock)completionHandler;

- (void)sendWatchDriverWithDriverUUID:(nonnull NSString *)uuid
                accessControlParamKey:(nonnull NSString *)accessControlParamKey
              accessControlParamValue:(nonnull NSString *)accessControlParamValue
                    completionHandler:(nullable SocketResponseBlock)completionHandler;

- (void)sendWatchWaypointWithWaypointId:(nonnull NSNumber *)waypointId
                           andOrderUUID:(nonnull NSString *)orderUUID
                      completionHandler:(nullable SocketResponseBlock)completionHandler;

- (BOOL)handleSocketIODidReceiveEvent:(nonnull NSString *)eventName
                             withData:(nonnull NSDictionary *)eventData;

- (nullable id<WaypointDelegate>)delegateForWaypointID:(nonnull NSNumber *)waypointId;

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
