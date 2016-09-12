//
//  GGOrderTests.m
//  BringgTracking
//
//  Created by Or Elmaliah on 12/09/2016.
//  Copyright © 2016 Bringg. All rights reserved.
//

#import <XCTest/XCTest.h>
#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>

#import "GGTestUtils.h"
#import "GGOrder.h"
#import "GGWaypoint.h"

@interface GGOrderTests : XCTestCase
@property (nullable, nonatomic, strong) NSDictionary *acceptJson;
@end

@implementation GGOrderTests

- (void)setUp {
    [super setUp];
    
    self.acceptJson = [GGTestUtils parseJsonFile:@"orderUpdate_onaccept"];
}

- (void)tearDown {
    [super tearDown];
    self.acceptJson = nil;
}

- (void)testOrderWayPointsCount {
    GGOrder *order = [[GGOrder alloc] initOrderWithData:self.acceptJson];
    XCTAssertNotNil(order.waypoints);
    XCTAssertTrue(order.waypoints.count == 4);
}

- (void)testOrderWayPointsOrdered {
    GGOrder *order = [[GGOrder alloc] initOrderWithData:self.acceptJson];
    XCTAssertNotNil(order.waypoints);
    
    [order.waypoints enumerateObjectsUsingBlock:^(GGWaypoint *wp, NSUInteger idx, BOOL *stop) {
        XCTAssertEqual(wp.position, idx);
    }];
}

@end
