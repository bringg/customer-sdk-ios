//
//  GGTestUtils.m
//  BringgTracking
//
//  Created by Matan on 05/11/2015.
//  Copyright © 2015 Matan Poreh. All rights reserved.
//

#import "GGTestUtils.h"
#import "BringgGlobals.h"

#import "GGOrder.h"
#import "GGDriver.h"
#import "GGSharedLocation.h"
#import "GGWaypoint.h"
#import "GGBringgUtils.h"

@implementation GGTestUtils

+ (nullable NSDictionary *)parseJsonFile:(NSString *_Nonnull)fileName{
    
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:fileName ofType:@"json"];
    NSString *jsonString = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
    // Parse the string into JSON
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
    
    if (json) {
        return json;
    }else{
        return nil;
    }

}


+(void)parseUpdateData:(NSDictionary * _Nonnull)eventData intoOrder:(GGOrder *_Nonnull *_Nonnull)order andDriver:(GGDriver *_Nonnull  *_Nonnull)driver{
    
    
   // NSString *orderUUID = [eventData objectForKey:PARAM_UUID];
    //NSNumber *orderStatus = [eventData objectForKey:PARAM_STATUS];
    
     *order = [[GGOrder alloc] initOrderWithData:eventData];
     *driver = [eventData objectForKey:PARAM_DRIVER] ? [[GGDriver alloc] initDriverWithData:[eventData objectForKey:PARAM_DRIVER]] : nil;
}


+(nonnull NSString *)exampleOrderJsonData{
    
    return @"{ \"accept_time\": \"2015-11-15T12:22:45.000Z\", \"active_way_point_id\": 351987, \"address\": \"Habarzel 10, Tel Aviv\", \"automatically_assigned\": false, \"automatically_ended\": \"0\", \"automatically_started\": \"0\", \"created_at\": \"2015-11-15T12:22:03.000Z\", \"customer_id\": 102961, \"dispatcher_id\": null, \"driver\": { \"access_token\": \"\", \"accuracy\": \"1414\", \"active_shift_id\": 23990, \"admin\": false, \"authentication_token\": \"fjbhmct1gXbxSsJ_rq8q\", \"authorization_flags\": \"{}\", \"average_rating\": 4, \"battery\": 93, \"belongs_to_partner\": \"true\", \"beta\": false, \"blocked_email\": \"false\", \"confirmation_code\": \"\", \"confirmation_token\": \"\", \"created_at\": \"2015-08-03T12:40:07.000Z\", \"current_sign_in_ip\": \"\", \"current_task_id\": \"\", \"debug\": false, \"default_user_activity\": \"5\", \"delete_at\": \"\", \"device_model\": \"\", \"dispatcher\": false, \"dispatcher_push_token\": \"\", \"driver\": true, \"driver_current_sign_in_at\": \"2015-11-15T11:57:28.000Z\", \"driver_last_sign_in_at\": \"2015-11-15T11:57:28.000Z\", \"driver_sign_in_count\": 19, \"email\": \"matan@bringg.com\", \"encrypted_password\": \"$2a$10$1NL49kR/L5wkpdNVCljlbuRBPZ6GtMS01z5hbJg8DJtXFzd.0dIp2\", \"external_id\": \"14065\", \"feature_flags\": null, \"id\": 14065, \"job_description\": \"the MAC\", \"language\": \"\", \"last_sign_in_at\": \"2015-11-15T12:22:50.000Z\", \"last_sign_in_ip\": \"\", \"lat\": 32.10948, \"lng\": 34.82962, \"merchant_id\": 8250, \"mobile_type\": \"2\", \"mobile_version\": \"I1.8.8\", \"name\": \"Matan P\", \"original_phone_number\": \"054 -554-1748\", \"partner_user\": false, \"password_hash\": \"\", \"password_salt\": \"\", \"phone\": \"+972545541748\", \"previous_lat\": \"32.10939\", \"previous_lng\": \"34.82979\", \"profile_image\": \"https://task-images.s3.amazonaws.com/uploads/user/uploaded_profile_image/14065/265d775e-3953-48e6-9b88-6a0cd2efb313.png\", \"push_token\": \"f8e345e8099b3400cca4250503de6eb7a190c3c7d94c586b237c682622936c07\", \"reset_password_token\": \"\", \"sign_in_count\": \"0\", \"status\": \"online\", \"sub\": \"checked-in\", \"time_since_last_update\": \"19\", \"update_at\": \"1447591110\", \"updated_at\": \"2015-11-15T12:22:52.000Z\", \"uploaded_profile_image\": \"265d775e-3953-48e6-9b88-6a0cd2efb313.png\", \"user_id\": \"14065\", \"uuid\": \"3d000d93-d6d7-457e-af6e-4898fe35ebad\" }, \"driver_uuid\": \"3d000d93-d6d7-457e-af6e-4898fe35ebad\", \"external_id\": \"287023\", \"id\": 287023, \"lat\": \"32.1069545\", \"late\": false, \"lng\": \"34.8362435\", \"merchant_id\": 8250, \"origin_id\": \"39067\", \"priority\": 287023, \"scheduled_at\": \"2015-11-16T12:22:03.000Z\", \"shift_id\": 36414, \"start_lat\": \"32.10948\", \"start_lng\": \"34.82962\", \"started_time\": \"2015-11-15T12:22:50.000Z\", \"status\": 3, \"tag_id\": null, \"team_ids\": [], \"title\": \"The Kiosk\", \"total_price\": 17250, \"updated_at\": \"2015-11-15T12:22:52.000Z\", \"user_id\": 14065, \"uuid\": \"7a427fe0-8b93-11e5-a3f8-c18e1b1d45b8\", \"way_points\": [ { \"address\": \"Habarzel 10, Tel Aviv\", \"address_second_line\": null, \"allow_editing_inventory\": true, \"allow_scanning_inventory\": false, \"asap\": false, \"automatically_checked_in\": 1, \"automatically_checked_out\": 0, \"checkin_lat\": 32.1069548, \"checkin_lng\": 34.8362434, \"checkin_time\": \"2015-11-15T12:22:49.000Z\", \"checkout_lat\": null, \"checkout_lng\": null, \"checkout_time\": null, \"created_at\": \"2015-11-15T12:22:03.279Z\", \"customer_id\": 102961, \"delete_at\": null, \"distance_traveled_client\": 0, \"distance_traveled_server\": null, \"done\": false, \"email\": \"matan@bringg.com\", \"estimated_distance\": 915, \"estimated_time\": 228, \"eta\": \"2015-11-15T12:26:38.982Z\", \"etl\": \"2015-11-15T12:26:38.982Z\", \"etos\": 300, \"find_me\": false, \"id\": 351987, \"lat\": 32.1069545, \"late\": false, \"lng\": 34.8362435, \"merchant_id\": 8250, \"must_approve_inventory\": false, \"note\": null, \"phone\": \"+972545541748\", \"place_id\": null, \"position\": 0, \"scheduled_at\": \"2015-11-16T12:22:03.212Z\", \"silent\": false, \"start_lat\": 32.10948, \"start_lng\": 34.82962, \"start_time\": \"2015-11-15T12:22:50.459Z\", \"task_id\": 287023, \"updated_at\": \"2015-11-15T12:22:52.519Z\", \"zipcode\": null } ] }";
}

