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
#import "GGWaypoint.h"
#import "BringgGlobals.h"

#import "NSObject+Observer.h"
#import "NSString+Extensions.h"

#define BTPhoneKey @"phone"
#define BTConfirmationCodeKey @"confirmation_code"
#define BTMerchantIdKey @"merchant_id"
#define BTDeveloperTokenKey @"developer_access_token"
#define BTCustomerTokenKey @"access_token"
#define BTCustomerPhoneKey @"phone"
#define BTTokenKey @"token"
#define BTRatingKey @"rating"

@interface GGTrackerManager()<NetworkClientUpdateDelegate>

@end


@implementation GGTrackerManager

@synthesize liveMonitor = _liveMonitor;
@synthesize appCustomer = _appCustomer;


- (nonnull instancetype)initWithDeveloperToken:(NSString *_Nullable)devToken HTTPManager:(GGHTTPClientManager * _Nullable)httpManager realTimeDelegate:(id <RealTimeDelegate> _Nullable)realTimeDelegate{
 
    
     if (self = [super init]) {
   
        // init the real time monitor
        self.liveMonitor = [[GGRealTimeMontior alloc] init];
        self.liveMonitor.realtimeConnectionDelegate = self;
        
        // init polled
        self.polledOrders = [NSMutableSet set];
        self.polledLocations = [NSMutableSet set];
        
        // setup http manager
        self.httpManager = httpManager;
        
        self.shouldReconnect = YES;
        
        self.numConnectionAttempts = 0;
        
        // set the customer token and developer token
        if (devToken) [self setDeveloperToken:devToken];
        
        // set the connection delegate
        if (realTimeDelegate) [self setRealTimeDelegate:realTimeDelegate];
    };
    
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
    
    if  (!self.developerToken.length) {
        [NSException raise:@"Invalid tracker Tokens" format:@"Developer Token can not be empty"];
    }
    else {
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

- (void)setLogsEnabled:(BOOL)logsEnabled {
    _logsEnabled = logsEnabled;
    self.liveMonitor.logsEnabled = logsEnabled;
}

#pragma mark - Setters

- (void)setRealTimeDelegate:(id <RealTimeDelegate>)delegate {
    
    // set a delegate to keep tracker of the delegate that came outside the sdk
    self.trackerRealtimeDelegate = delegate;
    
    [self.liveMonitor setRealtimeDelegate:self];
    
}

- (void)setDeveloperToken:(NSString *)developerToken {
    _developerToken = developerToken;
    NSLog(@"Tracker Set with Dev Token %@", _developerToken);
}

- (void)setHTTPManager:(GGHTTPClientManager * _Nullable)httpManager{
    
    _httpManager = httpManager;
    if (self.httpManager) {
        [self.httpManager setNetworkClientDelegate:self];
    }
    
}

- (void)setCustomer:(GGCustomer *)customer{
    _appCustomer = customer;
    _customerToken = customer ? customer.customerToken : nil;
}

- (void)setLiveMonitor:(GGRealTimeMontior *)liveMonitor{
    
   _liveMonitor = liveMonitor;
    
    if (self.liveMonitor) {
        [self.liveMonitor setNetworkClientDelegate:self];
    }

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

- (nullable NSString *)shareUUIDforDriverUUID:(nonnull NSString *)uuid{
    
    return [_liveMonitor getSharedUUIDforDriverUUID:uuid];
    
}

- (nullable GGDriver *)driverWithUUID:(nonnull NSString *)uuid{
    
    return [_liveMonitor getDriverWithUUID:uuid];
}

- (nullable GGOrder *)orderWithUUID:(nonnull NSString *)uuid{
    
    return [_liveMonitor getOrderWithUUID:uuid];
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
    if ([self.liveMonitor hasNetwork]) {
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
    
    if (!activeOrder){
        return;
    }
    
   
    
    __weak __typeof(&*self)weakSelf = self;
    // we can only poll with a shared location uuid
    // if its missing we should try to retireve it
    if (activeOrder.sharedLocationUUID) {
    
        // mark as being polled
        [self.polledLocations addObject:activeOrder.sharedLocationUUID];
        
        // ask our REST to poll
        [self.httpManager getSharedLocationByUUID:activeOrder.sharedLocationUUID extras:nil withCompletionHandler:^(BOOL success, NSDictionary * _Nullable response, GGSharedLocation * _Nullable sharedLocation, NSError * _Nullable error) {
            //
            
            // removed from the polled list
            [weakSelf.polledLocations removeObject:activeOrder.sharedLocationUUID];
            
            if (!error && sharedLocation != nil) {
                //
                // detect if any change in findme configuration
                __block BOOL oldCanFindMe = activeOrder.sharedLocation && [activeOrder.sharedLocation canSendFindMe];
                
                __block BOOL newCanFindMe = [sharedLocation canSendFindMe];
                
                // update shared location object
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
                    
                    // notify all interested parties that there has been a status change for the driver
                    [weakSelf notifyRESTUpdateForDriverWithUUID:sharedLocation.driver.uuid andSharedUUID:sharedLocation.locationUUID];
                    
                    
                    // notify findme change if relevant
                    if (oldCanFindMe != newCanFindMe) {
                        [weakSelf notifyRESTFindMeUpdatedForOrderWithUUID:activeOrder.uuid];
                    }
                    
                });
            }else{
                
                NSLog(@"ERROR POLLING LOCATION FOR ORDER %@:\n%@", activeOrder.uuid, [error localizedDescription]);
            }
            
            
        }];
    }else if (activeOrder.sharedLocationUUID && activeOrder.uuid){
        
        // try to poll for the watched order to get its shared uuid
        [self.httpManager getOrderByShareUUID:activeOrder.sharedLocationUUID
                        accessControlParamKey:PARAM_ORDER_UUID
                      accessControlParamValue:activeOrder.uuid
                                         extras:nil
                          withCompletionHandler:^(BOOL success, NSDictionary * _Nullable response, GGOrder * _Nullable order, NSError * _Nullable error) {
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
    
    __weak typeof(self) weakSelf = self;
    if (activeOrder.sharedLocationUUID) {
        
        [self.httpManager getOrderByShareUUID:activeOrder.sharedLocationUUID
                        accessControlParamKey:PARAM_ORDER_UUID
                      accessControlParamValue:activeOrder.uuid
                                       extras:nil
                        withCompletionHandler:^(BOOL success, NSDictionary * _Nullable response, GGOrder * _Nullable order, NSError * _Nullable error) {
            //
            
            // remove from polled orders
            [weakSelf.polledOrders removeObject:activeOrder.uuid];

            //
            if (success) {
      
                [weakSelf handleOrderUpdated:activeOrder withNewOrder:order andPoll:NO];

            }else{
                if (error) NSLog(@"ERROR POLLING FOR ORDER %@:\n%@", activeOrder.uuid, error.localizedDescription);
            }
            
        }];

    }else{
        
        // try to poll for the watched order to get its shared uuid
        
        [self.httpManager getOrderByShareUUID:activeOrder.sharedLocationUUID
                        accessControlParamKey:PARAM_ORDER_UUID
                      accessControlParamValue:activeOrder.uuid
                                         extras:nil
                          withCompletionHandler:^(BOOL success, NSDictionary * _Nullable response, GGOrder * _Nullable order, NSError * _Nullable error) {
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
        driver = [self driverWithUUID:driverUUID];
    }else{
        driver = [self.liveMonitor getDriverWithID:@(order.driverId)];
    }
 
    // update the order delegate
    id<OrderDelegate> delegate = [_liveMonitor.orderDelegates objectForKey:order.uuid];
    
    if (delegate) {
        switch (order.status) {
            case OrderStatusAccepted:
                if ([delegate respondsToSelector:@selector(orderDidAcceptWithOrder:withDriver:)]) {
                    [delegate orderDidAcceptWithOrder:order withDriver:driver];
                }
                break;
            case OrderStatusAssigned:
                if ([delegate respondsToSelector:@selector(orderDidAssignWithOrder:withDriver:)]) {
                    [delegate orderDidAssignWithOrder:order withDriver:driver];
                }
                break;
            case OrderStatusOnTheWay:
                if ([delegate respondsToSelector:@selector(orderDidStartWithOrder:withDriver:)]) {
                    [delegate orderDidStartWithOrder:order withDriver:driver];
                }
                break;
            case OrderStatusCheckedIn:
                if ([delegate respondsToSelector:@selector(orderDidArrive:withDriver:)]) {
                    [delegate orderDidArrive:order withDriver:driver];
                }
                break;
            case OrderStatusDone:
                if ([delegate respondsToSelector:@selector(orderDidFinish:withDriver:)]) {
                    [delegate orderDidFinish:order withDriver:driver];
                }
                break;
            case OrderStatusCancelled:
                if ([delegate respondsToSelector:@selector(orderDidCancel:withDriver:)]) {
                    [delegate orderDidCancel:order withDriver:driver];
                }
                break;
            default:
                break;
        }
    }
}

- (void)notifyRESTFindMeUpdatedForOrderWithUUID:(NSString * _Nonnull)orderUUID{
    GGOrder *order = [self.liveMonitor getOrderWithUUID:orderUUID];
   
    // update the order delegate
    id<OrderDelegate> delegate = [_liveMonitor.orderDelegates objectForKey:order.uuid];
    
    if (delegate) {
        // notifiy delegate findme configuration has been updated
        [delegate order:order didUpdateLocation:order.sharedLocation findMeConfiguration:order.sharedLocation.findMe];
    }
}

- (void)notifyRESTUpdateForDriverWithUUID:(NSString *)driverUUID andSharedUUID:(NSString *)shareUUID{
     GGDriver *driver = [self driverWithUUID:driverUUID];
    
    // update the order delegate
    id<DriverDelegate> delegate = [_liveMonitor.driverDelegates objectForKey:driverUUID];
    
    if ([delegate respondsToSelector:@selector(driverLocationDidChangeWithDriver:)]) {
        [delegate driverLocationDidChangeWithDriver:driver];
    }

}


- (void)startRESTWatchingOrderByOrderUUID:(NSString * _Nonnull)orderUUID
                    accessControlParamKey:(nonnull NSString *)accessControlParamKey
                  accessControlParamValue:(nonnull NSString *)accessControlParamValue
                    withCompletionHandler:(nullable GGOrderResponseHandler)completionHandler {
    
    if (!self.httpManager) {
        if (completionHandler) {
            
            completionHandler(NO, nil, nil, [NSError errorWithDomain:kSDKDomainSetup code:GGErrorTypeHTTPManagerNotSet userInfo:@{NSLocalizedDescriptionKey:@"http manager is not set"}]);
        }
    }
    else {
        [self.httpManager watchOrderByOrderUUID:orderUUID accessControlParamKey:accessControlParamKey accessControlParamValue:accessControlParamValue extras:nil withCompletionHandler:completionHandler];
        
    }
}

- (void)getWatchedOrderByShareUUID:(NSString * _Nonnull)shareUUID
             accessControlParamKey:(nonnull NSString *)accessControlParamKey
           accessControlParamValue:(nonnull NSString *)accessControlParamValue
             withCompletionHandler:(nullable GGOrderResponseHandler)completionHandler {
    
    if (!self.httpManager) {
        if (completionHandler) {
            
            completionHandler(NO, nil, nil, [NSError errorWithDomain:kSDKDomainSetup code:GGErrorTypeHTTPManagerNotSet userInfo:@{NSLocalizedDescriptionKey:@"http manager is not set"}]);
        }
    }
    else {
        [self.httpManager getOrderByShareUUID:shareUUID accessControlParamKey:accessControlParamKey accessControlParamValue:accessControlParamValue extras:nil withCompletionHandler:completionHandler];
        
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

- (void)sendFindMeRequestForOrderWithUUID:(NSString *_Nonnull)uuid  latitude:(double)lat longitude:(double)lng withCompletionHandler:(nullable GGActionResponseHandler)completionHandler{
    
    if (!self.httpManager) {
        if (completionHandler) {
            
            completionHandler(NO, [NSError errorWithDomain:kSDKDomainSetup code:GGErrorTypeHTTPManagerNotSet userInfo:@{NSLocalizedDescriptionKey:@"http manager is not set"}]);
        }
        
        return;
    }
    
    
    if (!uuid) {
        if (completionHandler) {
            
            completionHandler(NO, [NSError errorWithDomain:kSDKDomainData code:GGErrorTypeInvalidUUID userInfo:@{NSLocalizedDescriptionKey:@"supplied order uuid is invalid"}]);
        }
        
        return;
    }

    
    GGOrder *order = [self orderWithUUID:uuid];
    
    if (!order) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:kSDKDomainData code:GGErrorTypeOrderNotFound userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"no order found with uuid %@", uuid]}]);
        }
        
        return;
        
    }else{
        [self sendFindMeRequestForOrder:order latitude:lat longitude:lng withCompletionHandler:completionHandler];
    }
}



- (void)sendFindMeRequestForOrder:(nonnull GGOrder *)order latitude:(double)lat longitude:(double)lng withCompletionHandler:(nullable GGActionResponseHandler)completionHandler{
    
    if (!order.sharedLocation || ![order.sharedLocation canSendFindMe]) {
        // order is not eligable for find me
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:kSDKDomainData code:GGErrorTypeActionNotAllowed userInfo:@{NSLocalizedDescriptionKey:@"order is not eligable for 'Find me' at this time"}]);
        }
        return;
    }
    
    [self.httpManager sendFindMeRequestWithFindMeConfiguration:order.sharedLocation.findMe latitude:lat longitude:lng withCompletionHandler:completionHandler];
}

