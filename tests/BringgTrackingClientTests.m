//
//  BringgTrackingTests.m
//  BringgTrackingTests
//
//  Created by Matan on 12/07/2016.
//  Copyright © 2016 Matan Poreh. All rights reserved.
//

#import <XCTest/XCTest.h>
#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>

#import "GGTestUtils.h"
#import "BringgTrackingClient.h"
#import "BringgTrackingClient_Private.h"
#import "GGHTTPClientManager.h"

#import "GGTrackerManager_Private.h"
#import "GGTrackerManager.h"
#import "GGSDKExceptionHandler.h"


#import "GGOrder.h"
#import "GGDriver.h"
#import "GGSharedLocation.h"
#import "GGWaypoint.h"
#import "GGCustomer.h"

#define TEST_DEV_TOKEN @"SOME_DEV_TOKEN"

@interface GGTestRealTimeMockDelegate : NSObject<OrderDelegate, DriverDelegate, RealTimeDelegate, WaypointDelegate>

@property (nullable, nonatomic, strong) GGOrder * lastUpdatedOrder;
@property (nullable, nonatomic, strong) GGDriver * lastUpdatedDriver;
@property (nullable, nonatomic, strong) NSNumber * lastUpdatedWaypointId;
@property (nullable, nonatomic, strong) NSError * lastOrderError;
@property (nullable, nonatomic, strong) NSError * lastDriverError;
@property (nullable, nonatomic, strong) NSError * lastWaypointError;

- (void)resetDelegate;

@end

@implementation GGTestRealTimeMockDelegate

- (void)resetDelegate{
    self.lastUpdatedOrder = nil;
    self.lastUpdatedDriver = nil;
    self.lastOrderError = nil;
    self.lastDriverError = nil;
}

- (void)trackerDidConnect{
    
}

-(void)trackerDidDisconnectWithError:(NSError *)error{
    
}

- (void)watchOrderSucceedForOrder:(GGOrder *)order{
     self.lastUpdatedOrder = order;
}

- (void)watchDriverSucceedForDriver:(GGDriver *)driver{
    self.lastUpdatedDriver = driver;
}


-(void)watchDriverFailedForDriver:(GGDriver *)driver error:(NSError *)error{
    self.lastUpdatedDriver = driver;
    self.lastDriverError = error;
}

-(void)watchOrderFailForOrder:(GGOrder *)order error:(NSError *)error{
    self.lastUpdatedOrder = order;
    self.lastOrderError = error;
}

- (void)orderDidAssignWithOrder:(GGOrder *)order withDriver:(GGDriver *)driver{
    self.lastUpdatedOrder = order;
    self.lastUpdatedDriver = driver;
}

- (void)orderDidAcceptWithOrder:(GGOrder *)order withDriver:(GGDriver *)driver{
    self.lastUpdatedOrder = order;
    self.lastUpdatedDriver = driver;
}

- (void)orderDidStartWithOrder:(GGOrder *)order withDriver:(GGDriver *)driver{
    self.lastUpdatedOrder = order;
    self.lastUpdatedDriver = driver;
}

- (void)watchWaypointFailedForWaypointId:(NSNumber *)waypointId error:(NSError *)error{
    
    self.lastUpdatedWaypointId = waypointId;
    self.lastWaypointError = error;
}

- (void)watchWaypointSucceededForWaypointId:(NSNumber *)waypointId waypoint:(GGWaypoint *)waypoint{
    self.lastUpdatedWaypointId = waypointId;
}

- (void)waypointDidUpdatedWaypointId:(nonnull NSNumber *)waypointId eta:(nullable NSDate *)eta{
    self.lastUpdatedWaypointId = waypointId;
}

@end

@interface GGRealTimeMontiorMockingClass : GGRealTimeMontior

@property (nonatomic, strong) NSDictionary *watchOrderResponseJSON;

@end

@implementation GGRealTimeMontiorMockingClass

