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
        self.logsEnabled = NO;
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

- (nullable GGOrder *)orderWithUUID:(nonnull NSString *)uuid{
    
    return [_liveMonitor getOrderWithUUID:uuid];
}

- (nullable GGOrder *)orderWithCompoundUUID:(nonnull NSString *)compoundUUID{
    
    
    NSString *uuid;
    NSString *sharedUUID;
    NSError *error;
    
    error = nil;
    [GGBringgUtils parseOrderCompoundUUID:compoundUUID toOrderUUID:&uuid andSharedUUID:&sharedUUID error:&error];
    
    if (error) {
        return nil;
    }
    
    GGOrder *order = [_liveMonitor getOrderWithUUID:uuid];
    
    if (order && [order isWithSharedUUID:sharedUUID]) {
        
        return order;
    }
    
    return nil;
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
                    
                    // notify all interested parties that there has been a status change in the order
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
                                    orderUUID:activeOrder.uuid
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
                                    orderUUID:activeOrder.uuid
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
                                    orderUUID:activeOrder.uuid
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
        driver = [self.liveMonitor getDriverWithUUID:driverUUID];
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
     GGDriver *driver = [self.liveMonitor getDriverWithUUID:driverUUID];
    
     NSString *compoundKey = [[driverUUID stringByAppendingString:DRIVER_COMPOUND_SEPERATOR] stringByAppendingString:shareUUID];
    
    // update the order delegate
    id<DriverDelegate> delegate = [_liveMonitor.driverDelegates objectForKey:compoundKey];
    
    if (delegate) {
        [delegate driverLocationDidChangeWithDriver:driver];
    }

}


- (void)startRESTWatchingOrderByOrderUUID:(NSString * _Nonnull)orderUUID
                                shareUUID:(NSString * _Nullable)shareUUID
                    withCompletionHandler:(nullable GGOrderResponseHandler)completionHandler {
    
    if (!self.httpManager) {
        if (completionHandler) {
            
            completionHandler(NO, nil, nil, [NSError errorWithDomain:kSDKDomainSetup code:GGErrorTypeHTTPManagerNotSet userInfo:@{NSLocalizedDescriptionKey:@"http manager is not set"}]);
        }
    }
    else {
        [self.httpManager watchOrderByOrderUUID:orderUUID shareUUID:shareUUID extras:nil withCompletionHandler:completionHandler];
    }
}

-(void)getWatchedOrderByShareUUID:(NSString * _Nonnull)shareUUID
                        orderUUID:(NSString * _Nonnull)orderUUID
            withCompletionHandler:(nullable GGOrderResponseHandler)completionHandler{
    
    if (!self.httpManager) {
        if (completionHandler) {
            
            completionHandler(NO, nil, nil, [NSError errorWithDomain:kSDKDomainSetup code:GGErrorTypeHTTPManagerNotSet userInfo:@{NSLocalizedDescriptionKey:@"http manager is not set"}]);
        }
    }
    else {
        [self.httpManager getOrderByShareUUID:shareUUID orderUUID:orderUUID extras:nil withCompletionHandler:completionHandler];
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

- (void)sendFindMeRequestForOrderWithUUID:(NSString *_Nonnull)uuid latitude:(double)lat longitude:(double)lng withCompletionHandler:(nullable GGActionResponseHandler)completionHandler{
    
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

- (void)sendFindMeRequestForOrderWithCompoundUUID:(NSString *_Nonnull)compoundUUID latitude:(double)lat longitude:(double)lng withCompletionHandler:(nullable GGActionResponseHandler)completionHandler{
    
    if (!compoundUUID){
        NSLog(@"ERROR SENDING FIND ME FOR ORDER WITH COMPOUND %@", compoundUUID);
        
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:kSDKDomainData code:GGErrorTypeInvalidUUID userInfo:@{NSLocalizedDescriptionKey:@"no compound uuid supplied"}]);
        }
        
        return;
    }

    
    // parse the uuid, then check for valid order and valid findme config
    // first parse the compound - if it isnt valid raise an exception
    NSString *uuid;
    NSString *sharedUUID;
    NSError *error;
    
    error = nil;
    [GGBringgUtils parseOrderCompoundUUID:compoundUUID toOrderUUID:&uuid andSharedUUID:&sharedUUID error:&error];
    
    if (error) {
        
        NSLog(@"ERROR SENDING FIND ME FOR ORDER WITH COMPOUND %@", compoundUUID);
        
        if (completionHandler) {
            completionHandler(NO, error);
        }
 
        return;
        
    }else{
        // get the matching order
        GGOrder *order = [self orderWithCompoundUUID:compoundUUID];
        
        if (!order) {
            if (completionHandler) {
                completionHandler(NO, [NSError errorWithDomain:kSDKDomainData code:GGErrorTypeOrderNotFound userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"no order found with compound %@", compoundUUID]}]);
            }
            
            return;
            
        }else{
            [self sendFindMeRequestForOrder:order latitude:lat longitude:lng withCompletionHandler:completionHandler];
        }
        
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

