//
//  GGNetworkUtilsTests.m
//  BringgTracking
//
//  Created by Matan on 10/07/2016.
//  Copyright © 2016 Matan Poreh. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GGNetworkUtils.h"
@interface GGNetworkUtilsTests : XCTestCase

@end

@implementation GGNetworkUtilsTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void)testQueryStringFromParams{
    
    // test util when nil params
    XCTAssertNoThrow( [GGNetworkUtils queryStringFromParams:nil]);
    
    NSString *qs = [GGNetworkUtils queryStringFromParams:nil];
   
    XCTAssertNotNil(qs);
    // expected empty q string since no params
    XCTAssertTrue([qs isEqualToString:@""]);
    
    NSDictionary *params = @{};
    
    // test util with empty params
    qs = [GGNetworkUtils queryStringFromParams:params];
    XCTAssertNotNil(qs);
     // expected empty q string since params empty
    XCTAssertTrue([qs isEqualToString:@""]);
    
    // test util where params value is not a string
    params = @{@"numeric": @12345};
    XCTAssertNoThrow( [GGNetworkUtils queryStringFromParams:params]);
    qs = [GGNetworkUtils queryStringFromParams:params];
    XCTAssertNotNil(qs);
    // expected true q string
    XCTAssertTrue([qs isEqualToString:@"?numeric=12345"]);
    
    //test utils where param key isnt a string
    params = @{@12345:@67890};
    
    // test util with empty params
    qs = [GGNetworkUtils queryStringFromParams:params];
    XCTAssertNotNil(qs);
    // expected empty q string since key isnt string
    XCTAssertTrue([qs isEqualToString:@""]);
}


- (void)testParsingJsonResponses{
    // the json parse util purpuse is to infer from  the json object did the action succeed or fail
    // the util isnt responsbile for conevrting to a true NSObject.
    
    BOOL didSuccedd = YES;
    NSError *didError;
    
    // test response with error message key
    NSDictionary *jsonDict = @{@"status":@"error", BCMessageKey:@"error message"};
    
    [GGNetworkUtils parseStatusOfJSONResponse:jsonDict toSuccess:&didSuccedd andError:&didError];
    XCTAssertFalse(didSuccedd);
    XCTAssertNotNil(didError);
    XCTAssertTrue([[didError.userInfo objectForKey:NSLocalizedDescriptionKey] isEqualToString:@"error message"]);

    // test response where there is a success key (test where values are numbers and strings
    
    // reset params before each test
    didSuccedd = YES;
    didError = nil;
    jsonDict = @{BCSuccessKey:@NO, @"somedata":@[@"array"]};
    [GGNetworkUtils parseStatusOfJSONResponse:jsonDict toSuccess:&didSuccedd andError:&didError];
    XCTAssertFalse(didSuccedd); // expected false since value in json is false
    XCTAssertNotNil(didError);
    XCTAssertTrue([[didError.userInfo objectForKey:NSLocalizedDescriptionKey] isEqualToString:@"Undefined Error"]);
    
    didSuccedd = YES;
    didError = nil;
    jsonDict = @{BCSuccessKey:@YES, @"somedata":@[@"array"]};
    [GGNetworkUtils parseStatusOfJSONResponse:jsonDict toSuccess:&didSuccedd andError:&didError];
    XCTAssertTrue(didSuccedd); // expected true since value in json is true
    XCTAssertNil(didError);
    
    
    didSuccedd = YES;
    didError = nil;
    jsonDict = @{BCSuccessKey:@"false", @"somedata":@[@"array"]};
    [GGNetworkUtils parseStatusOfJSONResponse:jsonDict toSuccess:&didSuccedd andError:&didError];
    XCTAssertFalse(didSuccedd); // expected false since value in json is false
    XCTAssertNotNil(didError);
    XCTAssertTrue([[didError.userInfo objectForKey:NSLocalizedDescriptionKey] isEqualToString:@"Undefined Error"]);
    
    didSuccedd = YES;
    didError = nil;
    jsonDict = @{BCSuccessKey:@"true", @"somedata":@[@"array"]};
    [GGNetworkUtils parseStatusOfJSONResponse:jsonDict toSuccess:&didSuccedd andError:&didError];
    XCTAssertTrue(didSuccedd); // expected true since value in json is true
    XCTAssertNil(didError);

    
    didSuccedd = YES;
    didError = nil;
    jsonDict = @{BCSuccessKey:@[@"false"], @"somedata":@[@"array"]};
    [GGNetworkUtils parseStatusOfJSONResponse:jsonDict toSuccess:&didSuccedd andError:&didError];
    XCTAssertTrue(didSuccedd); // expected true since when the success key is inconclusive but we have other data, we consider the response successfull
    XCTAssertNil(didError);
    
    
    didSuccedd = YES;
    didError = nil;
    jsonDict = @{BCSuccessKey:@[@"false"]};
    [GGNetworkUtils parseStatusOfJSONResponse:jsonDict toSuccess:&didSuccedd andError:&didError];
    XCTAssertTrue(didSuccedd); // expected true since default success is TRUE and no error in json
    XCTAssertNil(didError); // there should be an error since success key isinvalid which makes the util job's imposbile
    //XCTAssertTrue([[didError.userInfo objectForKey:NSLocalizedDescriptionKey] isEqualToString:@"Undefined Error"]);
    
    didSuccedd = YES;
    didError = nil;
    jsonDict = @{};
    [GGNetworkUtils parseStatusOfJSONResponse:jsonDict toSuccess:&didSuccedd andError:&didError];
    XCTAssertTrue(didSuccedd); // expected true since default success is TRUE
    XCTAssertNil(didError); // there should be an error since success key isinvalid which makes the util job's imposbile
    
    didSuccedd = YES;
    didError = nil;
    jsonDict = nil;
    [GGNetworkUtils parseStatusOfJSONResponse:jsonDict toSuccess:&didSuccedd andError:&didError];
    XCTAssertFalse(didSuccedd); // expected false since value in json success is invalid and there is no other data to process in json
    XCTAssertNotNil(didError); // there should be an error since success key isinvalid which makes the util job's imposbile
    XCTAssertTrue([[didError.userInfo objectForKey:NSLocalizedDescriptionKey] isEqualToString:@"can not parse nil response"]);
    
    
}