-(void)sendMaskedNumberRequestForOrderWithUUID:(NSString *_Nonnull)uuid
                                forPhoneNumber:(NSString*_Nonnull)originalPhoneNumber
                         withCompletionHandler:(nullable GGMaskedPhoneNumberResponseHandler)completionHandler{
    
    if (!self.httpManager) {
        if (completionHandler) {
            
            completionHandler(NO,nil, [NSError errorWithDomain:kSDKDomainSetup code:GGErrorTypeHTTPManagerNotSet userInfo:@{NSLocalizedDescriptionKey:@"http manager is not set"}]);
        }
        
        return;
    }
    
    
    if (!uuid) {
        if (completionHandler) {
            
            completionHandler(NO,nil, [NSError errorWithDomain:kSDKDomainData code:GGErrorTypeInvalidUUID userInfo:@{NSLocalizedDescriptionKey:@"supplied order uuid is invalid"}]);
        }
        
        return;
    }

    GGOrder *order = [self orderWithUUID:uuid];
    
    if (!order) {
        if (completionHandler) {
            completionHandler(NO,nil, [NSError errorWithDomain:kSDKDomainData code:GGErrorTypeOrderNotFound userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"no order found with uuid %@", uuid]}]);
        }
        return;
        
    }else{
        [self.httpManager sendMaskedNumberRequestForOrderWithUUID:uuid
                                                   forPhoneNumber:originalPhoneNumber
                                            withCompletionHandler:completionHandler];
    }
}
    