- (void)sendWatchOrderWithAccessControlParamKey:(nonnull NSString *)accessControlParamKey
                        accessControlParamValue:(nonnull NSString *)accessControlParamValue
                    secondAccessControlParamKey:(nonnull NSString *)secondAccessControlParamKey
                  secondAccessControlParamValue:(nonnull NSString *)secondAccessControlParamValue
                              completionHandler:(nullable SocketResponseBlock)completionHandler{
    
    if (completionHandler) {
        
        BOOL success = [[self.watchOrderResponseJSON valueForKey:@"success"] boolValue];
        NSError *error;
        NSString *message = [self.watchOrderResponseJSON valueForKey:@"message"];
        if (message && !success) {
            NSNumber *rc = [self.watchOrderResponseJSON valueForKey:@"rc"] ?: @(-1);
            error = [NSError errorWithDomain:kSDKDomainResponse code:rc.integerValue userInfo:@{NSLocalizedDescriptionKey:  message}];
        }
        
        NSString *uuid;
        
        // check if one of the params is for order uuid
        if ([accessControlParamKey isEqualToString:PARAM_ORDER_UUID]) {
            uuid = accessControlParamValue;
        }else if ([secondAccessControlParamKey isEqualToString:PARAM_ORDER_UUID]) {
            uuid = secondAccessControlParamValue;
        }

        if (uuid) {
            id<OrderDelegate> existingDelegate = [self.orderDelegates objectForKey:uuid];
            
            if (existingDelegate) {
                if (success) {
                    if ([existingDelegate respondsToSelector:@selector(watchOrderSucceedForOrder:)]) {
                        [existingDelegate watchOrderSucceedForOrder:[self getOrderWithUUID:uuid]];
                    }
                    
                }else{
                    if ([existingDelegate respondsToSelector:@selector(watchOrderFailForOrder:error:)]) {
                         [existingDelegate watchOrderFailForOrder:[self getOrderWithUUID:uuid] error:error];
                    }
                   
                }
            }

        }
        
        
        completionHandler(success, self.watchOrderResponseJSON, error);
    }
    
}

- (void)sendWatchWaypointWithWaypointId:(NSNumber *)waypointId andOrderUUID:(NSString *)orderUUID completionHandler:(SocketResponseBlock)completionHandler{
    
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}


@end

@interface GGTrackerManagerMockClass : GGTrackerManager

@end

@implementation GGTrackerManagerMockClass

- (void)startWatchingOrderWithUUID:(NSString *_Nonnull)uuid
                        shareUUID:(NSString *_Nullable)shareUUID
                          delegate:(id <OrderDelegate> _Nullable)delegate{
    
    NSLog(@"SHOULD START WATCHING ORDER %@ with delegate %@", uuid, delegate);
    
    // uuid is invalid if empty
    if (!uuid || uuid.length == 0) {
        [NSException raise:@"Invalid UUID" format:@"order UUID can not be nil or empty"];
        return;
    }
    
}

- (void)startRESTWatchingOrderByOrderUUID:(NSString *)orderUUID accessControlParamKey:(NSString *)accessControlParamKey accessControlParamValue:(NSString *)accessControlParamValue withCompletionHandler:(GGOrderResponseHandler)completionHandler{
    
    // do nothing
    
}

@end

@interface GGHTTPClientManagerMockClass :  GGHTTPClientManager

@end

@implementation GGHTTPClientManagerMockClass

- (void)sendFindMeRequestWithFindMeConfiguration:(nonnull GGFindMe *)findmeConfig latitude:(double)lat longitude:(double)lng  withCompletionHandler:(nullable GGActionResponseHandler)completionHandler{
    
    // validate data
    if (!findmeConfig || ![findmeConfig canSendFindMe]) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:kSDKDomainData code:GGErrorTypeActionNotAllowed userInfo:@{NSLocalizedDescriptionKey:@"current find request is not allowed"}]);
        }
        
        return;
    }
    
    // validate coordinates
    if (![GGBringgUtils isValidCoordinatesWithLat:lat lng:lng]) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:kSDKDomainData code:GGErrorTypeActionNotAllowed userInfo:@{NSLocalizedDescriptionKey:@"coordinates values are invalid"}]);
        }
        
        return;
    }
    
    if (completionHandler) {
        completionHandler(YES, nil);
    }
    
}

