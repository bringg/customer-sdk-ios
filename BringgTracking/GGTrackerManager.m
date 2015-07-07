//
//  BringgTracker.m
//  BringgTracking
//
//  Created by Matan Poreh on 12/16/14.
//  Copyright (c) 2014 Matan Poreh. All rights reserved.
//

#import "GGTrackerManager.h"
#import "GGHTTPClientManager.h"
#import "GGHTTPClientManager_Private.h"

#import "GGRealTimeMontior+Private.h"
#import "GGRealTimeMontior.h"


#import "GGCustomer.h"
#import "GGSharedLocation.h"
#import "GGDriver.h"
#import "GGOrder.h"
#import "GGRating.h"

#import "BringgGlobals.h"


#define BTPhoneKey @"phone"
#define BTConfirmationCodeKey @"confirmation_code"
#define BTMerchantIdKey @"merchant_id"
#define BTDeveloperTokenKey @"developer_access_token"
#define BTCustomerTokenKey @"access_token"
#define BTCustomerPhoneKey @"phone"
#define BTTokenKey @"token"
#define BTRatingKey @"rating"


@interface GGTrackerManager ()



@property (nonatomic, strong) NSString *customerToken;
@property (nonatomic, strong) NSString *developerToken;
@property (nonatomic, strong) NSMutableArray *orders;
@property (nonatomic, strong) NSMutableArray *locations;

@property (nonatomic, strong) NSTimer *orderPollingTimer;
@property (nonatomic, strong) NSTimer *driverPollingTimer;

 
- (void)startOrderPolling;
- (void)stopOrderPolling;
- (void)startDriverPolling;
- (void)stopDriverPolling;

- (void)orderPolling:(NSTimer *)timer;
- (void)driverPolling:(NSTimer *)timer;

@end

@implementation GGTrackerManager

@synthesize liveMonitor = _liveMonitor;
@synthesize appCustomer = _appCustomer;




+ (id)tracker{
    
    return [self trackerWithCustomerToken:nil andDeveloperToken:nil andDelegate:nil];
    
}

+ (id)trackerWithCustomerToken:(NSString *)customerToken andDeveloperToken:(NSString *)devToken andDelegate:(id <RealTimeDelegate>)delegate{
 
    static GGTrackerManager *sharedObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // init the tracker
        sharedObject = [[self alloc] initTacker];
        
        // init the real time monitor
         sharedObject->_liveMonitor = [GGRealTimeMontior sharedInstance];
        
       
    });
    
    // set the customer token and developer token
    [sharedObject setCustomerToken:customerToken];
    [sharedObject setDeveloperToken:devToken];
    
    // set the connection delegate
    [sharedObject setRealTimeDelegate:delegate];
    
    return sharedObject;
}


-(id)initTacker{
    if (self = [super init]) {
        // do nothing
    }
    
    return self;
}



-(id)init{
    
    // we want to prevent the developer from using normal intializers
    // the tracker class should only be used as a singelton
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the class GGTrackerManager. Please use class method initializer"
                                 userInfo:nil];
    
    return self;
}

- (void)connect{
    
    // if no dev token we should raise an exception
    
    if  (!self.developerToken) {
        
        [NSException raise:@"Invalid tracker Tokens" format:@"Developer Token can not be nil"];
        
    }else{
        
        // update the real time monitor with the dev token
        [self.liveMonitor setDeveloperToken:self.developerToken];
        [self.liveMonitor connect];
        
        
    }
}

- (void)disconnect{
    [_liveMonitor disconnect];
}

- (void)dealloc {
    
}



#pragma mark - Setters

- (void)setRealTimeDelegate:(id <RealTimeDelegate>)delegate {
    [self.liveMonitor setRealTimeConnectionDelegate:delegate];
    
}

- (void)setCustomer:(GGCustomer *)customer{
    _appCustomer = customer;
    _customerToken = customer ? customer.customerToken : nil;
}

