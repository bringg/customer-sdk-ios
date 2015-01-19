//
//  BringgTracker.m
//  BringgTracking
//
//  Created by Ilya Kalinin on 12/16/14.
//  Copyright (c) 2014 Ilya Kalinin. All rights reserved.
//

#import "BringgTracker.h"
#import "SocketIOPacket.h"
#import "Reachability.h"

#define DEFINE_SHARED_INSTANCE_USING_BLOCK(block) \
static dispatch_once_t pred = 0; \
__strong static id _sharedObject = nil; \
dispatch_once(&pred, ^{ \
_sharedObject = block(); \
}); \
return _sharedObject;

#define BRINGG_REALTIME_SERVER @"realtime.bringg.com"

typedef NS_ENUM(NSInteger, OrderStatus) {
    OrderStatusCreated = 0,
    OrderStatusAssigned = 1,
    OrderStatusOnTheWay = 2,
    OrderStatusCheckedIn = 3,
    OrderStatusCheckedOut = 4,
    OrderStatusAccepted = 6,
    OrderStatusCancelled = 7,
    OrderStatusRejected = 8
    
};

typedef void (^CompletionBlock)(BOOL success, NSError *error);

@interface BringgTracker ()

@property (nonatomic, weak) id <RealTimeDelegate> delegate;
@property (nonatomic, strong) NSMutableDictionary *orderDelegates;
@property (nonatomic, strong) NSMutableDictionary *driverDelegates;

@property (nonatomic, assign) BOOL connected;
@property (nonatomic, assign) BOOL doConnect;
@property (nonatomic, assign) BOOL doMonitoringOrders;
@property (nonatomic, assign) BOOL doMonitoringDrivers;

@property (nonatomic,strong) SocketIO *socketIO;
@property (nonatomic, copy) CompletionBlock socketIOConnectedBlock;
@property (nonatomic, strong) Reachability* reachability;

@end

@implementation BringgTracker

+ (id)sharedInstance {
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
        
    });
}

- (id)init {
    if (self = [super init]) {
        self.orderDelegates = [[NSMutableDictionary alloc] init];
        self.driverDelegates = [[NSMutableDictionary alloc] init];
        self.socketIO = [[SocketIO alloc] initWithDelegate:self];
        
        //[self configureReachability];
        
    }
    return self;
    
}

- (void)dealloc {
    
}

#pragma mark - Helper

- (void)configureReachability {
    Reachability* reachability = [Reachability reachabilityWithHostname:@"www.google.com"];
    self.reachability = reachability;
    reachability.reachableBlock = ^(Reachability*reach) {
        NSLog(@"Reachable!");
        if (![self.socketIO isConnected] && ![self.socketIO isConnecting]) {
            if (self.doConnect) {
                [self connect];
                
            }
            
        }
    };
    reachability.unreachableBlock = ^(Reachability*reach) {
        NSLog(@"Unreachable!");
        
    };
    [reachability startNotifier];
    
}

#pragma mark - Setters

- (void)setConnectionDelegate:(id <RealTimeDelegate>)delegate {
    self.delegate = delegate;
    
}

#pragma mark - Status

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

#pragma mark - Actions

- (void)connect {
    NSLog(@"Connecting!");
    [self webSocketConnectWithCompletionHandler:^(BOOL success, NSError *error) {
        self.connected = success;
        NSLog(@"Connected: %d ", success);
        if (success) {
            [self.delegate trackerDidConnected];
            
        } else {
            [self.delegate trackerDidDisconnectedWithError:error];
            
        }
    }];
}

- (void)disconnect {
    [self webSocketDisconnect];
    
}

- (void)startWatchingOrederWithUUID:(NSString *)uuid shareUUID:(NSString *)shareUUID delegate:(id <OrderDelegate>)delegate {
    self.doMonitoringOrders = YES;
    id existingDelegate = [self.orderDelegates objectForKey:uuid];
    if (!existingDelegate) {
        @synchronized(self) {
            [self.orderDelegates setObject:delegate forKey:uuid];
            
        }
        [self sendWatchOrderWithOrderUUID:uuid shareUUID:shareUUID completionHandler:^(BOOL success, NSError *error) {
            if (!success) {
                id delegateToRemove = [self.orderDelegates objectForKey:uuid];
                @synchronized(self) {
                    [self.orderDelegates removeObjectForKey:uuid];
                    
                }
                [delegateToRemove watchOrderFailedForOrederWithUUID:uuid error:error];
                if (![self.orderDelegates count]) {
                    self.doMonitoringOrders = NO;
                    
                }
            }
        }];
    }
}

- (void)stopWatchingOrderWithUUID:(NSString *)uuid shareUUID:(NSString *)shareUUID {
    id existingDelegate = [self.orderDelegates objectForKey:uuid];
    if (existingDelegate) {
        @synchronized(self) {
            [self.orderDelegates removeObjectForKey:uuid];
            
        }
    }
}

