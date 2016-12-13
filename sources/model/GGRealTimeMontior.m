//
//  GGRealTimeManager.m
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import "GGRealTimeMontior.h"
#import "GGRealTimeMontior+Private.h"

#import "GGRealTimeAdapter.h"


#import "GGDriver.h"
#import "GGCustomer.h"
#import "GGOrder.h"
#import "GGSharedLocation.h"
#import "GGWaypoint.h"
#import "NSObject+Observer.h"
#import "GGRealTimeInternals.h"

@import SocketIO;

@interface GGRealTimeMontior() <SocketIOClientDelegate>

@property (nonatomic, strong) Reachability *reachability;

@end

@implementation GGRealTimeMontior

@synthesize realtimeDelegate;


+ (id)sharedInstance {
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
        
    });
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

- (id)init {
    if (self = [super init]) {
        
        self.orderDelegates = [NSMutableDictionary dictionary];
        self.driverDelegates = [NSMutableDictionary dictionary];
        self.waypointDelegates = [NSMutableDictionary dictionary];
        self.activeDrivers = [NSMutableDictionary dictionary];
        self.activeOrders = [NSMutableDictionary dictionary];
        // let the real time manager handle socket events
        self.socketIO = [[SocketIOClient alloc] initWithSocketURL:[NSURL URLWithString:BTRealtimeServer] config:nil];
        
        self.connected = NO;
        self.wasManuallyConnected = NO;
        
        // start reachability monitor
        [self configureReachability];
        
        
    }
    
    return self;
    
}

- (BOOL)isSocketIOConnected{
    return self.socketIO.status == SocketIOClientStatusConnected;
}

- (BOOL)isSocketIOConnecting{
    return self.socketIO.status == SocketIOClientStatusConnecting;
}

- (void)configureReachability {
    Reachability *reachability = [Reachability reachabilityWithHostName:@"www.google.com"];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    
    self.reachability = reachability;
    [self.reachability startNotifier];
}

- (void)reachabilityChanged:(NSNotification *)notification {
    id notificationObject = [notification object];
    if ([notificationObject isKindOfClass:[Reachability class]]) {
        Reachability *curReachability = (Reachability *)notificationObject;
        
        if (curReachability == self.reachability) {
            NetworkStatus netStatus = [curReachability currentReachabilityStatus];
            
            if (netStatus != NotReachable) {
                // reconnect only if isnt already connecting and was at least once connected manually
                if (![self isSocketIOConnected] &&
                    ![self isSocketIOConnecting] &&
                    self.developerToken &&
                    self.wasManuallyConnected) {
                    
                    [self connect];
                }
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self disconnect];
                });
            }
        }
    };
}


- (void) setRealTimeConnectionDelegate:(id<RealTimeDelegate>) connectionDelegate{
    self.realtimeDelegate = connectionDelegate;
}

-(void)sendConnectionError:(NSError *)error{
    
    self.connected = NO;
    
    if (self.realtimeDelegate && [self.realtimeDelegate respondsToSelector:@selector(trackerDidDisconnectWithError:)]) {
        [self.realtimeDelegate trackerDidDisconnectWithError:error];
    }
}

#pragma mark - Setters

-(void)useSecureConnection:(BOOL)shouldUse{
    self.useSSL = shouldUse;
}

- (nullable GGOrder *)addAndUpdateOrder:(GGOrder *)order{
    // add this order to the orders active list if needed;
    if (order != nil && order.uuid != nil) {
        
        if (![self.activeOrders objectForKey:order.uuid]) {
            [self.activeOrders setObject:order forKey:order.uuid];
        }else{
            [[self.activeOrders objectForKey:order.uuid] update:order];
        }
        
        return [self getOrderWithUUID:order.uuid];
        
    }else{
        return nil;
    }
    
}
- (nullable GGDriver *)addAndUpdateDriver:(GGDriver *)driver{
    // add this driver to the drivers active list if needed
    if (driver != nil && driver.uuid != nil) {
        
        if (![self.activeDrivers objectForKey:driver.uuid]) {
            [self.activeDrivers setObject:driver forKey:driver.uuid];
        }else{
            [[self.activeDrivers objectForKey:driver.uuid] update:driver];
 
        }
        
        return [self getDriverWithUUID:driver.uuid];
    }else{
        return nil;
    }
}