-(void)testGeneratingRequests{
    
    // test when creating with invalid values
    XCTAssertThrows([GGNetworkUtils jsonGetRequestWithServer:nil method:@"GET" path:nil params:nil]);
    //
    @try {
        NSMutableURLRequest *req = [GGNetworkUtils jsonGetRequestWithServer:nil method:@"GET" path:nil params:nil];
    } @catch (NSException *exception) {
        
        XCTAssertTrue([exception.name isEqualToString:@"InvalidArgumentsException"]);
    }
}

- (void)testCheckingForFullPaths{
    NSString *fullPath = @"http://10.0.1.148:3030/api/customer/task/351/find_me/";
    NSString *relativePath = @"/api/customer/confirmation/request";
    
    XCTAssertTrue([GGNetworkUtils isFullPath:fullPath]);
    XCTAssertFalse([GGNetworkUtils isFullPath:relativePath]);
}

- (void)testParsingFullPath{
    
     NSString *fullPath = @"http://10.0.1.148:3030/api/customer/task/351/find_me/5838da10-483b-11e6-992b-876217ca31ee";
    
    NSString *server = nil;
    NSString *relativePath = nil;
    
    [GGNetworkUtils parseFullPath:fullPath toServer:&server relativePath:&relativePath];
    
    XCTAssertNotNil(server);
    XCTAssertTrue([server isEqualToString:@"http://10.0.1.148:3030"]);
    
    XCTAssertNotNil(relativePath);
    XCTAssertTrue([relativePath isEqualToString:@"/api/customer/task/351/find_me/5838da10-483b-11e6-992b-876217ca31ee"]);
    
}

- (void)testParsingJsonContradictingResponse{
    NSDictionary *json = @{@"rc":@0, @"success":@0};
    BOOL success = YES;
    NSError *err;
    
    [GGNetworkUtils parseStatusOfJSONResponse:json toSuccess:&success andError:&err];
    
    XCTAssertFalse(success);
    XCTAssertNotNil(err); // should be nil since no error message
    XCTAssertTrue(err.code == 0);
    json = @{@"rc":@0, @"success":@0, @"message":@"some error happened"};
    success = YES;
    err = nil;
    
    [GGNetworkUtils parseStatusOfJSONResponse:json toSuccess:&success andError:&err];
    
    XCTAssertFalse(success);
    XCTAssertNotNil(err);
    XCTAssertTrue(err.code == 0);
    
}

- (void)testParsingExpiredResponse{
    NSDictionary *json = @{ @"expired" : @1,
                                    @"message" : @"Task 0e27a510-7184-4906-966a-e7dd92b514ab share expired",
                                    @"success" : @1};
    BOOL success = YES;
    NSError *err;
    
    [GGNetworkUtils parseStatusOfJSONResponse:json toSuccess:&success andError:&err];
    
    XCTAssertTrue(success);
    XCTAssertNil(err); // should be nil since success true
    
}

- (void)testHandlingResponse{
    
    NSDictionary *json = @{ @"expired" : @1,
                            @"message" : @"Task 0e27a510-7184-4906-966a-e7dd92b514ab share expired",
                            @"success" : @1};
    
    [GGNetworkUtils handleDataSuccessResponse:nil withData:[NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil] completionHandler:^(BOOL success, id  _Nullable JSON, NSError * _Nullable error) {
        //
        XCTAssertTrue(success);
        XCTAssertTrue([json isEqual:JSON]);
        
    }];
}

@end