- (void)startWatchingOrderWithOrderUUID:(nonnull NSString *)orderUUID
                  accessControlParamKey:(nonnull NSString *)accessControlParamKey
                accessControlParamValue:(nonnull NSString *)accessControlParamValue
                               delegate:(id <OrderDelegate> _Nullable)delegate {
    
    
    if ([NSString isStringEmpty:accessControlParamKey] || [NSString isStringEmpty:accessControlParamValue] || [NSString isStringEmpty:orderUUID]) {
        [NSException raise:@"Invalid params" format:@"order uuid and param keys and values must be provided"];
        
        return;
    }
    
    __block GGOrder *activeOrder = [[GGOrder alloc] initOrderWithUUID:orderUUID atStatus:OrderStatusCreated];
    __block id existingDelegate = [_liveMonitor.orderDelegates objectForKey:orderUUID];
    [_liveMonitor addAndUpdateOrder:activeOrder];
    
    _liveMonitor.doMonitoringOrders = YES;
    
    if (!existingDelegate) {
        
        if (delegate && orderUUID) {
            @synchronized(self) {
                [_liveMonitor.orderDelegates setObject:delegate forKey:orderUUID];
            }
        }
        
        [_liveMonitor sendWatchOrderWithAccessControlParamKey:PARAM_ORDER_UUID
                                      accessControlParamValue:orderUUID
                                  secondAccessControlParamKey:accessControlParamKey
                                secondAccessControlParamValue:accessControlParamValue
                                            completionHandler:^(BOOL success, id  _Nullable socketResponse, NSError * _Nullable error) {
                                                
                                                
                if (!success) {
                    // check if we can poll for orders if not - send error
                    if ([self canPollForOrders]) {
                        
                        __weak typeof(self) weakSelf = self;
                        
                        [self handleRealTimeWatchOrderFailForOrder:activeOrder
                                             accessControlParamKey:accessControlParamKey
                                           accessControlParamValue:accessControlParamValue
                                                     orderDelegate:delegate
                                                realTimeWatchError:error
                                                       pollHandler:^(BOOL success, NSDictionary * _Nullable response, GGOrder * _Nullable order, NSError * _Nullable error) {
                            //
                            if (success) {
                                // merge orders data
                                [weakSelf handleOrderUpdated:activeOrder withNewOrder:order andPoll:YES];
                                activeOrder = [weakSelf.liveMonitor addAndUpdateOrder:order];
                                
                                // notify watch success
                                if ([delegate respondsToSelector:@selector(watchOrderSucceedForOrder:)]) {
                                    
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        // notify socket fail
                                        [delegate watchOrderSucceedForOrder:activeOrder];
                                        
                                    });
                                }
                            }
                            else{
                                // notify watch fail
                                if ([delegate respondsToSelector:@selector(watchOrderFailForOrder:error:)]) {
                                    
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        
                                        [delegate watchOrderFailForOrder:activeOrder error:error];
                                        
                                    });
                                }
                                
                            }}];
                        
                    }
                    else {
                        // notify watch fail
                        if ([delegate respondsToSelector:@selector(watchOrderFailForOrder:error:)]) {
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                
                                [delegate watchOrderFailForOrder:activeOrder error:error];
                                
                            });
                        }
                    }
                }
                else{
                    
                    [self handleRealTimeWatchOrderSuccessForOrder:activeOrder
                                                        shareUUID:nil
                                                         response:socketResponse
                                                    orderDelegate:delegate];
                    
                }
            }];
    }

    
}

