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

#define DRIVER_COMPOUND_SEPERATOR @"|"
#define WAYPOINT_COMPOUND_SEPERATOR @"^"
#define POLLING_SEC 30


@interface GGTrackerManager()

@property (nonatomic, getter=isSecuredConnection) BOOL  useSSL;
@property (nonatomic, assign) BOOL shouldReconnect;

@property (nonatomic, strong) NSString * _Nullable customerToken;
@property (nonatomic, strong) NSString * _Nullable developerToken;

@property (nonatomic, strong) NSMutableSet * _Nonnull polledOrders;
@property (nonatomic, strong) NSMutableSet * _Nonnull polledLocations;
@property (nonatomic, strong) NSTimer * _Nullable orderPollingTimer;
@property (nonatomic, strong) NSTimer * _Nullable locationPollingTimer;
@property (nonatomic, weak) id<RealTimeDelegate> trackerRealtimeDelegate;
@property (nonatomic, weak) GGHTTPClientManager *httpManager;

- (void)parseDriverCompoundKey:(NSString * _Nonnull)key toDriverUUID:(NSString *_Nonnull*_Nonnull)driverUUID andSharedUUID:(NSString *_Nonnull*_Nonnull)sharedUUID;
- (void)parseWaypointCompoundKey:(NSString * _Nonnull)key toOrderUUID:(NSString *_Nonnull*_Nonnull)orderUUID andWaypointId:(NSString *_Nonnull*_Nonnull)waypointId;


- (void)orderPolling:(NSTimer *_Nonnull)timer;
- (void)locationPolling:(NSTimer *_Nonnull)timer;


- (void)notifyRESTUpdateForOrder:(NSString * _Nonnull)orderUUID;
- (void)notifyRESTUpdateForDriver:(NSString *_Nonnull)driverUUID andSharedUUID:(NSString *_Nonnull)shareUUID;

- (void)disconnectFromRealTimeUpdates;
- (void)restartLiveMonitor;

- (void)configurePollingTimers;
- (void)resetPollingTimers;
- (void)stopPolling;

- (void)reviveWatchedOrders;
- (void)reviveWatchedDrivers;
- (void)reviveWatchedWaypoints;

- (void)startOrderPolling;
- (void)startLocationPolling;

- (BOOL)canPollForOrders;
- (BOOL)canPollForLocations;


@end