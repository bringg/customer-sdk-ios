//
//  BringgClient.m
//  BringgTracking
//
//  Created by Matan on 13/02/2017.
//  Copyright © 2017 Bringg. All rights reserved.
//

#import "BringgTrackingClient.h"
#import "BringgTrackingClient_Private.h"
#import "GGHTTPClientManager.h"
#import "GGHTTPClientManager_Private.h"
#import "GGTrackerManager.h"   
#import "GGTrackerManager_Private.h"
#import "GGOrder.h"
#import "GGCustomer.h"
#import "GGSharedLocation.h"
#import "GGRating.h"
#import "BringgPrivates.h"
#import "NSString+Extensions.h"
#import "GGNetworkUtils.h"

#define LOCAL_URL @"http://10.0.1.125"
#define USE_LOCAL NO

@interface BringgTrackingClient () <PrivateClientConnectionDelegate>

@end

@implementation BringgTrackingClient


+ (nonnull instancetype)clientWithDeveloperToken:(nonnull NSString *)developerToken connectionDelegate:(nonnull id<RealTimeDelegate>)delegate{
    
    static BringgTrackingClient *sharedObject = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        // init the client
        sharedObject = [[self alloc] initWithDevToken:developerToken connectionDelegate:delegate];
        
    });
    
    return sharedObject;
    
}

- (instancetype)initWithDevToken:(nonnull NSString *)devToken connectionDelegate:(nonnull id<RealTimeDelegate>)delegate{
   
    if (self = [super init]) {
        self.region = [self getRegionFromDevToken:devToken];
        self.useSecuredConnection = YES;
        
        if (USE_LOCAL == YES) {
            self.useSecuredConnection = NO;
        }
        
        // init the http manager and tracking manager
        [self setupHTTPManagerWithDevToken:devToken securedConnection:self.useSecuredConnection];

        [self setupTrackerManagerWithDevToken:devToken httpManager:self.httpManager realtimeDelegate:delegate];
        
    }
    
    return self;
}

- (void)setupHTTPManagerWithDevToken:(nonnull NSString *)devToken securedConnection:(BOOL)useSecuredConnection{
    self.httpManager = [[GGHTTPClientManager alloc] initWithDeveloperToken:devToken];;
    [self.httpManager useSecuredConnection:useSecuredConnection];
    
    [self.httpManager setConnectionDelegate:self];
}


