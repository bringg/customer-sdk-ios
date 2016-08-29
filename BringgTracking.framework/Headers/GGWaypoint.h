//
//  GGWaypoint.h
//  BringgTracking
//
//  Created by Matan on 8/9/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BringgGlobals.h"



#define GGWaypointStoreKeyOrderID @"orderid"
#define GGWaypointStoreKeyID @"waypointid"
#define GGWaypointStoreKeyCustomerID @"customerId"
#define GGWaypointStoreKeyMerchantID @"merchantId"
#define GGWaypointStoreKeyPosition @"position"

#define GGWaypointStoreKeyDone @"done"
#define GGWaypointStoreKeyASAP @"asap"
#define GGWaypointStoreKeyAllowFindMe @"findme"

#define GGWaypointStoreKeyAddress @"address"
#define GGWaypointStoreKeyLatitude @"latitude"
#define GGWaypointStoreKeyLongitude @"longitude"

#define GGWaypointStoreKeyETA @"eta"

#define GGWaypointStoreKeyStartTime @"startTime"
#define GGWaypointStoreKeyArriveTime @"arriveTime"
#define GGWaypointStoreKeyDoneTime @"doneTime"

@interface GGWaypoint : NSObject<NSCoding>


@property (nonatomic, assign) NSInteger orderid;
@property (nonatomic, assign) NSInteger waypointId;
@property (nonatomic, assign) NSInteger customerId;
@property (nonatomic, assign) NSInteger merchantId;
@property (nonatomic, assign) NSInteger position;

@property (nonatomic, assign) BOOL done;
@property (nonatomic, assign) BOOL ASAP;
@property (nonatomic, assign) BOOL allowFindMe;

@property (nonatomic, strong) NSString *address;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;

@property (nonatomic, strong) NSString *ETA;

@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *checkinTime;
@property (nonatomic, strong) NSDate *doneTime;

-(id)initWaypointWithData:(NSDictionary*)data;

/*
 * example response for waypoint
{
    "way_points": [
                   {
                       "address": "Habarzel 33, Tel Aviv",
                       "address_second_line": null,
                       "allow_editing_inventory": true,
                       "allow_scanning_inventory": true,
                       "asap": false,
                       "automatically_checked_in": 0,
                       "automatically_checked_out": 0,
                       "checkin_lat": null,
                       "checkin_lng": null,
                       "checkin_time": null,
                       "checkout_lat": null,
                       "checkout_lng": null,
                       "checkout_time": null,
                       "created_at": "2015-08-23T11:50:05.622Z",
                       "customer_id": 102961,
                       "delete_at": null,
                       "distance_traveled_client": null,
                       "distance_traveled_server": null,
                       "done": false,
                       "email": null,
                       "estimated_distance": null,
                       "estimated_time": null,
                       "eta": null,
                       "etl": null,
                       "etos": null,
                       "find_me": false,
                       "id": 239176,
                       "lat": null,
                       "late": false, 
                       "lng": null, 
                       "merchant_id": 8250, 
                       "must_approve_inventory": false, 
                       "note": null, 
                       "phone": null, 
                       "place_id": null, 
                       "position": 0, 
                       "scheduled_at": "2015-08-24T11:50:05.277Z", 
                       "silent": false, 
                       "start_lat": null, 
                       "start_lng": null, 
                       "start_time": null, 
                       "task_id": 192519, 
                       "updated_at": "2015-08-23T11:50:05.622Z", 
                       "zipcode": null
                   }
                   ]
}
*/
@end
