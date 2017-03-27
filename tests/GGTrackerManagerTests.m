//
//  GGTrackerManagerTests.m
//  BringgTracking
//
//  Created by Matan on 05/11/2015.
//  Copyright © 2015 Matan Poreh. All rights reserved.
//

#import <XCTest/XCTest.h>
#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>

#import "GGTestUtils.h"

#import "GGHTTPClientManager.h"

#import "GGTrackerManager_Private.h"
#import "GGTrackerManager.h"


#import "GGOrder.h"
#import "GGDriver.h"
#import "GGSharedLocation.h"
#import "GGWaypoint.h"


@interface GGTestRealTimeDelegate : NSObject<OrderDelegate, DriverDelegate, RealTimeDelegate>

@end

@implementation GGTestRealTimeDelegate

- (void)trackerDidConnect{
    
}

-(void)trackerDidDisconnectWithError:(NSError *)error{
    
}

-(void)watchDriverFailedForDriver:(GGDriver *)driver error:(NSError *)error{
    
}

-(void)watchOrderFailForOrder:(GGOrder *)order error:(NSError *)error{
    
}

- (void)orderDidAssignWithOrder:(GGOrder *)order withDriver:(GGDriver *)driver{
    
}
- (void)orderDidAcceptWithOrder:(GGOrder *)order withDriver:(GGDriver *)driver{
    
}
- (void)orderDidStartWithOrder:(GGOrder *)order withDriver:(GGDriver *)driver{
    
}



@end

@interface GGRealTimeMontiorMockClass : GGRealTimeMontior

@property (nonatomic, strong) NSDictionary *watchOrderResponseJSON;

@end

@implementation GGRealTimeMontiorMockClass

- (void)sendWatchOrderWithOrderUUID:(nonnull NSString *)uuid
              accessControlParamKey:(nonnull NSString *)accessControlParamKey
            accessControlParamValue:(nonnull NSString *)accessControlParamValue
                  completionHandler:(nullable SocketResponseBlock)completionHandler{
    
    if (completionHandler) {
        completionHandler(YES, self.watchOrderResponseJSON, nil);
    }
    
}

@end

@interface GGTrackerManagerTestClass : GGTrackerManager

@end

@implementation GGTrackerManagerTestClass

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

@interface GGHTTPClientManagerTestClass :  GGHTTPClientManager

@end

@implementation GGHTTPClientManagerTestClass

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

@interface GGTrackerManagerTests : XCTestCase

@property (nonatomic, strong) GGTrackerManagerTestClass *trackerManager;
@property (nonatomic, strong) GGTestRealTimeDelegate  *realtimeDelegate;
@property (nullable, nonatomic, strong) NSDictionary *acceptJson;
@property (nullable, nonatomic, strong) NSDictionary *startJson;

@end

@implementation GGTrackerManagerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    self.realtimeDelegate = [[GGTestRealTimeDelegate alloc] init];
    self.trackerManager = [GGTrackerManagerTestClass trackerWithCustomerToken:nil andDeveloperToken:nil andDelegate:self.realtimeDelegate andHTTPManager:nil];
   
    
    self.acceptJson = [GGTestUtils parseJsonFile:@"orderUpdate_onaccept"];
    self.startJson = [GGTestUtils parseJsonFile:@"orderUpdate_onstart"];
    
    GGHTTPClientManagerTestClass *mockHttp = [GGHTTPClientManagerTestClass managerWithDeveloperToken:@"SOME_DEV_TOKEN"];
    [self.trackerManager setHTTPManager:mockHttp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    self.trackerManager = nil;
    self.realtimeDelegate = nil;
    
    self.acceptJson = nil;
    self.startJson = nil;

}

//MARK: Helpers
- (GGTrackerManager *)setupRealTrackerManager {
    
    GGTrackerManager *trackerManager = [[GGTrackerManager alloc] initTacker];
     
    GGHTTPClientManagerTestClass *mockHttp = [GGHTTPClientManagerTestClass managerWithDeveloperToken:@"SOME_DEV_TOKEN"];
    [trackerManager setHTTPManager:mockHttp];
    
    return trackerManager;
}

- (GGSharedLocation *)generateSharedLocationWithJSONSharedUUID:(nonnull NSString *)sharedUUID orderUUID:(nonnull NSString *)orderUUID {
    
    NSDictionary *json = @{PARAM_UUID:sharedUUID, PARAM_ORDER_UUID: orderUUID};
    
    return json;
}

