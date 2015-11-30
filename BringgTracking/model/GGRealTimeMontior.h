//
//  GGRealTimeManager.h
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocketIO.h"

#define BTRealtimeServer @"realtime-api.bringg.com"

@class GGOrder;
@class GGDriver;
@class GGRealTimeMontior;

@protocol GGRealTimeMonitorConnectionDelegate <NSObject>

-(NSString * __nonnull)hostDomainForRealTimeMonitor:(GGRealTimeMontior *__nonnull)realTimeMonitor;

@end

@interface GGRealTimeMontior : NSObject<SocketIODelegate>

@property (nullable, nonatomic, strong) NSDate *lastEventDate;

-(void)useSecureConnection:(BOOL)shouldUse;

-(BOOL)hasNetwork;

- (nullable GGOrder *)addAndUpdateOrder:(GGOrder *_Nonnull)order;
- (nullable GGDriver *)addAndUpdateDriver:(GGDriver *_Nonnull)driver;


-(GGOrder * _Nullable)getOrderWithUUID:(NSString * _Nonnull)uuid;
-(GGDriver * _Nullable)getDriverWithUUID:(NSString * _Nonnull)uuid;
-(GGDriver * _Nullable)getDriverWithID:(NSNumber * _Nonnull)driverId;
@end
