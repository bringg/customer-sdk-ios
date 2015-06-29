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

@interface GGRealTimeMontior ()

@property (nonatomic, strong) NSString *developerToken;

@property (nonatomic, strong) NSMutableDictionary *orderDelegates;
@property (nonatomic, strong) NSMutableDictionary *driverDelegates;
@property (nonatomic, strong) NSMutableDictionary *waypointDelegates;
@property (nonatomic, strong) NSMutableDictionary *activeDrivers;


@property (nonatomic, assign) BOOL doMonitoringOrders;
@property (nonatomic, assign) BOOL doMonitoringDrivers;
@property (nonatomic, assign) BOOL doMonitoringWaypoints;
@property (nonatomic, assign) BOOL connected;

+ (id)sharedInstance;

- (void)setRealTimeConnectionDelegate:(id<RealTimeDelegate>) connectionDelegate;


- (void)setDeveloperToken:(NSString *)developerToken;

- (void)connect;
- (void)disconnect;


-(void)sendConnectionError:(NSError *)error;


- (void)sendWatchOrderWithOrderUUID:(NSString *)uuid completionHandler:(void (^)(BOOL success, NSError *error))completionHandler ;

- (void)sendWatchDriverWithDriverUUID:(NSString *)uuid shareUUID:(NSString *)shareUUID completionHandler:(void (^)(BOOL success, NSError *error))completionHandler;

- (void)sendWatchWaypointWithWaypointId:(NSNumber *)waypointId completionHandler:(void (^)(BOOL success, NSError *error))completionHandler ;

@end
