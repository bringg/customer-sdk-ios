//
//  BringgTracker.m
//  BringgTracking
//
//  Created by Ilya Kalinin on 12/16/14.
//  Copyright (c) 2014 Ilya Kalinin. All rights reserved.
//

#import "BringgTracker.h"
#import "BringgCustomer_Private.h"
#import "SocketIOPacket.h"
#import "Reachability.h"
#import "AFNetworking.h"

#define DEFINE_SHARED_INSTANCE_USING_BLOCK(block) \
static dispatch_once_t pred = 0; \
__strong static id _sharedObject = nil; \
dispatch_once(&pred, ^{ \
_sharedObject = block(); \
}); \
return _sharedObject;

//#define BRINGG_REALTIME_SERVER @"realtime.bringg.com"
#define BTRealtimeServer @"realtime.bringg.com"

#define BTSuccessKey @"status"
#define BTStatusKey @"status"
#define BTMessageKey @"message"
#define BTNameKey @"name"
#define BTPhoneKey @"phone"
#define BTConfirmationCodeKey @"confirmation_code"
#define BTMerchantIdKey @"merchant_id"
#define BTDeveloperTokenKey @"developer_access_token"
#define BTCustomerTokenKey @"access_token"
#define BTCustomerPhoneKey @"phone"
#define BTRatingTokenKey @"rating_token"
#define BTTokenKey @"token"
#define BTRatingKey @"rating"

#define BTRESTSharedLocationPath @"/api/shared/"    //+uuid
#define BTRESTRatingPath @"/api/rate/"              //+uuid
#define BTRESTOrderPath @"/api/customer/task/"      //+id

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
@property (nonatomic, strong) NSMutableDictionary *waypointDelegates;

@property (nonatomic, assign) BOOL connected;
@property (nonatomic, assign) BOOL doConnect;
@property (nonatomic, assign) BOOL doMonitoringOrders;
@property (nonatomic, assign) BOOL doMonitoringDrivers;
@property (nonatomic, assign) BOOL doMonitoringWaypoints;

@property (nonatomic,strong) SocketIO *socketIO;
@property (nonatomic, copy) CompletionBlock socketIOConnectedBlock;
@property (nonatomic, strong) Reachability* reachability;

@property (nonatomic, strong) BringgCustomer *customer;
@property (nonatomic, strong) NSString *customerToken;
@property (nonatomic, strong) NSMutableArray *orders;
@property (nonatomic, strong) NSMutableArray *locations;

@property (nonatomic, strong) NSTimer *orderPollingTimer;
@property (nonatomic, strong) NSTimer *driverPollingTimer;

- (void)connect;

- (void)shareLocationWithShareUUID:(NSString *)uuid completionHandler:(void (^)(BOOL success, NSDictionary *JSON, NSError *error))completionHandler;
- (void)orderWithOrderID:(NSNumber *)orderID completionHandler:(void (^)(BOOL success, NSNumber *status, NSError *error))completionHandler;

- (void)startOrderPolling;
- (void)stopOrderPolling;
- (void)startDriverPolling;
- (void)stopDriverPolling;

- (void)orderPolling:(NSTimer *)timer;
- (void)driverPolling:(NSTimer *)timer;

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
        self.waypointDelegates = [[NSMutableDictionary alloc] init];
        self.socketIO = [[SocketIO alloc] initWithDelegate:self];
        
        //[self configureReachability];
        
    }
    return self;
    
}

