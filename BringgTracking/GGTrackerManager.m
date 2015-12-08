//
//  BringgTracker.m
//  BringgTracking
//
//  Created by Matan Poreh on 12/16/14.
//  Copyright (c) 2014 Matan Poreh. All rights reserved.
//

#import "GGTrackerManager_Private.h"

#import "GGHTTPClientManager.h"
#import "GGRealTimeMontior.h"


#import "GGCustomer.h"
#import "GGSharedLocation.h"
#import "GGDriver.h"
#import "GGOrder.h"
#import "GGRating.h"

#import "BringgGlobals.h"

#import "NSObject+Observer.h"


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
    
    return [self trackerWithCustomerToken:nil andDeveloperToken:nil andDelegate:nil andHTTPManager:nil];
    
}

+ (id)trackerWithCustomerToken:(NSString *)customerToken andDeveloperToken:(NSString *)devToken andDelegate:(id <RealTimeDelegate>)delegate andHTTPManager:(GGHTTPClientManager * _Nullable)httpManager{
 
    static GGTrackerManager *sharedObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // init the tracker
        sharedObject = [[self alloc] initTacker];
        
        // init the real time monitor
        sharedObject->_liveMonitor = [GGRealTimeMontior sharedInstance];
        sharedObject->_liveMonitor.realtimeConnectionDelegate = sharedObject;
        
        // init polled
        sharedObject->_polledOrders = [NSMutableSet set];
        sharedObject->_polledLocations = [NSMutableSet set];
        
        // setup http manager
        sharedObject->_httpManager = httpManager;
        
        sharedObject->_shouldReconnect = YES;
        
        sharedObject->_numConnectionAttempts = 0;
        
        // configure timers
        [sharedObject configurePollingTimers];
        
        // configure observers
        [sharedObject configureObservers];
        
       
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
    [self setRealTimeDelegate:self.trackerRealtimeDelegate];
    
    if (![self isConnected]) {

        if (self.shouldReconnect) {
            NSLog(@"******** RESTART TRACKER CONNECTION (delegate: %@)********", self.trackerRealtimeDelegate);
            [self connectUsingSecureConnection:self.useSSL];
        }
    }else{
        
        _numConnectionAttempts = 0;
        
        NSLog(@">>>>> CAN'T RESTART CONNECTION - TRACKER IS ALREADY CONNECTED");
    }
    
}


- (void)connectUsingSecureConnection:(BOOL)useSecure{
    
    // if no dev token we should raise an exception
    
    if  (!_developerToken) {
        
        [NSException raise:@"Invalid tracker Tokens" format:@"Developer Token can not be nil"];
        
    }else{
        
        // increment number of connection attempts
         _numConnectionAttempts++;
        
        self.useSSL = useSecure;
        
        // update the real time monitor with the dev token
        [self.liveMonitor setDeveloperToken:_developerToken];
        [self.liveMonitor useSecureConnection:useSecure];
        [self.liveMonitor connect];
        
        
    }
}

- (void)setShouldAutoReconnect:(BOOL)shouldAutoReconnect{
    self.shouldReconnect = shouldAutoReconnect;
}

- (void)disconnect{
    [_liveMonitor disconnect];
}

- (void)dealloc {
    
}

 


#pragma mark - Setters

- (void)setRealTimeDelegate:(id <RealTimeDelegate>)delegate {
    
    // set a delegate to keep tracker of the delegate that came outside the sdk
    self.trackerRealtimeDelegate = delegate;
    
    [self.liveMonitor setRealtimeDelegate:self];
    
}

