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

-(void)testParsingOrder{
    NSString *testData = @"{ \"accept_time\": \"2015-11-10T10:25:19.000Z\", \"active_way_point_id\": 342991, \"address\": \"Ha-Saraf Street 1, Ramat Hasharon, Israel\", \"automatically_assigned\": false, \"automatically_ended\": \"0\", \"automatically_started\": \"0\", \"created_at\": \"2015-11-10T10:25:14.000Z\", \"customer_id\": 78340, \"dispatcher_id\": null, \"driver\": { \"access_token\": \"\", \"accuracy\": \"65\", \"active_shift_id\": 31545, \"admin\": true, \"authentication_token\": \"bz2w6emMxqZhyEnsxJTo\", \"authorization_flags\": \"{}\", \"average_rating\": 3.75, \"battery\": 100, \"belongs_to_partner\": \"true\", \"beta\": true, \"blocked_email\": \"false\", \"confirmation_code\": \"1680\", \"confirmation_sent_at\": \"2015-05-10T07:36:49.000Z\", \"confirmation_token\": \"\", \"confirmed_at\": \"2015-05-10T07:41:28.000Z\", \"created_at\": \"2015-04-19T11:49:43.000Z\", \"current_sign_in_at\": \"2015-11-09T12:17:30.000Z\", \"current_sign_in_ip\": \"\", \"current_task_id\": \"\", \"debug\": false, \"default_user_activity\": \"5\", \"delete_at\": \"\", \"device_model\": \"\", \"dispatcher\": false, \"dispatcher_push_token\": \"\", \"driver\": true, \"driver_current_sign_in_at\": \"2015-11-09T12:10:29.000Z\", \"driver_last_sign_in_at\": \"2015-11-09T12:10:29.000Z\", \"driver_sign_in_count\": 197, \"email\": \"matan@bringg.com\", \"encrypted_password\": \"$2a$10$X4tFdBolYfGOsWOvWeZVgOflx0u2xQlPzjTCWhrFrecBlx.ACk5eq\", \"external_id\": \"4651\", \"feature_flags\": null, \"id\": 4651, \"job_description\": \"Titush\", \"language\": \"\", \"last_sign_in_at\": \"2015-11-10T10:37:35.000Z\", \"last_sign_in_ip\": \"\", \"lat\": 32.10681, \"lng\": 34.8345, \"merchant_id\": 1, \"mobile_type\": \"2\", \"mobile_version\": \"I1.8.9\", \"name\": \"Matan Poreh\", \"original_phone_number\": \"054 -554-1748\", \"partner_user\": false, \"password_hash\": \"\", \"password_salt\": \"\", \"phone\": \"+972545541748\", \"previous_lat\": \"32.1068\", \"previous_lng\": \"34.83449\", \"profile_image\": \"https://task-images.s3.amazonaws.com/uploads/user/uploaded_profile_image/4651/ab862ef7-968a-489a-89b9-cd705f9d0264.png\", \"push_token\": \"b8204bb32aab8dbba8f8f3db4f1af58303355a33b59888a3f309d84db4bf5d65\", \"reset_password_token\": \"\", \"sign_in_count\": \"86\", \"status\": \"online\", \"sub\": \"checked-in\", \"time_since_last_update\": \"11\", \"update_at\": \"1447152094\", \"updated_at\": \"2015-11-10T10:37:41.000Z\", \"uploaded_profile_image\": \"ab862ef7-968a-489a-89b9-cd705f9d0264.png\", \"user_id\": \"4651\", \"uuid\": \"fbf3b24a-8375-4309-b878-b7beb407b0a2\" }, \"driver_uuid\": \"fbf3b24a-8375-4309-b878-b7beb407b0a2\", \"external_id\": \"279382\", \"id\": 279382, \"lat\": \"32.1389704\", \"late\": false, \"lng\": \"34.8300717\", \"merchant_id\": 1, \"origin_id\": \"38692\", \"priority\": 279382, \"scheduled_at\": \"2015-11-10T10:54:38.000Z\", \"shift_id\": 35279, \"start_lat\": \"32.1068\", \"start_lng\": \"34.83448\", \"started_time\": \"2015-11-10T10:37:12.000Z\", \"status\": 3, \"tag_id\": \"5135\", \"team_ids\": [ 1 ], \"title\": \"test sdk 2\", \"updated_at\": \"2015-11-10T10:37:41.000Z\", \"user_id\": 4651, \"uuid\": \"a2f9c554-e9a6-4c21-9802-92161ff29465\", \"way_points\": [ { \"address\": \"Ha-Saraf Street 1, Ramat Hasharon, Israel\", \"address_second_line\": null, \"allow_editing_inventory\": null, \"allow_scanning_inventory\": null, \"asap\": null, \"automatically_checked_in\": 0, \"automatically_checked_out\": 0, \"checkin_lat\": 32.1389704, \"checkin_lng\": 34.8300717, \"checkin_time\": \"2015-11-10T10:37:40.000Z\", \"checkout_lat\": null, \"checkout_lng\": null, \"checkout_time\": null, \"created_at\": \"2015-11-10T10:25:14.630Z\", \"customer_id\": 78340, \"delete_at\": null, \"distance_traveled_client\": 0, \"distance_traveled_server\": null, \"done\": false, \"email\": \"\", \"estimated_distance\": 5036, \"estimated_time\": 785, \"eta\": \"2015-11-10T10:50:28.417Z\", \"etl\": \"2015-11-10T10:55:28.417Z\", \"etos\": 300, \"find_me\": false, \"id\": 342991, \"lat\": 32.1389704, \"late\": false, \"lng\": 34.8300717, \"merchant_id\": 1, \"must_approve_inventory\": null, \"note\": null, \"phone\": null, \"place_id\": null, \"position\": 1, \"scheduled_at\": \"2015-11-10T10:54:38.394Z\", \"silent\": false, \"start_lat\": 32.1068, \"start_lng\": 34.83448, \"start_time\": \"2015-11-10T10:37:12.829Z\", \"task_id\": 279382, \"updated_at\": \"2015-11-10T10:37:40.941Z\", \"zipcode\": null }, { \"address\": \"Ha-Keren ha-Kayemet Street 27, Herzliya, Israel\", \"address_second_line\": null, \"allow_editing_inventory\": null, \"allow_scanning_inventory\": null, \"asap\": null, \"automatically_checked_in\": 0, \"automatically_checked_out\": 0, \"checkin_lat\": null, \"checkin_lng\": null, \"checkin_time\": null, \"checkout_lat\": null, \"checkout_lng\": null, \"checkout_time\": null, \"created_at\": \"2015-11-10T10:25:14.907Z\", \"customer_id\": 64751, \"delete_at\": null, \"distance_traveled_client\": null, \"distance_traveled_server\": null, \"done\": false, \"email\": \"\", \"estimated_distance\": 3947, \"estimated_time\": 754, \"eta\": \"2015-11-10T11:08:02.419Z\", \"etl\": \"2015-11-10T11:13:02.419Z\", \"etos\": 300, \"find_me\": false, \"id\": 342992, \"lat\": 32.1623443, \"late\": false, \"lng\": 34.8467342, \"merchant_id\": 1, \"must_approve_inventory\": null, \"note\": null, \"phone\": null, \"place_id\": null, \"position\": 2, \"scheduled_at\": \"2015-11-10T11:24:49.607Z\", \"silent\": false, \"start_lat\": 32.1389704, \"start_lng\": 34.8300717, \"start_time\": null, \"task_id\": 279382, \"updated_at\": \"2015-11-10T10:37:23.421Z\", \"zipcode\": null }, { \"address\": \"Weizman Street 12, Herzliya, Israel\", \"address_second_line\": null, \"allow_editing_inventory\": null, \"allow_scanning_inventory\": null, \"asap\": null, \"automatically_checked_in\": 0, \"automatically_checked_out\": 0, \"checkin_lat\": null, \"checkin_lng\": null, \"checkin_time\": null, \"checkout_lat\": null, \"checkout_lng\": null, \"checkout_time\": null, \"created_at\": \"2015-11-10T10:25:14.978Z\", \"customer_id\": 64750, \"delete_at\": null, \"distance_traveled_client\": null, \"distance_traveled_server\": null, \"done\": false, \"email\": \"\", \"estimated_distance\": 1524, \"estimated_time\": 288, \"eta\": \"2015-11-10T11:17:50.420Z\", \"etl\": \"2015-11-10T11:22:50.420Z\", \"etos\": 300, \"find_me\": false, \"id\": 342993, \"lat\": 32.1638542, \"late\": false, \"lng\": 34.8350625, \"merchant_id\": 1, \"must_approve_inventory\": null, \"note\": null, \"phone\": null, \"place_id\": null, \"position\": 3, \"scheduled_at\": \"2015-11-10T11:54:56.887Z\", \"silent\": false, \"start_lat\": 32.1623443, \"start_lng\": 34.8467342, \"start_time\": null, \"task_id\": 279382, \"updated_at\": \"2015-11-10T10:37:23.422Z\", \"zipcode\": null } ] }";
    
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
