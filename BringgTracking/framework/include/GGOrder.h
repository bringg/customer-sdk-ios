//
//  BringgOrder.h
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BringgGlobals.h"

@class GGSharedLocation;
@class GGDriver;


#define GGOrderStoreKeyTitle                @"title"
#define GGOrderStoreKeyAmount               @"totalPrice"
#define GGOrderStoreKeyID                   @"orderid"

#define GGOrderStoreKeyLate                 @"late"
#define GGOrderStoreKeyStatus               @"status"
#define GGOrderStoreKeySharedLocation       @"sharedLocation"
#define GGOrderStoreKeySharedLocationUUID   @"sharedLocationUUID"
#define GGOrderStoreKeyUUID                 @"uuid"
#define GGOrderStoreKeyDriverUUID           @"driverUUID"
#define GGOrderStoreKeyDriver               @"driver"
#define GGOrderStoreKeyURL                  @"url"
#define GGOrderStoreKeyCustomerID           @"customerId"
#define GGOrderStoreKeyWaypoints            @"waypoints"
#define GGOrderStoreKeyWaypoint             @"waypoint%lu"

@interface GGOrder : NSObject <NSCoding>


@property (nonatomic, strong) GGSharedLocation * __nullable sharedLocation;
//@property (nonatomic, strong) GGDriver *driver;

@property (nonatomic, copy) NSString * __nonnull uuid;
@property (nonatomic, copy) NSString * __nullable title;
@property (nonatomic, copy) NSString * __nullable url;
@property (nonatomic, copy) NSString * __nullable driverUUID;
@property (nonatomic, copy) NSString * __nullable sharedLocationUUID;

@property (nonatomic, assign) double totalPrice;
@property (nonatomic, assign) double tip;
@property (nonatomic, assign) double leftToBePaid;

@property (nonatomic, assign) NSInteger activeWaypointId;
@property (nonatomic, assign) NSInteger orderid;
@property (nonatomic, assign) NSInteger customerId;
@property (nonatomic, assign) NSInteger merchantId;
@property (nonatomic, assign) NSInteger priority;
@property (nonatomic, assign) NSInteger driverId;

@property (nonatomic, assign) BOOL late;


@property (nonatomic, assign) OrderStatus status;
@property (nonatomic, strong) NSMutableArray * __nonnull waypoints;
@property (nonatomic, strong) NSDate * __nullable scheduled;
/**
 *  init an Order object using json data recieved from a server response
 *
 *  @param data a dictionary representing the json response object
 *
 *  @return an Order object
 */
-(nonnull instancetype)initOrderWithData:(NSDictionary*__nullable)data;

/**
 *  init an Order object with just a uuid and current status
 *
 *  @param ouuid   uuid of the order
 *  @param ostatus order status
 *  @see BringgGlobals.h
 *
 *  @return an Order object
 */
-(nonnull instancetype)initOrderWithUUID:(NSString * __nonnull)ouuid atStatus:(OrderStatus)ostatus;

/**
 *  updates the order status
 *
 *  @param newStatus
 */
-(void)updateOrderStatus:(OrderStatus)newStatus;

@end
