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

@synthesize orderid,waypointId,customerId,merchantId,position,done,ASAP,allowFindMe,address, latitude, longitude, ETA;


-(id)initWaypointWithData:(NSDictionary*)data{
    
    if (self = [super init]) {
        
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
        }
        
    }
    
    return self;
    
}

#pragma mark - NSCODING

- (id) initWithCoder:(NSCoder *)aDecoder{
    
    if (self = [super init]){
        
        self.orderid = [aDecoder decodeIntegerForKey:@"orderid"];
        self.customerId = [aDecoder decodeIntegerForKey:@"waypointId"];
        self.orderid = [aDecoder decodeIntegerForKey:@"customerId"];
        self.merchantId = [aDecoder decodeIntegerForKey:@"merchantId"];
        
        self.done = [aDecoder decodeBoolForKey:@"done"];
        self.ASAP = [aDecoder decodeBoolForKey:@"asap"];
        
        self.address = [[aDecoder decodeObjectForKey:@"address"] stringValue];
    }
    
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    
    [aCoder encodeInteger:orderid forKey:@"orderid"];
    [aCoder encodeInteger:waypointId forKey:@"waypointId"];
    [aCoder encodeInteger:customerId forKey:@"customerId"];
    [aCoder encodeInteger:merchantId forKey:@"merchantId"];
    
    [aCoder encodeBool:done forKey:@"done"];
    [aCoder encodeBool:ASAP forKey:@"asap"];
    
    [aCoder encodeObject:address forKey:@"address"];
    
}

@end
