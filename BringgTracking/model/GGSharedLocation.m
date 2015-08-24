//
//  GGSharedLocation.m
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import "GGSharedLocation.h"
#import "BringgGlobals.h"
#import "GGBringgUtils.h"

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
        driver = [[GGDriver alloc] initWithID:[GGBringgUtils integerFromJSON:data[@"user_id"] defaultTo:0]
                                         uuid:[GGBringgUtils stringFromJSON:data[PARAM_DRIVER_UUID] defaultTo:nil]
                                         name:[GGBringgUtils stringFromJSON:data[PARAM_DRIVER_NAME] defaultTo:nil]
                                        phone:[GGBringgUtils stringFromJSON:data[PARAM_DRIVER_PHONE] defaultTo:nil]
                                     latitude:[GGBringgUtils doubleFromJSON:data[PARAM_CURRENT_LAT] defaultTo:0]
                                    longitude:[GGBringgUtils doubleFromJSON:data[PARAM_CURRENT_LNG] defaultTo:0]
                                     activity:(int)[GGBringgUtils integerFromJSON:data[PARAM_ACTIVITY] defaultTo:0]
                                averageRating:[GGBringgUtils doubleFromJSON:data[PARAM_DRIVER_AVG_RATING_IN_SHARED_LOCATION] defaultTo:-1]
                                  ratingToken:[GGBringgUtils stringFromJSON:data[PARAM_RATING_TOKEN] defaultTo:nil]
                                    ratingURL:[GGBringgUtils stringFromJSON:data[PARAM_DRIVER_TOKEN_URL] defaultTo:nil]
                                     imageURL:[data objectForKey:PARAM_DRIVER_IMAGE_URL] ? [data objectForKey:PARAM_DRIVER_IMAGE_URL] : [data objectForKey:PARAM_DRIVER_IMAGE_URL2]
                  ];
        
    }
    
    return self;
    
}


@end