@end

@interface BringgTrackingClientTestClass : BringgTrackingClient<PrivateClientConnectionDelegate>

@property (nullable, nonatomic, strong) GGCustomer *mockCustomer;

@end

@implementation BringgTrackingClientTestClass

- (void)setupHTTPManagerWithDevToken:(NSString *)devToken securedConnection:(BOOL)useSecuredConnection {
    
    GGHTTPClientManagerMockClass *mockHttp = [[GGHTTPClientManagerMockClass alloc] initWithDeveloperToken:TEST_DEV_TOKEN];
    
    self.httpManager = mockHttp;
    [self.httpManager useSecuredConnection:useSecuredConnection];
    [self.httpManager setConnectionDelegate:self];
}

- (void)setupTrackerManagerWithDevToken:(nonnull NSString *)devToken httpManager:(nonnull GGHTTPClientManager *)httpManager realtimeDelegate:(nonnull id<RealTimeDelegate>)delegate {
    
    self.trackerManager = [[GGTrackerManagerMockClass alloc] initWithDeveloperToken:TEST_DEV_TOKEN HTTPManager:nil realTimeDelegate:delegate];
    
    [self.trackerManager setDeveloperToken:devToken];
    [self.trackerManager setHTTPManager:self.httpManager];
    [self.trackerManager setRealTimeDelegate:delegate];
    
    [self.trackerManager setConnectionDelegate:self];
    
    self.trackerManager.logsEnabled = NO;
}

- (nullable GGCustomer *)signedInCustomer{
    return self.mockCustomer;
    
}

@end


@interface BringgTrackingClientTests : XCTestCase

@property (nonatomic, strong) BringgTrackingClientTestClass *trackingClient;
@property (nonatomic, strong) GGTestRealTimeMockDelegate  *realtimeDelegate;
;

@end

@implementation BringgTrackingClientTests

- (void)setUp {
    [super setUp];
    
    self.realtimeDelegate = [[GGTestRealTimeMockDelegate alloc] init];
    self.trackingClient = [BringgTrackingClientTestClass clientWithDeveloperToken:@"aaa-bbb-ccc" connectionDelegate:self.realtimeDelegate];
    // clear nsuser defaults before each test
    
}



- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.trackingClient = nil;
    self.realtimeDelegate = nil;
    
    [self resetDefaults];
    
    [super tearDown];
}

//MARK: Helpers
- (void)resetDefaults {
    NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
    NSDictionary * dict = [defs dictionaryRepresentation];
    for (id key in dict) {
        [defs removeObjectForKey:key];
    }
    [defs synchronize];
}

- (NSDictionary *)generateSharedLocationJSONSharedUUID:(nonnull NSString *)shareUUID orderUUID:(nonnull NSString *)orderUUID {
    
    NSDictionary *json = @{PARAM_UUID:shareUUID, PARAM_ORDER_UUID: orderUUID};
    
    return json;
}

//MARK: Tests
- (void)testWatchingOrderUsingUUIDAndSharedUUID{
    NSString *uuid = nil;
    
    NSString *shareUUID = nil;
    
    GGTestRealTimeMockDelegate *delegate = [[GGTestRealTimeMockDelegate alloc] init];
    
    [self.trackingClient startWatchingOrderWithUUID:uuid shareUUID:shareUUID delegate:delegate];
    
    XCTAssertTrue(delegate.lastOrderError.code == GGErrorTypeInvalid);
    delegate.lastOrderError = nil;
    
    uuid = @"";
    
    [self.trackingClient startWatchingOrderWithUUID:uuid shareUUID:shareUUID delegate:delegate];
    XCTAssertTrue(delegate.lastOrderError.code == GGErrorTypeInvalid);
    delegate.lastOrderError = nil;
    
    
    shareUUID = @"";
    
    [self.trackingClient startWatchingOrderWithUUID:uuid shareUUID:shareUUID delegate:delegate];
    XCTAssertTrue(delegate.lastOrderError.code == GGErrorTypeInvalid);
    delegate.lastOrderError = nil;
    
    uuid = @"asd_asd_asdads";
    
    [self.trackingClient startWatchingOrderWithUUID:uuid shareUUID:shareUUID delegate:delegate];
    XCTAssertTrue(delegate.lastOrderError.code == GGErrorTypeInvalid);
    delegate.lastOrderError = nil;
    
    shareUUID = @"fefe-asd-fasd";
    
    [self.trackingClient startWatchingOrderWithUUID:uuid shareUUID:shareUUID delegate:delegate];
    XCTAssertNil(delegate.lastOrderError);
}

