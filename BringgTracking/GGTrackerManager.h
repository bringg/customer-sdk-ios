//
//  BringgTracker.h
//  BringgTrackingService
//
//  Created by Ilya Kalinin on 12/16/14.
//  Copyright (c) 2014 Ilya Kalinin. All rights reserved.
//

#import <Foundation/Foundation.h>


@class GGRealTimeMontior;
@class GGClientAppManager;
@class GGSharedLocation;
@class GGOrder;
@class GGDriver;
@class GGRating;

@protocol RealTimeDelegate <NSObject>
- (void)trackerDidConnect;
- (void)trackerDidDisconnectWithError:(NSError *)error;

@end



@interface GGTrackerManager : NSObject

@property (nonatomic, readonly) GGRealTimeMontior * liveMonitor;

+ (id)sharedInstance;

- (void)setConnectionDelegate:(id <RealTimeDelegate>)delegate;
- (void)setCustomerManager:(GGClientAppManager *)customer;
- (void)connect;

- (void)connectWithCustomerToken:(NSString *)customerToken andDeveloperToken:(NSString *)devToken withCompletionHandler:(void (^)(BOOL success, GGRealTimeMontior __weak  *realTimeManager , NSError *error))completionHandler;




- (void)rateWithRating:(NSUInteger)rating shareUUID:(NSString *)uuid completionHandler:(void (^)(BOOL success, NSError *error))completionHandler;

@end
