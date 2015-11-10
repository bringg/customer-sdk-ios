//
//  BringgGlobals.h
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#ifndef BringgTracking_BringgGlobals_h
#define BringgTracking_BringgGlobals_h

#define SDK_VERSION @"1.5.0.2"
//-----------------------------------------------------------------------------

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
#define PARAM_EMAIL @"email"
#define PARAM_PHONE @"phone"
#define PARAM_FACEBOOK_ID @"facebook_id"
#define PARAM_IMAGE @"image"
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

#define PARAM_SHARED_LOCATION @"shared_location"
#define PARAM_WAYPOINTS @"way_points"
#define PARAM_RATING_URL @"rating_url"
#define PARAM_ACCESS_TOKEN @"access_token"
#define PARAM_ETA @"eta"
#define PARAM_RATING @"rating"
#define PARAM_RATING_TOKEN @"rating_token"
#define PARAM_DRIVER_NAME @"employee_name"

#import "GGBringgUtils.h"

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



/**
 *  notifies that the tracker is about to revive all previously monitored orders
 *
 *  @param orderUUID uuid of order
 */
- (void)trackerWillReviveWatchedOrder:(NSString *)orderUUID;

@end

@protocol DriverDelegate <NSObject>

/**
 *  notifies if watching a driver failed
 *
 *  @param waypointId id of driver
 *  @param error      error
 */
- (void)watchDriverFailedForDriver:(GGDriver *)driver error:(NSError *)error;
@optional

/**
 *  notifies a driver has changed location
 *
 *  @param driver the updated driver object
 */
- (void)driverLocationDidChangeWithDriver:(GGDriver *)driver;

/**
 *  notifies that the tracker is about to revive all previously monitored drivers
 *
 *  @param driverUUID uuid of driver
 *  @param sharedUUID uuid of shared
 */
- (void)trackerWillReviveWatchedDriver:(NSString *)driverUUID withSharedUUID:(NSString *)sharedUUID;

@end

@protocol WaypointDelegate <NSObject>
/**
 *  notifies if watching a waypoint failed
 *
 *  @param waypointId id of waypoint
 *  @param error      error
 */
- (void)watchWaypointFailedForWaypointId:(NSNumber *)waypointId error:(NSError *)error;
@optional

/**
 *  notifies ETA updates to a waypoint
 *
 *  @param waypointId id of waypoint
 *  @param eta        ETA
 */
- (void)waypointDidUpdatedWaypointId:(NSNumber *)waypointId eta:(NSDate *)eta;


/**
 *  notifies a driver has arrvied a waypoint
 *
 *  @param waypointId id of waypoint
 */
- (void)waypointDidArrivedWaypointId:(NSNumber *)waypointId;

/**
 *  notifies a waypoint has finished
 *
 *  @param waypointId id of waypoint
 */
- (void)waypointDidFinishedWaypointId:(NSNumber *)waypointId;

/**
 *  notifies that the tracker is about to revive all previously monitored waypoints
 *
 *  @param waypointId id of waypoint
 */
- (void)trackerWillReviveWatchedWaypoint:(NSNumber *)waypointId;

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