- (void)startWatchingOrderWithUUID:(NSString *_Nonnull)uuid
                        sharedUUID:(NSString *_Nullable)shareduuid
                          delegate:(id <OrderDelegate> _Nullable)delegate{
    
    NSLog(@"Trying to start watching on order uuid: %@, with delegate %@", uuid, delegate);
    
    // uuid is invalid if empty
    if (!uuid || uuid.length == 0) {
        [NSException raise:@"Invalid UUID" format:@"order UUID can not be nil or empty"];
        
        return;
    }

    
    _liveMonitor.doMonitoringOrders = YES;
    id existingDelegate = [_liveMonitor.orderDelegates objectForKey:uuid];
    
    __block GGOrder *activeOrder = [[GGOrder alloc] initOrderWithUUID:uuid atStatus:OrderStatusCreated];
    
    if (shareduuid) {
        activeOrder.sharedLocationUUID = shareduuid;
    }
    
    [_liveMonitor addAndUpdateOrder:activeOrder];
    
    if (!existingDelegate) {
        @synchronized(self) {
            [_liveMonitor.orderDelegates setObject:delegate forKey:uuid];
        }
        
        [_liveMonitor sendWatchOrderWithOrderUUID:uuid shareUUID:shareduuid completionHandler:^(BOOL success, id socketResponse,  NSError *error) {
            
            __weak typeof(self) weakSelf = self;
            __block id delegateOfOrder = [_liveMonitor.orderDelegates objectForKey:uuid];
            
            //create a poll handler that uses full order data to periodicaly poll for changes (this is a backup incase socket io fails to work)
            GGOrderResponseHandler pollHandler =  ^(BOOL success, NSDictionary * _Nullable response, GGOrder * _Nullable order, NSError * _Nullable error){
                
                if (success) {
                    [weakSelf handleOrderUpdated:activeOrder withNewOrder:order andPoll:YES];
                }
                else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // notify socket fail
                        if ([delegateOfOrder respondsToSelector:@selector(watchOrderFailForOrder:error:)]) {
                            [delegateOfOrder watchOrderFailForOrder:activeOrder error:error];
                        }
                    });
                }
            };
            
            if (!success) {
                // check if we can poll for orders if not - send error
                if ([self canPollForOrders]) {
                    
                    // call the start watch from the http manager
                    // we are depending here that we have a shared uuid
                    if (uuid != nil) {
                        // try to start watching via REST
                        [self startRESTWatchingOrderByOrderUUID:uuid shareUUID:shareduuid withCompletionHandler:^(BOOL success, NSDictionary * _Nullable response, GGOrder * _Nullable order, NSError * _Nullable error) {
                            
                            if (success) {
                                GGOrder *updatedOrder = [weakSelf.liveMonitor addAndUpdateOrder:order];
                                
                                // check if we have a shared location object
                                if (updatedOrder.sharedLocationUUID != nil) {
                                    
                                    // get the full order via REST
                                    [weakSelf getWatchedOrderByShareUUID:updatedOrder.sharedLocationUUID orderUUID:updatedOrder.uuid withCompletionHandler:pollHandler];
                                }
                                else {
                                    if ([delegateOfOrder respondsToSelector:@selector(watchOrderFailForOrder:error:)]) {
                                        [delegateOfOrder watchOrderFailForOrder:activeOrder error:error];
                                    }
                                }
                            }
                            else{
                                // notify watch fail
                                if ([delegateOfOrder respondsToSelector:@selector(watchOrderFailForOrder:error:)]) {
                                    [delegateOfOrder watchOrderFailForOrder:activeOrder error:error];
                                }
                            }
                        }];
                    }
                    else {
                        // notify watch fail
                        NSError *error = [NSError errorWithDomain:kSDKDomainData code:-1 userInfo:@{NSLocalizedDescriptionKey:@"missing order uuid"}];
                        if ([delegateOfOrder respondsToSelector:@selector(watchOrderFailForOrder:error:)]) {
                            [delegateOfOrder watchOrderFailForOrder:activeOrder error:error];
                        }
                    }
                }
                else {
                    // notify watch fail
                    if ([delegateOfOrder respondsToSelector:@selector(watchOrderFailForOrder:error:)]) {
                        [delegateOfOrder watchOrderFailForOrder:activeOrder error:error];
                    }
                }
            }
            else{
                
                // check for share_uuid
                if ([socketResponse isKindOfClass:[NSDictionary class]]) {
                    
                    BOOL isShareUUIDExpired = NO;
                    id expiredObj = [socketResponse objectForKey:@"expired"];
                    if ([expiredObj isKindOfClass:[NSNumber class]]) {
                        isShareUUIDExpired = ((NSNumber *)expiredObj).boolValue;
                    }
                    
                    if (isShareUUIDExpired) {
                        [activeOrder setStatus:OrderStatusDone];
                        
                        if ([delegateOfOrder respondsToSelector:@selector(watchOrderSucceedForOrder:)]) {
                            [delegateOfOrder watchOrderSucceedForOrder:activeOrder];
                        }
                    }
                    else {
                        NSString *shareUUID = shareduuid;
                        
                        if (!shareUUID) {
                            shareUUID = [socketResponse objectForKey:@"share_uuid"];
                        }
                        
                        GGSharedLocation *sharedLocation  = [[GGSharedLocation alloc] initWithData:[socketResponse objectForKey:@"shared_location"] ];
                        
                        // updated the order model
                        activeOrder.sharedLocationUUID = shareUUID;
                        activeOrder.sharedLocation = sharedLocation;
                        [_liveMonitor addAndUpdateOrder:activeOrder];
                        
                        if (self.httpManager && shareUUID) {
                            // try to get the full order object once
                            [self getWatchedOrderByShareUUID:shareUUID orderUUID:uuid withCompletionHandler:^(BOOL success, NSDictionary * _Nullable response, GGOrder * _Nullable order, NSError * _Nullable error) {
                                
                                if (success && order) {
                                    order.sharedLocation = sharedLocation;

                                    [_liveMonitor addAndUpdateOrder:order];
                                    
                                    if ([delegateOfOrder respondsToSelector:@selector(watchOrderSucceedForOrder:)]) {
                                        [delegateOfOrder watchOrderSucceedForOrder:order];
                                    }
                                    
                                    NSLog(@"Received full order object %@", order);
                                }
                                else {
                                    if ([delegateOfOrder respondsToSelector:@selector(watchOrderSucceedForOrder:)]) {
                                        [delegateOfOrder watchOrderSucceedForOrder:activeOrder];
                                    }
                                }
                            }];
                        }
                        else {
                            if ([delegateOfOrder respondsToSelector:@selector(watchOrderSucceedForOrder:)]) {
                                [delegateOfOrder watchOrderSucceedForOrder:activeOrder];
                            }
                        }
                    }
                }
                
                NSLog(@"SUCCESS WATCHING ORDER %@ with delegate %@", uuid, delegate);
            }
        }];
    }
    
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