- (void)startWatchingOrderWithShareUUID:(nonnull NSString *)shareUUID
                  accessControlParamKey:(nonnull NSString *)accessControlParamKey
                accessControlParamValue:(nonnull NSString *)accessControlParamValue
                               delegate:(id <OrderDelegate> _Nullable)delegate {
    
    if ([NSString isStringEmpty:accessControlParamKey] || [NSString isStringEmpty:accessControlParamValue] || [NSString isStringEmpty:shareUUID]) {
        [NSException raise:@"Invalid params" format:@"order uuid and param keys and values must be provided"];
        
        return;
    }

    __block GGOrder *activeOrder = [[GGOrder alloc] init];
    [activeOrder setStatus:OrderStatusCreated];

    _liveMonitor.doMonitoringOrders = YES;
    [_liveMonitor sendWatchOrderWithAccessControlParamKey:PARAM_SHARE_UUID
                                  accessControlParamValue:shareUUID
                              secondAccessControlParamKey:accessControlParamKey
                            secondAccessControlParamValue:accessControlParamValue
                                        completionHandler:^(BOOL success, id  _Nullable socketResponse, NSError * _Nullable error) {
                                            
                                            
        if (!success) {
            // check if we can poll for orders if not - send error
            if ([self canPollForOrders]) {
                
                __weak typeof(self) weakSelf = self;
                
                [self handleRealTimeWatchOrderFailForShareUUID:shareUUID
                                         accessControlParamKey:accessControlParamKey
                                       accessControlParamValue:accessControlParamValue
                                                 orderDelegate:delegate
                                            realTimeWatchError:error
                                                   pollHandler:^(BOOL success, NSDictionary * _Nullable response, GGOrder * _Nullable order, NSError * _Nullable error) {
                    //
                    if (success) {
                        
                        [activeOrder setUuid:order.uuid];
                        
                        // merge orders data
                        [weakSelf handleOrderUpdated:activeOrder withNewOrder:order andPoll:YES];
                        activeOrder = [weakSelf.liveMonitor addAndUpdateOrder:order];
                        
                        // notify watch success
                        if ([delegate respondsToSelector:@selector(watchOrderSucceedForOrder:)]) {
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                // notify socket fail
                                [delegate watchOrderSucceedForOrder:activeOrder];
                                
                            });
                        }
                    }
                    else{
                        // notify watch fail
                        if ([delegate respondsToSelector:@selector(watchOrderFailForOrder:error:)]) {
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                
                                [delegate watchOrderFailForOrder:activeOrder error:error];
                                
                            });
                        }
                        
                    }
                }];
                
                
            }
            else {
                // notify watch fail
                if ([delegate respondsToSelector:@selector(watchOrderFailForOrder:error:)]) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        [delegate watchOrderFailForOrder:activeOrder error:error];
                        
                    });
                }
            }
        }
        else{
            
            // infer order uuid from response
            NSString *orderUUID = [socketResponse valueForKeyPath:PARAM_ORDER_UUID];
            [activeOrder setUuid:orderUUID];
            
            if (delegate && orderUUID) {
                @synchronized(self) {
                    [_liveMonitor.orderDelegates setObject:delegate forKey:orderUUID];
                }
            }
            
            [self handleRealTimeWatchOrderSuccessForOrder:activeOrder shareUUID:shareUUID response:socketResponse orderDelegate:delegate];
            
            
        }
    }];
}

