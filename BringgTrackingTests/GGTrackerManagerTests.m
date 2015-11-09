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

@interface GGTrackerManagerTests : XCTestCase

@property (nonatomic, strong) GGTrackerManager *trackerManager;
@property (nonatomic, strong) GGTestRealTimeDelegate  *realtimeDelegate;
@property (nullable, nonatomic, strong) NSDictionary *acceptJson;
@property (nullable, nonatomic, strong) NSDictionary *startJson;

@end

@implementation GGTrackerManagerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
     self.realtimeDelegate = [[GGTestRealTimeDelegate alloc] init];
    self.trackerManager = [GGTrackerManager trackerWithCustomerToken:nil andDeveloperToken:nil andDelegate:self.realtimeDelegate andHTTPManager:nil];
   
    
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
    
    [self.trackerManager.liveMonitor addAndUpdateOrder:updatedOrder];
    GGOrder *order = [self.trackerManager.liveMonitor.activeOrders objectForKey:updatedOrder.uuid];

    
    [self.trackerManager.liveMonitor.orderDelegates setObject:self.realtimeDelegate forKey:order.uuid];
    
    XCTAssertEqual(self.trackerManager.monitoredOrders.count, 1);
}


-(void)testMonitoredDrivers{
    
    // test on accept data
    NSDictionary *eventData = [NSDictionary dictionaryWithDictionary:self.acceptJson];
    
    GGOrder *updatedOrder;
    GGDriver *updatedDriver;
    
    [GGTestUtils parseUpdateData:eventData intoOrder:&updatedOrder andDriver:&updatedDriver];
    
    [self.trackerManager.liveMonitor addAndUpdateDriver:updatedDriver];
    GGDriver *driver = [self.trackerManager.liveMonitor.activeDrivers objectForKey:updatedDriver.uuid];
    
     NSString *compoundKey = [[driver.uuid stringByAppendingString:DRIVER_COMPOUND_SEPERATOR] stringByAppendingString:driver.uuid];
    
    
    [self.trackerManager.liveMonitor.driverDelegates setObject:self.realtimeDelegate forKey:compoundKey];
    
    NSLog(@"%@", self.trackerManager.monitoredDrivers);
    
    XCTAssertEqual(self.trackerManager.monitoredDrivers.count, 1);
    
    // also test compound key parsing
    
    
    NSString *driverUUID;
    NSString *sharedUUID;
    
    [self.trackerManager parseDriverCompoundKey:compoundKey toDriverUUID:&driverUUID andSharedUUID:&sharedUUID];
    
    XCTAssertTrue([driverUUID isEqualToString:sharedUUID]);
    
}

-(void)testParsingSharedLocation{
    
    NSString *testData = @"{\"alerting_token\":\"fa8ab9e0-86e0-11e5-81aa-a7b73b65a3c7\",\"alerting_url\":\"https://realtime-api.bringg.com/api/public_alert/fa8a92d0-86e0-11e5-81aa-a7b73b65a3c7\",\"arrived\":0,\"current_lat\":\"32.10644\",\"current_lng\":\"34.83514\",\"destination_lat\":0,\"destination_lng\":0,\"done\":0,\"driver_activity\":5,\"driver_id\":4651,\"driver_uuid\":\"fbf3b24a-8375-4309-b878-b7beb407b0a2\",\"embedded\":0,\"employee_image\":\"https://task-images.s3.amazonaws.com/uploads/user/uploaded_profile_image/4651/ab862ef7-968a-489a-89b9-cd705f9d0264.png\",\"employee_name\":\"Matan\",\"employee_phone\":\"+972545674815\",\"expired\":0,\"find_me_token\":\"<null>\",\"find_me_url\":\"https://realtime-api.bringg.com/api/customer/task/278265/find_me/fa8a92d0-86e0-11e5-81aa-a7b73b65a3c7\",\"hide_call_to_driver\":0,\"hide_footer\":0,\"hide_note_to_driver\":0,\"job_description\":\"Titush\",\"merchant_name\":\"Bringg1\",\"monitor_url\":\"https://realtime-api.bringg.com\",\"note_token\":\"fa8ab9e2-86e0-11e5-81aa-a7b73b65a3c7\",\"note_url\":\"https://realtime-api.bringg.com/api/notes/fa8a92d0-86e0-11e5-81aa-a7b73b65a3c7\",\"order_uuid\":\"1984aae4-8c48-4697-b228-e90b79b70a5c\",\"rate_us_title_tring\":\"<null>\",\"rating\":\"<null>\",\"rating_reason\":{\"items\":[{\"icon\":\"images/post_rating/d7241283.time.png\",\"id\":52,\"text\":\"Werewelate?\"},{\"icon\":\"images/post_rating/e86c1178.damage.png\",\"id\":50,\"text\":\"Didwebrakesomething?\"},{\"icon\":\"images/post_rating/a91f18eb.emoticon_3.png\",\"id\":51,\"text\":\"Werewerude?\"},{\"icon\":\"images/post_rating/6936d17a.dispatch.png\",\"id\":49,\"text\":\"Wronglocation?\"},{\"icon\":\"images/post_rating/6936d17a.dispatch.png\",\"id\":73,\"text\":\"Unabletocommunicatewithdriver?\"}],\"rating\":4,\"rating_reason_url\":\"https://realtime-api.bringg.com/api/rating_reason/fa8a92d0-86e0-11e5-81aa-a7b73b65a3c7\",\"title\":\"PleaseHelpUsImprove\",\"use\":1},\"rating_token\":\"fa8ab9e1-86e0-11e5-81aa-a7b73b65a3c7\",\"rating_url\":\"https://realtime-api.bringg.com/api/rate/fa8a92d0-86e0-11e5-81aa-a7b73b65a3c7\",\"route\":0,\"status\":\"ok\",\"support_find_me\":1,\"tipConfiguration\":{\"tipAmounts\":{\"0\":5,\"1\":10,\"2\":15},\"tipCurrency\":\"ILS\",\"tipDriverEnabled\":1,\"tipOtherAmountEnabled\":1,\"tipRequireSignature\":1,\"tipSignatureUploadPath\":\"https://realtime-api.bringg.com/api/customer/task/278265/tip_upload_url/fa8a92d0-86e0-11e5-81aa-a7b73b65a3c7\",\"tipType\":0,\"tipUrl\":\"https://realtime-api.bringg.com/api/customer/task/278265/tip/fa8a92d0-86e0-11e5-81aa-a7b73b65a3c7\"},\"tip_token\":\"<null>\",\"uuid\":\"fa8a92d0-86e0-11e5-81aa-a7b73b65a3c7\",\"way_point_id\":\"<null>\"}";
    
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


@end