- (void)startWatchingDriverWithUUID:(NSString *)uuid shareUUID:(NSString *)shareUUID delegate:(id <DriverDelegate>)delegate {
    self.doMonitoringDrivers = YES;
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
                [delegateToRemove watchDriverFailedForDriverWithUUID:uuid error:error];
                if (![self.driverDelegates count]) {
                    self.doMonitoringDrivers = NO;
                    
                }
            }
        }];
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

#pragma mark - SocketIO methods

- (void)webSocketConnectWithCompletionHandler:(void (^)(BOOL success, NSError *error))completionHandler {
    NSString *server = BRINGG_REALTIME_SERVER;
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
                           withTransport:SocketIOTransportWebSocket];
            
        } else {
            [self.socketIO connectToHost:server
                                  onPort:0
                           withTransport:SocketIOTransportXHRPolling];
            
        }
        self.socketIOConnectedBlock = completionHandler;
        
    }
}

- (void)webSocketDisconnect {
    NSLog(@"websocket disconnected");
    [self.socketIO disconnect];
    self.connected = NO;
    
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

- (void)sendWatchOrderWithOrderUUID:(NSString *)uuid shareUUID:(NSString *)shareUUID completionHandler:(void (^)(BOOL success, NSError *error))completionHandler {
    NSLog(@"watch order");
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   uuid, @"order_uuid",
                                   shareUUID, @"share_uuid",
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
        [self.delegate trackerDidDisconnectedWithError:error];
        
    }
    //    if (self.reachability.isReachable && self.doConnect) {
    //        //OVLogInfo(@"websocket trying to reconnect");
    //        [self connect];
    //
    //    }
}

- (void) socketIO:(SocketIO *)socket didReceiveMessage:(SocketIOPacket *)packet {
    NSLog(@"Received packet [%@]", packet.data);
    
}

- (void) socketIO:(SocketIO *)socket didReceiveJSON:(SocketIOPacket *)packet {
    NSLog(@"Received packet [%@]", packet.data);
    
}

- (void) socketIO:(SocketIO *)socket didReceiveEvent:(SocketIOPacket *)packet {
    NSLog(@"Received packet [%@]", packet.data);
    if ([packet.name isEqualToString:@"order update"]) {
        NSDictionary *orderUpdate = [packet.args firstObject];
        NSString *orderUUID = [orderUpdate objectForKey:@"uuid"];
        NSString *driverUUID = [orderUpdate objectForKey:@"driver_uuid"];
        NSNumber *orderStatus = [orderUpdate objectForKey:@"status"];
        id existingDelegate = [self.orderDelegates objectForKey:orderUUID];
        if (existingDelegate) {
            switch ([orderStatus integerValue]) {
                case OrderStatusAssigned:
                    [existingDelegate orderDidAssignedWithOrderUUID:orderUUID driverUUID:driverUUID];
                    break;
                case OrderStatusAccepted:
                    [existingDelegate orderDidAcceptedOrderUUID:orderUUID];
                    break;
                case OrderStatusOnTheWay:
                    [existingDelegate orderDidStartedOrderUUID:orderUUID];
                    break;
                case OrderStatusCheckedIn:
                    [existingDelegate orderDidArrivedOrderUUID:orderUUID];
                    break;
                case OrderStatusCheckedOut:
                    [existingDelegate orderDidFinishedOrderUUID:orderUUID];
                    break;
                case OrderStatusCancelled:
                case OrderStatusRejected:
                    [existingDelegate orderDidCancelledOrderUUID:orderUUID];
                    break;
                default:
                    break;
            }
            
        }
    }
    if ([packet.name isEqualToString:@"order done"]) {
        NSDictionary *orderDone = [packet.args firstObject];
        NSString *orderUUID = [orderDone objectForKey:@"uuid"];
        id existingDelegate = [self.orderDelegates objectForKey:orderUUID];
        if (existingDelegate) {
            [existingDelegate orderDidFinishedOrderUUID:orderUUID];
            
        }
    }
    if ([packet.name isEqualToString:@"location update"]) {
        NSDictionary *locationUpdate = [packet.args firstObject];
        NSString *driverUUID = [locationUpdate objectForKey:@"uuid"];
        NSNumber *lat = [locationUpdate objectForKey:@"lat"];
        NSNumber *lng = [locationUpdate objectForKey:@"lng"];
        id existingDelegate = [self.driverDelegates objectForKey:driverUUID];
        if (existingDelegate) {
            [existingDelegate driverLocationDidChangedWithDriverUUID:driverUUID lat:lat lng:lng];
            
        }
    }
}

- (void) socketIO:(SocketIO *)socket didSendMessage:(SocketIOPacket *)packet {
    NSLog(@"Packet sent [%@]", packet.data);
    
}

- (void) socketIO:(SocketIO *)socket onError:(NSError *)error {
    NSLog(@"Send error %@", error);
    
}

@end