+ (nonnull NSString *)exampleLocationJsonData{
    return @"{\"alerting_token\":\"fa8ab9e0-86e0-11e5-81aa-a7b73b65a3c7\",\"alerting_url\":\"https://realtime2-api.bringg.com/api/public_alert/fa8a92d0-86e0-11e5-81aa-a7b73b65a3c7\",\"arrived\":0,\"current_lat\":\"32.10644\",\"current_lng\":\"34.83514\",\"destination_lat\":0,\"destination_lng\":0,\"done\":0,\"driver_activity\":5,\"driver_id\":4651,\"driver_uuid\":\"fbf3b24a-8375-4309-b878-b7beb407b0a2\",\"embedded\":0,\"employee_image\":\"https://task-images.s3.amazonaws.com/uploads/user/uploaded_profile_image/4651/ab862ef7-968a-489a-89b9-cd705f9d0264.png\",\"employee_name\":\"Matan\",\"employee_phone\":\"+972545674815\",\"expired\":0,\"find_me_token\":\"<null>\",\"find_me_url\":\"https://realtime2-api.bringg.com/api/customer/task/278265/find_me/fa8a92d0-86e0-11e5-81aa-a7b73b65a3c7\",\"hide_call_to_driver\":0,\"hide_footer\":0,\"hide_note_to_driver\":0,\"job_description\":\"Titush\",\"merchant_name\":\"Bringg1\",\"monitor_url\":\"https://realtime2-api.bringg.com\",\"note_token\":\"fa8ab9e2-86e0-11e5-81aa-a7b73b65a3c7\",\"note_url\":\"https://realtime2-api.bringg.com/api/notes/fa8a92d0-86e0-11e5-81aa-a7b73b65a3c7\",\"order_uuid\":\"1984aae4-8c48-4697-b228-e90b79b70a5c\",\"rate_us_title_tring\":\"<null>\",\"rating\":\"<null>\",\"rating_reason\":{\"items\":[{\"icon\":\"images/post_rating/d7241283.time.png\",\"id\":52,\"text\":\"Werewelate?\"},{\"icon\":\"images/post_rating/e86c1178.damage.png\",\"id\":50,\"text\":\"Didwebrakesomething?\"},{\"icon\":\"images/post_rating/a91f18eb.emoticon_3.png\",\"id\":51,\"text\":\"Werewerude?\"},{\"icon\":\"images/post_rating/6936d17a.dispatch.png\",\"id\":49,\"text\":\"Wronglocation?\"},{\"icon\":\"images/post_rating/6936d17a.dispatch.png\",\"id\":73,\"text\":\"Unabletocommunicatewithdriver?\"}],\"rating\":4,\"rating_reason_url\":\"https://realtime2-api.bringg.com/api/rating_reason/fa8a92d0-86e0-11e5-81aa-a7b73b65a3c7\",\"title\":\"PleaseHelpUsImprove\",\"use\":1},\"rating_token\":\"fa8ab9e1-86e0-11e5-81aa-a7b73b65a3c7\",\"rating_url\":\"https://realtime2-api.bringg.com/api/rate/fa8a92d0-86e0-11e5-81aa-a7b73b65a3c7\",\"route\":0,\"status\":\"ok\",\"support_find_me\":1,\"tipConfiguration\":{\"tipAmounts\":{\"0\":5,\"1\":10,\"2\":15},\"tipCurrency\":\"ILS\",\"tipDriverEnabled\":1,\"tipOtherAmountEnabled\":1,\"tipRequireSignature\":1,\"tipSignatureUploadPath\":\"https://realtime2-api.bringg.com/api/customer/task/278265/tip_upload_url/fa8a92d0-86e0-11e5-81aa-a7b73b65a3c7\",\"tipType\":0,\"tipUrl\":\"https://realtime2-api.bringg.com/api/customer/task/278265/tip/fa8a92d0-86e0-11e5-81aa-a7b73b65a3c7\"},\"tip_token\":\"<null>\",\"uuid\":\"fa8a92d0-86e0-11e5-81aa-a7b73b65a3c7\",\"way_point_id\":\"<null>\"}";
}



@end
