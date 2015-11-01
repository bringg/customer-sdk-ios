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

@synthesize orderid,status,uuid,sharedLocation,activeWaypointId,late,totalPrice,priority,driverId,title,customerId,merchantId,tip,leftToBePaid, waypoints, scheduled, url,driverUUID, sharedLocationUUID;

static NSDateFormatter *dateFormat;

-(nonnull instancetype)initOrderWithData:(NSDictionary*__nullable)data{
    
    if (self = [super init]) {
        
        if (!data) {
            return self;
        }
        
        dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
        
        orderid = [GGBringgUtils integerFromJSON:data[PARAM_ID] defaultTo:[GGBringgUtils integerFromJSON:data[PARAM_ORDER_ID] defaultTo:0]];
        uuid = [GGBringgUtils stringFromJSON:data[PARAM_UUID] defaultTo:[GGBringgUtils stringFromJSON:data[PARAM_ORDER_UUID] defaultTo:@""]];
        
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
        
        url = [GGBringgUtils stringFromJSON:data[@"url"] defaultTo:nil];
        
        
        
        // get shared location model
        sharedLocation = [data objectForKey:PARAM_SHARED_LOCATION] ? [[GGSharedLocation alloc] initWithData:[data objectForKey:PARAM_SHARED_LOCATION]] : nil;
        
        sharedLocationUUID = sharedLocation ? sharedLocation.locationUUID : nil;
        
        self.waypoints = [NSMutableArray array];
        
        // get waypoints
        NSArray *waypointsData = [data objectForKey:PARAM_WAYPOINTS];
        if (waypointsData) {
            
            __block NSMutableArray *wps = [NSMutableArray arrayWithCapacity:waypointsData.count];
            
            [waypointsData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                GGWaypoint *wp = [[GGWaypoint alloc] initWaypointWithData:obj];
                [wps addObject:wp];
            }];
            
            self.waypoints = wps;
        }else{
            
            
        }
        
        // get date
        NSString *dateString = [GGBringgUtils stringFromJSON:data[@"scheduled_at"] defaultTo:@""];
        
        self.scheduled = [dateFormat dateFromString:dateString];
        
    }
    
    return self;
}

-(nonnull instancetype)initOrderWithUUID:(NSString * __nonnull)ouuid atStatus:(OrderStatus)ostatus{
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

// MARK: NSCoding
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [self init]) {
        self.uuid = [aDecoder decodeObjectForKey:GGOrderStoreKeyUUID];
        self.sharedLocationUUID = [aDecoder decodeObjectForKey:GGOrderStoreKeySharedLocationUUID];
        self.driverUUID = [aDecoder decodeObjectForKey:GGOrderStoreKeyDriverUUID];
        self.url = [aDecoder decodeObjectForKey:GGOrderStoreKeyURL];
        self.title = [aDecoder decodeObjectForKey:GGOrderStoreKeyTitle];
        
        self.orderid = [aDecoder decodeIntegerForKey:GGOrderStoreKeyID];
        self.customerId = [aDecoder decodeIntegerForKey:GGOrderStoreKeyCustomerID];
        self.status = [aDecoder decodeIntegerForKey:GGOrderStoreKeyStatus];
        
        self.totalPrice = [aDecoder decodeDoubleForKey:GGOrderStoreKeyAmount];
       
        self.late = [aDecoder decodeBoolForKey:GGOrderStoreKeyLate];
        
        
        // decode the array of waypoints
        int waypointsCounter = (int)[aDecoder decodeIntegerForKey:GGOrderStoreKeyWaypoints];
        
        self.waypoints = [NSMutableArray array];
        
        for (int i = 0; i < waypointsCounter; i++) {
            GGWaypoint *wp = (GGWaypoint *)[aDecoder decodeObjectForKey:[NSString stringWithFormat:GGOrderStoreKeyWaypoint, (unsigned long)i]];
            
            if (wp) {
                [self.waypoints addObject:wp];
            }
            
        }
 
    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.uuid forKey:GGOrderStoreKeyUUID];
    [aCoder encodeObject:self.sharedLocationUUID forKey:GGOrderStoreKeySharedLocationUUID];
    [aCoder encodeObject:self.driverUUID forKey:GGOrderStoreKeyDriverUUID];
    [aCoder encodeObject:self.url forKey:GGOrderStoreKeyURL];
    [aCoder encodeObject:self.title forKey:GGOrderStoreKeyTitle];
    
    [aCoder encodeInteger:self.orderid forKey:GGOrderStoreKeyID];
    [aCoder encodeInteger:self.customerId forKey:GGOrderStoreKeyCustomerID];
    [aCoder encodeInteger:self.status forKey:GGOrderStoreKeyStatus];
   
    [aCoder encodeDouble:self.totalPrice forKey:GGOrderStoreKeyAmount];

    [aCoder encodeBool:self.late forKey:GGOrderStoreKeyLate];
    
    // encode array of waypoints
    [aCoder encodeInteger:waypoints.count forKey:GGOrderStoreKeyWaypoints];
    
    [waypoints enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //
        [aCoder encodeObject:obj forKey:[NSString stringWithFormat:GGOrderStoreKeyWaypoint, (unsigned long)idx]];
    }];
    
 
    // do not store the shared location object - it has now use if a driver isnt actually doing a delivery
    //[aCoder encodeObject:self.sharedLocation forKey:GGOrderStoreKeySharedLocation];
    
    //TODO: after updating driver model uncomment this line
    //[aCoder encodeObject:self.driver forKey:GGOrderStoreKeyDriver];
}


#pragma mark - Setters
- (void)update:(GGOrder *__nullable)newOrder{
    
    if (newOrder) {
        if (newOrder.uuid.length > 0) {
            self.uuid = newOrder.uuid;
        }
        
        if (newOrder.title && newOrder.title.length > 0) {
            self.title = newOrder.title;
        }
        
        
        if (newOrder.merchantId > 0) {
            self.merchantId = newOrder.merchantId;
        }
        
        if (newOrder.priority> 0) {
            self.priority = newOrder.priority;
        }
        
        if (newOrder.customerId > 0) {
            self.customerId = newOrder.customerId;
        }
        
        if (newOrder.orderid  > 0) {
            self.orderid = newOrder.orderid;
        }
        
        if (newOrder.status) {
            self.status = newOrder.status;
        }
        
        if (newOrder.driverId != 0  ) {
            self.driverId = newOrder.driverId;
        }
        
        if (newOrder.driverUUID && newOrder.driverUUID.length > 0) {
            self.driverUUID = newOrder.driverUUID;
        }
        
        if (newOrder.sharedLocation) {
            self.sharedLocation = newOrder.sharedLocation;
        }
        
        if (newOrder.sharedLocationUUID && newOrder.sharedLocationUUID.length > 0) {
            self.sharedLocationUUID = newOrder.sharedLocationUUID;
        }
    }
}



@end
