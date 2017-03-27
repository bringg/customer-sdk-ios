//
//  GGRealTimeManager.h
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>

#define BTRealtimeServer @"realtime2-api.bringg.com"

@class GGOrder;
@class GGDriver;
@class GGRealTimeMontior;
@class GGWaypoint;

@protocol GGRealTimeMonitorConnectionDelegate <NSObject>

-(NSString * __nonnull)hostDomainForRealTimeMonitor:(GGRealTimeMontior *__nonnull)realTimeMonitor;

@end

@interface GGRealTimeMontior : NSObject

@property (nullable, nonatomic, strong) NSDate *lastEventDate;
@property (nonatomic) BOOL logsEnabled;

-(void)useSecureConnection:(BOOL)shouldUse;

-(BOOL)hasNetwork;

- (nullable GGOrder *)addAndUpdateOrder:(GGOrder *_Nonnull)order;
- (nullable GGDriver *)addAndUpdateDriver:(GGDriver *_Nonnull)driver;
- (nullable GGOrder *)addAndUpdateWaypoint:(GGWaypoint *_Nonnull)waypoint;

-(GGOrder * _Nullable)getOrderWithUUID:(NSString * _Nonnull)uuid;
-(GGOrder * _Nullable)getOrderWithID:(NSNumber * _Nonnull)orderid;
-(GGDriver * _Nullable)getDriverWithUUID:(NSString * _Nonnull)uuid;
-(GGDriver * _Nullable)getDriverWithID:(NSNumber * _Nonnull)driverId;

- (nullable NSString *)getSharedUUIDforDriverUUID:(nonnull NSString *)uuid;

@end