- (void)dealloc {
    
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

- (void)setCustomer:(BringgCustomer *)customer {
    _customer = customer;
    
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

- (BOOL)isWatchingWaypoints {
    return self.doMonitoringWaypoints;
    
}

- (BOOL)isWatchingWaypointWithWaypointId:(NSNumber *)waypointId {
    return ([self.waypointDelegates objectForKey:waypointId]) ? YES : NO;
    
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

- (void)stopDriverPolling {
    [self.driverPollingTimer invalidate];
    self.driverPollingTimer = nil;
    
}

- (void)orderPolling:(NSTimer *)timer {
    
}

- (void)driverPolling:(NSTimer *)timer {
    [self shareLocationWithShareUUID:nil completionHandler:^(BOOL success, NSDictionary *JSON, NSError *error) {
        if (success) {
            
            
        }
    }];
}

#pragma mark - Actions

- (void)orderWithOrderID:(NSNumber *)orderID completionHandler:(void (^)(BOOL success, NSNumber *status, NSError *error))completionHandler {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:3];
    if (self.customer.developerToken) {
        [params setObject:self.customer.developerToken forKey:BTDeveloperTokenKey];
        
    }
    if (self.customer.customerToken) {
        [params setObject:self.customer.customerToken forKey:BTCustomerTokenKey];
        
    }
    if (self.customer.merchantId) {
        [params setObject:self.customer.merchantId forKey:BTMerchantIdKey];
        
    }
    if (self.customer.phone) {
        [params setObject:self.customer.phone forKey:BTCustomerPhoneKey];
        
    }
    //NSLog(@"order params %@", params);
    NSString *url = [NSString stringWithFormat:@"http://%@%@%@", BTRealtimeServer, BTRESTOrderPath, orderID];
    NSLog(@"%@", url);
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        BOOL result = NO;
        NSError *error;
        NSNumber *orderStatus;
        //NSLog(@"response order %@", responseObject);
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            id success = [responseObject objectForKey:BTSuccessKey];
            id status = [responseObject objectForKey:BTStatusKey];
            if ([success isKindOfClass:[NSString class]] &&
                [success isEqualToString:@"ok"] &&
                [status isKindOfClass:[NSNumber class]]) {
                result = YES;
                status = status;
                
            } else {
                id message = [responseObject objectForKey:BTMessageKey];
                if ([message isKindOfClass:[NSString class]]) {
                    error = [NSError errorWithDomain:@"BringgCustomer" code:0
                                            userInfo:@{NSLocalizedDescriptionKey: message,
                                                       NSLocalizedRecoverySuggestionErrorKey: message}];
                    
                } else {
                    error = [NSError errorWithDomain:@"BringgCustomer" code:0
                                            userInfo:@{NSLocalizedDescriptionKey: @"Undefined Error",
                                                       NSLocalizedRecoverySuggestionErrorKey: @"Undefined Error"}];
                    
                }
            }
        }
        if (completionHandler) {
            completionHandler(result, orderStatus, error);
            
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completionHandler) {
            completionHandler(NO, nil, error);
            
        }
    }];

}

- (void)shareLocationWithShareUUID:(NSString *)uuid completionHandler:(void (^)(BOOL success, NSDictionary *JSON, NSError *error))completionHandler {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:3];
    if (self.customer.developerToken) {
        [params setObject:self.customer.developerToken forKey:BTDeveloperTokenKey];
        
    }
    if (self.customerToken) {
        [params setObject:self.customerToken forKey:BTCustomerTokenKey];
        
    }
    if (self.customer.merchantId) {
        [params setObject:self.customer.merchantId forKey:BTMerchantIdKey];
        
    }
    //NSLog(@"shareLocation %@ %@ %@", self.customer.developerToken, self.customerToken, self.customer.merchantId);
    NSString *url = [NSString stringWithFormat:@"http://%@%@%@", BTRealtimeServer, BTRESTSharedLocationPath, uuid];
    NSLog(@"%@", url);
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        BOOL result = NO;
        NSError *error;
        //NSString *ratingToken;
        //NSLog(@"%@", responseObject);
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            id success = [responseObject objectForKey:BTSuccessKey];
            //id token = [responseObject objectForKey:BTRatingTokenKey];
            if ([success isKindOfClass:[NSString class]] &&
                [success isEqualToString:@"ok"] /*&&
                [token isKindOfClass:[NSString class]]*/) {
                result = YES;
                //ratingToken = token;
                
            } else {
                id message = [responseObject objectForKey:BTMessageKey];
                if ([message isKindOfClass:[NSString class]]) {
                    error = [NSError errorWithDomain:@"BringgCustomer" code:0
                                            userInfo:@{NSLocalizedDescriptionKey: message,
                                                       NSLocalizedRecoverySuggestionErrorKey: message}];
                    
                } else {
                    error = [NSError errorWithDomain:@"BringgCustomer" code:0
                                            userInfo:@{NSLocalizedDescriptionKey: @"Undefined Error",
                                                       NSLocalizedRecoverySuggestionErrorKey: @"Undefined Error"}];
                    
                }
            }
        }
        if (completionHandler) {
            completionHandler(result, responseObject, error);
            
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completionHandler) {
            completionHandler(NO, nil, error);
            
        }
    }];
}

