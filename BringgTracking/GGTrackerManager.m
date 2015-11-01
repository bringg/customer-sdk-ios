//
//  BringgTracker.m
//  BringgTracking
//
//  Created by Matan Poreh on 12/16/14.
//  Copyright (c) 2014 Matan Poreh. All rights reserved.
//

#import "GGTrackerManager_Private.h"

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
        
        // init polled
        sharedObject->_polledOrders = [NSMutableSet set];
        sharedObject->_polledLocations = [NSMutableSet set];
        
        // setup http manager
        sharedObject->_httpManager = [GGHTTPClientManager manager];
        
       
    });
    
    // set the customer token and developer token
    if (customerToken) [sharedObject setCustomerToken:customerToken];
    if (devToken) [sharedObject setDeveloperToken:devToken];
    
    // set the connection delegate
    if (delegate) [sharedObject setRealTimeDelegate:delegate];
    
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

- (void)restartLiveMonitor{
    // for the live monitor itself set the tracker as the delegated
    [self.liveMonitor setRealTimeConnectionDelegate:self];
    if (![self isConnected]) {
        NSLog(@"******** RESTART TRACKER CONNECTION ********");
        
        [self connectUsingSecureConnection:self.useSSL];
    }else{
        NSLog(@">>>>> CAN'T RESTART CONNECTION - TRACKER IS ALREADY CONNECTED");
    }
    
}


- (void)connectUsingSecureConnection:(BOOL)useSecure{
    
    // if no dev token we should raise an exception
    
    if  (!_developerToken) {
        
        [NSException raise:@"Invalid tracker Tokens" format:@"Developer Token can not be nil"];
        
    }else{
        
        self.useSSL = useSecure;
        
        // update the real time monitor with the dev token
        [self.liveMonitor setDeveloperToken:_developerToken];
        [self.liveMonitor useSecureConnection:useSecure];
        [self.liveMonitor connect];
        
        
    }
}

- (void)disconnect{
    [_liveMonitor disconnect];
}

- (void)dealloc {
    
}

#pragma mark - Helpers

- (void)parseDriverCompoundKey:(NSString *)key toDriverUUID:(NSString *__autoreleasing  _Nonnull *)driverUUID andSharedUUID:(NSString *__autoreleasing  _Nonnull *)sharedUUID{
 
    NSArray *pair = [key componentsSeparatedByString:DRIVER_COMPOUND_SEPERATOR];

    @try {
        *driverUUID = [pair objectAtIndex:0];
        *sharedUUID = [pair   objectAtIndex:1];
    }
    @catch (NSException *exception) {
        //
        NSLog(@"cant parse driver comound key %@ - error:%@", key, exception);
    }

}

#pragma mark - Setters

- (void)setRealTimeDelegate:(id <RealTimeDelegate>)delegate {
    
    // set a delegate to keep tracker of the delegate that came outside the sdk
    self.trackerRealtimeDelegate = delegate;
    
    [self.liveMonitor setRealtimeDelegate:self];
    
}

- (void)setCustomer:(GGCustomer *)customer{
    _appCustomer = customer;
    _customerToken = customer ? customer.customerToken : nil;
}

- (void)setDeveloperToken:(NSString *)devToken{
    
    
    _developerToken = devToken;
    NSLog(@"Tracker Set with Dev Token %@", _developerToken);
}

#pragma mark - Getters
- (NSArray *)monitoredOrders{
    
    return _liveMonitor.orderDelegates.allKeys;
}
- (NSArray *)monitoredDrivers{
    
    return _liveMonitor.driverDelegates.allKeys;
    
}
- (NSArray *)monitoredWaypoints{
    return _liveMonitor.waypointDelegates.allKeys;
}


#pragma mark - Polling
- (void)configurePollingTimers{
    
    self.orderPollingTimer = [ NSTimer scheduledTimerWithTimeInterval:POLLING_SEC target:self selector:@selector(orderPolling:) userInfo:nil repeats:YES];
    
    self.locationPollingTimer = [ NSTimer scheduledTimerWithTimeInterval:POLLING_SEC target:self selector:@selector(locationPolling:) userInfo:nil repeats:YES];
}


- (void)resetPollingTimers {
    [self stopPolling];
    [self configurePollingTimers];
    
    if (self.orderPollingTimer && [self.orderPollingTimer isValid]) {
        [self.orderPollingTimer fire];
    }
    
    if (self.locationPollingTimer && [self.locationPollingTimer isValid]) {
        [self.locationPollingTimer fire];
    }
}

- (void)stopPolling{
    if (self.orderPollingTimer && [self.orderPollingTimer isValid]) {
        [self.orderPollingTimer invalidate];
    }
    
    if (self.locationPollingTimer && [self.locationPollingTimer isValid]) {
        [self.locationPollingTimer invalidate];
    }
}