- (void)startWatchingOrderWithCompoundUUID:(NSString *)compoundUUID delegate:(id<OrderDelegate>)delegate{
    
    // first parse the compound - if it isnt valid raise an exception
    NSString *uuid;
    NSString *sharedUUID;
    NSError *error;
    
    error = nil;
    [GGBringgUtils parseOrderCompoundUUID:compoundUUID toOrderUUID:&uuid andSharedUUID:&sharedUUID error:&error];
    
    if (error) {
        
        NSLog(@"ERROR START WATCHING ORDER WITH COMPOUND %@ with delegate %@", compoundUUID, delegate);
        
        [NSException raise:@"invalid compound UUID" format:@"compound UUID must be of valid structure"];
        
    }else{
        [self startWatchingOrderWithUUID:uuid sharedUUID:sharedUUID delegate:delegate];
    }
}

- (void)startWatchingOrderWithUUID:(NSString *)uuid delegate:(id <OrderDelegate>)delegate {
    [self startWatchingOrderWithUUID:uuid sharedUUID:nil delegate:delegate];
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
                id delegateOfDriver = [_liveMonitor.driverDelegates objectForKey:compoundKey];
                
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
                    
                    NSLog(@"SUCCESS START WATCHING DRIVER %@ SHARED %@ with delegate %@", uuid, shareUUID, delegate);
                }
            }];
        }
    }
    else {
        [NSException raise:@"Invalid UUIDs" format:@"Driver and Share UUIDs can not be nil"];
    }
}

- (void)startWatchingWaypointWithWaypointId:(NSNumber *)waypointId
                               andOrderUUID:(NSString * _Nonnull)orderUUID
                                   delegate:(id <WaypointDelegate>)delegate {
    
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

- (void)stopWatchingOrderWithCompoundUUID:(NSString *)compoundUUID{
    // parse the compound
    NSString *uuid;
    NSString *sharedUUID;
    NSError *error;
    
    error = nil;
    [GGBringgUtils parseOrderCompoundUUID:compoundUUID toOrderUUID:&uuid andSharedUUID:&sharedUUID error:&error];
    
    // if there is an error in parsing return no
    if (error) {
        [NSException raise:@"invalid compound UUID" format:@"compound UUID must be of valid structure"];
        return ;
    }
    
    [self stopWatchingOrderWithUUID:uuid];

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
    
    NSString *retval;
    
    if (self.connectionDelegate && [self.connectionDelegate respondsToSelector:@selector(hostDomainForTrackerManager:)]) {
        
        retval = [self.connectionDelegate hostDomainForTrackerManager:self];
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

- (BOOL)isWatchingOrderWithCompoundUUID:(NSString *)compoundUUID{
    if (!compoundUUID) {
        return NO;
    }
    
    // parse the compound
    NSString *uuid;
    NSString *sharedUUID;
    NSError *error;
    
    error = nil;
    [GGBringgUtils parseOrderCompoundUUID:compoundUUID toOrderUUID:&uuid andSharedUUID:&sharedUUID error:&error];
    
    // if there is an error in parsing return no
    if (error) {
        return NO;
    }
    
    // return if watching the order uuid
    return [self isWatchingOrderWithUUID:uuid];
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