- (void)rateWithRating:(NSUInteger)rating shareUUID:(NSString *)uuid completionHandler:(void (^)(BOOL success, NSError *error))completionHandler {
    [self shareLocationWithShareUUID:uuid completionHandler:^(BOOL success, NSDictionary *JSON, NSError *error) {
        if (success) {
            NSString *ratingToken = [JSON objectForKey:BTRatingTokenKey];
            NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:5];
            if (self.customer.developerToken) {
                [params setObject:self.customer.developerToken forKey:BTDeveloperTokenKey];
                
            }
            if (self.customerToken) {
                [params setObject:self.customerToken forKey:BTCustomerTokenKey];
                
            }
            if (self.customer.merchantId) {
                [params setObject:self.customer.merchantId forKey:BTMerchantIdKey];
                
            }
            if (ratingToken) {
                [params setObject:ratingToken forKey:BTTokenKey];
                
            }
            if (rating) {
                [params setObject:@(rating) forKey:BTRatingKey];
                
            }
            //NSLog(@"rate params %@", params);
            NSString *url = [NSString stringWithFormat:@"http://%@%@%@", BTRealtimeServer, BTRESTRatingPath, uuid];
            AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
            [manager setRequestSerializer:[AFHTTPRequestSerializer serializer]];
            [manager.requestSerializer setTimeoutInterval:90.0];
            
            [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
                BOOL result = NO;
                NSError *error;
                //NSLog(@"%@", responseObject);
                if ([responseObject isKindOfClass:[NSDictionary class]]) {
                    id success = [responseObject objectForKey:@"success"];
                    if ([success isKindOfClass:[NSNumber class]] &&
                        [success isEqualToNumber:@(true)]) {
                        result = YES;
                        
                    } else {
                        id message = [responseObject objectForKey:BTMessageKey];
                        if ([message isKindOfClass:[NSString class]]) {
                            error = [NSError errorWithDomain:@"BringgCustomer" code:0
                                                    userInfo:@{NSLocalizedDescriptionKey: message,
                                                               NSLocalizedRecoverySuggestionErrorKey: message}];
                            
                        } else {
                            error = [NSError errorWithDomain:@"BringgCustomer" code:0
                                                    userInfo:@{NSLocalizedDescriptionKey: @"Undefined Error",
                                                               NSLocalizedRecoverySuggestionErrorKey: @"Undefined Error"}];
                            
                        }
                    }
                }
                if (completionHandler) {
                    completionHandler(result, error);
                    
                }
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (completionHandler) {
                    completionHandler(NO, error);
                    
                }
            }];
        } else {
            if (completionHandler) {
                completionHandler(NO, error);
                
            }
        }
    }];
}

- (void)connectWithCustomerToken:(NSString *)customerToken {
    self.customerToken = customerToken;
    [self connect];
    
}

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

- (void)startWatchingOrderWithUUID:(NSString *)uuid delegate:(id <OrderDelegate>)delegate {
    if (uuid) {
        self.doMonitoringOrders = YES;
        id existingDelegate = [self.orderDelegates objectForKey:uuid];
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
                    [delegateToRemove watchOrderFailedForOrderWithUUID:uuid error:error];
                    if (![self.orderDelegates count]) {
                        self.doMonitoringOrders = NO;
                        
                    }
                }
            }];
        }
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

