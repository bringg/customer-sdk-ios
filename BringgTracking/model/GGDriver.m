//
//  BringgDriver.m
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import "GGDriver.h"
#import "BringgGlobals.h"

@implementation GGDriver

@synthesize driverid, uuid;
@synthesize name, imageURL;
@synthesize latitude,longitude;
@synthesize averageRating,activity,arrived;


-(id)initWithID:(NSInteger)dId
           uuid:(NSString *)dUUID
           name:(NSString *)dName
       latitude:(double)dLat
      longitude:(double)dLng
       activity:(int)dActivity
  averageRating:(double)dRating
       imageURL:(NSString *)dUrl{
    
    if (self = [super init]) {
        //
        
        driverid = dId;
        uuid = dUUID;
        name = dName;
        imageURL = dUrl;
        latitude = dLat;
        longitude = dLng;
        averageRating = dRating;
        activity = dActivity;
         
        
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
 
        driver = [[GGDriver alloc] initWithID:[[data objectForKey:PARAM_ID] integerValue]
                                         uuid:[data objectForKey:PARAM_UUID]
                                         name:[data objectForKey:PARAM_NAME]
                                     latitude:[[data objectForKey:PARAM_LAT] doubleValue]
                                    longitude:[[data objectForKey:PARAM_LNG] doubleValue]
                                     activity:[data objectForKey:PARAM_ACTIVITY] ? [[data objectForKey:PARAM_ACTIVITY] intValue] : 0
                                averageRating:[data objectForKey:PARAM_DRIVER_AVG_RATING] ? [[data objectForKey:PARAM_DRIVER_AVG_RATING] doubleValue] : -1
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