//MARK: Tests
-(void)testMonitoredOrders{
    
    NSDictionary *eventData = [NSDictionary dictionaryWithDictionary:self.acceptJson];
    
    GGOrder *updatedOrder;
    GGDriver *updatedDriver;
    
    [GGTestUtils parseUpdateData:eventData intoOrder:&updatedOrder andDriver:&updatedDriver];
    
    GGOrder *order = [self.trackerManager.liveMonitor addAndUpdateOrder:updatedOrder];
    
    
    [self.trackerManager.liveMonitor.orderDelegates setObject:self.realtimeDelegate forKey:order.uuid];
    
    XCTAssertEqual(self.trackerManager.monitoredOrders.count, 1);
}


-(void)testMonitoredDrivers{
    
    // test on accept data
    NSDictionary *eventData = [NSDictionary dictionaryWithDictionary:self.acceptJson];
    
    GGOrder *updatedOrder;
    GGDriver *updatedDriver;
    
    [GGTestUtils parseUpdateData:eventData intoOrder:&updatedOrder andDriver:&updatedDriver];
    
    GGDriver *driver = [self.trackerManager.liveMonitor addAndUpdateDriver:updatedDriver];
    
    
    NSString *compoundKey = [[driver.uuid stringByAppendingString:DRIVER_COMPOUND_SEPERATOR] stringByAppendingString:driver.uuid];
    
    
    [self.trackerManager.liveMonitor.driverDelegates setObject:self.realtimeDelegate forKey:compoundKey];
    
    NSLog(@"%@", self.trackerManager.monitoredDrivers);
    
    XCTAssertEqual(self.trackerManager.monitoredDrivers.count, 1);
    
    // also test compound key parsing
    
    
    NSString *driverUUID;
    NSString *sharedUUID;
    
    [GGBringgUtils parseDriverCompoundKey:compoundKey toDriverUUID:&driverUUID andSharedUUID:&sharedUUID];
    
    XCTAssertTrue([driverUUID isEqualToString:sharedUUID]);
    
}

-(void)testParsingOrder{
    NSString *testData = [GGTestUtils exampleOrderJsonData];
    
    NSError *jsonError;
    NSData *objectData = [testData dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&jsonError];
    
    XCTAssertNotNil(json);
    
    
    GGOrder *order = [[GGOrder alloc] initOrderWithData:json];
    
    NSInteger  activeWP = order.activeWaypointId;
    NSNumber *dataActiveWpiD = [json objectForKey:@"active_way_point_id"];
    
    
    XCTAssertTrue(activeWP == dataActiveWpiD.integerValue);

}

-(void)testParsingSharedLocation{
    
    NSString *testData = [GGTestUtils exampleLocationJsonData];
    
    NSError *jsonError;
    NSData *objectData = [testData dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&jsonError];
    
    XCTAssertNotNil(json);
    
    
    GGSharedLocation *sharedLocation = [[GGSharedLocation alloc] initWithData:json];
    
    NSString *driverUUID = sharedLocation.driver.uuid;
    NSString *dataDriverUUID = [json objectForKey:@"driver_uuid"];
    
    
    XCTAssertTrue([driverUUID isEqualToString:dataDriverUUID]);
}

-(void)testMakingDataPrintSafe{
    
    NSString *testData = [GGTestUtils exampleOrderJsonData];
    
    NSError *jsonError;
    NSData *objectData = [testData dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&jsonError];
    
    XCTAssertNotNil(json);
    
    NSDictionary *safeData = [GGBringgUtils userPrintSafeDataFromData:json];
    
    XCTAssertNotNil(safeData);

}

- (void)testWatchingOrderUsingUUIDAndSharedUUID{
    NSString *uuid = nil;
    
    XCTAssertThrows([self.trackerManager startWatchingOrderWithUUID:uuid sharedUUID:nil delegate:self.realtimeDelegate]);
    
    uuid = @"";
    
    XCTAssertThrows([self.trackerManager startWatchingOrderWithUUID:uuid sharedUUID:nil delegate:self.realtimeDelegate]);
    
    
    uuid = @"asd_asd_asdads";
    
    XCTAssertNoThrow([self.trackerManager startWatchingOrderWithUUID:uuid sharedUUID:nil delegate:self.realtimeDelegate]);
    
}