- (void)testWatchingOrderUsingUUIDAndCustomerAccessToken{
    NSString *uuid = nil;
    
    NSString *customerToken = nil;
    
    GGTestRealTimeMockDelegate *delegate = [[GGTestRealTimeMockDelegate alloc] init];
    
    [self.trackingClient startWatchingOrderWithUUID:uuid customerAccessToken:customerToken delegate:delegate];
    XCTAssertTrue(delegate.lastOrderError.code == GGErrorTypeInvalid);
    delegate.lastOrderError = nil;
    
    uuid = @"";
    
    [self.trackingClient startWatchingOrderWithUUID:uuid customerAccessToken:customerToken delegate:delegate];
    XCTAssertTrue(delegate.lastOrderError.code == GGErrorTypeInvalid);
    delegate.lastOrderError = nil;
    
    customerToken = @"";
    
    [self.trackingClient startWatchingOrderWithUUID:uuid customerAccessToken:customerToken delegate:delegate];
    XCTAssertTrue(delegate.lastOrderError.code == GGErrorTypeInvalid);
    delegate.lastOrderError = nil;
    
    uuid = @"asd_asd_asdads";
    
    [self.trackingClient startWatchingOrderWithUUID:uuid customerAccessToken:customerToken delegate:delegate];
    XCTAssertTrue(delegate.lastOrderError.code == GGErrorTypeInvalid);
    delegate.lastOrderError = nil;
    
    customerToken = @"fefe-asd-fasd";
    
    [self.trackingClient startWatchingOrderWithUUID:uuid customerAccessToken:customerToken delegate:delegate];
    XCTAssertNil(delegate.lastOrderError);
}

- (void)testWatchingDriverUsingUUIDAndSharedUUID{
    NSString *uuid = nil;
    
    NSString *shareUUID = nil;
    
    GGTestRealTimeMockDelegate *delegate = [[GGTestRealTimeMockDelegate alloc] init];
    
    [self.trackingClient startWatchingDriverWithUUID:uuid shareUUID:shareUUID delegate:delegate];
    XCTAssertTrue(delegate.lastDriverError.code == GGErrorTypeInvalid);
    delegate.lastDriverError = nil;
    
    uuid = @"";
    
    [self.trackingClient startWatchingDriverWithUUID:uuid shareUUID:shareUUID delegate:delegate];
    XCTAssertTrue(delegate.lastDriverError.code == GGErrorTypeInvalid);
    delegate.lastDriverError = nil;
    
    shareUUID = @"";
    
    [self.trackingClient startWatchingDriverWithUUID:uuid shareUUID:shareUUID delegate:delegate];
    XCTAssertTrue(delegate.lastDriverError.code == GGErrorTypeInvalid);
    delegate.lastDriverError = nil;
    
    uuid = @"asd_asd_asdads";
    
    [self.trackingClient startWatchingDriverWithUUID:uuid shareUUID:shareUUID delegate:delegate];
    XCTAssertTrue(delegate.lastDriverError.code == GGErrorTypeInvalid);
    delegate.lastDriverError = nil;
    
    shareUUID = @"fefe-asd-fasd";
    
    [self.trackingClient startWatchingDriverWithUUID:uuid shareUUID:shareUUID delegate:delegate];
    XCTAssertNil(delegate.lastDriverError);
}

