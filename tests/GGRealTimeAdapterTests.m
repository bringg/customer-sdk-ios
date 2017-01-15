//
//  GGRealTimeAdapterTests.m
//  BringgTracking
//
//  Created by Matan on 12/01/2017.
//  Copyright © 2017 Bringg. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GGRealTimeAdapter.h"
@interface GGRealTimeAdapterTests : XCTestCase

@end

@implementation GGRealTimeAdapterTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testErrorAckWithSuccessTrue{
    
    NSDictionary *responseData = @{ @"expired" : @1,
                                    @"message" : @"Task 0e27a510-7184-4906-966a-e7dd92b514ab share expired",
                                    @"success" : @1};
    
    NSError *error;
    
    [GGRealTimeAdapter errorAck:responseData error:&error];
    
    XCTAssertNil(error); // we expect no error since success is true (this is bad json structure for error)
    
}

- (void)testErrorAckWithSuccessFalse{
    
    NSDictionary *responseData = @{ @"expired" : @1,
                                    @"message" : @"Task 0e27a510-7184-4906-966a-e7dd92b514ab share expired",
                                    @"success" : @0};
    
    NSError *error;
    
    [GGRealTimeAdapter errorAck:responseData error:&error];
    
    XCTAssertNotNil(error);
    
    XCTAssertTrue([[[error userInfo] valueForKey:NSLocalizedDescriptionKey] isEqualToString:@"Task 0e27a510-7184-4906-966a-e7dd92b514ab share expired"]);
}

@end