- (void)handleRealTimeWatchOrderSuccessForOrder:(nonnull GGOrder *)activeOrder
                                     shareUUID:(nullable NSString *)shareUUID
                                       response:(nullable NSDictionary *)response
                                  orderDelegate:(id <OrderDelegate> _Nullable)orderDelegate{
    
    // check for share_uuid
    if (response && [response isKindOfClass:[NSDictionary class]]) {
        
        NSString *_shareUUID = shareUUID;
        
        if (!_shareUUID) {
            _shareUUID = [response objectForKey:PARAM_SHARE_UUID];
        }
        
        // try building the shared location object from callback
        GGSharedLocation *sharedLocation  = [[GGSharedLocation alloc] initWithData:[response objectForKey:PARAM_SHARED_LOCATION] ];
        
        // update order model with shared location object
        if (sharedLocation) {
            // updated the order model
            activeOrder.sharedLocationUUID = _shareUUID;
            activeOrder.sharedLocation = sharedLocation;
            [_liveMonitor addAndUpdateOrder:activeOrder];
        }
        
        
        BOOL isShareUUIDExpired = NO;
        id expiredObj = [response objectForKey:PARAM_EXPIRED];
       
        if ([expiredObj isKindOfClass:[NSNumber class]]) {
            isShareUUIDExpired = ((NSNumber *)expiredObj).boolValue;
        }
        
        
        if (isShareUUIDExpired) {
            [activeOrder setStatus:OrderStatusDone];
            
            if ([orderDelegate respondsToSelector:@selector(watchOrderSucceedForOrder:)]) {
                [orderDelegate watchOrderSucceedForOrder:activeOrder];
            }
        } else {
            
            if (self.httpManager && _shareUUID) {
                // try to get the full order object once
                [self getWatchedOrderByShareUUID:_shareUUID
                           accessControlParamKey:PARAM_ORDER_UUID
                         accessControlParamValue:activeOrder.uuid
                           withCompletionHandler:^(BOOL success, NSDictionary * _Nullable response, GGOrder * _Nullable order, NSError * _Nullable error) {
                    
                    if (success && order) {
                        order.sharedLocation = sharedLocation;
                        
                        [_liveMonitor addAndUpdateOrder:order];
                        
                        if ([orderDelegate respondsToSelector:@selector(watchOrderSucceedForOrder:)]) {
                            [orderDelegate watchOrderSucceedForOrder:order];
                        }
                        
                        NSLog(@"Received full order object %@", order);
                    }
                    else {
                        if ([orderDelegate respondsToSelector:@selector(watchOrderSucceedForOrder:)]) {
                            [orderDelegate watchOrderSucceedForOrder:activeOrder];
                        }
                    }
                }];
            }
            else {
                if ([orderDelegate respondsToSelector:@selector(watchOrderSucceedForOrder:)]) {
                    [orderDelegate watchOrderSucceedForOrder:activeOrder];
                }
            }
        }
    }
    
    NSLog(@"SUCCESS WATCHING ORDER %@ with delegate %@", activeOrder.uuid, orderDelegate);

}


