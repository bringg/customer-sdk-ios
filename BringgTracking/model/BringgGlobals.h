//
//  BringgGlobals.h
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#ifndef BringgTracking_BringgGlobals_h
#define BringgTracking_BringgGlobals_h


#define PARAM_STATUS @"status"
#define PARAM_CUSTOMER @"customer"
#define PARAM_CUSTOMER_ID @"customer_id"
#define PARAM_ORDER_ID @"task_id"
#define PARAM_ORDER_UUID @"order_uuid"
#define PARAM_MERCHANT_ID @"merchant_id"
#define PARAM_DRIVER @"driver"
#define PARAM_DRIVER_ID @"driver_id"
#define PARAM_DRIVER_UUID @"driver_uuid"
#define PARAM_SHARE_UUID @"share_uuid"
#define PARAM_WAY_POINT_ID @"way_point_id"
#define PARAM_ID @"id"
#define PARAM_ADDRESS @"address"
#define PARAM_UUID @"uuid"
#define PARAM_NAME @"name"
#define PARAM_LAT @"lat"
#define PARAM_LNG @"lng"
#define PARAM_CURRENT_LAT @"current_lat"
#define PARAM_CURRENT_LNG @"current_lng"
#define PARAM_ACTIVITY @"activity"
#define PARAM_DRIVER_ACTIVITY @"driver_activity"
#define PARAM_DRIVER_AVG_RATING @"average_rating"
#define PARAM_DRIVER_AVG_RATING_IN_SHARED_LOCATION @"driver_average_rating"
#define PARAM_DRIVER_IMAGE_URL @"profile_image"
#define PARAM_DRIVER_IMAGE_URL2 @"employee_image"
#define PARAM_DRIVER_PHONE @"employee_phone"
#define PARAM_DRIVER_PHONE2 @"phone"
#define PARAM_SHARED_LOCATION @"shared_location"
#define PARAM_WAYPOINTS @"way_points"
#define PARAM_DRIVER_TOKEN_URL @"rating_url"

#define PARAM_ETA @"eta"
#define PARAM_RATING_TOKEN @"rating_token"
#define PARAM_DRIVER_NAME @"employee_name"


#define DEFINE_SHARED_INSTANCE_USING_BLOCK(block) \
static dispatch_once_t pred = 0; \
__strong static id _sharedObject = nil; \
dispatch_once(&pred, ^{ \
_sharedObject = block(); \
}); \
return _sharedObject;

@class GGOrder;
@class GGDriver;
@class GGCustomer;
@class GGRating;
@class GGSharedLocation;

@protocol OrderDelegate <NSObject>
- (void)watchOrderFailForOrder:(GGOrder *)order error:(NSError *)error;
- (void)orderDidAssignWithOrder:(GGOrder *)order withDriver:(GGDriver *)driver;
- (void)orderDidAcceptWithOrder:(GGOrder *)order withDriver:(GGDriver *)driver;
- (void)orderDidStartWithOrder:(GGOrder *)order withDriver:(GGDriver *)driver;
@optional
- (void)orderDidArrive:(GGOrder *)order withDriver:(GGDriver *)driver;
- (void)orderDidFinish:(GGOrder *)order withDriver:(GGDriver *)driver;
- (void)orderDidCancel:(GGOrder *)order withDriver:(GGDriver *)driver;

@end

@protocol DriverDelegate <NSObject>
- (void)watchDriverFailedForDriver:(GGDriver *)driver error:(NSError *)error;
@optional
- (void)driverLocationDidChangeWithDriver:(GGDriver *)driver;

@end

@protocol WaypointDelegate <NSObject>
- (void)watchWaypointFailedForWaypointId:(NSNumber *)waypointId error:(NSError *)error;
@optional
- (void)waypointDidUpdatedWaypointId:(NSNumber *)waypointId eta:(NSDate *)eta;
- (void)waypointDidArrivedWaypointId:(NSNumber *)waypointId;
- (void)waypointDidFinishedWaypointId:(NSNumber *)waypointId;

@end


typedef NS_ENUM(NSInteger, OrderStatus) {
    OrderStatusInvalid = -1,
    OrderStatusCreated = 0,
    OrderStatusAssigned = 1,
    OrderStatusOnTheWay = 2,
    OrderStatusCheckedIn = 3,
    OrderStatusDone = 4,
    OrderStatusAccepted = 6,
    OrderStatusCancelled = 7,
    OrderStatusRejected = 8,
    OrderStatusRemotelyDeleted = 200
    
};

#endif