- (void)setHTTPManager:(GGHTTPClientManager * _Nullable)httpManager{
    
    // remove observer prior to nullifing the manager
    if (!httpManager) {
        [self removeHTTPObserver];
    }
    
    self.httpManager = httpManager;
    if (self.httpManager) {
        [self configureHTTPObserver];
    }
    
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


#pragma mark - Observers
- (void)configureObservers{
    [self configureSocketObserver];
    
    if (self.httpManager) {
        [self configureHTTPObserver];
    }
    
}

- (void)configureSocketObserver{
   if (self.liveMonitor)  [NSObject addObserver:self
                 toObject:self.liveMonitor
               forKeyPath:@"lastEventDate" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)configureHTTPObserver {
    if (self.httpManager) [NSObject addObserver:self
                 toObject:self.httpManager
               forKeyPath:@"lastEventDate" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeHTTPObserver{
    if (self.httpManager) [NSObject removeObserver:self fromObject:self.httpManager forKeyPath:@"lastEventDate"];
}

- (void)removeSocketObserver{
    if (self.liveMonitor) [NSObject removeObserver:self fromObject:self.liveMonitor forKeyPath:@"lastEventDate"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    
    if ([keyPath isEqualToString:@"lastEventDate"] ) {
        //
        // handle tracker event data update
        if (self.liveMonitor.lastEventDate && self.trackerRealtimeDelegate && [self.trackerRealtimeDelegate respondsToSelector:@selector(trackerDidRecieveDataEventAtDate:)]) {
            //
            [self.trackerRealtimeDelegate trackerDidRecieveDataEventAtDate:self.liveMonitor.lastEventDate];
        }
    }
    
}

#pragma mark - Polling
- (void)configurePollingTimers{
    
    self.orderPollingTimer = [NSTimer scheduledTimerWithTimeInterval:POLLING_SEC target:self selector:@selector(orderPolling:) userInfo:nil repeats:YES];
    
    self.locationPollingTimer = [NSTimer scheduledTimerWithTimeInterval:POLLING_SEC target:self selector:@selector(locationPolling:) userInfo:nil repeats:YES];
    
   self.eventPollingTimer = [NSTimer scheduledTimerWithTimeInterval:POLLING_SEC target:self selector:@selector(eventPolling:) userInfo:nil repeats:YES];
    
   
}



- (void)resetPollingTimers {
    [self stopPolling];
    [self configurePollingTimers];
    
    
    // fire all timers
    if (self.orderPollingTimer && [self.orderPollingTimer isValid]) {
        [self.orderPollingTimer fire];
    }
    
    if (self.locationPollingTimer && [self.locationPollingTimer isValid]) {
        [self.locationPollingTimer fire];
    }
    
    if (self.eventPollingTimer && [self.eventPollingTimer isValid]) {
        [self.eventPollingTimer fire];
    }
}

- (void)stopPolling{
    if (self.orderPollingTimer && [self.orderPollingTimer isValid]) {
        [self.orderPollingTimer invalidate];
    }
    
    if (self.locationPollingTimer && [self.locationPollingTimer isValid]) {
        [self.locationPollingTimer invalidate];
    }
    
    if (self.eventPollingTimer && [self.eventPollingTimer isValid]) {
        [self.eventPollingTimer invalidate];
    }

}


- (void)startOrderPolling{
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

- (BOOL)canPollForOrders{
    return self.httpManager != nil;
}

- (BOOL)canPollForLocations{
    return self.httpManager != nil;
}

- (void)startLocationPolling{
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



- (void)eventPolling:(NSTimer *)timer {
 
    // check if we have an internet connection
    if ([self.liveMonitor.reachability isReachable]) {
        // if realtime isnt connected try to reconnect
        if (!self.isConnected) {
            
            
            // socket is not connected
            // check if it has been too long since a REST poll event. if so - poll
            if ([self.httpManager isWaitingTooLongForHTTPEvent]) {
                
                [self.orderPollingTimer fire];
                [self.locationPollingTimer fire];
            }
            
            
        }else{
            // realtime is connected
            // check if it has been too long since a socket or poll event. if so - poll
            if ([self.liveMonitor isWaitingTooLongForSocketEvent] || [self.httpManager isWaitingTooLongForHTTPEvent]) {
                
                [self.orderPollingTimer fire];
                [self.locationPollingTimer fire];
            }
           
        }
    }else{
        // remove this timer until reacahbility is returned
    }
    
    
}

- (void)locationPolling:(NSTimer *)timer {
    
    // location polling doesnt require authentication use it
//    if (![self isPollingSupported]) {
//        return;
//    }

    if (![self canPollForLocations] || !self.monitoredOrders || self.monitoredOrders.count == 0) {
        return;
    }
    
    // no need to poll if real time connection is working
    if ([self.liveMonitor isWorkingConnection]) {
        return;
    }
    
    NSLog(@"polling location for orders : %@", self.monitoredOrders);
    
    [self.monitoredOrders enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //
        NSString *orderUUID = (NSString *)obj;
       
        __block GGOrder *activeOrder = [self.liveMonitor getOrderWithUUID:orderUUID];
       
        
        
        // if we have a shared location object for this order we can now poll
        if (activeOrder.sharedLocation || activeOrder.sharedLocationUUID) {
            
            // check that we arent already polling this
            if (![self.polledLocations containsObject:activeOrder.sharedLocationUUID]) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self pollForLocation:activeOrder];
                });
            }
        }

        
    }];
}


- (void)pollForLocation:(nonnull GGOrder *)activeOrder{
    
    if (![self canPollForLocations]) {
        return  ;
    }
    
    // mark as being polled
    [self.polledLocations addObject:activeOrder.sharedLocationUUID];
    
    __weak __typeof(&*self)weakSelf = self;
    // we can only poll with a shared location uuid
    // if its missing we should try to retireve it
    if (activeOrder.sharedLocationUUID) {
    
        // ask our REST to poll
        [self.httpManager getSharedLocationByUUID:activeOrder.sharedLocationUUID extras:nil withCompletionHandler:^(BOOL success, NSDictionary * _Nullable response, GGSharedLocation * _Nullable sharedLocation, NSError * _Nullable error) {
            //
            
            // removed from the polled list
            [weakSelf.polledLocations removeObject:activeOrder.sharedLocationUUID];
            
            if (!error && sharedLocation != nil) {
                //
                if (!activeOrder.sharedLocation) {
                    activeOrder.sharedLocation = sharedLocation;
                }else{
                    [activeOrder.sharedLocation update:sharedLocation];
                    
                }
                
                [_liveMonitor addAndUpdateOrder:activeOrder];
                [_liveMonitor addAndUpdateDriver:sharedLocation.driver];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    // notify all interested parties that there has been a status change in the order
                    [weakSelf notifyRESTUpdateForOrderWithUUID:activeOrder.uuid];
                    
                    // notify all interested parties that there has been a status change in the order
                    [weakSelf notifyRESTUpdateForDriverWithUUID:sharedLocation.driver.uuid andSharedUUID:sharedLocation.locationUUID];
                    
                });
            }else{
                
                NSLog(@"ERROR POLLING LOCATION FOR ORDER %@:\n%@", activeOrder.uuid, [error localizedDescription]);
            }
            
            
        }];
    }else{
        
        // try to poll for the watched order to get its shared uuid
        [self.httpManager watchOrderByOrderUUID:activeOrder.uuid extras:nil withCompletionHandler:^(BOOL success, NSDictionary * _Nullable response, GGOrder * _Nullable order, NSError * _Nullable error) {
            //
            if (success && order) {
                
                // update and retrieve the updated model
                GGOrder *updatedOrder = [weakSelf.liveMonitor addAndUpdateOrder:order];
                
                // if we have a shared location object-> retry to poll the location
                if (updatedOrder.sharedLocationUUID) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf pollForLocation:updatedOrder];
                    });
                }
                
                
            }
            
        }];
    }
}