- (void)handleRealTimeWatchOrderFailForOrder:(nonnull GGOrder *)activeOrder
                       accessControlParamKey:(nonnull NSString *)accessControlParamKey
                     accessControlParamValue:(nonnull NSString *)accessControlParamValue
                               orderDelegate:(id <OrderDelegate> _Nullable)orderDelegate
                          realTimeWatchError:(nullable NSError *)realTimeWatchError
                                 pollHandler:(nonnull GGOrderResponseHandler)pollHandler{
    
    // call the start watch from the http manager
    // we are depending here that we have a shared uuid or customer access token
    // try to start watching via REST
    
    // if we dont have an order uuid just call the poll handler with failure
    if ([NSString isStringEmpty:activeOrder.uuid]) {
        
        pollHandler(NO , nil, activeOrder, realTimeWatchError);
        
        return;
        
    }
    
    __weak __typeof(self)weakSelf = self;
    [self startRESTWatchingOrderByOrderUUID:activeOrder.uuid accessControlParamKey:accessControlParamKey accessControlParamValue:accessControlParamValue withCompletionHandler:^(BOOL success, NSDictionary * _Nullable response, GGOrder * _Nullable order, NSError * _Nullable error) {
        
        if (success) {
            GGOrder *updatedOrder = [weakSelf.liveMonitor addAndUpdateOrder:order];
            
            pollHandler(YES , response, updatedOrder, error);
        }
        else{
            pollHandler(NO , response, activeOrder, error);
        }
    }];
}

- (void)handleRealTimeWatchOrderFailForShareUUID:(nonnull NSString *)shareUUID
                           accessControlParamKey:(nonnull NSString *)accessControlParamKey
                         accessControlParamValue:(nonnull NSString *)accessControlParamValue
                                   orderDelegate:(id <OrderDelegate> _Nullable)orderDelegate
                              realTimeWatchError:(nullable NSError *)realTimeWatchError
                                     pollHandler:(nonnull GGOrderResponseHandler)pollHandler{
    
    
    // if we dont have a share uuid just call the poll handler with failure
    if ([NSString isStringEmpty:shareUUID]) {
        
        pollHandler(NO , nil, nil, realTimeWatchError);
        
        return;
        
    }
    
    // call the start watch from the http manager
    // we are depending here that we have a shared uuid and either customer access token or order uuid
    // try to start watching via REST
    __weak __typeof(self)weakSelf = self;
    
    [self getWatchedOrderByShareUUID:shareUUID accessControlParamKey:accessControlParamKey accessControlParamValue:accessControlParamValue withCompletionHandler:^(BOOL success, NSDictionary * _Nullable response, GGOrder * _Nullable order, NSError * _Nullable error) {
        //
        if (success) {
            __block GGOrder *updatedOrder = [weakSelf.liveMonitor addAndUpdateOrder:order];
           
            
            // if we dont have a shared location object related to this order - fetch it
            if (!updatedOrder.sharedLocationUUID) {
                
                [weakSelf.httpManager getOrderSharedLocationByUUID:shareUUID extras:nil withCompletionHandler:^(BOOL locationSuccess, NSDictionary * _Nullable locationResponse, GGSharedLocation * _Nullable sharedLocation, NSError * _Nullable locationError) {
                    //
                    updatedOrder.sharedLocationUUID = shareUUID;
                    updatedOrder.sharedLocation = sharedLocation;
                    
                    pollHandler(YES , response, updatedOrder, nil);
                }];
            }else{
                 pollHandler(YES , response, updatedOrder, nil);
            }
            
           
        }
        else{
            pollHandler(NO , response, order, error);
        }
    }];
    
   
}