- (nullable GGOrder *)addAndUpdateWaypoint:(GGWaypoint *_Nonnull)waypoint{
    
    if (waypoint != nil && waypoint.orderid > 0){
        
        NSNumber *taskId = @(waypoint.orderid);
        GGOrder *order = [self getOrderWithID:taskId];
        if (order) {
            // find the relevent waypoint
            GGWaypoint *wp = [[order.waypoints filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"waypointId == %@", @(waypoint.waypointId)]] firstObject];
            if (wp) {
                [wp update:waypoint];
            }
        }
        
        return order;
        
    }else{
        return nil;
    }
    
}

#pragma mark - Getters

-(BOOL)hasNetwork{
    return self.reachability.currentReachabilityStatus != NotReachable;
}

-(GGOrder * _Nullable)getOrderWithUUID:(NSString * _Nonnull)uuid{
    return [self.activeOrders objectForKey:uuid];
}

-(GGOrder * _Nullable)getOrderWithID:(NSNumber * _Nonnull)orderid{
    __block GGOrder *retVal;
    [self.activeOrders enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, GGOrder * _Nonnull obj, BOOL * _Nonnull stop) {
        //
        if (obj.orderid == orderid.integerValue){
            retVal = obj;
            *stop = YES;
        }
    }];
    
    return retVal;
}

-(GGDriver * _Nullable)getDriverWithUUID:(NSString * _Nonnull)uuid{
    return [self.activeDrivers objectForKey:uuid];
}

-(GGDriver * _Nullable)getDriverWithID:(NSNumber * _Nonnull)driverId{
    NSArray *allActiveDrivers = [self.activeDrivers allValues];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"driverid==%@", driverId];
    return [[allActiveDrivers filteredArrayUsingPredicate:pred] firstObject];
}

- (BOOL)isWaitingTooLongForSocketEvent{
    
    if (!self.lastEventDate) return NO;
    
    NSTimeInterval timeSinceRealTimeEvent = fabs([[NSDate date] timeIntervalSinceDate:self.lastEventDate]);
    
    return (timeSinceRealTimeEvent >= MAX_WITHOUT_REALTIME_SEC);
}

- (BOOL)isWorkingConnection{
    return [self isSocketIOConnected] && ![self isWaitingTooLongForSocketEvent] && self.lastEventDate;
}


#pragma mark - Helper


-(id<WaypointDelegate>)delegateForWaypointID:(NSNumber *)waypointId{
    
    if (!waypointId) {
        return nil;
    }
    
    __block id<WaypointDelegate> retVal;
    
    [self.waypointDelegates.allKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSString *waypointCompoundKey = (NSString *)obj;
        NSString *orderUUID;
        NSString *waypointIdStr;
        
        [GGBringgUtils parseWaypointCompoundKey:waypointCompoundKey toOrderUUID:&orderUUID andWaypointId:&waypointIdStr];
        
        if (waypointIdStr != nil) {
            NSNumber *wpid = [NSNumber numberWithInteger:waypointIdStr.integerValue];
            
            //check there is still a delegate listening
            if ([wpid isEqualToNumber:waypointId]){
                retVal = [self.waypointDelegates objectForKey:waypointCompoundKey];
                *stop = YES;
            }
            
        }
        
        
    }];
    
    return retVal;
}

#pragma mark - SocketIO actions