- (void)testWatchingCustomerDriver{
     NSString *uuid = nil;
    
    GGTestRealTimeMockDelegate *delegate = [[GGTestRealTimeMockDelegate alloc] init];
    
    [self.trackingClient startWatchingCustomerDriverWithUUID:uuid delegate:delegate];
    XCTAssertTrue(delegate.lastDriverError.code == GGErrorTypeInvalid);
    delegate.lastDriverError = nil;
    
    uuid = @"";
    
    [self.trackingClient startWatchingCustomerDriverWithUUID:uuid delegate:delegate];
    XCTAssertTrue(delegate.lastDriverError.code == GGErrorTypeInvalid);
    delegate.lastDriverError = nil;
    
    uuid = @"asd_asd_asdads";
 
    [self.trackingClient startWatchingCustomerDriverWithUUID:uuid delegate:delegate];
    XCTAssertNotNil(delegate.lastDriverError);
    
    XCTAssertTrue([[delegate.lastDriverError.userInfo valueForKey:NSLocalizedDescriptionKey] isEqualToString:@"cant watch driver without valid customer"]);
    
    // define a mock customer
    NSString *token = @"12345654321";
    GGCustomer *mockCustomer = [[GGCustomer alloc] init];
    mockCustomer.customerToken = token;
    
    self.trackingClient.mockCustomer = mockCustomer;

    [delegate resetDelegate];
    
    // now calling the watch customer driver should work, no exception , no error, since we have a customer object
    [self.trackingClient startWatchingCustomerDriverWithUUID:uuid delegate:delegate];
    XCTAssertNil(delegate.lastDriverError);
    
    
    // cleanup
    self.trackingClient.mockCustomer = nil;
}

- (void)testWatchingWayointUsingWaypointIDAndOrderUUID{
   
    NSString *uuid = nil;
    NSNumber *wpid = nil;
   
    GGTestRealTimeMockDelegate *delegate = [[GGTestRealTimeMockDelegate alloc] init];
    
    BringgTrackingClient *realTrackingClient = [[BringgTrackingClient alloc] initWithDevToken:TEST_DEV_TOKEN connectionDelegate:delegate];
    
    GGRealTimeMontiorMockingClass *mockLiveMonitor = [[GGRealTimeMontiorMockingClass alloc] init];
    
    realTrackingClient.trackerManager.liveMonitor = mockLiveMonitor;
    
    [realTrackingClient startWatchingWaypointWithWaypointId:wpid andOrderUUID:uuid delegate:delegate];
    XCTAssertTrue(delegate.lastWaypointError.code == GGErrorTypeInvalid);
    delegate.lastWaypointError = nil;
    uuid = @"";
    
    [realTrackingClient startWatchingWaypointWithWaypointId:wpid andOrderUUID:uuid delegate:delegate];
    XCTAssertTrue(delegate.lastWaypointError.code == GGErrorTypeInvalid);
    delegate.lastWaypointError = nil;
    
    wpid = @123456789;
    
    [realTrackingClient startWatchingWaypointWithWaypointId:wpid andOrderUUID:uuid delegate:delegate];
    XCTAssertTrue(delegate.lastWaypointError.code == GGErrorTypeInvalid);
    delegate.lastWaypointError = nil;
    
    uuid = @"asd_asd_asdads";
    
    [realTrackingClient startWatchingWaypointWithWaypointId:wpid andOrderUUID:uuid delegate:delegate];
    XCTAssertNil(delegate.lastWaypointError);
}