- (void)setupTrackerManagerWithDevToken:(nonnull NSString *)devToken httpManager:(nonnull GGHTTPClientManager *)httpManager realtimeDelegate:(nonnull id<RealTimeDelegate>)delegate {
    
    self.trackerManager = [[GGTrackerManager alloc] initWithDeveloperToken:devToken HTTPManager:httpManager realTimeDelegate:delegate];
    
    [self.trackerManager setConnectionDelegate:self];
    
    self.trackerManager.logsEnabled = NO;
}
- (GGRegion)getRegionFromDevToken:(NSString*)devToken {
    if ([devToken hasPrefix:@"ew1_"]) {
        return GGRegionEuWest1;
    }
    return GGRegionUsEast1;
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

- (BOOL)isConnected{
    return [self.trackerManager isConnected];
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
                         shareUUID:(NSString *_Nonnull)shareUUID
                          delegate:(id <OrderDelegate> _Nullable)delegate{
    
    NSLog(@"Trying to start watching on order uuid: %@, shared %@, with delegate %@", uuid, shareUUID, delegate);
    
    if ([NSString isStringEmpty:uuid] || [NSString isStringEmpty:shareUUID]) {
        [NSException raise:@"Invalid params" format:@"Order and Share UUIDs can not be empty"];
        
        return;
    }
    
    [self.trackerManager startWatchingOrderWithOrderUUID:uuid accessControlParamKey:PARAM_SHARE_UUID accessControlParamValue:shareUUID delegate:delegate];
    

}

- (void)startWatchingOrderWithUUID:(NSString *_Nonnull)uuid
               customerAccessToken:(NSString *_Nonnull)customerAccessToken
                          delegate:(id <OrderDelegate> _Nullable)delegate{
 
    NSLog(@"Trying to start watching using customer token on order uuid: %@, with delegate %@", uuid, delegate);
    
    
    if ([NSString isStringEmpty:uuid] || [NSString isStringEmpty:customerAccessToken]) {
        [NSException raise:@"Invalid params" format:@"Order and customer token can not be empty"];
        
        return;
    }

     [self.trackerManager startWatchingOrderWithOrderUUID:uuid accessControlParamKey:PARAM_ACCESS_TOKEN accessControlParamValue:customerAccessToken delegate:delegate];
    
}


- (void)startWatchingOrderWithShareUUID:(NSString *_Nonnull)shareUUID
                    customerAccessToken:(NSString *_Nonnull)customerAccessToken
                               delegate:(id <OrderDelegate> _Nullable)delegate{
    
     NSLog(@"Trying to start watching using customer token and share uuid: %@, with delegate %@", shareUUID, delegate);
    
    if ([NSString isStringEmpty:shareUUID] || [NSString isStringEmpty:customerAccessToken]) {
        [NSException raise:@"Invalid params" format:@"Share UUID and customer token can not be empty"];
        
        return;
    }
    
    [self.trackerManager startWatchingOrderWithShareUUID:shareUUID accessControlParamKey:PARAM_ACCESS_TOKEN accessControlParamValue:customerAccessToken delegate:delegate];

}


- (void)startWatchingDriverWithUUID:(NSString *_Nonnull)uuid
                          shareUUID:(NSString *_Nonnull)shareUUID
                           delegate:(id <DriverDelegate> _Nullable)delegate{
    
    NSLog(@"Trying to start watching on driver uuid: %@, with delegate %@", uuid, delegate);
    
    
    if ([NSString isStringEmpty:uuid] || [NSString isStringEmpty:shareUUID]) {
        [NSException raise:@"Invalid params" format:@"driver and shared uuid can not be empty"];
        
        return;
    }
    
    [self.trackerManager startWatchingDriverWithUUID:uuid accessControlParamKey:PARAM_SHARE_UUID accessControlParamValue:shareUUID delegate:delegate];
}


- (void)startWatchingCustomerDriverWithUUID:(NSString *_Nonnull)uuid
                                   delegate:(id <DriverDelegate> _Nullable)delegate{
    
    
    NSLog(@"Trying to start watching using customer token on driver uuid: %@, with delegate %@", uuid, delegate);
    
    
    if ([NSString isStringEmpty:uuid]) {
        [NSException raise:@"Invalid params" format:@"driver uuid can not be empty"];
        
        return;
    }
    
    NSString *customerAccessToken = [[self signedInCustomer] customerToken];
    
    if (![NSString isStringEmpty:customerAccessToken]) {
         [self.trackerManager startWatchingDriverWithUUID:uuid accessControlParamKey:PARAM_ACCESS_TOKEN accessControlParamValue:customerAccessToken delegate:delegate];
    }else{
        // if we can find a shared uuid for this driver use it to start watching. if not call the watch failed on the delegate
        NSString *shareUUID = [self shareUUIDForDriverWithUUID:uuid];
        
        if (![NSString isStringEmpty:shareUUID]) {
            
             [self.trackerManager startWatchingDriverWithUUID:uuid accessControlParamKey:PARAM_SHARE_UUID accessControlParamValue:shareUUID delegate:delegate];
        }else if ([delegate respondsToSelector:@selector(watchDriverFailedForDriver:error:)]){
            
            NSError *error = [NSError errorWithDomain:kSDKDomainData code:0 userInfo:@{NSLocalizedDescriptionKey: @"cant watch driver without valid customer"}];
            
            [delegate watchDriverFailedForDriver:nil error:error];
        }
    }

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

- (void)getMaskedNumberWithShareUUID:(NSString *_Nonnull)shareUUID
                                       forPhoneNumber:(NSString*_Nonnull)originalPhoneNumber
  withCompletionHandler:(nullable GGMaskedPhoneNumberResponseHandler)completionHandler {
    
    [self.trackerManager sendMaskedNumberRequestWithShareUUID:shareUUID
                                                  forPhoneNumber:originalPhoneNumber
                                           withCompletionHandler:completionHandler];
}

- (void)rateOrder:(nonnull GGOrder *)order
       withRating:(int)rating
completionHandler:(nullable GGRatingResponseHandler)completionHandler{
    
    // before rating we must  correct shared location object (if we dont - we need to get one
    if (order.sharedLocation && order.sharedLocation.ratingURL &&  order.sharedLocation.rating.token) {
        

         [self.httpManager rate:rating
                      withToken:order.sharedLocation.rating.token
                      ratingURL:order.sharedLocation.ratingURL
                         extras:nil
          withCompletionHandler:completionHandler];
        
    }else if (order.sharedLocationUUID){
        

        // get an updated shared location object for order
        [self.httpManager getOrderSharedLocationByUUID:order.sharedLocationUUID extras:nil withCompletionHandler:^(BOOL success, NSDictionary * _Nullable response, GGSharedLocation * _Nullable sharedLocation, NSError * _Nullable error) {
            //
            if (success && sharedLocation) {
                
                [self.httpManager rate:rating
                             withToken:sharedLocation.rating.token
                             ratingURL:sharedLocation.ratingURL
                                extras:nil
                 withCompletionHandler:completionHandler];
            }else{
                if (completionHandler) {
                    completionHandler(NO, response, nil, error);
                }
            }
            
        }];
        
        
    }else{
        // we dont have enough data to do rating
        if (completionHandler) {
            completionHandler(NO, nil, nil, [NSError errorWithDomain:kSDKDomainData code:GGErrorTypeActionNotAllowed userInfo:@{NSLocalizedDescriptionKey:@"can not rate order without valid shared location data"}]);
        }
        
        
    }
    
   
}

- (void)stopWatchingOrderWithUUID:(NSString *_Nonnull)uuid{
    [self.trackerManager stopWatchingOrderWithUUID:uuid];
}


- (void)stopWatchingAllOrders{
    [self.trackerManager stopWatchingAllOrders];
}


- (void)stopWatchingDriverWithUUID:(NSString *_Nonnull)uuid{
    
    [self.trackerManager stopWatchingDriverWithUUID:uuid];
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

- (BOOL)isWatchingDriverWithUUID:(NSString *_Nonnull)uuid{
    
    return [self.trackerManager isWatchingDriverWithUUID:uuid];
}

- (BOOL)isWatchingWaypointWithWaypointId:(NSNumber *_Nonnull)waypointId andOrderUUID:(NSString * _Nonnull)orderUUID{
    
    return [self.trackerManager isWatchingWaypointWithWaypointId:waypointId andOrderUUID:orderUUID];
}

- (nullable GGOrder *)orderWithUUID:(nonnull NSString *)uuid{
    return [self.trackerManager orderWithUUID:uuid];
}

- (nullable GGDriver *)driverWithUUID:(nonnull NSString *)uuid{
    return [self.trackerManager driverWithUUID:uuid];
}

- (nullable NSString *)shareUUIDForDriverWithUUID:(nonnull NSString*)driverUUID{
    return [self.trackerManager shareUUIDforDriverUUID:driverUUID];
}

//MARK: -- URLs Delegate

- (NSString *)hostDomainForClientManager:(GGHTTPClientManager *)clientManager {
    NSString *hostDomainURL = [GGNetworkUtils bringgAPIUrlByRegion:self.region];
        //Local
    if (USE_LOCAL == YES) {
        hostDomainURL = [NSString stringWithFormat:@"%@:3000", LOCAL_URL];
    }
    return hostDomainURL;
}

- (NSString *)hostDomainForTrackerManager:(GGTrackerManager *)trackerManager {
    NSString *realtimeURL = [GGNetworkUtils bringgRealtimeUrlByRegion:self.region];
    //Local
    if (USE_LOCAL == YES) {
        
        realtimeURL = [NSString stringWithFormat:@"%@:3030", LOCAL_URL];
    }
    return realtimeURL;
}

@end
