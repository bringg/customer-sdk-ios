//
//  GGBringgUtilsTests.m
//  BringgTracking
//
//  Created by Matan on 23/06/2016.
//  Copyright © 2016 Matan Poreh. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GGBringgUtils.h"
#import "BringgGlobals.h"

@interface GGBringgUtilsTests : XCTestCase

@end

@implementation GGBringgUtilsTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testParseCompoundUUID{
    // test no compound key, invalid compound key, valid compound key
    
    NSString *compoundUUID;
    
    NSString *orderUUID;
    NSString *sharedUUID;
    
    NSError *error;
    
    
    [GGBringgUtils parseOrderCompoundUUID:compoundUUID toOrderUUID:&orderUUID andSharedUUID:&sharedUUID error:&error];
    
    // since comound uuid is empty we should have an error
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, GGErrorTypeUUIDNotFound);
    
    
    compoundUUID = @"asldfhasl fhaksldjhf asldkfj asdlfjkasdf";
    error = nil;
    
    [GGBringgUtils parseOrderCompoundUUID:compoundUUID toOrderUUID:&orderUUID andSharedUUID:&sharedUUID error:&error];
    
    // since comound uuid is empty we should have an error
    XCTAssertNotNil(error);
    XCTAssertEqual(error.code, GGErrorTypeInvalidUUID);
    
    compoundUUID = @"SOME_ORDER_UUID$$SOME_SHARED_UUID";
    error = nil;
     [GGBringgUtils parseOrderCompoundUUID:compoundUUID toOrderUUID:&orderUUID andSharedUUID:&sharedUUID error:&error];
    
    XCTAssertNil(error);
    XCTAssertNotNil(orderUUID);
    XCTAssertNotNil(sharedUUID);
    XCTAssertTrue([orderUUID isEqualToString: @"SOME_ORDER_UUID"]);
    XCTAssertTrue([sharedUUID isEqualToString: @"SOME_SHARED_UUID"]);

    
}
@end