- (void)locationPolling:(NSTimer *)timer {
    
    // polling is only available if signed in
    if (![self.httpManager isSignedIn]) {
        return;
    }
    
    [self.monitoredOrders enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //
        NSString *orderUUID = (NSString *)obj;
       
        __block GGOrder *activeOrder = [self.liveMonitor getOrderWithUUID:orderUUID];
       
        
        __weak __typeof(&*self)weakSelf = self;
        
        // if we have a shared location object for this order we can now poll
        if (activeOrder.sharedLocation) {
            
            // check that we arent already polling this
            if (![self.polledLocations containsObject:activeOrder.sharedLocationUUID]) {
                
                // mark as being polled
                [self.polledLocations addObject:activeOrder.sharedLocationUUID];
                
                // ask our REST to poll
                [[GGHTTPClientManager manager] getSharedLocationByUUID:activeOrder.sharedLocationUUID withCompletionHandler:^(BOOL success, GGSharedLocation *sharedLocation, NSError *error) {
                    //
                    
                    // removed from the polled list
                    [weakSelf.polledLocations removeObject:activeOrder.sharedLocationUUID];
                    
                    if (!error && sharedLocation != nil) {
                        //
                        activeOrder.sharedLocation = sharedLocation;
                    }
                    
                    if (sharedLocation.driver) {
                        [_liveMonitor addAndUpdateDriver:sharedLocation.driver];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            // notify all interested parties that there has been a status change in the order
                            [weakSelf notifyRESTUpdateForDriver:sharedLocation.driver.uuid andSharedUUID:sharedLocation.locationUUID];
                        });
                        
                    }
                    
                    
                }];
            }
        }

        
    }];
}


- (void)orderPolling:(NSTimer *)timer{
    
    // polling is only available if signed in
    if (![self.httpManager isSignedIn]) {
        return;
    }
    
    [self.monitoredOrders enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        __block NSString *orderUUID = (NSString *)obj;
        
        // check that we are not polling already
        if (![self.polledOrders containsObject:orderUUID]) {
            
            // we need order id to do this so skip polling until the first real time updated that gets us full order model
            __block GGOrder *activeOrder = [self.liveMonitor getOrderWithUUID:orderUUID];
            
            // check that we have an order id needed for polling
            if (activeOrder && activeOrder.orderid) {
                [self.polledOrders addObject:orderUUID];
                
                __weak __typeof(&*self)weakSelf = self;
                
                [[GGHTTPClientManager manager] getOrderByID:activeOrder.orderid withCompletionHandler:^(BOOL success, GGOrder *order, NSError *error) {
                    
                    // remove from polled orders
                    [weakSelf.polledOrders removeObject:orderUUID];
                    
                    
                    //
                    if (!error && order != nil) {
                        // check that is is the update we were waiting for
                        if ([order.uuid isEqualToString:activeOrder.uuid]) {

                            
                            BOOL hasStatusChanged = NO;
                            // check if there was a status change
                            if (order.status != activeOrder.status) {
                                hasStatusChanged = YES;
                            }
                            
                            // update the local model in the live monitor
                            [_liveMonitor addAndUpdateOrder:order];
                            
                            // check if we can also update the driver related to the order
                            if ([[order sharedLocation] driver]) {
                                [_liveMonitor addAndUpdateDriver:[[order sharedLocation] driver]];
                            }

                            if (hasStatusChanged) {
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    // notify all interested parties that there has been a status change in the order
                                    [weakSelf notifyRESTUpdateForOrder:order.uuid];
                                });
                                
                            }
                        }
                    }
                    
                }];
            }
            
            
            
        }
    }];
}

/**
 *  due to REST polling notify order delegates that an order has updated
 *
 *  @param orderUUID uuid of updated order
 */
- (void)notifyRESTUpdateForOrder:(NSString *)orderUUID{
    
    GGOrder *order = [self.liveMonitor getOrderWithUUID:orderUUID];
    GGDriver *driver = [self.liveMonitor getDriverWithUUID:order.driverUUID ? order.driverUUID : order.sharedLocation.driver.uuid];
    
    // update the order delegate
    id<OrderDelegate> delegate = [_liveMonitor.orderDelegates objectForKey:order.uuid];
    
    if (delegate) {
        
        
        switch (order.status) {
            case OrderStatusAccepted:
                [delegate orderDidAcceptWithOrder:order withDriver:driver];
                break;
            case OrderStatusAssigned:
                [delegate orderDidAssignWithOrder:order withDriver:driver];
                break;
            case OrderStatusOnTheWay:
                [delegate orderDidStartWithOrder:order withDriver:driver];
                break;
            case OrderStatusCheckedIn:
                [delegate orderDidArrive:order withDriver:driver];
                break;
            case OrderStatusDone:
                [delegate orderDidFinish:order withDriver:driver];
                break;
            case OrderStatusCancelled:
                [delegate orderDidCancel:order withDriver:driver];
                break;
    
            
            default:
                break;
        }
    }
}

