//
//  GGRealTimeMonitorTests.m
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


#import "GGRealTimeMontior+Private.h"
#import "GGRealTimeMontior.h"

#import "GGOrder.h"
#import "GGDriver.h"
#import "GGSharedLocation.h"
#import "GGWaypoint.h"

@interface WaypointDelegateTestClass : NSObject<WaypointDelegate>
@property (nonatomic, strong) NSNumber *lastUpdatedWaypointId;
@property (nonatomic, strong) NSDate *lastUpdatedEta;


@end

@implementation WaypointDelegateTestClass

-(void)watchWaypointFailedForWaypointId:(NSNumber *)waypointId error:(NSError *)error{
    
}

-(void)waypointDidArrivedWaypointId:(NSNumber *)waypointId{
     self.lastUpdatedWaypointId = waypointId;
}

-(void)waypointDidFinishedWaypointId:(NSNumber *)waypointId{
     self.lastUpdatedWaypointId = waypointId;
}

-(void)waypointDidUpdatedWaypointId:(NSNumber *)waypointId eta:(NSDate *)eta{
    self.lastUpdatedEta = eta;
    self.lastUpdatedWaypointId = waypointId;
}

- (void)watchWaypointSucceededForWaypointId:(nonnull NSNumber *)waypointId waypoint:(nonnull GGWaypoint *)waypoint {
}


@end

@interface DriverDelegateTestClass : NSObject<DriverDelegate>

@property (nonatomic, assign) double lastUpdateLat;
@property (nonatomic, assign) double lastUpdateLng;
@end

@implementation DriverDelegateTestClass

- (void)watchDriverSucceedForDriver:(GGDriver *)driver{
    
}

- (void)watchDriverFailedForDriver:(GGDriver *)driver error:(NSError *)error{
    
}

- (void)driverLocationDidChangeWithDriver:(GGDriver *)driver{
    _lastUpdateLat = driver.latitude;
    _lastUpdateLng = driver.longitude;
}

@end

@interface GGRealTimeMonitorTests : XCTestCase

@property (nonatomic, strong) GGRealTimeMontior *liveMonitor;

@property (nullable, nonatomic, strong) NSDictionary *acceptJson;
@property (nullable, nonatomic, strong) NSDictionary *startJson;



@end

@implementation GGRealTimeMonitorTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
   
    self.liveMonitor = [[GGRealTimeMontior alloc] init];
    
    self.acceptJson = [GGTestUtils parseJsonFile:@"orderUpdate_onaccept"];
    self.startJson = [GGTestUtils parseJsonFile:@"orderUpdate_onstart"];

 
    
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    self.liveMonitor = nil;
    self.acceptJson = nil;
    self.startJson = nil;
 
}

-(void)testLoadedJsons{
    XCTAssertNotNil(self.acceptJson);
    XCTAssertNotNil(self.startJson);
}


-(void)testParsingAcceptDataToObjects{
    
    NSDictionary *eventData = [NSDictionary dictionaryWithDictionary:self.acceptJson];
    
    GGOrder *updatedOrder;
    GGDriver *updatedDriver;
    
    [GGTestUtils parseUpdateData:eventData intoOrder:&updatedOrder andDriver:&updatedDriver];
    
    XCTAssertNotNil(updatedOrder);
    XCTAssertNotNil(updatedDriver);
    
    XCTAssertNotNil(updatedOrder.uuid);
    XCTAssertNotNil(updatedDriver.uuid);

}


-(void)testActiveOrders{
    // test on accept data

     NSDictionary *eventData = [NSDictionary dictionaryWithDictionary:self.acceptJson];
    
    GGOrder *updatedOrder;
    GGDriver *updatedDriver;
    
    [GGTestUtils parseUpdateData:eventData intoOrder:&updatedOrder andDriver:&updatedDriver];
    
    [self.liveMonitor addAndUpdateOrder:updatedOrder];
    GGOrder *order = [self.liveMonitor.activeOrders objectForKey:updatedOrder.uuid];
    
    XCTAssertNotNil(order);
    
    // test on start data
    
    eventData = [NSDictionary dictionaryWithDictionary:self.startJson];
    [GGTestUtils parseUpdateData:eventData intoOrder:&updatedOrder andDriver:&updatedDriver];
    
    [self.liveMonitor addAndUpdateOrder:updatedOrder];
    order = [self.liveMonitor.activeOrders objectForKey:updatedOrder.uuid];
    
    XCTAssertNotNil(order);

    
}

-(void)testActiveDrivers{
    // test on accept data
    NSDictionary *eventData = [NSDictionary dictionaryWithDictionary:self.acceptJson];
    
    GGOrder *updatedOrder;
    GGDriver *updatedDriver;
    
    [GGTestUtils parseUpdateData:eventData intoOrder:&updatedOrder andDriver:&updatedDriver];
    
   [self.liveMonitor addAndUpdateDriver:updatedDriver];
    GGDriver *driver = [self.liveMonitor.activeDrivers objectForKey:updatedDriver.uuid];
    
    XCTAssertNotNil(driver);
    
    
    // test on start data

    eventData = [NSDictionary dictionaryWithDictionary:self.startJson];
    [GGTestUtils parseUpdateData:eventData intoOrder:&updatedOrder andDriver:&updatedDriver];
    
    [self.liveMonitor addAndUpdateDriver:updatedDriver];
    driver = [self.liveMonitor.activeDrivers objectForKey:updatedDriver.uuid];
    
    XCTAssertNotNil(driver);

}

