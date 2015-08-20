//
//  GGWaypoint.m
//  BringgTracking
//
//  Created by Matan on 8/9/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import "GGWaypoint.h"

@implementation GGWaypoint

@synthesize orderid,waypointId,customerId,merchantId,position,done,ASAP,address;


-(id)initWaypointWithData:(NSDictionary*)data{
    
    if (self = [super init]) {
        
        if (data){
            orderid = data[PARAM_ORDER_ID] ? [data[PARAM_ORDER_ID] integerValue] : 0;
            waypointId = data[PARAM_ID] ? [data[PARAM_ID] integerValue] : 0;
            customerId = data[PARAM_CUSTOMER_ID] ? [data[PARAM_CUSTOMER_ID] integerValue] : 0;
            merchantId = data[PARAM_MERCHANT_ID] ? [data[PARAM_MERCHANT_ID] integerValue] : 0;
            
            done = data[@"done"] ? [data[@"done"] boolValue] : NO;
            ASAP = data[@"asap"] ? [data[@"asap"] boolValue] : NO;
            
            address = data[PARAM_ADDRESS] ? data[PARAM_ADDRESS] : nil;
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
