//
//  BringgTrackingClient_Private.h
//  BringgTracking
//
//  Created by Matan on 27/03/2017.
//  Copyright © 2017 Bringg. All rights reserved.
//

#import "BringgTrackingClient.h"
#import "BringgGlobals.h"

@class GGHTTPClientManager, GGTrackerManager;

@interface BringgTrackingClient()

@property (nonnull, nonatomic, strong) NSString *developerToken;
@property (nonnull, nonatomic, strong) GGTrackerManager *trackerManager;
@property (nonnull, nonatomic, strong) GGHTTPClientManager *httpManager;

@property (nullable, nonatomic, weak) id<RealTimeDelegate> realTimeDelegate;

@property (nonatomic) BOOL useSecuredConnection;
@property (nonatomic) BOOL shouldAutoWatchDriver;
@property (nonatomic) BOOL shouldAutoWatchOrder;


- (nonnull instancetype)initWithDevToken:(nonnull NSString *)devToken region:(GGRegion)region connectionDelegate:(nonnull id<RealTimeDelegate>)delegate;

- (void)setupHTTPManagerWithDevToken:(nonnull NSString *)devToken securedConnection:(BOOL)useSecuredConnection;

- (void)setupTrackerManagerWithDevToken:(nonnull NSString *)devToken httpManager:(nonnull GGHTTPClientManager *)httpManager realtimeDelegate:(nonnull id<RealTimeDelegate>)delegate;


@end