- (void)testRequestingFindMeUsingOrderUUID{
    
    NSString *uuid = nil;
    [self.trackerManager sendFindMeRequestForOrderWithUUID:uuid latitude:0 longitude:0 withCompletionHandler:^(BOOL success, NSError * _Nullable error) {
        
         XCTAssertEqual(error.code, GGErrorTypeInvalidUUID);
    }];
    
    uuid = @"";
    [self.trackerManager sendFindMeRequestForOrderWithUUID:uuid latitude:0 longitude:0 withCompletionHandler:^(BOOL success, NSError * _Nullable error) {
        XCTAssertEqual(error.code, GGErrorTypeOrderNotFound);
    }];
    
     GGOrder *order = [[GGOrder alloc] initOrderWithUUID:@"SOME_ORDER_UUID" atStatus:OrderStatusCreated];
    [self.trackerManager.liveMonitor addAndUpdateOrder:order];
    
    uuid = @"SOME_UUID";
    [self.trackerManager sendFindMeRequestForOrderWithUUID:uuid latitude:0 longitude:0 withCompletionHandler:^(BOOL success, NSError * _Nullable error) {
        XCTAssertEqual(error.code, GGErrorTypeOrderNotFound);
    }];
    
    
    uuid = @"SOME_ORDER_UUID";
    [self.trackerManager sendFindMeRequestForOrderWithUUID:uuid latitude:0 longitude:0 withCompletionHandler:^(BOOL success, NSError * _Nullable error) {
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

    [self.trackerManager.liveMonitor addAndUpdateOrder:order];
    
    uuid = @"SOME_ORDER_UUID";
    [self.trackerManager sendFindMeRequestForOrderWithUUID:uuid latitude:0 longitude:0 withCompletionHandler:^(BOOL success, NSError * _Nullable error) {
        // should fail since cooridantes are invalid
        XCTAssertEqual(error.code, GGErrorTypeActionNotAllowed);
    }];
    
    [self.trackerManager sendFindMeRequestForOrderWithUUID:uuid latitude:12.1231 longitude:87.55 withCompletionHandler:^(BOOL success, NSError * _Nullable error) {
        
        XCTAssertTrue(success);
    }];

    
}

- (void)testWatchingOrderWithExpiredResponseMissingSharedLocation{
    
    GGTrackerManager *trackerManager = [self setupRealTrackerManager];
    
    GGRealTimeMontiorMockClass *mockLiveMonitor = [[GGRealTimeMontiorMockClass alloc] init];
    
    __block NSString *orderUUID = @"abvsd-asd-asdasd";
    __block NSString *shareUUID = @"asdf00asb7";
    
    
    mockLiveMonitor.watchOrderResponseJSON = @{@"expired": @YES,
                                               @"message": [NSString stringWithFormat:@"Order %@ share %@ expired",orderUUID , shareUUID],
                                               @"success": @YES};
    
    trackerManager.liveMonitor = mockLiveMonitor;
    
    GGOrder * activeOrder = [trackerManager orderWithUUID:orderUUID];
    
    // prove order doesnt exist yet
    XCTAssertNil(activeOrder);
    
    [trackerManager startWatchingOrderWithUUID:orderUUID accessControlParamKey:PARAM_SHARE_UUID accessControlParamValue:shareUUID delegate:self.realtimeDelegate];
        
    activeOrder = [trackerManager orderWithUUID:orderUUID];
    
    XCTAssertNotNil(activeOrder);
    XCTAssertNil(activeOrder.sharedLocation); // we expect new order object to not contain any shared location
}

- (void)testWatchingOrderWithExpiredResponse{
    
    GGTrackerManager *trackerManager = [self setupRealTrackerManager];
    
    GGRealTimeMontiorMockClass *mockLiveMonitor = [[GGRealTimeMontiorMockClass alloc] init];
    
    __block NSString *orderUUID = @"abvsd-asd-asdasd";
    __block NSString *shareUUID = @"asdf00asb7";
    
    
    mockLiveMonitor.watchOrderResponseJSON = @{@"expired": @YES,
                                               @"message": [NSString stringWithFormat:@"Order %@ share %@ expired",orderUUID , shareUUID],
                                               @"shared_location": [self generateSharedLocationWithJSONSharedUUID:shareUUID orderUUID:orderUUID],
                                               @"success": @YES};
    
    trackerManager.liveMonitor = mockLiveMonitor;
    
     GGOrder * activeOrder = [trackerManager orderWithUUID:orderUUID];
    
    // prove order doesnt exist yet
    XCTAssertNil(activeOrder);
    
     [trackerManager startWatchingOrderWithUUID:orderUUID accessControlParamKey:PARAM_SHARE_UUID accessControlParamValue:shareUUID delegate:self.realtimeDelegate];
    
    activeOrder = [trackerManager orderWithUUID:orderUUID];
    
    XCTAssertNotNil(activeOrder);
    XCTAssertNotNil(activeOrder.sharedLocation); // we expect new order object to contain the shared location of the response
    XCTAssertTrue([activeOrder.sharedLocation.locationUUID isEqualToString:shareUUID]);
}

@end
