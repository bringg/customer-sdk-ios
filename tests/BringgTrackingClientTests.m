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


#import "GGOrder.h"
#import "GGDriver.h"
#import "GGSharedLocation.h"
#import "GGWaypoint.h"

#define TEST_DEV_TOKEN @"SOME_DEV_TOKEN"

@interface GGTestRealTimeMockDelegate : NSObject<OrderDelegate, DriverDelegate, RealTimeDelegate>

@property (nullable, nonatomic, strong) GGOrder * lastUpdatedOrder;
@property (nullable, nonatomic, strong) GGDriver * lastUpdatedDriver;
@property (nullable, nonatomic, strong) NSError * lastOrderError;
@property (nullable, nonatomic, strong) NSError * lastDriverError;

@end

@implementation GGTestRealTimeMockDelegate

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
    self.lastOrderError = error;
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



@end

@interface GGRealTimeMontiorMockingClass : GGRealTimeMontior

@property (nonatomic, strong) NSDictionary *watchOrderResponseJSON;

@end

@implementation GGRealTimeMontiorMockingClass

- (void)sendWatchOrderWithOrderUUID:(nonnull NSString *)uuid
              accessControlParamKey:(nonnull NSString *)accessControlParamKey
            accessControlParamValue:(nonnull NSString *)accessControlParamValue
                  completionHandler:(nullable SocketResponseBlock)completionHandler{
    
    if (completionHandler) {
        
        BOOL success = [[self.watchOrderResponseJSON valueForKey:@"success"] boolValue];
        NSError *error;
        NSString *message = [self.watchOrderResponseJSON valueForKey:@"message"];
        if (message && !success) {
            NSNumber *rc = [self.watchOrderResponseJSON valueForKey:@"rc"] ?: @(-1);
            error = [NSError errorWithDomain:kSDKDomainResponse code:rc.integerValue userInfo:@{NSLocalizedDescriptionKey:  message}];
        }
        
        id<OrderDelegate> existingDelegate = [self.orderDelegates objectForKey:uuid];
        
        if (existingDelegate) {
            if (success) {
                [existingDelegate watchOrderSucceedForOrder:[self getOrderWithUUID:uuid]];
            }else{
                [existingDelegate watchOrderFailForOrder:[self getOrderWithUUID:uuid] error:error];
            }
        }
        
        completionHandler(success, self.watchOrderResponseJSON, error);
    }
    
}

@end

@interface GGTrackerManagerMockClass : GGTrackerManager

@end

@implementation GGTrackerManagerMockClass