- (void)setDeveloperToken:(NSString *)devToken{
    _developerToken = devToken;
}


#pragma mark - Polling

- (void)startOrderPolling {
    self.orderPollingTimer = [NSTimer scheduledTimerWithTimeInterval:20.0
                                                              target:self
                                                            selector:@selector(orderPolling:)
                                                            userInfo:nil
                                                             repeats:YES];
    
}

- (void)stopOrderPolling {
    [self.orderPollingTimer invalidate];
    self.orderPollingTimer = nil;
    
}

- (void)startDriverPolling {
    self.driverPollingTimer = [NSTimer scheduledTimerWithTimeInterval:20.0
                                                              target:self
                                                             selector:@selector(driverPolling:)
                                                            userInfo:nil
                                                             repeats:YES];
    
}

- (void)stopDriverPolling{
    [self.driverPollingTimer invalidate];
    self.driverPollingTimer = nil;
    
}



- (void)driverPolling:(NSTimer *)timer {
#warning TODO add driver polling functionality
}


- (void)orderPolling:(NSTimer *)timer{
    #warning TODO add order polling functionality
}

#pragma mark - Track Actions
- (void)startWatchingOrderWithUUID:(NSString *)uuid delegate:(id <OrderDelegate>)delegate {
    
    if (uuid) {
        _liveMonitor.doMonitoringOrders = YES;
        id existingDelegate = [_liveMonitor.orderDelegates objectForKey:uuid];
        
        GGOrder *order = [[GGOrder alloc] initOrderWithUUID:uuid atStatus:OrderStatusCreated];
        
        if (!existingDelegate) {
            @synchronized(self) {
                [_liveMonitor.orderDelegates setObject:delegate forKey:uuid];
                
            }
            [_liveMonitor sendWatchOrderWithOrderUUID:uuid completionHandler:^(BOOL success, NSError *error) {
                if (!success) {
                    id delegateToRemove = [_liveMonitor.orderDelegates objectForKey:uuid];
                    @synchronized(_liveMonitor) {
                        [_liveMonitor.orderDelegates removeObjectForKey:uuid];
                        
                    }
                    [delegateToRemove watchOrderFailForOrder:order error:error];
                    if (![_liveMonitor.orderDelegates count]) {
                        _liveMonitor.doMonitoringOrders = NO;
                        
                    }
                }
            }];
        }
    }else{
        [NSException raise:@"Invalid UUID" format:@"Driver UUID can not be nil"];
    }
}



- (void)startWatchingDriverWithUUID:(NSString *)uuid shareUUID:(NSString *)shareUUID delegate:(id <DriverDelegate>)delegate {
    
    if (uuid && shareUUID) {
        _liveMonitor.doMonitoringDrivers = YES;
        
        GGDriver *driver = [[GGDriver alloc] initWithUUID:uuid];
        
        id existingDelegate = [_liveMonitor.driverDelegates objectForKey:uuid];
        if (!existingDelegate) {
            @synchronized(self) {
                [_liveMonitor.driverDelegates setObject:delegate forKey:uuid];
                
            }
            [_liveMonitor sendWatchDriverWithDriverUUID:uuid shareUUID:(NSString *)shareUUID completionHandler:^(BOOL success, NSError *error) {
                if (!success) {
                    id delegateToRemove = [_liveMonitor.driverDelegates objectForKey:uuid];
                    @synchronized(_liveMonitor) {
                        [_liveMonitor.driverDelegates removeObjectForKey:uuid];
                        
                    }
                    [delegateToRemove watchDriverFailedForDriver:driver error:error];
                    if (![_liveMonitor.driverDelegates count]) {
                        _liveMonitor.doMonitoringDrivers = NO;
                        
                    }
                }
            }];
        }
    }else{
        
        [NSException raise:@"Invalid UUIDs" format:@"Driver and Share UUIDs can not be nil"];
    }
    
}

