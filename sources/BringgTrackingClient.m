//
//  BringgClient.m
//  BringgTracking
//
//  Created by Matan on 13/02/2017.
//  Copyright © 2017 Bringg. All rights reserved.
//

#import "BringgTrackingClient.h"
#import "GGHTTPClientManager.h"
#import "GGTrackerManager.h"    
#import "GGOrder.h"
#import "GGCustomer.h"



@interface BringgTrackingClient ()


@property (nullable, nonatomic, strong) NSString *developerToken;
@property (nonnull, nonatomic, strong) GGTrackerManager *trackerManager;
@property (nonnull, nonatomic, strong) GGHTTPClientManager *httpManager;

@property (nonatomic, weak) id<RealTimeDelegate> realTimeDelegate;

@property (nonatomic) BOOL useSecuredConnection;
@property (nonatomic) BOOL shouldAutoWatchDriver;
@property (nonatomic) BOOL shouldAutoWatchOrder;


- (id)initWithDevToken:(nullable NSString *)devToken connectionDelegate:(nonnull id<RealTimeDelegate>)delegate;

@end

@implementation BringgTrackingClient


+ (nonnull instancetype)clientWithDeveloperToken:(NSString *_Nullable)developerToken connectionDelegate:(nonnull id<RealTimeDelegate>)delegate{
    
    static BringgTrackingClient *sharedObject = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        // init the client
        sharedObject = [[self alloc] initWithDevToken:developerToken connectionDelegate:delegate];
        
    });
    
    return sharedObject;
}

- (id)initWithDevToken:(nullable NSString *)devToken connectionDelegate:(nonnull id<RealTimeDelegate>)delegate{
   
    if (self = [super init]) {
        
        self.useSecuredConnection = YES;
        
        // init the http manager and tracking manager
        self.httpManager = [GGHTTPClientManager managerWithDeveloperToken:devToken];
        [self.httpManager useSecuredConnection:self.useSecuredConnection];
        
        self.trackerManager = [GGTrackerManager tracker];
        [self.trackerManager setDeveloperToken:devToken];
        [self.trackerManager setHTTPManager:self.httpManager];
        [self.trackerManager setRealTimeDelegate:delegate];
        self.trackerManager.logsEnabled = NO;
    }
    
    return self;
}

//MARK: -- Connection

- (void)connect{
    if (![self.trackerManager isConnected]) {
        [self.trackerManager connectUsingSecureConnection:self.useSecuredConnection];
        
    }
}

 
- (void)disconnect{
    if ([self.trackerManager isConnected]) {
        [self.trackerManager disconnect];
    }
}

- (void)signInWithName:(NSString * _Nullable)name
                 phone:(NSString * _Nullable)phone
                 email:(NSString * _Nullable)email
              password:(NSString * _Nullable)password
      confirmationCode:(NSString * _Nullable)confirmationCode
            merchantId:(NSString * _Nonnull)merchantId
                extras:(NSDictionary * _Nullable)extras
     completionHandler:(nullable GGCustomerResponseHandler)completionHandler{
    
    [self.httpManager signInWithName:name
                               phone:phone
                               email:email
                            password:password
                    confirmationCode:confirmationCode
                          merchantId:merchantId
                              extras:extras
                   completionHandler:^(BOOL success, NSDictionary * _Nullable response, GGCustomer * _Nullable customer, NSError * _Nullable error) {
                       //
                       
                       // after sign in we assign the customer signed in to the tracking manager
                       if (customer) {
                           [self.trackerManager setCustomer:customer];
                       }
                       
                       if (completionHandler) {
                           completionHandler(success, response, customer, error);
                       }
                   }];
}

- (BOOL)isSignedIn{
    return [self.httpManager isSignedIn];
}

- (nullable GGCustomer *)signedInCustomer{
    return [self.httpManager signedInCustomer];
}

//MARK: -- Tracking


