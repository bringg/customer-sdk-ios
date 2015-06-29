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

@synthesize locationUUID,orderUUID,waypointID,eta,driver,rating;

-(id)initWithData:(NSDictionary *)data{
    
    if (self = [super init]) {
        //
        locationUUID = [data objectForKey:PARAM_UUID];
        orderUUID = [data objectForKey:PARAM_ORDER_UUID];
        waypointID = [[data objectForKey:PARAM_WAY_POINT_ID] integerValue];
        eta = [data objectForKey:PARAM_ETA];
        
        rating = [[GGRating alloc] initWithRatingToken:[data objectForKey:PARAM_RATING_TOKEN]];
        driver = [[GGDriver alloc] initWithID:[[data objectForKey:PARAM_DRIVER_ID] integerValue]
                                         uuid:[data objectForKey:PARAM_DRIVER_UUID]
                                         name:[data objectForKey:PARAM_DRIVER_NAME]
                                     latitude:[[data objectForKey:PARAM_CURRENT_LAT] doubleValue]
                                    longitude:[[data objectForKey:PARAM_CURRENT_LNG] doubleValue]
                                     activity:[[data objectForKey:PARAM_DRIVER_ACTIVITY] intValue]
                                averageRating:[[data objectForKey:PARAM_DRIVER_AVG_RATING] doubleValue]
                                     imageURL:[data objectForKey:PARAM_DRIVER_IMAGE_URL]
                  ];
        
    }
    
    return self;
    
}


@end