- (void)orderPolling:(NSTimer *)timer{
    
    if (![self canPollForOrders] || !self.monitoredOrders || self.monitoredOrders.count == 0) {
        return;
    }
    
    // no need to poll if real time connection is working
    if ([self.liveMonitor isWorkingConnection]) {
        return;
    }
    
     NSLog(@"polling orders : %@", self.monitoredOrders);
    
    [self.monitoredOrders enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        __block NSString *orderUUID = (NSString *)obj;
        
        // check that we are not polling already
        if (![self.polledOrders containsObject:orderUUID]) {
            
            // we need order id to do this so skip polling until the first real time updated that gets us full order model
            __block GGOrder *activeOrder = [self.liveMonitor getOrderWithUUID:orderUUID];
            
            // check that we have an order id needed for polling
            if (activeOrder && activeOrder.orderid) {
                [self.polledOrders addObject:orderUUID];
                
                // poll the order
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self pollForOrder:activeOrder];
                 });
                
            }
            
            
            
        }
    }];
}

-(void)pollForOrder:(nonnull GGOrder * )activeOrder{
    
    // exit if not allowed to poll
    if (![self canPollForOrders]) {
        return;
    }
    // to poll for an order we must have it's shared location uuid. if we dont have it we should retrieve it first
    
    __weak __typeof(&*self)weakSelf = self;
    if (activeOrder.sharedLocationUUID) {
        
        [self.httpManager getOrderByUUID:activeOrder.uuid withShareUUID:activeOrder.sharedLocationUUID extras:nil withCompletionHandler:^(BOOL success, NSDictionary * _Nullable response, GGOrder * _Nullable order, NSError * _Nullable error) {
            //
            
            // remove from polled orders
            [weakSelf.polledOrders removeObject:activeOrder.uuid];
            
            
            //
            if (!error && order != nil) {
#if DEBUG
                NSLog(@"GOT POLLED ORDER %@ when active is %@", order.uuid, activeOrder.uuid);
#endif
                // check that is is the update we were waiting for
                if ([order.uuid isEqualToString:activeOrder.uuid]) {
                    
                    
                    // update and retrieve the updated model
                    GGOrder *updatedOrder = [weakSelf.liveMonitor addAndUpdateOrder:order];
                    
                    GGDriver *sharedLocationDriver = [[updatedOrder sharedLocation] driver];
                    
                    // check if we can also update the driver related to the order
                    if (sharedLocationDriver) {
                        [_liveMonitor addAndUpdateDriver:sharedLocationDriver];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // notify all interested parties that there has been a status change in the order
                        [weakSelf notifyRESTUpdateForOrderWithUUID:order.uuid];
                    });
                }
            }else{
                NSLog(@"ERROR POLLING FOR ORDER %@:\n%@", activeOrder.uuid, error.localizedDescription);
            }
            
        }];

    }else{
        
        // try to poll for the watched order to get its shared uuid
        
        [self.httpManager watchOrderByOrderUUID:activeOrder.uuid extras:nil withCompletionHandler:^(BOOL success, NSDictionary * _Nullable response, GGOrder * _Nullable order, NSError * _Nullable error) {
            //
            if (success && order) {
                
                // update and retrieve the updated model
                GGOrder *updatedOrder = [weakSelf.liveMonitor addAndUpdateOrder:order];
                
                // if we have a shared location object-> retry to poll the order
                if (updatedOrder.sharedLocationUUID) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf pollForOrder:updatedOrder];
                    });
                }
                
               
            }
            
        }];
    }

    
}


