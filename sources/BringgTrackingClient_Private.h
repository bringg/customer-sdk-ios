//
//  BringgTrackingClient_Private.h
//  BringgTracking
//
//  Created by Matan on 27/03/2017.
//  Copyright © 2017 Bringg. All rights reserved.
//

#import "BringgTrackingClient.h"
#import "BringgGlobals.h"

@class GGHTTPClientManager, GGTrackerManager, GGSDKExceptionHandler;

@interface BringgTrackingClient()

@property (nonnull, nonatomic, strong) NSString *developerToken;
@property (nonnull, nonatomic, strong) GGTrackerManager *trackerManager;
@property (nonnull, nonatomic, strong) GGHTTPClientManager *httpManager;
@property (nonnull, nonatomic, strong) GGSDKExceptionHandler *exceptionHandler;
@property (nullable, nonatomic, weak) id<RealTimeDelegate> realTimeDelegate;

@property (nonatomic) BOOL useSecuredConnection;
@property (nonatomic) BOOL shouldAutoWatchDriver;
@property (nonatomic) BOOL shouldAutoWatchOrder;


- (nonnull instancetype)initWithDevToken:(nonnull NSString *)devToken connectionDelegate:(nonnull id<RealTimeDelegate>)delegate;

- (void)setupHTTPManagerWithDevToken:(nonnull NSString *)devToken securedConnection:(BOOL)useSecuredConnection;

- (void)setupTrackerManagerWithDevToken:(nonnull NSString *)devToken httpManager:(nonnull GGHTTPClientManager *)httpManager realtimeDelegate:(nonnull id<RealTimeDelegate>)delegate;

- (void)setupFrameworkExceptionHandler;

- (nonnull NSArray<NSString *> *)cachedExceptions;

- (void)checkAndReportPreviousCrashes;

@end
