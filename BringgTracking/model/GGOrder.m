//
//  BringgOrder.m
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import "GGOrder.h"
#import "GGSharedLocation.h"
#import "GGWaypoint.h"
#import "GGBringgUtils.h"

@implementation GGOrder

@synthesize orderid,status,uuid,sharedLocation,activeWaypointId,late,totalPrice,priority,driverId,title,customerId,merchantId,tip,leftToBePaid, waypoints;

-(id)initOrderWithData:(NSDictionary*)data{
    
    if (self = [super init]) {
        orderid = [GGBringgUtils integerFromJSON:data[PARAM_ID] defaultTo:0];
        uuid = [GGBringgUtils stringFromJSON:data[PARAM_UUID] defaultTo:nil];
        
        status = (OrderStatus)[GGBringgUtils integerFromJSON:data[PARAM_STATUS] defaultTo:0];
 
        totalPrice = [GGBringgUtils doubleFromJSON:data[@"total_price"] defaultTo:0];
        tip = [GGBringgUtils doubleFromJSON:data[@"tip"] defaultTo:0];
        leftToBePaid = [GGBringgUtils doubleFromJSON:data[@"left_to_be_paid"] defaultTo:0];
        
        activeWaypointId = [GGBringgUtils integerFromJSON:data[@"active_way_point_id"] defaultTo:0];
        customerId = [GGBringgUtils integerFromJSON:data[@"customer_id"] defaultTo:0];
        merchantId = [GGBringgUtils integerFromJSON:data[@"merchant_id"] defaultTo:0];
        priority = [GGBringgUtils integerFromJSON:data[@"priority"] defaultTo:0];
        driverId = [GGBringgUtils integerFromJSON:data[@"user_id"] defaultTo:0];
        
        late = [GGBringgUtils boolFromJSON:data[@"late"] defaultTo:NO];
        
        title = [GGBringgUtils stringFromJSON:data[@"title"] defaultTo:nil];
        
        sharedLocation = [data objectForKey:PARAM_SHARED_LOCATION] ? [[GGSharedLocation alloc] initWithData:[data objectForKey:PARAM_SHARED_LOCATION]] : nil;
        
        NSArray *waypointsData = [data objectForKey:PARAM_WAYPOINTS];
        if (waypointsData) {
            
            __block NSMutableArray *wps = [NSMutableArray arrayWithCapacity:waypointsData.count];
            
            [waypointsData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                GGWaypoint *wp = [[GGWaypoint alloc] initWaypointWithData:obj];
                [wps addObject:wp];
            }];
            
            self.waypoints = wps;
        }
        

    }
    
    return self;
}

-(id)initOrderWithUUID:(NSString *)ouuid atStatus:(OrderStatus)ostatus{
    if (self = [super init]) {
        orderid = 0;
        uuid = ouuid;
        status = ostatus;
        sharedLocation = nil;
        
    }
    
    return self;
}

-(void)updateOrderStatus:(OrderStatus)newStatus{
    self.status = newStatus;
}

@end