- (void)testRequestingFindMeUsingOrderUUID{
    
    NSString *uuid = nil;
    [self.trackingClient sendFindMeRequestForOrderWithUUID:uuid latitude:0 longitude:0 withCompletionHandler:^(BOOL success, NSError * _Nullable error) {
        
        XCTAssertEqual(error.code, GGErrorTypeInvalidUUID);
    }];
    
    uuid = @"";
    [self.trackingClient sendFindMeRequestForOrderWithUUID:uuid latitude:0 longitude:0 withCompletionHandler:^(BOOL success, NSError * _Nullable error) {
        XCTAssertEqual(error.code, GGErrorTypeOrderNotFound);
    }];
    
    GGOrder *order = [[GGOrder alloc] initOrderWithUUID:@"SOME_ORDER_UUID" atStatus:OrderStatusCreated];
    [self.trackingClient.trackerManager.liveMonitor addAndUpdateOrder:order];
    
    uuid = @"SOME_UUID";
    [self.trackingClient sendFindMeRequestForOrderWithUUID:uuid latitude:0 longitude:0 withCompletionHandler:^(BOOL success, NSError * _Nullable error) {
        XCTAssertEqual(error.code, GGErrorTypeOrderNotFound);
    }];
    
    
    uuid = @"SOME_ORDER_UUID";
    [self.trackingClient sendFindMeRequestForOrderWithUUID:uuid latitude:0 longitude:0 withCompletionHandler:^(BOOL success, NSError * _Nullable error) {
        XCTAssertEqual(error.code, GGErrorTypeActionNotAllowed);
    }];
    
    
    GGFindMe *findmeconfig = [[GGFindMe alloc] init];
    findmeconfig.url = @"http://bringg.com/findme";
    findmeconfig.token = @"SOME_TOKEN";
    findmeconfig.enabled = YES;
    
    
    GGSharedLocation *sharedL = [[GGSharedLocation alloc] init];
    sharedL.locationUUID = @"SOME_SHARE_UUID";
    sharedL.findMe = findmeconfig;
    
    order.sharedLocationUUID = @"SOME_SHARE_UUID";
    order.sharedLocation = sharedL;
    
    [self.trackingClient.trackerManager.liveMonitor addAndUpdateOrder:order];
    
    uuid = @"SOME_ORDER_UUID";
    [self.trackingClient sendFindMeRequestForOrderWithUUID:uuid latitude:0 longitude:0 withCompletionHandler:^(BOOL success, NSError * _Nullable error) {
        // should fail since cooridantes are invalid
        XCTAssertEqual(error.code, GGErrorTypeActionNotAllowed);
    }];
    
    [self.trackingClient sendFindMeRequestForOrderWithUUID:uuid latitude:12.1231 longitude:87.55 withCompletionHandler:^(BOOL success, NSError * _Nullable error) {
        
        XCTAssertTrue(success);
    }];
    
    
}

- (void)testWatchingOrderWithExpiredResponseMissingSharedLocation{
    
    BringgTrackingClient *realTrackingClient = [[BringgTrackingClient alloc] initWithDevToken:TEST_DEV_TOKEN connectionDelegate:self.realtimeDelegate];
    
    GGRealTimeMontiorMockingClass *mockLiveMonitor = [[GGRealTimeMontiorMockingClass alloc] init];
    
    __block NSString *orderUUID = @"abvsd-asd-asdasd";
    __block NSString *shareUUID = @"asdf00asb7";
    
    
    mockLiveMonitor.watchOrderResponseJSON = @{@"expired": @YES,
                                               @"message": [NSString stringWithFormat:@"Order %@ share %@ expired",orderUUID , shareUUID],
                                               @"success": @YES};
    
    realTrackingClient.trackerManager.liveMonitor = mockLiveMonitor;
    
    GGOrder * activeOrder = [realTrackingClient orderWithUUID:orderUUID];
    
    // prove order doesnt exist yet
    XCTAssertNil(activeOrder);
    
    GGTestRealTimeMockDelegate *delegate = [[GGTestRealTimeMockDelegate alloc] init];
    
    [realTrackingClient startWatchingOrderWithUUID:orderUUID shareUUID:shareUUID delegate:delegate];
    
    activeOrder = [realTrackingClient orderWithUUID:orderUUID];
    
    XCTAssertNotNil(activeOrder);
    XCTAssertNil(activeOrder.sharedLocation); // we expect new order object to not contain any shared location
    
    XCTAssertNil(delegate.lastOrderError);
    XCTAssertNotNil(delegate.lastUpdatedOrder);
}


