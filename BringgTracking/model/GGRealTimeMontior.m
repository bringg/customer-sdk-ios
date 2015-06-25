//
//  GGRealTimeManager.m
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Ilya Kalinin. All rights reserved.
//

#import "GGRealTimeMontior.h"

#import "SocketIOPacket.h"
#import "Reachability.h"

#import "GGDriver.h"
#import "GGCustomer.h"
#import "GGOrder.h"
#import "GGSharedLocation.h"
#import "GGRating.m"

//#define BRINGG_REALTIME_SERVER @"realtime.bringg.com"


#define EVENT_ORDER_UPDATE @"order update"
#define EVENT_ORDER_DONE @"order done"

#define EVENT_DRIVER_LOCATION_CHANGED @"location update"
#define EVENT_DRIVER_ACTIVITY_CHANGED @"activity change"

#define EVENT_WAY_POINT_ARRIVED @"way point arrived"
#define EVENT_WAY_POINT_DONE @"way point done"
#define EVENT_WAY_POINT_ETA_UPDATE @"way point eta updated"

typedef void (^CompletionBlock)(BOOL success, NSError *error);

@interface GGRealTimeMontior ()

@property (nonatomic,strong) SocketIO *socketIO;
@property (nonatomic, copy) CompletionBlock socketIOConnectedBlock;
@property (nonatomic, weak) id<RealTimeDelegate> realtimeDelegate;

@property (nonatomic, assign) BOOL connected;
@property (nonatomic, strong) Reachability* reachability;

@property (nonatomic, strong) NSString *developerToken;

@property (nonatomic, strong) NSMutableDictionary *orderDelegates;
@property (nonatomic, strong) NSMutableDictionary *driverDelegates;
@property (nonatomic, strong) NSMutableDictionary *waypointDelegates;
@property (nonatomic, strong) NSMutableDictionary *activeDrivers;


@property (nonatomic, assign) BOOL doMonitoringOrders;
@property (nonatomic, assign) BOOL doMonitoringDrivers;
@property (nonatomic, assign) BOOL doMonitoringWaypoints;

@end

@implementation GGRealTimeMontior

@synthesize realtimeDelegate;


+ (id)sharedInstance {
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
        
    });
}

- (id)init {
    if (self = [super init]) {
        
        self.orderDelegates = [NSMutableDictionary dictionary];
        self.driverDelegates = [NSMutableDictionary dictionary];
        self.waypointDelegates = [NSMutableDictionary dictionary];
        self.activeDrivers = [NSMutableDictionary dictionary];
        // let the real time manager handle socket events
        self.socketIO = [[SocketIO alloc] initWithDelegate:self];
        
    }
    
    return self;
    
}


- (void)configureReachability {
    Reachability* reachability = [Reachability reachabilityWithHostname:@"www.google.com"];
    self.reachability = reachability;
    reachability.reachableBlock = ^(Reachability*reach) {
        NSLog(@"Reachable!");
        if (![self.socketIO isConnected] && ![self.socketIO isConnecting]) {
            
            
        }
    };
    reachability.unreachableBlock = ^(Reachability*reach) {
        NSLog(@"Unreachable!");
        
    };
    [reachability startNotifier];
    
}



- (void) setRealTimeConnectionDelegate:(id<RealTimeDelegate>) connectionDelegate{
    realtimeDelegate = connectionDelegate;
}

-(void)sendConnectionError:(NSError *)error{
    
    if (realtimeDelegate && [realtimeDelegate respondsToSelector:@selector(trackerDidDisconnectWithError:)]) {
        [realtimeDelegate trackerDidDisconnectWithError:error];
    }
}

#pragma mark - Helper