- (void)webSocketConnectWithCompletionHandler:(void (^)(BOOL success, NSError *error))completionHandler {
    
    NSString *server;
    
    if (self.realtimeConnectionDelegate && [self.realtimeConnectionDelegate respondsToSelector:@selector(hostDomainForRealTimeMonitor:)]) {
        server = [self.realtimeConnectionDelegate hostDomainForRealTimeMonitor:self];
    }
    
    if (!server) {
        server = BTRealtimeServer;
    }
    
    
    
    NSNumber *showLogs = @NO;
    
#ifdef DEBUG
    showLogs = @YES;
#endif
    
    // add correct scheme to server address
    [GGBringgUtils fixURLString:&server forSSL:self.useSSL];
    
    
    if (!self.useSSL) {
        
        server = [server stringByReplacingOccurrencesOfString:@"3000" withString:@"3030"];
        
    }
    
    NSDictionary *connectionParams = @{@"CLIENT": @"BRINGG-SDK-iOS", @"CLIENT-VERSION": SDK_VERSION, @"developer_access_token":self.developerToken};
    
    
    NSDictionary *connectionOptions = @{@"log":showLogs, @"forceWebsockets":@YES, @"secure": @(self.useSSL), @"reconnects":@NO, @"cookies":@[], @"connectParams":connectionParams};
    
    self.socketIO = [[SocketIOClient alloc] initWithSocketURL:[NSURL URLWithString:server] config:connectionOptions];
    
    
    
    if ([self isSocketIOConnected] || [self isSocketIOConnecting]) {
        
        if (completionHandler) {
            NSError *error = [NSError errorWithDomain:kSDKDomainRealTime code:0
                                             userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Already connected.", @"eng/heb")}];
            completionHandler(NO, error);
            
        }
    } else {
        
        if (!self.developerToken) {
            if (completionHandler) {
                NSError *error = [NSError errorWithDomain:kSDKDomainRealTime code:0
                                                 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid Developer Token", @"eng/heb")}];
                completionHandler(NO, error);
                
            }
            
            
            return;
        }
        
        [self addSocketHandlers];
        
        self.socketIOConnectedBlock = completionHandler;
        
        if ([self hasNetwork]) {
            
            NSLog(@"websocket connecting %@", server);
            
            @try {
                [self.socketIO connect];
                
            } @catch (NSException *exception) {
                
                NSLog(@"error connected: %@", exception);
            }
            
            
            
        }
        
        
    }
}

- (void)addSocketHandlers{
    [GGRealTimeAdapter addConnectionHandlerToClient:self.socketIO andDelegate:self];
    [GGRealTimeAdapter addDisconnectionHandlerToClient:self.socketIO andDelegate:self];
    [GGRealTimeAdapter addEventHandlerToClient:self.socketIO andDelegate:self];
    [GGRealTimeAdapter addErrorHandlerToClient:self.socketIO andDelegate:self];
}

- (void)setDeveloperToken:(NSString *)developerToken{
    _developerToken = developerToken;
}



- (void)connect {
    NSLog(@"Trying Connecting!");
    [self webSocketConnectWithCompletionHandler:^(BOOL success, NSError *error) {
        
        self.connected = success;
        NSLog(@"Connected: %d ", success);
        
        if (success) {
            
            self.wasManuallyConnected = YES;
            [self.realtimeDelegate trackerDidConnect];
            
            
        } else {
            [self.realtimeDelegate trackerDidDisconnectWithError:error];
            
        }
    }];
}

- (void)disconnect {
    [self webSocketDisconnect];
    
}


- (void)webSocketDisconnect {
    NSLog(@"websocket disconnected");
    [self.socketIO disconnect];
    self.connected = NO;
    
}

- (BOOL)handleSocketIODidReceiveEvent:(NSString *)eventName withData:(NSDictionary *)eventData{
    
    if (!eventName || !eventData) {
        return NO;
    }
    
    // update last date
    self.lastEventDate = [NSDate date];
    
    if ([eventName isEqualToString:EVENT_ORDER_UPDATE]) {
        
        NSString *orderUUID = [eventData objectForKey:PARAM_UUID];
        NSNumber *orderStatus = [eventData objectForKey:PARAM_STATUS];
        
        //GGOrder *order = [[GGOrder alloc] initOrderWithUUID:orderUUID atStatus:(OrderStatus)orderStatus.integerValue];
        
        GGOrder *updatedOrder = [[GGOrder alloc] initOrderWithData:eventData];
        GGDriver *updatedDriver = [eventData objectForKey:PARAM_DRIVER] ? [[GGDriver alloc] initDriverWithData:[eventData objectForKey:PARAM_DRIVER]] : nil;
        
        
        
        
        
        // updated existing model and retrieve the updated file
        GGOrder *order = [self addAndUpdateOrder:updatedOrder];
        GGDriver *driver = [self addAndUpdateDriver:updatedDriver];
        
        
        id existingDelegate = [self.orderDelegates objectForKey:orderUUID];
#ifdef DEBUG
        NSLog(@"delegate: %@ should update order with status:%@", existingDelegate, orderStatus );
#endif
        if (existingDelegate) {
            switch ([orderStatus integerValue]) {
                case OrderStatusAssigned:
                    [existingDelegate orderDidAssignWithOrder:order withDriver:driver];
                    break;
                case OrderStatusAccepted:
                    [existingDelegate orderDidAcceptWithOrder:order withDriver:driver];
                    break;
                case OrderStatusOnTheWay:
                    [existingDelegate orderDidStartWithOrder:order withDriver:driver];
                    break;
                case OrderStatusCheckedIn:
                    [existingDelegate orderDidArrive:order withDriver:driver];
                    break;
                case OrderStatusDone:
                    [existingDelegate orderDidFinish:order withDriver:driver];
                    break;
                case OrderStatusCancelled:
                case OrderStatusRejected:
                    [existingDelegate orderDidCancel:order withDriver:driver];
                    break;
                default:
                    break;
            }
            
        }
        
        return YES;
        
    } else if ([eventName isEqualToString:EVENT_ORDER_DONE]) {
        
        NSString *orderUUID = [eventData objectForKey:PARAM_UUID];
        
        GGOrder *updatedOrder = [[GGOrder alloc] initOrderWithData:eventData];
        
        if (!updatedOrder){
            updatedOrder = [self.activeOrders objectForKey:orderUUID];
        }
        
        [updatedOrder updateOrderStatus:OrderStatusDone];
        
        GGDriver *updatedDriver = [[GGDriver alloc] initDriverWithData:[eventData objectForKey:PARAM_DRIVER]];
        
        
        // updated existing model
        [self addAndUpdateOrder:updatedOrder];
        [self addAndUpdateDriver:updatedDriver];
        
        
        // get most updated model
        GGOrder *order = [self.activeOrders objectForKey:orderUUID];
        GGDriver *driver = [self.activeDrivers objectForKey:updatedDriver.uuid];
        
        
        id existingDelegate = [self.orderDelegates objectForKey:orderUUID];
#ifdef DEBUG
        NSLog(@"delegate: %@ should finish order %ld(%@)", existingDelegate, (long)order.orderid, order.uuid );
#endif
        if (existingDelegate) {
            [existingDelegate orderDidFinish:order  withDriver:driver];
            
        }
        
        return YES;
        
    } else if ([eventName isEqualToString:EVENT_DRIVER_LOCATION_CHANGED]) {
        NSDictionary *locationUpdate = eventData;
        NSString *driverUUID = [locationUpdate objectForKey:PARAM_DRIVER_UUID];
        NSString *shareUUID = [locationUpdate objectForKey:PARAM_SHARE_UUID];
        NSNumber *lat = [locationUpdate objectForKey:@"lat"];
        NSNumber *lng = [locationUpdate objectForKey:@"lng"];
        
        // get driver from data
        GGDriver *driver = [self.activeDrivers objectForKey:driverUUID];
        
        // if no data get it from the current active drivers
        if (!driver) {
            // try to get driver from shared uuid
            // to do this we go over all orders - check which has the specified shared uuid & shared location object and then get the driver related
            NSArray *sharedLocations = [self.activeOrders valueForKeyPath:@"sharedLocation"];
            if (sharedLocations.count > 0) {
                GGSharedLocation *sl = [[sharedLocations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"locationUUID == %@", shareUUID]] firstObject];
                if (sl && sl.driver) {
                    driver = sl.driver;
                }else{
                    driver = [self.activeDrivers objectForKey:self.activeDrivers.allKeys.firstObject];
                }
            }else{
                driver = [self.activeDrivers objectForKey:self.activeDrivers.allKeys.firstObject];
            }
            
            
        }
        
        if (driver) {
            [driver updateLocationToLatitude:lat.doubleValue longtitude:lng.doubleValue];
            
            driver = [self addAndUpdateDriver:driver];
            
            // search for the delegates appropriate and notify
            NSArray *monitoredDrivers = self.driverDelegates.allKeys;
            
            [monitoredDrivers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *driverCompoundKey = (NSString *)obj;
                
                
                NSString *driverUUID;
                NSString *sharedUUID;
                
                [GGBringgUtils parseDriverCompoundKey:driverCompoundKey toDriverUUID:&driverUUID andSharedUUID:&sharedUUID];
                
                //check there is still a delegate listening
                id<DriverDelegate> driverDelegate = [self.driverDelegates objectForKey:driverCompoundKey];
                
                
                
                if ([driverUUID isEqualToString:driver.uuid]) {
                    
#ifdef DEBUG
                    NSLog(@"delegate: %@ should udpate location for driver :%@", driverDelegate, driver.uuid );
#endif
                    if (driverDelegate) {
                        [driverDelegate driverLocationDidChangeWithDriver:driver];
                    }
                    
                }
            }];
            
        }
        
        return YES;
        
    } else if ([eventName isEqualToString:EVENT_DRIVER_ACTIVITY_CHANGED]) {
        //activity change
#ifdef DEBUG
        NSLog(@"driver activity changed: %@", [GGBringgUtils userPrintSafeDataFromData:@[eventData]]);
#endif
        
        return YES;
        
    }else if ([eventName isEqualToString:EVENT_WAY_POINT_LOCATION]){
        NSDictionary *locationUpdate = eventData;
        NSNumber *wpid = [GGBringgUtils numberFromJSON:[eventData objectForKey:@"way_point_id"] defaultTo:[GGBringgUtils numberFromJSON:[eventData objectForKey:@"id"] defaultTo:nil]];
        
        id existingDelegate = [self delegateForWaypointID:wpid];
        NSNumber *lat = [GGBringgUtils numberFromJSON:[locationUpdate objectForKey:@"lat"] defaultTo:nil];
        NSNumber *lng = [GGBringgUtils numberFromJSON:[locationUpdate objectForKey:@"lat"] defaultTo:nil];
        
        NSLog(@"delegate: %@ should udpate waypoint %@ location to: %@/%@ withData:%@", existingDelegate, wpid, lat, lng , eventData);
        
        if (lat && lng && existingDelegate) {
            [existingDelegate waypoint:wpid didUpdatedCoordinatesToLat:lat lng:lng];
        }
        
    }else if ([eventName isEqualToString:EVENT_WAY_POINT_ETA_UPDATE]) {
        
        NSNumber *wpid = [GGBringgUtils numberFromJSON:[eventData objectForKey:@"way_point_id"] defaultTo:[GGBringgUtils numberFromJSON:[eventData objectForKey:@"id"] defaultTo:nil]];
        NSString *eta = [eventData objectForKey:@"eta"];
        NSDate *etaToDate = [GGBringgUtils dateFromString:eta];
        
        id existingDelegate = [self delegateForWaypointID:wpid];
        
        NSLog(@"delegate: %@ should udpate waypoint %@ ETA to: %@ withData:%@", existingDelegate, wpid, eta , eventData);
        
        if (existingDelegate) {
            [existingDelegate waypointDidUpdatedWaypointId:wpid eta:etaToDate];
            
        }
        
        return YES;
        
    } else if ([eventName isEqualToString:EVENT_WAY_POINT_ARRIVED]) {
        
        NSNumber *wpid = [GGBringgUtils numberFromJSON:[eventData objectForKey:@"way_point_id"] defaultTo:[GGBringgUtils numberFromJSON:[eventData objectForKey:@"id"] defaultTo:nil]];
        id existingDelegate = [self delegateForWaypointID:wpid];
        
        
        NSLog(@"delegate: %@ should udpate waypoint %@ arrived withData:%@", existingDelegate, wpid, eventData );
        
        if (existingDelegate) {
            [existingDelegate waypointDidArrivedWaypointId:wpid];
            
        }
        
        return YES;
        
    } else if ([eventName isEqualToString:EVENT_WAY_POINT_DONE]) {
        
        NSNumber *wpid = [GGBringgUtils numberFromJSON:[eventData objectForKey:@"way_point_id"] defaultTo:[GGBringgUtils numberFromJSON:[eventData objectForKey:@"id"] defaultTo:nil]];
        id existingDelegate = [self delegateForWaypointID:wpid];
        
        NSLog(@"delegate: %@ should udpate waypoint %@ done withData:%@", existingDelegate, wpid, eventData );
        
        if (existingDelegate) {
            [existingDelegate waypointDidArrivedWaypointId:wpid];
            
        }
        
        return YES;
    }
    
    
    return NO;
}

