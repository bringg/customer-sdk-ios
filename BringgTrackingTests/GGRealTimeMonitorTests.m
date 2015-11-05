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


@interface GGRealTimeMonitorTests : XCTestCase

@property (nonatomic, strong) GGRealTimeMontior *liveMonitor;

@property (nullable, nonatomic, strong) NSDictionary *acceptJson;
@property (nullable, nonatomic, strong) NSDictionary *startJson;



@end

@implementation GGRealTimeMonitorTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
   
    self.liveMonitor = [GGRealTimeMontior sharedInstance];
    
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

@end