- (NSDate *)dateFromString:(NSString *)string {
    NSDate *date;
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    date = [dateFormat dateFromString:string];
    if (!date) {
        [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
        date = [dateFormat dateFromString:string];
        
    }
    if (!date) {
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
        date = [dateFormat dateFromString:string];
        
    }
    return date;
    
}


#pragma mark - SocketIO actions

- (void)webSocketConnectWithCompletionHandler:(void (^)(BOOL success, NSError *error))completionHandler {
    NSString *server = BTRealtimeServer;
    if ([self.socketIO isConnected] || [self.socketIO isConnecting]) {
        if (completionHandler) {
            NSError *error = [NSError errorWithDomain:@"OVDomain" code:0
                                             userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Already connected.", @"eng/heb")}];
            completionHandler(NO, error);
            
        }
    } else {
        NSLog(@"websocket connected %@", server);
        if (self.reachability.isReachableViaWiFi) {
            [self.socketIO connectToHost:server
                                  onPort:0
                              withParams:@{@"developer_access_token":self.developerToken}
             /*withTransport:SocketIOTransportWebSocket*/];
            
        } else {
            [self.socketIO connectToHost:server
                                  onPort:0
                              withParams:@{@"developer_access_token":self.developerToken}
             /* withTransport:SocketIOTransportXHRPolling*/];
            
        }
        self.socketIOConnectedBlock = completionHandler;
        
    }
}

- (void)setDeveloperToken:(NSString *)developerToken{
    self.developerToken = developerToken;
}



- (void)connect {
    NSLog(@"Connecting!");
    [self webSocketConnectWithCompletionHandler:^(BOOL success, NSError *error) {
        self.connected = success;
        NSLog(@"Connected: %d ", success);
        if (success) {
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

- (void)sendEventWithName:(NSString *)name params:(NSDictionary *)params completionHandler:(void (^)(BOOL success, NSError *error))completionHandler {
    if (!self.connected) {
        if (completionHandler) {
            NSError *error = [NSError errorWithDomain:@"OVDomain" code:0
                                             userInfo:@{NSLocalizedDescriptionKey: @"Web socket disconnected.",
                                                        NSLocalizedRecoverySuggestionErrorKey: @"Web socket disconnected."}];
            completionHandler(NO, error);
            
        }
        return;
        
    }
    SocketIOCallback cb;
    if (completionHandler) {
        
        cb = ^(id argsData) {
            NSLog(@"SocketIOCallback argsData %@", argsData);
            NSError *error;
            if (![self errorAck:argsData error:&error]) {
                completionHandler(YES, nil);
                
            } else {
                completionHandler(NO, error);
                
            }
        };
    }
    
    [self.socketIO sendEvent:name withData:params andAcknowledge:cb];
    
}



- (BOOL)errorAck:(id)argsData error:(NSError **)error {
    BOOL errorResult = NO;
    NSString *message;
    if ([argsData isKindOfClass:[NSString class]]) {
        NSString *data = (NSString *)argsData;
        if ([[data lowercaseString] rangeOfString:@"error"].location != NSNotFound) {
            errorResult = YES;
            message = data;
        }
        
    } else if ([argsData isKindOfClass:[NSDictionary class]]) {
        NSNumber *success = [argsData objectForKey:@"success"];
        message = [argsData objectForKey:@"message"];
        if (![success boolValue]) {
            errorResult = YES;
            
        }
    }
    if (errorResult) {
        *error = [NSError errorWithDomain:@"OVDomain" code:0
                                 userInfo:@{NSLocalizedDescriptionKey:message,
                                            NSLocalizedRecoverySuggestionErrorKey:message}];
        
    }
    return errorResult;
    
}


#pragma mark - SocketIO callbacks

- (void) socketIODidConnect:(SocketIO *)socket {
    NSLog(@"websocket connected");
    if (self.socketIOConnectedBlock) {
        self.socketIOConnectedBlock(YES, nil);
        self.socketIOConnectedBlock = nil;
        
    }
    
}

- (void) socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error {
    NSLog(@"websocket disconnected, error %@", error);
    if (self.socketIOConnectedBlock) {
        self.socketIOConnectedBlock(NO, error);
        self.socketIOConnectedBlock = nil;
        
    } else {
        
        [self sendConnectionError:error];
 
        
        
    }
  
}

- (void) socketIO:(SocketIO *)socket didReceiveMessage:(SocketIOPacket *)packet {
    NSLog(@"Received packet [%@]", packet.data);
    
}

- (void) socketIO:(SocketIO *)socket didReceiveJSON:(SocketIOPacket *)packet {
    NSLog(@"Received packet [%@]", packet.data);
    
}

- (void) socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet {
    NSLog(@"Received packet [%@]", packet.data);
    if ([packet.name isEqualToString:EVENT_ORDER_UPDATE]) {
        
        NSDictionary *eventData = [packet.args firstObject];
        
        NSString *orderUUID = [eventData objectForKey:PARAM_UUID];
        NSNumber *orderStatus = [eventData objectForKey:PARAM_STATUS];
        
        GGOrder *order = [[GGOrder alloc] initOrderWithUUID:orderUUID atStatus:(OrderStatus)orderStatus.integerValue];
        
        GGDriver *driver = [GGDriver driverFromData:[eventData objectForKey:PARAM_DRIVER]];
        
        // add this driver to the drivers active list if needed
        if (![self.activeDrivers objectForKey:driver.uuid]) {
            [self.activeDrivers setObject:driver forKey:driver.uuid];
        }
        
    
        
        //test get order method
//        NSNumber *orderID = [eventData objectForKey:PARAM_ID];
//
//         
//        [self orderWithOrderID:orderID completionHandler:^(BOOL success, NSNumber *status, NSError *error) {
//            NSLog(@"status %@, error %@", status, error);
//
//        }];
        
        id existingDelegate = [self.orderDelegates objectForKey:orderUUID];
        if (existingDelegate) {
            switch ([orderStatus integerValue]) {
                case OrderStatusAssigned:
                    [existingDelegate orderDidAssignWithOrder:order withDriver:driver];
                    break;
                case OrderStatusAccepted:
                    [existingDelegate orderDidAcceptOrder:order withDriver:driver];
                    break;
                case OrderStatusOnTheWay:
                    [existingDelegate orderDidStartOrder:order withDriver:driver];
                    break;
                case OrderStatusCheckedIn:
                    [existingDelegate orderDidArrive:order];
                    break;
                case OrderStatusDone:
                    [existingDelegate orderDidFinish:order];
                    break;
                case OrderStatusCancelled:
                case OrderStatusRejected:
                    [existingDelegate orderDidCancel:order];
                    break;
                default:
                    break;
            }
            
        }
    } else if ([packet.name isEqualToString:EVENT_ORDER_DONE]) {
        NSDictionary *orderDone = [packet.args firstObject];
        NSString *orderUUID = [orderDone objectForKey:@"uuid"];
        
        GGOrder *order = [[GGOrder alloc] initOrderWithUUID:orderUUID atStatus:OrderStatusDone];
        
        id existingDelegate = [self.orderDelegates objectForKey:orderUUID];
        if (existingDelegate) {
            [existingDelegate orderDidFinish:order];
            
        }
    } else if ([packet.name isEqualToString:EVENT_DRIVER_LOCATION_CHANGED]) {
        NSDictionary *locationUpdate = [packet.args firstObject];
        NSString *driverUUID = [locationUpdate objectForKey:PARAM_DRIVER_UUID];
        NSNumber *lat = [locationUpdate objectForKey:@"lat"];
        NSNumber *lng = [locationUpdate objectForKey:@"lng"];
        
        GGDriver *driver = [self.activeDrivers objectForKey:driverUUID];
        [driver updateLocationToLatitude:lat.doubleValue longtitude:lng.doubleValue];
        
        id existingDelegate = [self.driverDelegates objectForKey:driverUUID];
        if (existingDelegate) {
            [existingDelegate driverLocationDidChangedWithDriver:driver];
            
        }
    } else if ([packet.name isEqualToString:EVENT_DRIVER_ACTIVITY_CHANGED]) {
        //activity change
        
    } else if ([packet.name isEqualToString:EVENT_WAY_POINT_ETA_UPDATE]) {
        NSDictionary *etaUpdate = [packet.args firstObject];
        NSNumber *wpid = [etaUpdate objectForKey:@"way_point_id"];
        NSString *eta = [etaUpdate objectForKey:@"eta"];
        NSDate *etaToDate = [self dateFromString:eta];
        id existingDelegate = [self.waypointDelegates objectForKey:wpid];
        if (existingDelegate) {
            [existingDelegate waypointDidUpdatedWaypointId:wpid eta:etaToDate];
            
        }
    } else if ([packet.name isEqualToString:EVENT_WAY_POINT_ARRIVED]) {
        NSDictionary *waypointArrived = [packet.args firstObject];
        NSNumber *wpid = [waypointArrived objectForKey:@"way_point_id"];
        id existingDelegate = [self.waypointDelegates objectForKey:wpid];
        if (existingDelegate) {
            [existingDelegate waypointDidArrivedWaypointId:wpid];
            
        }
        
    } else if ([packet.name isEqualToString:EVENT_WAY_POINT_DONE]) {
        NSDictionary *waypointDone = [packet.args firstObject];
        NSNumber *wpid = [waypointDone objectForKey:@"way_point_id"];
        id existingDelegate = [self.waypointDelegates objectForKey:wpid];
        if (existingDelegate) {
            [existingDelegate waypointDidArrivedWaypointId:wpid];
            
        }
    }
}

- (void) socketIO:(SocketIO *)socket didSendMessage:(SocketIOPacket *)packet {
    NSLog(@"Packet sent [%@]", packet.data);
    
}

- (void) socketIO:(SocketIO *)socket onError:(NSError *)error {
    NSLog(@"Send error %@", error);
    
}

#pragma mark - Track Requests

- (void)startWatchingOrderWithUUID:(NSString *)uuid delegate:(id <OrderDelegate>)delegate {
   
    if (uuid) {
        self.doMonitoringOrders = YES;
        id existingDelegate = [self.orderDelegates objectForKey:uuid];
        
        GGOrder *order = [[GGOrder alloc] initOrderWithUUID:uuid atStatus:OrderStatusCreated];
        
        if (!existingDelegate) {
            @synchronized(self) {
                [self.orderDelegates setObject:delegate forKey:uuid];
                
            }
            [self sendWatchOrderWithOrderUUID:uuid completionHandler:^(BOOL success, NSError *error) {
                if (!success) {
                    id delegateToRemove = [self.orderDelegates objectForKey:uuid];
                    @synchronized(self) {
                        [self.orderDelegates removeObjectForKey:uuid];
                        
                    }
                    [delegateToRemove watchOrderFailForOrder:order error:error];
                    if (![self.orderDelegates count]) {
                        self.doMonitoringOrders = NO;
                        
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
        self.doMonitoringDrivers = YES;
        
        GGDriver *driver = [[GGDriver alloc] initWithUUID:uuid];
        
        id existingDelegate = [self.driverDelegates objectForKey:uuid];
        if (!existingDelegate) {
            @synchronized(self) {
                [self.driverDelegates setObject:delegate forKey:uuid];
                
            }
            [self sendWatchDriverWithDriverUUID:uuid shareUUID:(NSString *)shareUUID completionHandler:^(BOOL success, NSError *error) {
                if (!success) {
                    id delegateToRemove = [self.driverDelegates objectForKey:uuid];
                    @synchronized(self) {
                        [self.driverDelegates removeObjectForKey:uuid];
                        
                    }
                    [delegateToRemove watchDriverFailedForDriver:driver error:error];
                    if (![self.driverDelegates count]) {
                        self.doMonitoringDrivers = NO;
                        
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
        self.doMonitoringWaypoints = YES;
        id existingDelegate = [self.waypointDelegates objectForKey:waypointId];
        if (!existingDelegate) {
            @synchronized(self) {
                [self.waypointDelegates setObject:delegate forKey:waypointId];
                
            }
            [self sendWatchWaypointWithWaypointId:waypointId completionHandler:^(BOOL success, NSError *error) {
                if (!success) {
                    id delegateToRemove = [self.waypointDelegates objectForKey:waypointId];
                    @synchronized(self) {
                        [self.waypointDelegates removeObjectForKey:waypointId];
                        
                    }
                    [delegateToRemove watchWaypointFailedForWaypointId:waypointId error:error];
                    if (![self.waypointDelegates count]) {
                        self.doMonitoringWaypoints = NO;
                        
                    }
                }
            }];
        }
    }else{
        [NSException raise:@"Invalid waypoint ID" format:@"Waypoint ID can not be nil"];
    }
    
    
}

- (void)stopWatchingOrderWithUUID:(NSString *)uuid {
    id existingDelegate = [self.orderDelegates objectForKey:uuid];
    if (existingDelegate) {
        @synchronized(self) {
            [self.orderDelegates removeObjectForKey:uuid];
            
        }
    }
}

- (void)stopWatchingDriverWithUUID:(NSString *)uuid shareUUID:(NSString *)shareUUID {
    id existingDelegate = [self.driverDelegates objectForKey:uuid];
    if (existingDelegate) {
        @synchronized(self) {
            [self.driverDelegates removeObjectForKey:uuid];
            
        }
    }
}

- (void)stopWatchingWaypointWithWaypointId:(NSNumber *)waypointId {
    id existingDelegate = [self.waypointDelegates objectForKey:waypointId];
    if (existingDelegate) {
        @synchronized(self) {
            [self.waypointDelegates removeObjectForKey:waypointId];
            
        }
    }
}

- (void)sendWatchOrderWithOrderUUID:(NSString *)uuid completionHandler:(void (^)(BOOL success, NSError *error))completionHandler {
    NSLog(@"watch order");
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   uuid, @"order_uuid",
                                   nil];
    [self sendEventWithName:@"watch order" params:params completionHandler:completionHandler];
    
}

- (void)sendWatchDriverWithDriverUUID:(NSString *)uuid shareUUID:(NSString *)shareUUID completionHandler:(void (^)(BOOL success, NSError *error))completionHandler {
    NSLog(@"watch driver");
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   uuid, @"driver_uuid",
                                   shareUUID, @"share_uuid",
                                   nil];
    [self sendEventWithName:@"watch driver" params:params completionHandler:completionHandler];
    
}

- (void)sendWatchWaypointWithWaypointId:(NSNumber *)waypointId completionHandler:(void (^)(BOOL success, NSError *error))completionHandler {
    NSLog(@"watch waypoint");
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   waypointId, @"way_point_id",
                                   nil];
    [self sendEventWithName:@"watch way point" params:params completionHandler:completionHandler];
    
}


#pragma mark Getters

- (BOOL)isConnected {
    return self.connected;
    
}

- (BOOL)isWatchingOrders {
    return self.doMonitoringOrders;
    
}

- (BOOL)isWatchingOrderWithUUID:(NSString *)uuid {
    return ([self.orderDelegates objectForKey:uuid]) ? YES : NO;
    
}

- (BOOL)isWatchingDrivers {
    return self.doMonitoringDrivers;
    
}

- (BOOL)isWatchingDriverWithUUID:(NSString *)uuid {
    return ([self.driverDelegates objectForKey:uuid]) ? YES : NO;
    
}

- (BOOL)isWatchingWaypoints {
    return self.doMonitoringWaypoints;
    
}

- (BOOL)isWatchingWaypointWithWaypointId:(NSNumber *)waypointId {
    return ([self.waypointDelegates objectForKey:waypointId]) ? YES : NO;
    
}


@end