#pragma mark - Watch Actions

- (void)sendWatchOrderWithOrderUUID:(NSString *)uuid completionHandler:(SocketResponseBlock)completionHandler {
    
    [self sendWatchOrderWithOrderUUID:uuid shareUUID:nil completionHandler:completionHandler];
}

- (void)sendWatchOrderWithOrderUUID:(NSString *)uuid shareUUID:(NSString *)shareUUID completionHandler:(SocketResponseBlock)completionHandler{
    
    NSLog(@"watch order %@", uuid);
    
    if (!uuid) {
        if (completionHandler) {
            NSError *error = [NSError errorWithDomain:kSDKDomainData code:GGErrorTypeUUIDNotFound userInfo:@{NSLocalizedDescriptionKey:@"missing UUID"}];
            
            completionHandler(NO, nil, error);
        }
        
        return;
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   uuid, @"order_uuid",
                                   nil];
    
    // if we have shared uuid - supply it as well
    if (shareUUID) {
        [params setObject:shareUUID forKey:@"share_uuid"];
    }
    
    [GGRealTimeAdapter sendEventWithClient:self.socketIO eventName:@"watch order" params:params completionHandler:completionHandler];
    
}

- (void)sendWatchDriverWithDriverUUID:(NSString *)uuid shareUUID:(NSString *)shareUUID completionHandler:(SocketResponseBlock)completionHandler {
    
    NSLog(@"watch driver %@ / %@", uuid, shareUUID);
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   uuid, @"driver_uuid",
                                   shareUUID, @"share_uuid",
                                   nil];
    [GGRealTimeAdapter sendEventWithClient:self.socketIO eventName:@"watch driver" params:params completionHandler:completionHandler];
    
}