- (void)startWatchingOrderWithUUID:(NSString *_Nonnull)uuid
                        sharedUUID:(NSString *_Nullable)shareduuid
                          delegate:(id <OrderDelegate> _Nullable)delegate{
    
    [self.trackerManager startWatchingOrderWithUUID:uuid sharedUUID:shareduuid delegate:delegate];
}



- (void)startWatchingDriverWithUUID:(NSString *_Nonnull)uuid
                          shareUUID:(NSString *_Nonnull)shareUUID
                           delegate:(id <DriverDelegate> _Nullable)delegate{
    
    [self.trackerManager startWatchingDriverWithUUID:uuid shareUUID:shareUUID delegate:delegate];
}


- (void)startWatchingWaypointWithWaypointId:(NSNumber *_Nonnull)waypointId
                               andOrderUUID:(NSString * _Nonnull)orderUUID
                                   delegate:(id <WaypointDelegate> _Nullable)delegate{
    
    [self.trackerManager startWatchingWaypointWithWaypointId:waypointId andOrderUUID:orderUUID delegate:delegate];
    
}

- (void)sendFindMeRequestForOrderWithUUID:(NSString *_Nonnull)uuid
                                 latitude:(double)lat
                                longitude:(double)lng
                    withCompletionHandler:(nullable GGActionResponseHandler)completionHandler{
    
    [self.trackerManager sendFindMeRequestForOrderWithUUID:uuid latitude:lat longitude:lng withCompletionHandler:completionHandler];
}

- (void)rate:(int)rating
   withToken:(NSString * _Nonnull)ratingToken
   ratingURL:(NSString *_Nonnull)ratingURL
      extras:(NSDictionary * _Nullable)extras
withCompletionHandler:(nullable GGRatingResponseHandler)completionHandler{
    
    [self.httpManager rate:rating withToken:ratingToken ratingURL:ratingURL extras:extras withCompletionHandler:completionHandler];
}

- (void)stopWatchingOrderWithUUID:(NSString *_Nonnull)uuid{
    [self.trackerManager stopWatchingOrderWithUUID:uuid];
}


- (void)stopWatchingAllOrders{
    [self.trackerManager stopWatchingAllOrders];
}


- (void)stopWatchingDriverWithUUID:(NSString *_Nonnull)uuid
                         shareUUID:(NSString *_Nullable)shareUUID{
    
    [self.trackerManager stopWatchingDriverWithUUID:uuid shareUUID:shareUUID];
}

- (void)stopWatchingAllDrivers{
    [self.trackerManager stopWatchingAllDrivers];
}


- (void)stopWatchingWaypointWithWaypointId:(NSNumber * _Nonnull)waypointId andOrderUUID:(NSString * _Nonnull)orderUUID{
    
    [self.trackerManager stopWatchingWaypointWithWaypointId:waypointId andOrderUUID:orderUUID];
}


- (void)stopWatchingAllWaypoints{
    [self.trackerManager stopWatchingAllWaypoints];
}

- (BOOL)isWatchingOrderWithUUID:(NSString *_Nonnull)uuid{
    
    return [self.trackerManager isWatchingOrderWithUUID:uuid];
}

- (BOOL)isWatchingDriverWithUUID:(NSString *_Nonnull)uuid andShareUUID:(NSString *_Nonnull)shareUUID{
    
    return [self.trackerManager isWatchingDriverWithUUID:uuid andShareUUID:shareUUID];
}

- (BOOL)isWatchingWaypointWithWaypointId:(NSNumber *_Nonnull)waypointId andOrderUUID:(NSString * _Nonnull)orderUUID{
    
    return [self.trackerManager isWatchingWaypointWithWaypointId:waypointId andOrderUUID:orderUUID];
}

- (nullable GGOrder *)orderWithUUID:(nonnull NSString *)uuid{
    return [self.trackerManager orderWithUUID:uuid];
}

@end
