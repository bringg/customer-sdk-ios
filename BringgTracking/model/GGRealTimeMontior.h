//
//  GGRealTimeManager.h
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Ilya Kalinin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GGTrackerManager.h"
#import "BringgGlobals.h"
#import "SocketIO.h"

#define BTRealtimeServer @"realtime-api.bringg.com"



@interface GGRealTimeMontior : NSObject<SocketIODelegate>


+ (id)sharedInstance;

- (void)setRealTimeConnectionDelegate:(id<RealTimeDelegate>) connectionDelegate;


- (void)setDeveloperToken:(NSString *)developerToken;

- (void)connect;
- (void)disconnect;

- (void)sendEventWithName:(NSString *)name params:(NSDictionary *)params completionHandler:(void (^)(BOOL success, NSError *error))completionHandler;

- (BOOL)isConnected;

// status checks
- (BOOL)isWatchingOrders;
- (BOOL)isWatchingOrderWithUUID:(NSString *)uuid;


- (BOOL)isWatchingDrivers;
- (BOOL)isWatchingDriverWithUUID:(NSString *)uuid;


- (BOOL)isWatchingWaypoints;
- (BOOL)isWatchingWaypointWithWaypointId:(NSNumber *)waypointId;

// watch requests
- (void)startWatchingOrderWithUUID:(NSString *)uuid
                          delegate:(id <OrderDelegate>)delegate;

- (void)startWatchingDriverWithUUID:(NSString *)uuid
                          shareUUID:(NSString *)shareUUID
                           delegate:(id <DriverDelegate>)delegate;

- (void)startWatchingWaypointWithWaypointId:(NSNumber *)waypointId
                                   delegate:(id <WaypointDelegate>)delegate;


- (void)stopWatchingOrderWithUUID:(NSString *)uuid;

- (void)stopWatchingDriverWithUUID:(NSString *)uuid
                         shareUUID:(NSString *)shareUUID;

- (void)stopWatchingWaypointWithWaypointId:(NSNumber *)waypointId;


@end