- (void)startWatchingOrderWithUUID:(NSString *_Nonnull)uuid
                        sharedUUID:(NSString *_Nullable)shareduuid
                          delegate:(id <OrderDelegate> _Nullable)delegate{
    
    NSLog(@"SHOULD START WATCHING ORDER %@ with delegate %@", uuid, delegate);
    
    // uuid is invalid if empty
    if (!uuid || uuid.length == 0) {
        [NSException raise:@"Invalid UUID" format:@"order UUID can not be nil or empty"];
        return;
    }
    
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

@end

@implementation BringgTrackingClientTestClass

- (void)setupHTTPManagerWithDevToken:(NSString *)devToken securedConnection:(BOOL)useSecuredConnection {
    
    GGHTTPClientManagerMockClass *mockHttp = [GGHTTPClientManagerMockClass managerWithDeveloperToken:TEST_DEV_TOKEN];
    
    self.httpManager = mockHttp;
    [self.httpManager useSecuredConnection:useSecuredConnection];
    [self.httpManager setConnectionDelegate:self];
}

- (void)setupTrackerManagerWithDevToken:(nonnull NSString *)devToken httpManager:(nonnull GGHTTPClientManager *)httpManager realtimeDelegate:(nonnull id<RealTimeDelegate>)delegate {
    
    self.trackerManager = [GGTrackerManagerMockClass trackerWithCustomerToken:nil andDeveloperToken:TEST_DEV_TOKEN andDelegate:delegate andHTTPManager:nil];
    
    [self.trackerManager setDeveloperToken:devToken];
    [self.trackerManager setHTTPManager:self.httpManager];
    [self.trackerManager setRealTimeDelegate:delegate];
    
    [self.trackerManager setConnectionDelegate:self];
    
    self.trackerManager.logsEnabled = NO;
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
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.trackingClient = nil;
    self.realtimeDelegate = nil;
    
    [super tearDown];
}

//MARK: Helpers


- (NSDictionary *)generateSharedLocationJSONSharedUUID:(nonnull NSString *)sharedUUID orderUUID:(nonnull NSString *)orderUUID {
    
    NSDictionary *json = @{PARAM_UUID:sharedUUID, PARAM_ORDER_UUID: orderUUID};
    
    return json;
}

//MARK: Tests
- (void)testWatchingOrderUsingUUIDAndSharedUUID{
    NSString *uuid = nil;
    
    NSString *shareduuid = nil;
    
    XCTAssertThrows([self.trackingClient startWatchingOrderWithUUID:uuid sharedUUID:shareduuid delegate:self.realtimeDelegate]);
    
    uuid = @"";
    
    XCTAssertThrows([self.trackingClient startWatchingOrderWithUUID:uuid sharedUUID:shareduuid delegate:self.realtimeDelegate]);
    
    shareduuid = @"";
    
    XCTAssertThrows([self.trackingClient startWatchingOrderWithUUID:uuid sharedUUID:shareduuid delegate:self.realtimeDelegate]);
    
    
    uuid = @"asd_asd_asdads";
    
    XCTAssertThrows([self.trackingClient startWatchingOrderWithUUID:uuid sharedUUID:shareduuid delegate:self.realtimeDelegate]);
    
    shareduuid = @"fefe-asd-fasd";
    
    XCTAssertNoThrow([self.trackingClient startWatchingOrderWithUUID:uuid sharedUUID:shareduuid delegate:self.realtimeDelegate]);
    
}

- (void)testWatchingOrderUsingUUIDAndCustomerAccessToken{
    NSString *uuid = nil;
    
    NSString *customerToken = nil;
    
    XCTAssertThrows([self.trackingClient startWatchingOrderWithUUID:uuid customerAccessToken:customerToken delegate:self.realtimeDelegate]);
    
    uuid = @"";
    
    XCTAssertThrows([self.trackingClient startWatchingOrderWithUUID:uuid customerAccessToken:customerToken delegate:self.realtimeDelegate]);
    
    customerToken = @"";
    
    XCTAssertThrows([self.trackingClient startWatchingOrderWithUUID:uuid customerAccessToken:customerToken delegate:self.realtimeDelegate]);
    
    
    uuid = @"asd_asd_asdads";
    
    XCTAssertThrows([self.trackingClient startWatchingOrderWithUUID:uuid customerAccessToken:customerToken delegate:self.realtimeDelegate]);
    
    customerToken = @"fefe-asd-fasd";
    
    XCTAssertNoThrow([self.trackingClient startWatchingOrderWithUUID:uuid customerAccessToken:customerToken delegate:self.realtimeDelegate]);
    
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
    
    [realTrackingClient startWatchingOrderWithUUID:orderUUID sharedUUID:shareUUID delegate:delegate];
    
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
    
     [realTrackingClient startWatchingOrderWithUUID:orderUUID sharedUUID:shareUUID delegate:delegate];
    
    activeOrder = [realTrackingClient orderWithUUID:orderUUID];
    
    XCTAssertNotNil(activeOrder);
    XCTAssertNotNil(activeOrder.sharedLocation); // we expect new order object to contain the shared location of the response
    XCTAssertTrue([activeOrder.sharedLocation.locationUUID isEqualToString:shareUUID]);
    
    XCTAssertNil(delegate.lastOrderError);
    XCTAssertNotNil(delegate.lastUpdatedOrder);
}


- (void)testWatchingOrderWithFailedResponse {
    BringgTrackingClient *realTrackingClient = [[BringgTrackingClient alloc] initWithDevToken:TEST_DEV_TOKEN connectionDelegate:self.realtimeDelegate];
    
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
    

    [realTrackingClient startWatchingOrderWithUUID:orderUUID sharedUUID:shareUUID delegate:delegate];
    
    activeOrder = [realTrackingClient orderWithUUID:orderUUID];
    
    XCTAssertNotNil(activeOrder); // active order exists since calling watch creates a thin ggorder model
    XCTAssertNil(activeOrder.sharedLocation); // we expect no shared location since the response failed
    
    XCTAssertNotNil(delegate.lastOrderError);
    XCTAssertTrue(delegate.lastOrderError.code == rc);
    XCTAssertTrue([[delegate.lastOrderError.userInfo valueForKey:NSLocalizedDescriptionKey] isEqualToString:msg]);
}

@end