/**
 *  due to REST polling notify driver delegates that a driver location has updated
 *
 *  @param driverUUID uuid of updated driver
 *  @param shareUUID  shared uuid of updated related location
 */
- (void)notifyRESTUpdateForDriver:(NSString *)driverUUID andSharedUUID:(NSString *)shareUUID{
     GGDriver *driver = [self.liveMonitor getDriverWithUUID:driverUUID];
    
     NSString *compoundKey = [[driverUUID stringByAppendingString:DRIVER_COMPOUND_SEPERATOR] stringByAppendingString:shareUUID];
    
    // update the order delegate
    id<DriverDelegate> delegate = [_liveMonitor.driverDelegates objectForKey:compoundKey];
    
    if (delegate) {
        [delegate driverLocationDidChangeWithDriver:driver];
    }

}

#pragma mark - Track Actions
- (void)disconnectFromRealTimeUpdates{
    NSLog(@"DISCONNECTING TRACKER");
    
    // remove internal delegate
    [self.liveMonitor setRealTimeConnectionDelegate:nil];
    
    // stop all watching
    //[self stopWatchingAllOrders];
    //[self stopWatchingAllDrivers];
    //[self stopWatchingAllWaypoints];
    [self disconnect];
}


- (void)startWatchingOrderWithUUID:(NSString *)uuid delegate:(id <OrderDelegate>)delegate {
    
    NSLog(@"SHOULD START WATCHING ORDER %@ with delegate %@", uuid, delegate);
    
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
                        NSLog(@"SHOULD STOP WATCHING ORDER %@ with delegate %@", uuid, delegate);
                        
                        [_liveMonitor.orderDelegates removeObjectForKey:uuid];
                        
                    }
                    [delegateToRemove watchOrderFailForOrder:order error:error];
                    if (![_liveMonitor.orderDelegates count]) {
                        _liveMonitor.doMonitoringOrders = NO;
                        
                    }
                }else{
                    // with a little delay - also start polling orders
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        //
                        if (self.orderPollingTimer && [self.orderPollingTimer isValid]) {
                            [self.orderPollingTimer fire];
                        }else{
                            [self resetPollingTimers];
                        }
                    });
                }
            }];
        }
    }else{
        [NSException raise:@"Invalid UUID" format:@"Driver UUID can not be nil"];
    }
}



