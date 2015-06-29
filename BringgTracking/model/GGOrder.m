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

@synthesize orderid,status,uuid,sharedLocation;

-(id)initOrderWithData:(NSDictionary*)data{
    
    if (self = [super init]) {
        orderid = [[data objectForKey:PARAM_ID] integerValue];
        uuid = [data objectForKey:PARAM_UUID];
        status = (OrderStatus)[[data objectForKey:PARAM_STATUS] integerValue];
        
        sharedLocation = [[GGSharedLocation alloc] initWithData:[data objectForKey:PARAM_SHARED_LOCATION]];
        
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

@end
