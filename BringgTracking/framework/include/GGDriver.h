//
//  BringgDriver.h
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GGDriver : NSObject


@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *imageURL;

@property (nonatomic) NSUInteger driverid;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic) double averageRating;
@property (nonatomic) int activity;
@property (nonatomic, getter=hasArrived) BOOL arrived;


@property (nonatomic, copy) NSString * ratingToken;
@property (nonatomic, copy) NSString * ratingUrl;
@property (nonatomic, copy) NSString * phone;


/**
 *  init a Driver object
 *
 *  @param dId       driver id
 *  @param dUUID     driver uuid
 *  @param dName     driver name
 *  @param dLat      latitude
 *  @param dLng      longitude
 *  @param dActivity driver activity
 *  @param dRating   driver rating
 *  @param dUrl      driver profile image url
 *
 *  @return init a Driver object
 */
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
       imageURL:(NSString *)dUrl;

/**
 *  init a Driver object with just uuid and geo location
 *
 *  @param dUUID driver uuid
 *  @param dLat  latitude
 *  @param dLng  longitude
 *
 *  @return a Driver object
 */
-(id)initWithUUID:(NSString *)dUUID
         latitude:(double)dLat
        longitude:(double)dLng;


/**
 *  init a Driver object with just uuid
 *
 *  @param dUUID driver uuid
 *
 *  @return a Driver object
 */
-(id)initWithUUID:(NSString *)dUUID;

/**
 *  updates the driver location
 *
 *  @param newlatitude  new latitude
 *  @param newlongitude new longitude
 */
- (void)updateLocationToLatitude:(double)newlatitude longtitude:(double)newlongitude;


/**
 *  creates a Driver object from a json response object
 *
 *  @param data a dictionary representing the json response object
 *
 *  @return a Driver object
 */
+ (GGDriver *)driverFromData:(NSDictionary *)data;

@end