- (void)testRetrievingWatchedWaypoint{
    // test on accept data
    NSDictionary *eventData = [NSDictionary dictionaryWithDictionary:self.acceptJson];
    
    GGOrder *updatedOrder;
    GGDriver *updatedDriver;
    
    [GGTestUtils parseUpdateData:eventData intoOrder:&updatedOrder andDriver:&updatedDriver];
    
    XCTAssertTrue(updatedOrder.waypoints.count > 0);
    
    GGWaypoint *anyWP = [updatedOrder.waypoints objectAtIndex:0];
    
    // create the compound key
    __block NSString *compoundKey = [[updatedOrder.uuid stringByAppendingString:WAYPOINT_COMPOUND_SEPERATOR] stringByAppendingString:@(anyWP.waypointId).stringValue];
    
    id delegate = [[WaypointDelegateTestClass alloc] init];
    
    [self.liveMonitor.waypointDelegates setObject:delegate forKey:compoundKey];
    
    id retVal = [self.liveMonitor delegateForWaypointID:@(anyWP.waypointId)];
    
    // test retval exists and is the same as the initial delegate we set
    XCTAssertNotNil(retVal);
    XCTAssertTrue([retVal isEqual:delegate]);

}

- (void)testHandlingETAEvent{
    // test on start data
    NSDictionary *eventData = [NSDictionary dictionaryWithDictionary:self.startJson];
    
    GGOrder *updatedOrder;
    GGDriver *updatedDriver;
    
    [GGTestUtils parseUpdateData:eventData intoOrder:&updatedOrder andDriver:&updatedDriver];
    
    XCTAssertTrue(updatedOrder.waypoints.count > 0);
    
    GGWaypoint *anyWP = [updatedOrder.waypoints objectAtIndex:0];
    
    // create the compound key
    __block NSString *compoundKey = [[updatedOrder.uuid stringByAppendingString:WAYPOINT_COMPOUND_SEPERATOR] stringByAppendingString:@(anyWP.waypointId).stringValue];
    
    WaypointDelegateTestClass *delegate = [[WaypointDelegateTestClass alloc] init];
    
    XCTAssertNil(delegate.lastUpdatedWaypointId);
    XCTAssertNil(delegate.lastUpdatedEta);
    
    [self.liveMonitor.waypointDelegates setObject:delegate forKey:compoundKey];
    
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
    NSString *eta = [dateFormat stringFromDate:now];
    
    NSDictionary *waypointETAUpdateData = @{@"way_point_id":@(anyWP.waypointId), @"eta":eta};
    
    [self.liveMonitor handleSocketIODidReceiveEvent:EVENT_WAY_POINT_ETA_UPDATE withData:waypointETAUpdateData];
    
    XCTAssertNotNil(delegate.lastUpdatedWaypointId);
    XCTAssertTrue(delegate.lastUpdatedWaypointId.integerValue == anyWP.waypointId);
    XCTAssertNotNil(delegate.lastUpdatedEta);
    XCTAssertTrue([[GGBringgUtils dateFromString:eta] isEqualToDate:delegate.lastUpdatedEta]);
}

-(void)testHandlingLocationUpdateEvent{
    
    NSDictionary *eventData = [NSDictionary dictionaryWithDictionary:self.startJson];
    
    GGOrder *updatedOrder;
    GGDriver *updatedDriver;
    
    [GGTestUtils parseUpdateData:eventData intoOrder:&updatedOrder andDriver:&updatedDriver];
    
    XCTAssertNotNil(updatedOrder);
    XCTAssertNotNil(updatedDriver);
    
    double randomLat = [GGTestUtils randomBetweenMin:-90.0 andMax:90.0];
    double randomLng = [GGTestUtils randomBetweenMin:-180.0 andMax:180.0];
    
    DriverDelegateTestClass *delegate = [[DriverDelegateTestClass alloc] init];
    XCTAssertEqual(delegate.lastUpdateLat, 0);
    XCTAssertEqual(delegate.lastUpdateLng, 0);
    
    [self.liveMonitor.driverDelegates setObject:delegate forKey:updatedDriver.uuid];
    [self.liveMonitor.activeDrivers setObject:updatedDriver forKey:updatedDriver.uuid];
    [self.liveMonitor.activeOrders setObject:updatedOrder forKey:updatedOrder.uuid];
    
    NSDictionary *locationUpdateData = @{PARAM_DRIVER_UUID: updatedDriver.uuid, PARAM_LAT: @(randomLat), PARAM_LNG: @(randomLng)};
    
    XCTAssertTrue([self.liveMonitor handleLocationUpdateWithData:locationUpdateData]);
    
    XCTAssertTrue(delegate.lastUpdateLat == randomLat);
    XCTAssertTrue(delegate.lastUpdateLng == randomLng);
}

