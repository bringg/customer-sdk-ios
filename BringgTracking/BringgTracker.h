//
//  BringgTracker.h
//  BringgTrackingService
//
//  Created by Ilya Kalinin on 12/16/14.
//  Copyright (c) 2014 Ilya Kalinin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SocketIO.h"

@class BringgCustomer;

@protocol RealTimeDelegate <NSObject>
- (void)trackerDidConnected;
- (void)trackerDidDisconnectedWithError:(NSError *)error;

@end

@protocol OrderDelegate <NSObject>
- (void)watchOrderFailedForOrederWithUUID:(NSString *)uuid error:(NSError *)error;
- (void)orderDidAssignedWithOrderUUID:(NSString *)uuid driverUUID:(NSString *)driverUUID;
- (void)orderDidAcceptedOrderUUID:(NSString *)uuid driverUUID:(NSString *)driverUUID;
- (void)orderDidStartedOrderUUID:(NSString *)uuid driverUUID:(NSString *)driverUUID;
@optional
- (void)orderDidArrivedOrderUUID:(NSString *)uuid;
- (void)orderDidFinishedOrderUUID:(NSString *)uuid;
- (void)orderDidCancelledOrderUUID:(NSString *)uuid;

@end

@protocol DriverDelegate <NSObject>
- (void)watchDriverFailedForDriverWithUUID:(NSString *)uuid error:(NSError *)error;
@optional
- (void)driverLocationDidChangedWithDriverUUID:(NSString *)driverUUID lat:(NSNumber *)lat lng:(NSNumber *)lng;

@end

@protocol WaypointDelegate <NSObject>
- (void)watchWaypointFailedForWaypointId:(NSNumber *)waypointId error:(NSError *)error;
@optional
- (void)waypointDidUpdatedWaypointId:(NSNumber *)waypointId eta:(NSDate *)eta;
- (void)waypointDidArrivedWaypointId:(NSNumber *)waypointId;
- (void)waypointDidFinishedWaypointId:(NSNumber *)waypointId;

@end

@interface BringgTracker : NSObject <SocketIODelegate>

+ (id)sharedInstance;

- (void)setConnectionDelegate:(id <RealTimeDelegate>)delegate;
- (void)setCustomer:(BringgCustomer *)customer;

- (BOOL)isConnected;
- (void)connectWithCustomerToken:(NSString *)customerToken;
- (void)disconnect;

- (BOOL)isWatchingOrders;
- (BOOL)isWatchingOrderWithUUID:(NSString *)uuid;
- (void)startWatchingOrederWithUUID:(NSString *)uuid delegate:(id <OrderDelegate>)delegate;
- (void)stopWatchingOrderWithUUID:(NSString *)uuid;

- (BOOL)isWatchingDrivers;
- (BOOL)isWatchingDriverWithUUID:(NSString *)uuid;
- (void)startWatchingDriverWithUUID:(NSString *)uuid shareUUID:(NSString *)shareUUID delegate:(id <DriverDelegate>)delegate;
- (void)stopWatchingDriverWithUUID:(NSString *)uuid shareUUID:(NSString *)shareUUID;

- (BOOL)isWatchingWaypoints;
- (BOOL)isWatchingWaypointWithWaypointId:(NSNumber *)waypointId;
- (void)startWatchingWaypointWithWaypointId:(NSNumber *)waypointId delegate:(id <WaypointDelegate>)delegate;
- (void)stopWatchingWaypointWithWaypointId:(NSNumber *)waypointId;

- (void)rateWithRating:(NSUInteger)rating shareUUID:(NSString *)uuid completionHandler:(void (^)(BOOL success, NSError *error))completionHandler;

@end
