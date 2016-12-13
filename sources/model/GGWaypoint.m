//
//  GGWaypoint.m
//  BringgTracking
//
//  Created by Matan on 8/9/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import "GGWaypoint.h"
#import "GGBringgUtils.h"

@implementation GGWaypoint

@synthesize orderid,waypointId,customerId,merchantId,position,done,ASAP,allowFindMe,address, latitude, longitude, ETA, startTime, checkinTime, doneTime;

static NSDateFormatter *dateFormat;

/*
 extras =     {
 "way_point" =         {
 address = "Weizman St 12, Herzliya, Israel";
 "customer_id" = 1;
 done = 0;
 eta = "<null>";
 etl = "2016-12-13T17:51:25+02:00";
 id = 18;
 lat = "32.1638542";
 lng = "34.8350625";
 note = "<null>";
 phone = "<null>";
 position = 1;
 "scheduled_at" = "2016-12-13T17:46:25+02:00";
 "task_id" = 18;
 };
 };
 */

-(id)initWaypointWithData:(NSDictionary*)data{
    
    if (self = [super init]) {
        
        
        dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
        
        if (data){
            orderid = [GGBringgUtils integerFromJSON:data[PARAM_ORDER_ID] defaultTo:0];
            waypointId = [GGBringgUtils integerFromJSON:data[PARAM_ID] defaultTo:0];
            customerId = [GGBringgUtils integerFromJSON:data[PARAM_CUSTOMER_ID] defaultTo:0];
            merchantId = [GGBringgUtils integerFromJSON:data[PARAM_MERCHANT_ID] defaultTo:0];
            
            done =[GGBringgUtils boolFromJSON:data[@"done"] defaultTo:NO];
            ASAP = [GGBringgUtils boolFromJSON:data[@"asap"] defaultTo:NO];
            allowFindMe = [GGBringgUtils boolFromJSON:data[@"find_me"] defaultTo:NO];
            
            address =  [GGBringgUtils stringFromJSON:data[PARAM_ADDRESS] defaultTo:nil];
            
            latitude =  [GGBringgUtils doubleFromJSON:data[@"lat"] defaultTo:0];
            longitude =  [GGBringgUtils doubleFromJSON:data[@"lng"] defaultTo:0];
            
            ETA = [GGBringgUtils stringFromJSON:data[PARAM_ETA] defaultTo:nil];
            
            position = [GGBringgUtils integerFromJSON:data[PARAM_POSITION] defaultTo:0];
            
            // get start/checkin/checkout dates
            NSString *startString   = [GGBringgUtils stringFromJSON:data[@"start_time"] defaultTo:nil];
            NSString *checkinString = [GGBringgUtils stringFromJSON:data[@"checkin_time"] defaultTo:nil];
            NSString *doneString    = [GGBringgUtils stringFromJSON:data[@"checkout_time"] defaultTo:nil];
            
            self.startTime    = startString ? [dateFormat dateFromString:startString] : nil;
            self.checkinTime  = checkinString ? [dateFormat dateFromString:checkinString] : nil;
            self.doneTime     = doneString ? [dateFormat dateFromString:doneString] : nil;
        }
        
    }
    
    return self;
    
}

#pragma mark - NSCODING

