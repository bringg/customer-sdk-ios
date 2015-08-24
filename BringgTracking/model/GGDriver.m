//
//  BringgDriver.m
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import "GGDriver.h"
#import "BringgGlobals.h"
#import "GGBringgUtils.h"

@implementation GGDriver

@synthesize driverid, uuid;
@synthesize name, imageURL;
@synthesize latitude,longitude;
@synthesize averageRating,activity,arrived;
@synthesize ratingToken, ratingUrl, phone;

-(id)initWithID:(NSInteger)dId
           uuid:(NSString *)dUUID
           name:(NSString *)dName
          phone:(NSString *)dPhone
       latitude:(double)dLat
      longitude:(double)dLng
       activity:(int)dActivity
  averageRating:(double)dRating
    ratingToken:(NSString *)dToken
      ratingURL:(NSString *)dRatingUrl
       imageURL:(NSString *)dUrl{
    
    if (self = [super init]) {
        //
        
        driverid = dId;
        uuid = dUUID;
        name = dName;
        phone = dPhone;
        imageURL = dUrl;
        latitude = dLat;
        longitude = dLng;
        averageRating = dRating;
        activity = dActivity;
        ratingToken = dToken;
        ratingUrl = dRatingUrl;
        
        
    }
    
    return self;
}

-(id)initWithUUID:(NSString *)dUUID
         latitude:(double)dLat
        longitude:(double)dLng{
    
    if (self = [super init]) {
        //
        
        driverid = 0;
        uuid = dUUID;
        name = nil;
        imageURL = nil;
        latitude = dLat;
        longitude = dLng;
        averageRating = -1;
        activity = 0;
        
        
    }
    
    return self;
    
}


-(id)initWithUUID:(NSString *)dUUID{
    if (self = [super init]) {
        //
        
        driverid = 0;
        uuid = dUUID;
        name = nil;
        imageURL = nil;
        latitude = 0;
        longitude = 0;
        averageRating = -1;
        activity = 0;
        
        
    }
    
    return self;
}

- (void)updateLocationToLatitude:(double)newlatitude longtitude:(double)newlongitude{
    self.latitude = newlatitude;
    self.longitude = newlongitude;
}

+ (GGDriver *)driverFromData:(NSDictionary *)data {
    
    GGDriver *driver = nil;
    
    if (data ) {
 
        driver = [[GGDriver alloc] initWithID:[GGBringgUtils integerFromJSON:data[PARAM_ID] defaultTo:0]
                                         uuid:[GGBringgUtils stringFromJSON:data[PARAM_UUID] defaultTo:nil]
                                         name:[GGBringgUtils stringFromJSON:data[PARAM_NAME] defaultTo:nil]
                                        phone:[GGBringgUtils stringFromJSON:data[PARAM_DRIVER_PHONE] defaultTo:nil]
                                     latitude:[GGBringgUtils doubleFromJSON:data[PARAM_LAT] defaultTo:0]
                                    longitude:[GGBringgUtils doubleFromJSON:data[PARAM_LNG] defaultTo:0]
                                     activity:(int)[GGBringgUtils integerFromJSON:data[PARAM_ACTIVITY] defaultTo:0]
                                averageRating:[GGBringgUtils doubleFromJSON:data[PARAM_DRIVER_AVG_RATING] defaultTo:-1]
                                  ratingToken:[GGBringgUtils stringFromJSON:data[PARAM_RATING_TOKEN] defaultTo:nil]
                                    ratingURL:[GGBringgUtils stringFromJSON:data[PARAM_DRIVER_TOKEN_URL] defaultTo:nil]
                                     imageURL:[data objectForKey:PARAM_DRIVER_IMAGE_URL] ? [data objectForKey:PARAM_DRIVER_IMAGE_URL] : [data objectForKey:PARAM_DRIVER_IMAGE_URL2]
                  ];
        
 
    }
    
    return driver;
}

- (NSString *)imageURL{
    if ([imageURL isEqualToString:@"/images/avatar.png"]) {
        // this is a stub  so return nil
        return nil;
    }else{
        return imageURL;
    }
}

@end