- (void)startWatchingDriverWithUUID:(NSString *)uuid shareUUID:(NSString *)shareUUID delegate:(id <DriverDelegate>)delegate {
    
    NSLog(@"SHOULD START WATCHING DRIVER %@ SHARED %@ with delegate %@", uuid, shareUUID, delegate);
    
    if (uuid && shareUUID) {
        _liveMonitor.doMonitoringDrivers = YES;
        
        GGDriver *driver = [[GGDriver alloc] initWithUUID:uuid];
        
        // here the key is a match
        NSString *compoundKey = [[uuid stringByAppendingString:DRIVER_COMPOUND_SEPERATOR] stringByAppendingString:shareUUID];
        
        id existingDelegate = [_liveMonitor.driverDelegates objectForKey:compoundKey];
        
        if (!existingDelegate) {
            @synchronized(self) {
                [_liveMonitor.driverDelegates setObject:delegate forKey:uuid];
                
            }
            [_liveMonitor sendWatchDriverWithDriverUUID:uuid shareUUID:(NSString *)shareUUID completionHandler:^(BOOL success, NSError *error) {
                if (!success) {
                    id delegateToRemove = [_liveMonitor.driverDelegates objectForKey:uuid];
                    @synchronized(_liveMonitor) {
                        
                         NSLog(@"SHOULD START WATCHING DRIVER %@ SHARED %@ with delegate %@", uuid, shareUUID, delegate);
                        
                        [_liveMonitor.driverDelegates removeObjectForKey:uuid];
                        
                    }
                    [delegateToRemove watchDriverFailedForDriver:driver error:error];
                    if (![_liveMonitor.driverDelegates count]) {
                        _liveMonitor.doMonitoringDrivers = NO;
                        
                    }
                }else{
                    // with a little delay - also start polling orders
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        //
                        if (self.locationPollingTimer && [self.locationPollingTimer isValid]) {
                            [self.locationPollingTimer fire];
                        }else{
                            [self resetPollingTimers];
                        }
                    });
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
            
            NSLog(@"SHOULD STOP WATCHING ORDER %@ with delegate %@", uuid, existingDelegate);
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
            
            NSLog(@"SHOULD START WATCHING DRIVER %@ SHARED %@ with delegate %@", uuid, shareUUID, existingDelegate);
            
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

- (void)reviveWatchedOrders{
    
    [self.monitoredOrders enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //
        NSString *orderUUID = (NSString *)obj;
        //check there is still a delegate listening
        id<OrderDelegate> orderDelegate = [_liveMonitor.orderDelegates objectForKey:orderUUID];
        
        // remove the old entry in the dictionary
        [_liveMonitor.orderDelegates removeObjectForKey:orderUUID];
        
        // if delegate isnt null than start watching again
        if (orderDelegate && ![orderDelegate isEqual: [NSNull null]]) {
            
            [orderDelegate trackerWillReviveWatchedOrder:orderUUID];
            
            [self startWatchingOrderWithUUID:orderUUID delegate:orderDelegate];
            
        }
    }];
}

- (void)reviveWatchedDrivers{
    
    [self.monitoredDrivers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //
        
        NSString *driverCompoundKey = (NSString *)obj;
        
        
        NSString *driverUUID;
        NSString *sharedUUID;
        
        [self parseDriverCompoundKey:driverCompoundKey toDriverUUID:&driverUUID andSharedUUID:&sharedUUID];
        
        //check there is still a delegate listening
        id<DriverDelegate> driverDelegate = [_liveMonitor.driverDelegates objectForKey:driverCompoundKey];
        
        // remove the old entry in the dictionary
        [_liveMonitor.driverDelegates removeObjectForKey:driverCompoundKey];
        
        // if delegate isnt null than start watching again
        if (driverDelegate && ![driverDelegate isEqual: [NSNull null]]) {
            
            [driverDelegate trackerWillReviveWatchedDriver:driverUUID withSharedUUID:sharedUUID];
            
            [self startWatchingDriverWithUUID:driverUUID shareUUID:sharedUUID delegate:driverDelegate];
            
        }
    }];
}
- (void)reviveWatchedWaypoints{
    
    [self.monitoredWaypoints enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //
        NSNumber *waypointId = (NSNumber *)obj;
        //check there is still a delegate listening
        id<WaypointDelegate> wpDelegate = [_liveMonitor.waypointDelegates objectForKey:waypointId];
        
        // remove the old entry in the dictionary
        [_liveMonitor.waypointDelegates removeObjectForKey:waypointId];
        
        // if delegate isnt null than start watching again
        if (wpDelegate && ![wpDelegate isEqual: [NSNull null]]) {
        
            [wpDelegate trackerWillReviveWatchedWaypoint:waypointId];
            
            [self startWatchingWaypointWithWaypointId:waypointId delegate:wpDelegate];
            
        }
    }];
}

#pragma mark - cleanup
-(void)removeOrderDelegates{
    [self.liveMonitor.orderDelegates removeAllObjects];
}

-(void)removeDriverDelegates{
    [self.liveMonitor.driverDelegates removeAllObjects];
}

-(void)removeWaypointDelegates{
    [self.liveMonitor.waypointDelegates removeAllObjects];
}

-(void)removeAllDelegates{
    
    [self removeOrderDelegates];
    [self removeDriverDelegates];
    [self removeWaypointDelegates];
}

#pragma mark - Real time delegate

-(void)trackerDidConnect{
    
    // check if we have any monotired order/driver/waypoints
    // if so we should re watch-them
    [self reviveWatchedOrders];
    [self reviveWatchedDrivers];
    [self reviveWatchedWaypoints];
    
    // report to the external delegate
    if (self.trackerRealtimeDelegate) {
        [self.trackerRealtimeDelegate trackerDidConnect];
    }
}

-(void)trackerDidDisconnectWithError:(NSError *)error{

    NSLog(@"tracker disconnected with error %@", error);

    // report to the external delegate
    if (self.trackerRealtimeDelegate) {
        [self.trackerRealtimeDelegate trackerDidDisconnectWithError:error];
    }
    
    // HANDLE RECONNECTION
    
    // disconnect real time for now
    [self disconnectFromRealTimeUpdates];
    
    
    // stop polling
    [self stopPolling];
    
    // clear polled items
    [self.polledLocations removeAllObjects];
    [self.polledOrders removeAllObjects];
    
    
    // check if there is network available - if yes > try to reconnect
    if ([self.liveMonitor.reachability isReachable]) {
        [self restartLiveMonitor];
    }
}


#pragma mark - Real Time status checks

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