- (id) initWithCoder:(NSCoder *)aDecoder{
    
    if (self = [super init]){
        
        self.orderid = [aDecoder decodeIntegerForKey:GGWaypointStoreKeyOrderID];
        self.waypointId = [aDecoder decodeIntegerForKey:GGWaypointStoreKeyID];
        self.customerId = [aDecoder decodeIntegerForKey:GGWaypointStoreKeyCustomerID];
        self.merchantId = [aDecoder decodeIntegerForKey:GGWaypointStoreKeyMerchantID];
        self.position = [aDecoder decodeIntegerForKey:GGWaypointStoreKeyPosition];
        
        self.done = [aDecoder decodeBoolForKey:GGWaypointStoreKeyDone];
        self.ASAP = [aDecoder decodeBoolForKey:GGWaypointStoreKeyASAP];
        self.allowFindMe = [aDecoder decodeBoolForKey:GGWaypointStoreKeyAllowFindMe];
        
        self.address = [aDecoder decodeObjectForKey:GGWaypointStoreKeyAddress];
        self.latitude = [aDecoder decodeDoubleForKey:GGWaypointStoreKeyLatitude];
        self.longitude = [aDecoder decodeDoubleForKey:GGWaypointStoreKeyLongitude];
        
        self.ETA = [aDecoder decodeObjectForKey:GGWaypointStoreKeyETA];
        
        
        self.startTime = [aDecoder decodeObjectForKey:GGWaypointStoreKeyStartTime];
        self.checkinTime = [aDecoder decodeObjectForKey:GGWaypointStoreKeyArriveTime];
        self.doneTime = [aDecoder decodeObjectForKey:GGWaypointStoreKeyDoneTime];
    }
    
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    
    [aCoder encodeInteger:orderid forKey:GGWaypointStoreKeyOrderID];
    [aCoder encodeInteger:waypointId forKey:GGWaypointStoreKeyID];
    [aCoder encodeInteger:customerId forKey:GGWaypointStoreKeyCustomerID];
    [aCoder encodeInteger:merchantId forKey:GGWaypointStoreKeyMerchantID];
    [aCoder encodeInteger:position forKey:GGWaypointStoreKeyPosition];
    
    [aCoder encodeBool:done forKey:GGWaypointStoreKeyDone];
    [aCoder encodeBool:ASAP forKey:GGWaypointStoreKeyASAP];
    [aCoder encodeBool:allowFindMe forKey:GGWaypointStoreKeyAllowFindMe];
    
    [aCoder encodeObject:address forKey:GGWaypointStoreKeyAddress];
    [aCoder encodeDouble:latitude forKey:GGWaypointStoreKeyLatitude];
    [aCoder encodeDouble:longitude forKey:GGWaypointStoreKeyLongitude];
    
    [aCoder encodeObject:ETA forKey:GGWaypointStoreKeyETA];
    
    [aCoder encodeObject:startTime forKey:GGWaypointStoreKeyStartTime];
    [aCoder encodeObject:checkinTime forKey:GGWaypointStoreKeyArriveTime];
    [aCoder encodeObject:doneTime forKey:GGWaypointStoreKeyDoneTime];
    
}

- (NSString *)description{
    return [NSString stringWithFormat:@"waypoint (%ld) of order (%ld) - to address %@", (long)self.waypointId,(long)self.orderid, self.address];
}

- (void)update:(GGWaypoint *__nullable)newWaypoint{
    if (newWaypoint && newWaypoint.waypointId == self.waypointId && newWaypoint.orderid == self.orderid) {
        
        if (newWaypoint.customerId) {
            self.customerId = newWaypoint.customerId;
        }
        
        if (newWaypoint.position){
            self.position = newWaypoint.position;
        }
        
        if (newWaypoint.done) {
            self.done = newWaypoint.done;
        }
        
        if (newWaypoint.ASAP) {
            self.ASAP = newWaypoint.ASAP;
        }
        
        if (newWaypoint.allowFindMe) {
            self.allowFindMe = newWaypoint.allowFindMe;
        }
        
        if (newWaypoint.address) {
            self.address = newWaypoint.address;
        }
        
        if (newWaypoint.latitude != 0.0) {
            self.latitude = newWaypoint.latitude;
        }
        
        if (newWaypoint.longitude != 0.0) {
            self.longitude = newWaypoint.longitude;
        }
        
        if (newWaypoint.ETA) {
            self.ETA = newWaypoint.ETA;
        }
        
        
        if (newWaypoint.startTime) {
            self.startTime = newWaypoint.startTime;
        }
        
        if (newWaypoint.checkinTime) {
            self.checkinTime = newWaypoint.checkinTime;
        }
        
        if (newWaypoint.doneTime) {
            self.doneTime = newWaypoint.doneTime;
        }
    }
}

@end