- (void)testWatchingOrderWithExpiredResponse{
    
    BringgTrackingClient *realTrackingClient = [[BringgTrackingClient alloc] initWithDevToken:TEST_DEV_TOKEN connectionDelegate:self.realtimeDelegate];
    
    GGRealTimeMontiorMockingClass *mockLiveMonitor = [[GGRealTimeMontiorMockingClass alloc] init];
    
    __block NSString *orderUUID = @"abvsd-asd-asdasd";
    __block NSString *shareUUID = @"asdf00asb7";
    
    
    mockLiveMonitor.watchOrderResponseJSON = @{@"expired": @YES,
                                               @"message": [NSString stringWithFormat:@"Order %@ share %@ expired",orderUUID , shareUUID],
                                               @"shared_location": [self generateSharedLocationJSONSharedUUID:shareUUID orderUUID:orderUUID],
                                               @"success": @YES};
    
    realTrackingClient.trackerManager.liveMonitor = mockLiveMonitor;
    
    GGOrder * activeOrder = [realTrackingClient orderWithUUID:orderUUID];
    
    // prove order doesnt exist yet
    XCTAssertNil(activeOrder);
    
     GGTestRealTimeMockDelegate *delegate = [[GGTestRealTimeMockDelegate alloc] init];
    
     [realTrackingClient startWatchingOrderWithUUID:orderUUID shareUUID:shareUUID delegate:delegate];
    
    activeOrder = [realTrackingClient orderWithUUID:orderUUID];
    
    XCTAssertNotNil(activeOrder);
    XCTAssertNotNil(activeOrder.sharedLocation); // we expect new order object to contain the shared location of the response
    XCTAssertTrue([activeOrder.sharedLocation.locationUUID isEqualToString:shareUUID]);
    
    XCTAssertNil(delegate.lastOrderError);
    XCTAssertNotNil(delegate.lastUpdatedOrder);
}


- (void)testWatchingOrderWithFailedResponse {
    BringgTrackingClient *realTrackingClient = [[BringgTrackingClient alloc] initWithDevToken:TEST_DEV_TOKEN connectionDelegate:self.realtimeDelegate];
    
    GGTrackerManagerMockClass *trackerMock = [[GGTrackerManagerMockClass alloc] initWithDeveloperToken:TEST_DEV_TOKEN HTTPManager:nil realTimeDelegate:self.realtimeDelegate];
    
    [realTrackingClient setTrackerManager:trackerMock];
    
    GGRealTimeMontiorMockingClass *mockLiveMonitor = [[GGRealTimeMontiorMockingClass alloc] init];
    
    __block NSString *orderUUID = @"abvsd-asd-asdasd";
    __block NSString *shareUUID = @"asdf00asb7";
    
    NSString *msg = @"Shared Location was not found";
    NSInteger rc = 3;
    
    mockLiveMonitor.watchOrderResponseJSON = @{@"message": msg,
                                               @"rc": @(rc),
                                               @"success": @NO};
    
    realTrackingClient.trackerManager.liveMonitor = mockLiveMonitor;
    
    GGOrder * activeOrder = [realTrackingClient orderWithUUID:orderUUID];
    
    // prove order doesnt exist yet
    XCTAssertNil(activeOrder);
    
    GGTestRealTimeMockDelegate *delegate = [[GGTestRealTimeMockDelegate alloc] init];
    

    [realTrackingClient startWatchingOrderWithUUID:orderUUID shareUUID:shareUUID delegate:delegate];
    
    activeOrder = [realTrackingClient orderWithUUID:orderUUID];
    
    XCTAssertNotNil(activeOrder); // active order exists since calling watch creates a thin ggorder model
    XCTAssertNil(activeOrder.sharedLocation); // we expect no shared location since the response failed
    
    XCTAssertNotNil(delegate.lastOrderError);
    XCTAssertTrue(delegate.lastOrderError.code == rc);
    XCTAssertTrue([[delegate.lastOrderError.userInfo valueForKey:NSLocalizedDescriptionKey] isEqualToString:msg]);
}


@end
