//
//  BringgOrder.m
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import "GGOrder.h"
#import "GGSharedLocation.h"

@implementation GGOrder

@synthesize orderid,status,uuid,sharedLocation,activeWaypointId,late,totalPrice,priority,driverId,title,customerId,merchantId,tip,leftToBePaid;

-(id)initOrderWithData:(NSDictionary*)data{
    
    if (self = [super init]) {
        orderid = [[data objectForKey:PARAM_ID] integerValue];
        uuid = [data objectForKey:PARAM_UUID];
        
        status = (OrderStatus)[[data objectForKey:PARAM_STATUS] integerValue];
 
        totalPrice = [data[@"total_price"] doubleValue];
        tip = [data[@"tip"] doubleValue];
        leftToBePaid = [data[@"left_to_be_paid"] doubleValue];
        
        activeWaypointId = [data[@"active_way_point_id"] integerValue];
        customerId = [data[@"customer_id"] integerValue];
        merchantId = [data[@"merchant_id"] integerValue];
        priority = [data[@"priority"] integerValue];
        driverId = [data[@"user_id"] integerValue];
        
        late = [data[@"late"] boolValue];
        
        title = data[@"title"];
        
        sharedLocation = [data objectForKey:PARAM_SHARED_LOCATION] ? [[GGSharedLocation alloc] initWithData:[data objectForKey:PARAM_SHARED_LOCATION]] : nil;

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
