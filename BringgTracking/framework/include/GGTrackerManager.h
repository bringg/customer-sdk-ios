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

+ (id)trackerWithCustomerToken:(NSString *)customerToken andDeveloperToken:(NSString *)devToken andDelegate:(id <RealTimeDelegate>)delegate;

- (void)connect;

- (void)setCustomer:(GGCustomer *)customer;



// status checks

- (BOOL)isConnected;

- (BOOL)isWatchingOrders;
- (BOOL)isWatchingOrderWithUUID:(NSString *)uuid;


- (BOOL)isWatchingDrivers;
- (BOOL)isWatchingDriverWithUUID:(NSString *)uuid;


- (BOOL)isWatchingWaypoints;
- (BOOL)isWatchingWaypointWithWaypointId:(NSNumber *)waypointId;

// track actions
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
