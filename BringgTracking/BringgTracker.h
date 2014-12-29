//
//  BringgTracker.h
//  BringgTrackingService
//
//  Created by Ilya Kalinin on 12/16/14.
//  Copyright (c) 2014 Ilya Kalinin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SocketIO.h"

@protocol RealTimeDelegate <NSObject>
- (void)trackerDidConnected;
- (void)trackerDidDisconnectedWithError:(NSError *)error;

@end

@protocol OrderDelegate <NSObject>
- (void)orderMonitoringFailedForOrederWithUUID:(NSString *)uuid error:(NSError *)error;
- (void)orderDidAssignedWithOrderUUID:(NSString *)uuid driverUUID:(NSString *)driverUUID;
@optional
- (void)orderDidAcceptedOrderUUID:(NSString *)uuid;
- (void)orderDidStartedOrderUUID:(NSString *)uuid;
- (void)orderDidArrivedOrderUUID:(NSString *)uuid;
- (void)orderDidFinishedOrderUUID:(NSString *)uuid;
- (void)orderDidCancelledOrderUUID:(NSString *)uuid;

@end

@protocol DriverDelegate <NSObject>
- (void)driverMonitoringFailedForDriverWithUUID:(NSString *)uuid error:(NSError *)error;
@optional
- (void)driverLocationDidChangedWithDriverUUID:(NSString *)driverUUID lat:(NSNumber *)lat lng:(NSNumber *)lng;

@end

@interface BringgTracker : NSObject <SocketIODelegate>

+ (id)sharedInstance;

- (void)setConnectionDelegate:(id <RealTimeDelegate>)delegate;

- (BOOL)isConnected;
- (void)connect;
- (void)disconnect;

- (BOOL)isMonitoringOrders;
- (BOOL)isMonitoringOrderWithUUID:(NSString *)uuid;
- (void)startMonitorOrederWithUUID:(NSString *)uuid shareUUID:(NSString *)shareUUID delegate:(id <OrderDelegate>)delegate;
- (void)stopMonitorOrderWithUUID:(NSString *)uuid shareUUID:(NSString *)shareUUID;

- (BOOL)isMonitoringDrivers;
- (BOOL)isMonitoringDriverWithUUID:(NSString *)uuid;
- (void)startMonitorDriverWithUUID:(NSString *)uuid shareUUID:(NSString *)shareUUID delegate:(id <DriverDelegate>)delegate;
- (void)stopMonitorDriverWithUUID:(NSString *)uuid shareUUID:(NSString *)shareUUID;

@end