- (void)notifyRESTUpdateForOrderWithUUID:(NSString *)orderUUID{
    
    GGOrder *order = [self.liveMonitor getOrderWithUUID:orderUUID];
    NSString *driverUUID;
    if (order.driverUUID) {
        driverUUID = order.driverUUID;
    }else if (order.sharedLocation.driver.uuid){
        driverUUID = order.sharedLocation.driver.uuid;
        
    }else{
        // sometimes rest order updates are missing relevent driver data
        // so we wil try to get the driver object by driver id instead of uuid
  
    }
    
    GGDriver *driver;
    
    if (driverUUID) {
        driver = [self.liveMonitor getDriverWithUUID:driverUUID];
    }else{
        driver = [self.liveMonitor getDriverWithID:@(order.driverId)];
    }
 
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


- (void)notifyRESTUpdateForDriverWithUUID:(NSString *)driverUUID andSharedUUID:(NSString *)shareUUID{
     GGDriver *driver = [self.liveMonitor getDriverWithUUID:driverUUID];
    
     NSString *compoundKey = [[driverUUID stringByAppendingString:DRIVER_COMPOUND_SEPERATOR] stringByAppendingString:shareUUID];
    
    // update the order delegate
    id<DriverDelegate> delegate = [_liveMonitor.driverDelegates objectForKey:compoundKey];
    
    if (delegate) {
        [delegate driverLocationDidChangeWithDriver:driver];
    }

}

-(void)getWatchedOrderByOrderUUID:(NSString * _Nonnull)orderUUID
            withCompletionHandler:(void (^ __nullable)(BOOL success, NSDictionary * _Nullable response,GGOrder * _Nullable order, NSError *_Nullable error))completionHandler{
    
    if (!self.httpManager) {
        if (completionHandler) {

            completionHandler(NO, nil, nil,  [NSError errorWithDomain:@"SDKDomain" code:0 userInfo:@{NSLocalizedDescriptionKey:@"Unknown error"}]);
        }
    }else{
        
        [self.httpManager watchOrderByOrderUUID:orderUUID
                                         extras:nil
                          withCompletionHandler:completionHandler];
    }
    
}


#pragma mark - Track Actions
- (void)disconnectFromRealTimeUpdates{
    NSLog(@"DISCONNECTING TRACKER");
    
    // remove internal delegate
    [self.liveMonitor setRealtimeDelegate:nil];
    
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
        
        __block GGOrder *activeOrder = [[GGOrder alloc] initOrderWithUUID:uuid atStatus:OrderStatusCreated];
        
        [_liveMonitor addAndUpdateOrder:activeOrder];
        
        if (!existingDelegate) {
            @synchronized(self) {
                [_liveMonitor.orderDelegates setObject:delegate forKey:uuid];
                
            }
            [_liveMonitor sendWatchOrderWithOrderUUID:uuid completionHandler:^(BOOL success, id socketResponse,  NSError *error) {
                
                  __weak __typeof(&*self)weakSelf = self;
                 __block id delegateOfOrder = [_liveMonitor.orderDelegates objectForKey:uuid];
                
                void (^pollHandler)(BOOL success, NSDictionary * _Nullable response, GGOrder * _Nullable order, NSError * _Nullable error) =  ^(BOOL success, NSDictionary * _Nullable response, GGOrder * _Nullable order, NSError * _Nullable error){
                    
                    if (success) {
                        
#if DEBUG
                        NSLog(@"GOT WATCHED ORDER %@ for UUID %@", order.uuid, uuid);
#endif
                        // update the local model in the live monitor and retrieve
                        GGOrder *updatedOrder = [weakSelf.liveMonitor addAndUpdateOrder:order];
                        
                        GGDriver *sharedLocationDriver = [[updatedOrder sharedLocation] driver];
                        
                        // check if we can also update the driver related to the order
                        if (sharedLocationDriver) {
                            [_liveMonitor addAndUpdateDriver:sharedLocationDriver];
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            // notify all interested parties that there has been a status change in the order
                            [weakSelf notifyRESTUpdateForOrderWithUUID:order.uuid];
                            
                            // start actuall polling
                            [self startOrderPolling];
                        });
                        
                        
                        
                    }else{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            // notify socket fail
                            [delegateOfOrder watchOrderFailForOrder:order error:error];
                        });
                        
                    }
                };
                
                if (!success) {
 
                    
                    // check if we can poll for orders if not - send error
                    
                    if ([self canPollForOrders]) {
                        
                        // start polling if possible
                        // first get the full order data

                        [self getWatchedOrderByOrderUUID:uuid withCompletionHandler:pollHandler];
                        
                    }else{
                        // notify socket fail
                        [delegateOfOrder watchOrderFailForOrder:activeOrder error:error];
                    }

 
                }else{
                    
                    // check for share_uuid
                    if (socketResponse && [socketResponse isKindOfClass:[NSDictionary class]]) {
                        NSString *shareUUID = [socketResponse objectForKey:@"share_uuid"];
                        GGSharedLocation *sharedLocation  = [[GGSharedLocation alloc] initWithData:[socketResponse objectForKey:@"shared_location"] ];
                        
                        // updated the order model
                        activeOrder.sharedLocationUUID = shareUUID;
                        activeOrder.sharedLocation = sharedLocation;
                        [_liveMonitor addAndUpdateOrder:activeOrder];
                        
                        
                        if (self.httpManager && [sharedLocation orderID]) {
                            // try to poll once for the full object
                            
                            if ([self.httpManager isSignedIn]) {
                                [self.httpManager getOrderByID:[sharedLocation orderID] extras:nil withCompletionHandler:^(BOOL success, NSDictionary * _Nullable response, GGOrder * _Nullable order, NSError * _Nullable error) {
                                    //
                                    if (success && order) {
                                        [_liveMonitor addAndUpdateOrder:order];
                                        [self notifyRESTUpdateForOrderWithUUID:order.uuid];
                                    }
                                }];
                            }else if ([self canPollForOrders]){
                                [self getWatchedOrderByOrderUUID:uuid withCompletionHandler:pollHandler];
                            }
 

                        }
                    }
                    
                    NSLog(@"SUCCESS WATCHING ORDER %@ with delegate %@", uuid, delegate);
                    
                    
                    //[self startOrderPolling];
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
        __block NSString *compoundKey = [[uuid stringByAppendingString:DRIVER_COMPOUND_SEPERATOR] stringByAppendingString:shareUUID];
        
        id existingDelegate = [_liveMonitor.driverDelegates objectForKey:compoundKey];
        
        if (!existingDelegate) {
            @synchronized(self) {
                [_liveMonitor.driverDelegates setObject:delegate forKey:compoundKey];
                
            }
            [_liveMonitor sendWatchDriverWithDriverUUID:uuid shareUUID:(NSString *)shareUUID completionHandler:^(BOOL success,id socketResponse, NSError *error) {
                if (!success) {
                    
                    id delegateOfDriver = [_liveMonitor.driverDelegates objectForKey:compoundKey];

                    if ([self canPollForLocations]) {
                        
                        
                        [self startLocationPolling];
                    }else{
                        
//                        @synchronized(_liveMonitor) {
//                            
//                            NSLog(@"SHOULD STOP WATCHING DRIVER %@ SHARED %@ with delegate %@", uuid, shareUUID, delegate);
//                            
//                            [_liveMonitor.driverDelegates removeObjectForKey:compoundKey];
//                            
//                        }
//                        
//                        if (![_liveMonitor.driverDelegates count]) {
//                            _liveMonitor.doMonitoringDrivers = NO;
//                            
//                        }
                        
                        [delegateOfDriver watchDriverFailedForDriver:driver error:error];
                    }
                    
                    
                    
                }else{
                    
                     NSLog(@"SUCCESS START WATCHING DRIVER %@ SHARED %@ with delegate %@", uuid, shareUUID, delegate);
                    
                    //[self startLocationPolling];
                }
            }];
        }
    }else{
        
        [NSException raise:@"Invalid UUIDs" format:@"Driver and Share UUIDs can not be nil"];
    }
    
}

- (void)startWatchingWaypointWithWaypointId:(NSNumber *)waypointId
                               andOrderUUID:(NSString * _Nonnull)orderUUID                                   delegate:(id <WaypointDelegate>)delegate {
    
     NSLog(@"SHOULD START WATCHING WAYPOINT %@ with delegate %@", waypointId, delegate);
    
    if (waypointId && orderUUID) {
        _liveMonitor.doMonitoringWaypoints = YES;
        
        // here the key is a match
        __block NSString *compoundKey = [[orderUUID stringByAppendingString:WAYPOINT_COMPOUND_SEPERATOR] stringByAppendingString:waypointId.stringValue];
        
        id existingDelegate = [_liveMonitor.waypointDelegates objectForKey:compoundKey];
        
        if (!existingDelegate) {
            @synchronized(self) {
                [_liveMonitor.waypointDelegates setObject:delegate forKey:compoundKey];
                
            }
            [_liveMonitor sendWatchWaypointWithWaypointId:waypointId andOrderUUID:orderUUID completionHandler:^(BOOL success, id socketResponse, NSError *error) {
                if (!success) {
 
                    id delegateOfWaypoint = [_liveMonitor.waypointDelegates objectForKey:compoundKey];
                    
                    @synchronized(_liveMonitor) {
                        
                        NSLog(@"SHOULD STOP WATCHING WAYPOINT %@ with delegate %@", waypointId, delegate);
                        
                        [_liveMonitor.waypointDelegates removeObjectForKey:compoundKey];
                        
                    }
                    
                    [delegateOfWaypoint watchWaypointFailedForWaypointId:waypointId error:error];
                    
                    if (![_liveMonitor.waypointDelegates count]) {
                        _liveMonitor.doMonitoringWaypoints = NO;
                        
                    }
                }else{
                    NSLog(@"SUCCESS WATCHING WAYPOINT %@ with delegate %@", waypointId, delegate);
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
    
    
     NSString *compoundKey = [[uuid stringByAppendingString:DRIVER_COMPOUND_SEPERATOR] stringByAppendingString:shareUUID];
    
    id existingDelegate = [_liveMonitor.driverDelegates objectForKey:compoundKey];
    if (existingDelegate) {
        @synchronized(_liveMonitor) {
            
            NSLog(@"SHOULD START WATCHING DRIVER %@ SHARED %@ with delegate %@", uuid, shareUUID, existingDelegate);
            
            [_liveMonitor.driverDelegates removeObjectForKey:compoundKey];
            
        }
    }
}

- (void)stopWatchingAllDrivers{
    @synchronized(_liveMonitor) {
        [_liveMonitor.driverDelegates removeAllObjects];
        
    }
}

- (void)stopWatchingWaypointWithWaypointId:(NSNumber * _Nonnull)waypointId andOrderUUID:(NSString * _Nonnull)orderUUID {
    
    NSString *compoundKey = [[orderUUID stringByAppendingString:WAYPOINT_COMPOUND_SEPERATOR] stringByAppendingString:waypointId.stringValue];
    
    
    id existingDelegate = [_liveMonitor.waypointDelegates objectForKey:compoundKey];
    if (existingDelegate) {
        @synchronized(_liveMonitor) {
            
             NSLog(@"SHOULD START WATCHING WAYPOINT %@ ORDER %@ with delegate %@", waypointId, orderUUID, existingDelegate);
            
            [_liveMonitor.waypointDelegates removeObjectForKey:compoundKey];
            
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
            
            if ([orderDelegate respondsToSelector:@selector(trackerWillReviveWatchedOrder:)]) {
                
                [orderDelegate trackerWillReviveWatchedOrder:orderUUID];
            }
 
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
        
        [GGBringgUtils parseDriverCompoundKey:driverCompoundKey toDriverUUID:&driverUUID andSharedUUID:&sharedUUID];
        
        //check there is still a delegate listening
        id<DriverDelegate> driverDelegate = [_liveMonitor.driverDelegates objectForKey:driverCompoundKey];
        
        // remove the old entry in the dictionary
        [_liveMonitor.driverDelegates removeObjectForKey:driverCompoundKey];
        
        // if delegate isnt null than start watching again
        if (driverDelegate && ![driverDelegate isEqual: [NSNull null]]) {
            
            if ([driverDelegate respondsToSelector:@selector(trackerWillReviveWatchedDriver:withSharedUUID:)]) {
                [driverDelegate trackerWillReviveWatchedDriver:driverUUID withSharedUUID:sharedUUID];
            }

            [self startWatchingDriverWithUUID:driverUUID shareUUID:sharedUUID delegate:driverDelegate];
            
        }
    }];
}
- (void)reviveWatchedWaypoints{
    
    [self.monitoredWaypoints enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //
        
        
        NSString *waypointCompoundKey = (NSString *)obj;
        
        
        NSString *orderUUID;
        NSString *waypointIdStr;
        
        [GGBringgUtils parseWaypointCompoundKey:waypointCompoundKey toOrderUUID:&orderUUID andWaypointId:&waypointIdStr];
        
        NSNumber *waypointId = [NSNumber numberWithInteger:waypointIdStr.integerValue];
        //check there is still a delegate listening
        id<WaypointDelegate> wpDelegate = [_liveMonitor.waypointDelegates objectForKey:waypointCompoundKey];
        
        // remove the old entry in the dictionary
        [_liveMonitor.waypointDelegates removeObjectForKey:waypointId];
        
        // if delegate isnt null than start watching again
        if (wpDelegate && ![wpDelegate isEqual: [NSNull null]]) {
        
            if ([wpDelegate respondsToSelector:@selector(trackerWillReviveWatchedWaypoint:)]) {
                [wpDelegate trackerWillReviveWatchedWaypoint:waypointId];
            }
            
            [self startWatchingWaypointWithWaypointId:waypointId andOrderUUID:orderUUID delegate:wpDelegate];
            
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
    
    // reset number of connection attempts
    _numConnectionAttempts = 0;
    
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
    
    
    // on error check if there is network available - if yes > try to reconnect
    if (error && [self.liveMonitor.reachability isReachable]) {
        
        // check if we maxxed out our connection attempts
        if (self.numConnectionAttempts >= MAX_CONNECTION_RETRIES) {
            
            NSLog(@">>>>> TOO MANY FAILED CONNECTION ATTEMPTS - DISABLING AUTO RECONNECTION");
            [self setShouldAutoReconnect:NO];
            
        }else{
            // try to reconnect
             [self restartLiveMonitor];
        }
        
       
    }
}

#pragma mark - Real Time Monitor Connection Delegate
-(NSString *)hostDomainForRealTimeMonitor:(GGRealTimeMontior *)realTimeMonitor{
    
    NSString *retval;
    
    if (self.trackerRealtimeDelegate && [self.trackerRealtimeDelegate respondsToSelector:@selector(hostDomainForTrackerManager:)]) {
        
        retval = [self.trackerRealtimeDelegate hostDomainForTrackerManager:self];
        
    }
    
    if (!retval) {
        retval = BTRealtimeServer;
    }
    
    return retval;
}

#pragma mark - Real Time status checks

- (BOOL)isPollingSupported{
    return self.httpManager != nil && [self.httpManager signedInCustomer] != nil;
}

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

- (BOOL)isWatchingDriverWithUUID:(NSString *_Nonnull)uuid andShareUUID:(NSString *_Nonnull)shareUUID {
    
    NSString *compoundKey = [[uuid stringByAppendingString:DRIVER_COMPOUND_SEPERATOR] stringByAppendingString:shareUUID];
    
    
    return ([_liveMonitor.driverDelegates objectForKey:compoundKey]) ? YES : NO;
    
}

- (BOOL)isWatchingWaypoints {
    return _liveMonitor.doMonitoringWaypoints;
    
}

- (BOOL)isWatchingWaypointWithWaypointId:(NSNumber *)waypointId andOrderUUID:(NSString * _Nonnull)orderUUID {
    
     NSString *compoundKey = [[orderUUID stringByAppendingString:WAYPOINT_COMPOUND_SEPERATOR] stringByAppendingString:waypointId.stringValue];
    
    return ([_liveMonitor.waypointDelegates objectForKey:compoundKey]) ? YES : NO;
    
}


@end
