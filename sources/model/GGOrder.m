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
#import "GGItem.h"

@implementation GGOrder

@synthesize orderid,status,uuid,sharedLocation,activeWaypointId,late,totalPrice,priority,driverId,title,customerId,merchantId,tip,leftToBePaid, waypoints, scheduled, url,driverUUID, sharedLocationUUID,items;

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
        
        activeWaypointId = [[GGBringgUtils numberFromJSON:data[@"active_way_point_id"] defaultTo:@0] integerValue];
        customerId = [GGBringgUtils integerFromJSON:data[@"customer_id"] defaultTo:0];
        merchantId = [GGBringgUtils integerFromJSON:data[@"merchant_id"] defaultTo:0];
        priority = [GGBringgUtils integerFromJSON:data[@"priority"] defaultTo:0];
        driverId = [GGBringgUtils integerFromJSON:data[@"user_id"] defaultTo:0];
        
        late = [GGBringgUtils boolFromJSON:data[@"late"] defaultTo:NO];
        
        
        title = [GGBringgUtils stringFromJSON:data[@"title"] defaultTo:nil];
        
        url = [GGBringgUtils stringFromJSON:data[@"url"] defaultTo:nil];
        
        
        
        // get shared location model
        sharedLocation = [GGBringgUtils objectFromJSON:[data objectForKey:PARAM_SHARED_LOCATION] defaultTo:nil] ? [[GGSharedLocation alloc] initWithData:[data objectForKey:PARAM_SHARED_LOCATION]] : nil;
        
        // check alternative shared location param
        if (!sharedLocation) {
            sharedLocation = [GGBringgUtils objectFromJSON:[data objectForKey:PARAM_SHARED_LOCATION_ALTERNATE] defaultTo:nil]  ? [[GGSharedLocation alloc] initWithData:[data objectForKey:PARAM_SHARED_LOCATION_ALTERNATE]] : nil;
        }
        
        
        sharedLocationUUID = sharedLocation ? sharedLocation.locationUUID : nil;
        
        self.waypoints = [NSMutableArray array];
        
        // get waypoints
        NSArray *waypointsData = [GGBringgUtils arrayFromJSON:[data objectForKey:PARAM_WAYPOINTS] defaultTo:@[]];
        if (waypointsData && [waypointsData isKindOfClass:[NSArray class]]) {
            
            __block NSMutableArray *wps = [NSMutableArray arrayWithCapacity:waypointsData.count];
            
            [waypointsData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                GGWaypoint *wp = [[GGWaypoint alloc] initWaypointWithData:obj];
                [wps addObject:wp];
            }];
            
            NSArray *sortedWayPoints = [wps sortedArrayUsingComparator:^NSComparisonResult(GGWaypoint *wp1, GGWaypoint *wp2) {
                if (wp1.position > wp2.position) {
                    return NSOrderedDescending;
                }
                else if (wp1.position < wp2.position) {
                    return NSOrderedAscending;
                }
                else {
                    return NSOrderedSame;
                }
            }];
            
            self.waypoints = [NSMutableArray arrayWithArray:sortedWayPoints];
        }
        
        // get items
        NSArray *itemsData = [GGBringgUtils arrayFromJSON:[data objectForKey:PARAM_TASK_INVENTORIES] defaultTo:@[]];
        
        if (itemsData && [itemsData isKindOfClass:[NSArray class]]) {
            
            __block NSMutableArray *itms = [NSMutableArray arrayWithCapacity:itemsData.count];
            
            [itemsData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                GGItem *it = [[GGItem alloc] initItemWithData:obj];
                [itms addObject:it];
                
            }];
            
            self.items = itms;
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
        
        // decode the array of items
        int itemsCounter = (int)[aDecoder decodeIntegerForKey:GGOrderStoreKeyItems];
        
        self.items = [NSMutableArray array];
        
        for (int i = 0; i < itemsCounter; i++) {
            GGItem *it = (GGItem *)[aDecoder decodeObjectForKey:[NSString stringWithFormat:GGOrderStoreKeyItem, (unsigned long)i]];
            
            if (it) {
                [self.items addObject:it];
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
    [aCoder encodeInteger:waypoints ? [waypoints count] : 0 forKey:GGOrderStoreKeyWaypoints];
    
    [waypoints enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //
        [aCoder encodeObject:obj forKey:[NSString stringWithFormat:GGOrderStoreKeyWaypoint, (unsigned long)idx]];
    }];
    
    // encode array of items
    [aCoder encodeInteger:items ? [items count] : 0 forKey:GGOrderStoreKeyItems];
    
    [items enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //
        [aCoder encodeObject:obj forKey:[NSString stringWithFormat:GGOrderStoreKeyItem, (unsigned long)idx]];
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
        
        if (newOrder.activeWaypointId > 0) {
            self.activeWaypointId = newOrder.activeWaypointId;
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
        
        if (newOrder.sharedLocationUUID && newOrder.sharedLocationUUID.length > 0) {
            self.sharedLocationUUID = newOrder.sharedLocationUUID;
        }
        
        if (newOrder.sharedLocation) {
            if (!self.sharedLocation) {
                self.sharedLocation = newOrder.sharedLocation;
            }else{
                [self.sharedLocation update:newOrder.sharedLocation];
            }
            
            if ([newOrder.sharedLocation locationUUID]) {
                self.sharedLocationUUID = [newOrder.sharedLocation locationUUID];
            }
        }
        
        
        
        if (newOrder.waypoints) {
            self.waypoints = newOrder.waypoints;
        }
        
        if (newOrder.items) {
            self.items = newOrder.items;
        }
        
        if (newOrder.late) {
            self.late = newOrder.late;
        }
    }
}

//MARK: Getters
- (BOOL)isWithSharedUUID:(nonnull NSString *)sharedUUID{
    return (self.sharedLocationUUID && [self.sharedLocationUUID isEqualToString:sharedUUID]) || (self.sharedLocation && self.sharedLocation.locationUUID && [self.sharedLocation.locationUUID isEqualToString:sharedUUID]);
}

@end