- (void)handleOrderUpdated:(GGOrder *)activeOrder withNewOrder:(GGOrder *)order andPoll:(BOOL)doPoll{
    
    if (!activeOrder || !order) {
        return;
    }
    
    if (![activeOrder.uuid isEqualToString:order.uuid]) {
        return;
    }
    
    if (self.logsEnabled) {
        NSLog(@"GOT WATCHED ORDER %@ for UUID %@", order.uuid, activeOrder.uuid);
    }

    // update the local model in the live monitor and retrieve
    GGOrder *updatedOrder = [self.liveMonitor addAndUpdateOrder:order];
    
    GGDriver *sharedLocationDriver = [[updatedOrder sharedLocation] driver];
    
    // detect if any change in findme configuration
    __block BOOL oldCanFindMe = activeOrder.sharedLocation && [activeOrder.sharedLocation canSendFindMe];
    
    __block BOOL newCanFindMe = order.sharedLocation && [order.sharedLocation canSendFindMe];
    
    // check if we can also update the driver related to the order
    if (sharedLocationDriver) {
        [_liveMonitor addAndUpdateDriver:sharedLocationDriver];
    }
    
     __weak __typeof(&*self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        // notify all interested parties that there has been a status change in the order
        [weakSelf notifyRESTUpdateForOrderWithUUID:order.uuid];
        
        // notify findme change if relevant
        if (oldCanFindMe != newCanFindMe) {
            [weakSelf notifyRESTFindMeUpdatedForOrderWithUUID:order.uuid];
        }
        
        // start actuall polling
        if (doPoll) {
            [self startOrderPolling];
        };
    });
    

}


 
- (void)startWatchingDriverWithUUID:(nonnull NSString *)uuid
              accessControlParamKey:(nonnull NSString *)accessControlParamKey
            accessControlParamValue:(nonnull NSString *)accessControlParamValue
                           delegate:(id <DriverDelegate> _Nullable)delegate {
    
    if ([NSString isStringEmpty:uuid] || [NSString isStringEmpty:accessControlParamKey] || [NSString isStringEmpty:accessControlParamValue]) {
        [NSException raise:@"Invalid params" format:@"driver and access controll params can not be empty"];
        
        return;
    }

    _liveMonitor.doMonitoringDrivers = YES;
    
    GGDriver *driver = [[GGDriver alloc] initWithUUID:uuid];
    

    id existingDelegate = [_liveMonitor.driverDelegates objectForKey:uuid];
    
    if (!existingDelegate) {
        
        if (delegate) {
            @synchronized(self) {
                [_liveMonitor.driverDelegates setObject:delegate forKey:uuid];
            }
        }
 
        [_liveMonitor sendWatchDriverWithDriverUUID:uuid accessControlParamKey:accessControlParamKey accessControlParamValue:accessControlParamValue completionHandler:^(BOOL success,id socketResponse, NSError *error) {
            
            id delegateOfDriver = [_liveMonitor.driverDelegates objectForKey:uuid];
            
            if (!success) {
                void(^callDelegateBlock)(void) = ^(void) {
                    if ([delegateOfDriver respondsToSelector:@selector(watchDriverFailedForDriver:error:)]) {
                        [delegateOfDriver watchDriverFailedForDriver:driver error:error];
                    }
                };
                
                NSString *errorMessage = error.userInfo[NSLocalizedDescriptionKey];
                if ([errorMessage isEqualToString:@"Uuid mismatch"]) {
                    callDelegateBlock();
                }
                else {
                    if ([self canPollForLocations]) {
                        [self startLocationPolling];
                    }
                    else {
                        callDelegateBlock();
                    }
                }
            }
            else {
                if ([delegateOfDriver respondsToSelector:@selector(watchDriverSucceedForDriver:)]) {
                    [delegateOfDriver watchDriverSucceedForDriver:driver];
                }
                
                NSLog(@"SUCCESS START WATCHING DRIVER %@ -> %@: %@ with delegate %@", uuid, accessControlParamKey, accessControlParamValue, delegate);
            }
        }];
    }
}