- (void)startWatchingWaypointWithWaypointId:(NSNumber *)waypointId delegate:(id <WaypointDelegate>)delegate {
    
    if (waypointId) {
        _liveMonitor.doMonitoringWaypoints = YES;
        id existingDelegate = [_liveMonitor.waypointDelegates objectForKey:waypointId];
        if (!existingDelegate) {
            @synchronized(self) {
                [_liveMonitor.waypointDelegates setObject:delegate forKey:waypointId];
                
            }
            [_liveMonitor sendWatchWaypointWithWaypointId:waypointId completionHandler:^(BOOL success, NSError *error) {
                if (!success) {
                    id delegateToRemove = [_liveMonitor.waypointDelegates objectForKey:waypointId];
                    @synchronized(_liveMonitor) {
                        [_liveMonitor.waypointDelegates removeObjectForKey:waypointId];
                        
                    }
                    [delegateToRemove watchWaypointFailedForWaypointId:waypointId error:error];
                    if (![_liveMonitor.waypointDelegates count]) {
                        _liveMonitor.doMonitoringWaypoints = NO;
                        
                    }
                }
            }];
        }
    }else{
        [NSException raise:@"Invalid waypoint ID" format:@"Waypoint ID can not be nil"];
    }
    
    
}

- (void)stopWatchingOrderWithUUID:(NSString *)uuid {
    id existingDelegate = [_liveMonitor.orderDelegates objectForKey:uuid];
    if (existingDelegate) {
        @synchronized(_liveMonitor) {
            [_liveMonitor.orderDelegates removeObjectForKey:uuid];
            
        }
    }
}

- (void)stopWatchingAllOrders{
    @synchronized(_liveMonitor) {
        [_liveMonitor.orderDelegates removeAllObjects];
        
    }
}

- (void)stopWatchingDriverWithUUID:(NSString *)uuid shareUUID:(NSString *)shareUUID {
    id existingDelegate = [_liveMonitor.driverDelegates objectForKey:uuid];
    if (existingDelegate) {
        @synchronized(_liveMonitor) {
            [_liveMonitor.driverDelegates removeObjectForKey:uuid];
            
        }
    }
}

- (void)stopWatchingAllDrivers{
    @synchronized(_liveMonitor) {
        [_liveMonitor.driverDelegates removeAllObjects];
        
    }
}

- (void)stopWatchingWaypointWithWaypointId:(NSNumber *)waypointId {
    id existingDelegate = [_liveMonitor.waypointDelegates objectForKey:waypointId];
    if (existingDelegate) {
        @synchronized(_liveMonitor) {
            [_liveMonitor.waypointDelegates removeObjectForKey:waypointId];
            
        }
    }
}

- (void)stopWatchingAllWaypoints{
    @synchronized(_liveMonitor) {
        [_liveMonitor.waypointDelegates removeAllObjects];
        
    }
}

#pragma mark Real Time status checks

- (BOOL)isConnected {
    return _liveMonitor.connected;
    
}

- (BOOL)isWatchingOrders {
    return _liveMonitor.doMonitoringOrders;
    
}

- (BOOL)isWatchingOrderWithUUID:(NSString *)uuid {
    return ([_liveMonitor.orderDelegates objectForKey:uuid]) ? YES : NO;
    
}

- (BOOL)isWatchingDrivers {
    return _liveMonitor.doMonitoringDrivers;
    
}

- (BOOL)isWatchingDriverWithUUID:(NSString *)uuid {
    return ([_liveMonitor.driverDelegates objectForKey:uuid]) ? YES : NO;
    
}

- (BOOL)isWatchingWaypoints {
    return _liveMonitor.doMonitoringWaypoints;
    
}

- (BOOL)isWatchingWaypointWithWaypointId:(NSNumber *)waypointId {
    return ([_liveMonitor.waypointDelegates objectForKey:waypointId]) ? YES : NO;
    
}


@end