- (void)sendWatchWaypointWithWaypointId:(NSNumber *)waypointId andOrderUUID:(NSString *)orderUUID completionHandler:(SocketResponseBlock)completionHandler {
    
    NSLog(@"watch waypoint %@ for order %@", waypointId, orderUUID);
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   waypointId, @"way_point_id",
                                   orderUUID, @"order_uuid",
                                   nil];
    
    [GGRealTimeAdapter sendEventWithClient:self.socketIO eventName:@"watch way point" params:params completionHandler:completionHandler];
    
}


#pragma mark - SocketIOClient callbacks

- (void) socketIODidConnect:(SocketIOClient *)socketIO {
    NSLog(@"websocket connected");
    
    self.connected = YES;
    
    if (self.socketIOConnectedBlock) {
        
        NSLog(@"\t\thandling connect success");
        
        self.socketIOConnectedBlock(YES, nil);
        self.socketIOConnectedBlock = nil;
        
    }
    
}

- (void) socketIODidDisconnect:(SocketIOClient *)socketIO disconnectedWithError:(NSError *)error {
    NSLog(@"websocket disconnected, error %@", error);
    
    // set the real timemonitor as disconnected
    self.connected = NO;
    
    if (self.socketIO) {
        // remove all handlers. they will be added again in the future once a connection is retried
        [self.socketIO removeAllHandlers];
    }
    
    
    // try to execture connection blocks
    if (self.socketIOConnectedBlock) {
        self.socketIOConnectedBlock(NO, error);
        self.socketIOConnectedBlock = nil;
        
    } else {
        // report connection error
        [self sendConnectionError:error];
        
    }
    
    
    
}


- (void) socketIO:(SocketIOClient *)socketIO didReceiveEvent:(NSString *)eventName withData:(NSArray *)eventDataItems {
#ifdef DEBUG
    NSLog(@"Received EVENT packet [%@]", eventName);
#endif
    
    [self handleSocketIODidReceiveEvent:eventName withData:eventDataItems.firstObject];
    
    
}

- (void)socketIO:(SocketIOClient *)socketIO onError:(NSError *)error {
    
    self.connected = [self isSocketIOConnected];
#ifdef DEBUG
    NSLog(@"Send error %@", error);
#endif
}


@end