- (void)startWatchingWaypointWithWaypointId:(NSNumber *)waypointId
                               andOrderUUID:(NSString * _Nonnull)orderUUID
                                   delegate:(id <WaypointDelegate>)delegate {
    
    
    if (!waypointId || [NSString isStringEmpty:orderUUID]) {
        [NSException raise:@"Invalid params" format:@"waypoint id and order uuid params can not be empty"];
        
        return;
    }

    _liveMonitor.doMonitoringWaypoints = YES;
    
    // here the key is a match
    __block NSString *compoundKey = [[orderUUID stringByAppendingString:WAYPOINT_COMPOUND_SEPERATOR] stringByAppendingString:waypointId.stringValue];
    
    id existingDelegate = [_liveMonitor.waypointDelegates objectForKey:compoundKey];
    
    if (!existingDelegate) {
        
        if (delegate) {
            @synchronized(self) {
                [_liveMonitor.waypointDelegates setObject:delegate forKey:compoundKey];
                
            }
        }
        
        [_liveMonitor sendWatchWaypointWithWaypointId:waypointId andOrderUUID:orderUUID completionHandler:^(BOOL success, id socketResponse, NSError *error) {
            
            id delegateOfWaypoint = [_liveMonitor.waypointDelegates objectForKey:compoundKey];
            
            if (!success) {
                
                @synchronized(_liveMonitor) {
                    
                    NSLog(@"SHOULD STOP WATCHING WAYPOINT %@ with delegate %@", waypointId, delegate);
                    
                    [_liveMonitor.waypointDelegates removeObjectForKey:compoundKey];
                    
                }
                
                if ([delegateOfWaypoint respondsToSelector:@selector(watchWaypointFailedForWaypointId:error:)]) {
                    [delegateOfWaypoint watchWaypointFailedForWaypointId:waypointId error:error];
                }
                
                if (![_liveMonitor.waypointDelegates count]) {
                    _liveMonitor.doMonitoringWaypoints = NO;
                    
                }
            }else{
                NSLog(@"SUCCESS WATCHING WAYPOINT %@ with delegate %@", waypointId, delegate);
                
                GGWaypoint *wp;
                // search for waypoint model in callback
                NSDictionary *waypointData = [socketResponse objectForKey:@"way_point"];
                if (waypointData) {
                    wp = [[GGWaypoint alloc] initWaypointWithData:waypointData];
                    // if valid wp we need to update the order waypoint
                    if (wp){
                        // update local model with wp
                        [_liveMonitor addAndUpdateWaypoint:wp];
                    }
                }
                
                if ([delegateOfWaypoint respondsToSelector:@selector(watchWaypointSucceededForWaypointId:waypoint:)]) {
                    [delegateOfWaypoint watchWaypointSucceededForWaypointId:waypointId waypoint:wp];
                }
                
                
                
            }
        }];
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

- (void)stopWatchingDriverWithUUID:(NSString *)uuid {
    
    
    
    id existingDelegate = [_liveMonitor.driverDelegates objectForKey:uuid];
    if (existingDelegate) {
        @synchronized(_liveMonitor) {
            
            NSLog(@"SHOULD START WATCHING DRIVER %@ with delegate %@", uuid, existingDelegate);
            
            [_liveMonitor.driverDelegates removeObjectForKey:uuid];
            
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
            
            // for the revival to work we need the order shared uuid which we should have if the order was indeed previously being watched
            GGOrder *order = [self orderWithUUID:orderUUID];
            
            if (order && ![NSString isStringEmpty:order.sharedLocationUUID]) {
                if ([orderDelegate respondsToSelector:@selector(trackerWillReviveWatchedOrder:)]) {
                    
                    [orderDelegate trackerWillReviveWatchedOrder:orderUUID];
                }
                
                [self startWatchingOrderWithOrderUUID:orderUUID accessControlParamKey:PARAM_SHARE_UUID accessControlParamValue:order.sharedLocationUUID delegate:orderDelegate];
                
            }
            
           
            
        }
    }];
}

- (void)reviveWatchedDrivers{
    
    [self.monitoredDrivers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //
        NSString *driverUUID = (NSString *)obj;
        
        //check there is still a delegate listening
        id<DriverDelegate> driverDelegate = [_liveMonitor.driverDelegates objectForKey:driverUUID];
        
        // remove the old entry in the dictionary
        [_liveMonitor.driverDelegates removeObjectForKey:driverUUID];
        
        NSString *shareUUID = [self shareUUIDforDriverUUID:driverUUID];
        
        // if delegate isnt null than and we have a valid shared uuid start watching again
        if (![NSString isStringEmpty:shareUUID] && driverDelegate && ![driverDelegate isEqual: [NSNull null]]) {
            
            if ([driverDelegate respondsToSelector:@selector(trackerWillReviveWatchedDriver:)]) {
                [driverDelegate trackerWillReviveWatchedDriver:driverUUID];
            }

            [self startWatchingDriverWithUUID:driverUUID accessControlParamKey:PARAM_SHARE_UUID accessControlParamValue:shareUUID delegate:driverDelegate];
            
            
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
        [_liveMonitor.waypointDelegates removeObjectForKey:waypointCompoundKey];
        
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
    if (error && [self.liveMonitor hasNetwork]) {
        
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
    if (self.connectionDelegate && [self.connectionDelegate respondsToSelector:@selector(hostDomainForTrackerManager:)]) {
        
        return [self.connectionDelegate hostDomainForTrackerManager:self];
    }
    return nil;
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

- (BOOL)isWatchingDriverWithUUID:(NSString *_Nonnull)uuid {
    
    return ([_liveMonitor.driverDelegates objectForKey:uuid]) ? YES : NO;
    
}

- (BOOL)isWatchingWaypoints {
    return _liveMonitor.doMonitoringWaypoints;
    
}

- (BOOL)isWatchingWaypointWithWaypointId:(NSNumber *)waypointId andOrderUUID:(NSString * _Nonnull)orderUUID {
    
     NSString *compoundKey = [[orderUUID stringByAppendingString:WAYPOINT_COMPOUND_SEPERATOR] stringByAppendingString:waypointId.stringValue];
    
    return ([_liveMonitor.waypointDelegates objectForKey:compoundKey]) ? YES : NO;
    
}

#pragma mark - NetworkClientUpdateDelegate

-(void)networkClient:(id)networkClient didReciveUpdateEventAtDate:(NSDate *)eventDate{
    // handle tracker event data update
    if (self.liveMonitor.lastEventDate && self.trackerRealtimeDelegate && [self.trackerRealtimeDelegate respondsToSelector:@selector(trackerDidRecieveDataEventAtDate:)]) {
        //
        [self.trackerRealtimeDelegate trackerDidRecieveDataEventAtDate:eventDate];
    }
}
@end