- (void)startWatchingDriverWithUUID:(NSString *)uuid shareUUID:(NSString *)shareUUID delegate:(id <DriverDelegate>)delegate {
    if (uuid && shareUUID) {
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
}

- (void)stopWatchingDriverWithUUID:(NSString *)uuid shareUUID:(NSString *)shareUUID {
    id existingDelegate = [self.driverDelegates objectForKey:uuid];
    if (existingDelegate) {
        @synchronized(self) {
            [self.driverDelegates removeObjectForKey:uuid];
            
        }
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

#pragma mark - SocketIO methods

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
                           /*withTransport:SocketIOTransportWebSocket*/];
            
        } else {
            [self.socketIO connectToHost:server
                                  onPort:0
                          /* withTransport:SocketIOTransportXHRPolling*/];
            
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
        //test get order method
//        NSNumber *orderID = [orderUpdate objectForKey:@"id"];
//        
//        [self orderWithOrderID:orderID completionHandler:^(BOOL success, NSNumber *status, NSError *error) {
//            NSLog(@"status %@, error %@", status, error);
//            
//        }];
        
        id existingDelegate = [self.orderDelegates objectForKey:orderUUID];
        if (existingDelegate) {
            switch ([orderStatus integerValue]) {
                case OrderStatusAssigned:
                    [existingDelegate orderDidAssignedWithOrderUUID:orderUUID driverUUID:driverUUID];
                    break;
                case OrderStatusAccepted:
                    [existingDelegate orderDidAcceptedOrderUUID:orderUUID driverUUID:driverUUID];
                    break;
                case OrderStatusOnTheWay:
                    [existingDelegate orderDidStartedOrderUUID:orderUUID driverUUID:driverUUID];
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
    } else if ([packet.name isEqualToString:@"order done"]) {
        NSDictionary *orderDone = [packet.args firstObject];
        NSString *orderUUID = [orderDone objectForKey:@"uuid"];
        id existingDelegate = [self.orderDelegates objectForKey:orderUUID];
        if (existingDelegate) {
            [existingDelegate orderDidFinishedOrderUUID:orderUUID];
            
        }
    } else if ([packet.name isEqualToString:@"location update"]) {
        NSDictionary *locationUpdate = [packet.args firstObject];
        NSString *driverUUID = [locationUpdate objectForKey:@"uuid"];
        NSNumber *lat = [locationUpdate objectForKey:@"lat"];
        NSNumber *lng = [locationUpdate objectForKey:@"lng"];
        id existingDelegate = [self.driverDelegates objectForKey:driverUUID];
        if (existingDelegate) {
            [existingDelegate driverLocationDidChangedWithDriverUUID:driverUUID lat:lat lng:lng];
            
        }
    } else if ([packet.name isEqualToString:@"activity change"]) {
        //activity change
        
    } else if ([packet.name isEqualToString:@"way point eta updated"]) {
        NSDictionary *etaUpdate = [packet.args firstObject];
        NSNumber *wpid = [etaUpdate objectForKey:@"way_point_id"];
        NSString *eta = [etaUpdate objectForKey:@"eta"];
        NSDate *etaToDate = [self dateFromString:eta];
        id existingDelegate = [self.waypointDelegates objectForKey:wpid];
        if (existingDelegate) {
            [existingDelegate waypointDidUpdatedWaypointId:wpid eta:etaToDate];
            
        }
    } else if ([packet.name isEqualToString:@"way point arrived"]) {
        NSDictionary *waypointArrived = [packet.args firstObject];
        NSNumber *wpid = [waypointArrived objectForKey:@"way_point_id"];
        id existingDelegate = [self.waypointDelegates objectForKey:wpid];
        if (existingDelegate) {
            [existingDelegate waypointDidArrivedWaypointId:wpid];
            
        }
        
    } else if ([packet.name isEqualToString:@"way point done"]) {
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

@end
