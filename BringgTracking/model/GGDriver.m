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


- (nonnull instancetype)initDriverWithData:(NSDictionary*__nullable)data{
    
    if (data) {
        
        return [self initWithID:[GGBringgUtils integerFromJSON:data[PARAM_DRIVER_ID] defaultTo:0]
                           uuid:[GGBringgUtils stringFromJSON:data[PARAM_DRIVER_UUID] defaultTo:@""]
                           name:[GGBringgUtils stringFromJSON:data[PARAM_DRIVER_NAME] defaultTo:nil]
                          phone:[GGBringgUtils stringFromJSON:data[PARAM_DRIVER_PHONE] defaultTo:[GGBringgUtils stringFromJSON:data[PARAM_DRIVER_PHONE2] defaultTo:nil]]
                       latitude:[GGBringgUtils doubleFromJSON:data[PARAM_CURRENT_LAT] defaultTo:0]
                      longitude:[GGBringgUtils doubleFromJSON:data[PARAM_CURRENT_LNG] defaultTo:0]
                       activity:(int)[GGBringgUtils integerFromJSON:data[PARAM_DRIVER_ACTIVITY] defaultTo:0]
                  averageRating:[GGBringgUtils doubleFromJSON:data[PARAM_DRIVER_AVG_RATING] defaultTo:-1]
                    ratingToken:[GGBringgUtils stringFromJSON:data[PARAM_RATING_TOKEN] defaultTo:nil]
                      ratingURL:[GGBringgUtils stringFromJSON:data[PARAM_DRIVER_TOKEN_URL] defaultTo:nil]
                       imageURL:[GGBringgUtils stringFromJSON:data[PARAM_DRIVER_IMAGE_URL] defaultTo:[GGBringgUtils stringFromJSON:data[PARAM_DRIVER_IMAGE_URL2] defaultTo:nil]]];
        
        
    }else{
        
        self = [super init];
        
        return self;
    }

    
}

-(nonnull instancetype)initWithID:(NSInteger)dId
                             uuid:(NSString *__nonnull )dUUID
                             name:(NSString *__nullable )dName
                            phone:(NSString *__nullable )dPhone
                         latitude:(double)dLat
                        longitude:(double)dLng
                         activity:(int)dActivity
                    averageRating:(double)dRating
                      ratingToken:(NSString *__nullable )dToken
                        ratingURL:(NSString *__nullable )dRatingUrl
                         imageURL:(NSString *__nullable )dUrl{
    
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

-(nonnull instancetype)initWithUUID:(NSString *__nonnull )dUUID
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


-(nonnull instancetype)initWithUUID:(NSString *__nonnull)dUUID{
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



- (NSString *)imageURL{
    if ([imageURL isEqualToString:@"/images/avatar.png"]) {
        // this is a stub  so return nil
        return nil;
    }else{
        return imageURL;
    }
}

//MARK: NSCoding
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [self initDriverWithData:nil]) {
        
        self.ratingToken = [aDecoder decodeObjectForKey:GGDriverStoreKeyRatingToken];
        self.ratingUrl = [aDecoder decodeObjectForKey:GGDriverStoreKeyRatingURL];
        self.uuid = [aDecoder decodeObjectForKey:GGDriverStoreKeyUUID];
        self.name = [aDecoder decodeObjectForKey:GGDriverStoreKeyName];
        self.imageURL = [aDecoder decodeObjectForKey:GGDriverStoreKeyImageURL];
        self.phone = [aDecoder decodeObjectForKey:GGDriverStoreKeyPhone];
        
        self.latitude = [aDecoder decodeDoubleForKey:GGDriverStoreKeyLatitude];
        self.longitude = [aDecoder decodeDoubleForKey:GGDriverStoreKeyLongitude];
        self.averageRating = [aDecoder decodeDoubleForKey:GGDriverStoreKeyRatingAvg];
        
        self.driverid = (uint)[aDecoder decodeIntForKey:GGDriverStoreKeyID];
        self.activity = [aDecoder decodeIntForKey:GGDriverStoreKeyActivity];
        
    }
    
    return self;

}

-(void)encodeWithCoder:(NSCoder *)aCoder{
    
    [aCoder encodeObject:self.ratingToken forKey:GGDriverStoreKeyRatingToken];
    [aCoder encodeObject:self.ratingUrl forKey:GGDriverStoreKeyRatingURL];
    [aCoder encodeObject:self.uuid forKey:GGDriverStoreKeyUUID];
    [aCoder encodeObject:self.name forKey:GGDriverStoreKeyName];
    [aCoder encodeObject:self.imageURL forKey:GGDriverStoreKeyImageURL];
    [aCoder encodeObject:self.phone forKey:GGDriverStoreKeyPhone];
    
    [aCoder encodeDouble:self.latitude forKey:GGDriverStoreKeyLatitude];
    [aCoder encodeDouble:self.longitude forKey:GGDriverStoreKeyLongitude];
    [aCoder encodeDouble:self.averageRating forKey:GGDriverStoreKeyRatingAvg];
    
    
    [aCoder encodeInt:self.activity forKey:GGDriverStoreKeyActivity];
    [aCoder encodeInt:(int)self.driverid forKey:GGDriverStoreKeyID];
}

@end