-(void)testHandlingLocationUpdateEventBaseOnShareUUID{
    
    NSDictionary *eventData = [NSDictionary dictionaryWithDictionary:self.startJson];
    
    GGOrder *updatedOrder;
    GGDriver *updatedDriver;
    
    [GGTestUtils parseUpdateData:eventData intoOrder:&updatedOrder andDriver:&updatedDriver];
    
    XCTAssertNotNil(updatedOrder);
    XCTAssertNotNil(updatedDriver);
    
    double randomLat = [GGTestUtils randomBetweenMin:-90.0 andMax:90.0];
    double randomLng = [GGTestUtils randomBetweenMin:-180.0 andMax:180.0];
    
    DriverDelegateTestClass *delegate = [[DriverDelegateTestClass alloc] init];
    XCTAssertEqual(delegate.lastUpdateLat, 0);
    XCTAssertEqual(delegate.lastUpdateLng, 0);
    
    [self.liveMonitor.driverDelegates setObject:delegate forKey:updatedDriver.uuid];
    [self.liveMonitor.activeDrivers setObject:updatedDriver forKey:updatedDriver.uuid];
    [self.liveMonitor.activeOrders setObject:updatedOrder forKey:updatedOrder.uuid];
    
    NSDictionary *locationUpdateData = @{PARAM_SHARE_UUID:updatedOrder.sharedLocationUUID, PARAM_LAT: @(randomLat), PARAM_LNG: @(randomLng)};
    
    XCTAssertTrue([self.liveMonitor handleLocationUpdateWithData:locationUpdateData]);
    
    XCTAssertTrue(delegate.lastUpdateLat == randomLat);
    XCTAssertTrue(delegate.lastUpdateLng == randomLng);
}

-(void)testHandlingLocationUpdateEventNoShareUUIDOrDriverUUID{
    
    NSDictionary *eventData = [NSDictionary dictionaryWithDictionary:self.startJson];
    
    GGOrder *updatedOrder;
    GGDriver *updatedDriver;
    
    [GGTestUtils parseUpdateData:eventData intoOrder:&updatedOrder andDriver:&updatedDriver];
    
    XCTAssertNotNil(updatedOrder);
    XCTAssertNotNil(updatedDriver);
    
    double randomLat = [GGTestUtils randomBetweenMin:-90.0 andMax:90.0];
    double randomLng = [GGTestUtils randomBetweenMin:-180.0 andMax:180.0];
   
    [self.liveMonitor.activeDrivers setObject:updatedDriver forKey:updatedDriver.uuid];
    [self.liveMonitor.activeOrders setObject:updatedOrder forKey:updatedOrder.uuid];
    
    NSDictionary *locationUpdateData = @{PARAM_LAT: @(randomLat), PARAM_LNG: @(randomLng)};
    
    XCTAssertFalse([self.liveMonitor handleLocationUpdateWithData:locationUpdateData]);
    
}

-(void)testHandlingLocationUpdateEventNoLat{
    
    NSDictionary *eventData = [NSDictionary dictionaryWithDictionary:self.startJson];
    
    GGOrder *updatedOrder;
    GGDriver *updatedDriver;
    
    [GGTestUtils parseUpdateData:eventData intoOrder:&updatedOrder andDriver:&updatedDriver];
    
    XCTAssertNotNil(updatedOrder);
    XCTAssertNotNil(updatedDriver);
    
     double randomLng = [GGTestUtils randomBetweenMin:-180.0 andMax:180.0];
    
    [self.liveMonitor.activeDrivers setObject:updatedDriver forKey:updatedDriver.uuid];
    [self.liveMonitor.activeOrders setObject:updatedOrder forKey:updatedOrder.uuid];
    
    NSDictionary *locationUpdateData = @{PARAM_LAT: [NSNull null], PARAM_LNG: @(randomLng)};
    
    XCTAssertFalse([self.liveMonitor handleLocationUpdateWithData:locationUpdateData]);
    
}

-(void)testHandlingLocationUpdateEventNoLng{
    
    NSDictionary *eventData = [NSDictionary dictionaryWithDictionary:self.startJson];
    
    GGOrder *updatedOrder;
    GGDriver *updatedDriver;
    
    [GGTestUtils parseUpdateData:eventData intoOrder:&updatedOrder andDriver:&updatedDriver];
    
    XCTAssertNotNil(updatedOrder);
    XCTAssertNotNil(updatedDriver);
    
    double randomLat = [GGTestUtils randomBetweenMin:-90.0 andMax:90.0];
    
    [self.liveMonitor.activeDrivers setObject:updatedDriver forKey:updatedDriver.uuid];
    [self.liveMonitor.activeOrders setObject:updatedOrder forKey:updatedOrder.uuid];
    
    NSDictionary *locationUpdateData = @{PARAM_LAT: @(randomLat), PARAM_LNG: [NSNull null]};
    
    XCTAssertFalse([self.liveMonitor handleLocationUpdateWithData:locationUpdateData]);
    
}

@end
