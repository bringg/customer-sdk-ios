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
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    self.trackerManager = nil;
    self.realtimeDelegate = nil;
    
    self.acceptJson = nil;
    self.startJson = nil;

}

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
- (void)testWatchingOrderUsingCompoundUUID{
    
    NSString *compoundUUID = nil;
    
    XCTAssertThrows([self.trackerManager startWatchingOrderWithCompoundUUID:compoundUUID delegate:self.realtimeDelegate]);
    
    
    compoundUUID = @"";
    
    XCTAssertThrows([self.trackerManager startWatchingOrderWithCompoundUUID:compoundUUID delegate:self.realtimeDelegate]);
    
    compoundUUID = @"SOME_ORDER_UUID";
    
    XCTAssertThrows([self.trackerManager startWatchingOrderWithCompoundUUID:compoundUUID delegate:self.realtimeDelegate]);
    
    // when doing a compound with the seperator - it should work even without a shared uuid
    compoundUUID = @"SOME_ORDER_UUID$$";
    
    XCTAssertThrows([self.trackerManager startWatchingOrderWithCompoundUUID:compoundUUID delegate:self.realtimeDelegate]);
    
    compoundUUID = @"SOME_ORDER_UUID$$SOME_SHARE_UUID";
    
    XCTAssertNoThrow([self.trackerManager startWatchingOrderWithCompoundUUID:compoundUUID delegate:self.realtimeDelegate]);
}

@end
