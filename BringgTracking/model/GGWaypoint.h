//
//  GGWaypoint.h
//  BringgTracking
//
//  Created by Matan on 8/9/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BringgGlobals.h"
@interface GGWaypoint : NSObject<NSCoding>


@property (nonatomic, assign) NSInteger orderid;
@property (nonatomic, assign) NSInteger waypointId;
@property (nonatomic, assign) NSInteger customerId;
@property (nonatomic, assign) NSInteger merchantId;
@property (nonatomic, assign) NSInteger position;

@property (nonatomic, assign) BOOL done;
@property (nonatomic, assign) BOOL ASAP;

@property (nonatomic, strong) NSString *address;


-(id)initWaypointWithData:(NSDictionary*)data;

@end
