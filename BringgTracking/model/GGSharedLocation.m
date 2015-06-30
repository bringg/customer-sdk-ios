//
//  GGSharedLocation.m
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import "GGSharedLocation.h"
#import "BringgGlobals.h"

@implementation GGSharedLocation

@synthesize locationUUID,orderUUID,waypointID,eta,driver,rating,trackingURL, orderID;

-(id)initWithData:(NSDictionary *)data{
    
    if (self = [super init]) {
        //
        locationUUID = [data objectForKey:PARAM_UUID];
        orderUUID = [data objectForKey:PARAM_ORDER_UUID];
        orderID = [[data objectForKey:@"task_id"] integerValue];
        waypointID = [[data objectForKey:PARAM_WAY_POINT_ID] integerValue];
        eta = [data objectForKey:PARAM_ETA];
        trackingURL = data[@"url"];
        
        rating = [[GGRating alloc] initWithRatingToken:[data objectForKey:PARAM_RATING_TOKEN]];
        driver = [[GGDriver alloc] initWithID:[[data objectForKey:@"user_id"] integerValue]
                                         uuid:[data objectForKey:PARAM_DRIVER_UUID]
                                         name:[data objectForKey:PARAM_DRIVER_NAME]
                                     latitude:[[data objectForKey:PARAM_CURRENT_LAT] doubleValue]
                                    longitude:[[data objectForKey:PARAM_CURRENT_LNG] doubleValue]
                                     activity:[[data objectForKey:PARAM_DRIVER_ACTIVITY] intValue]
                                averageRating:[[data objectForKey:PARAM_DRIVER_AVG_RATING] doubleValue]
                                     imageURL:[data objectForKey:PARAM_DRIVER_IMAGE_URL] ? [data objectForKey:PARAM_DRIVER_IMAGE_URL] : [data objectForKey:PARAM_DRIVER_IMAGE_URL2]
                  ];
        
    }
    
    return self;
    
}


@end
