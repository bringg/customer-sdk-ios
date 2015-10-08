//
//  BringgDriver.h
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>


#define GGDriverStoreKeyRatingToken @"ratingToken"
#define GGDriverStoreKeyRatingURL @"ratingUrl"
#define GGDriverStoreKeyUUID @"uuid"
#define GGDriverStoreKeyName @"name"
#define GGDriverStoreKeyImageURL @"imageURL"
#define GGDriverStoreKeyPhone @"phone"
#define GGDriverStoreKeyLatitude @"latitude"
#define GGDriverStoreKeyLongitude @"longitude"
#define GGDriverStoreKeyRatingAvg @"averageRating"
#define GGDriverStoreKeyActivity @"activity"
#define GGDriverStoreKeyID @"driverid"

@interface GGDriver : NSObject <NSCoding>


@property (nonatomic, copy) NSString * __nonnull uuid;
@property (nonatomic, copy) NSString * __nullable name;
@property (nonatomic, copy) NSString * __nullable imageURL;

@property (nonatomic) NSUInteger driverid;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic) double averageRating;
@property (nonatomic) int activity;
@property (nonatomic, getter=hasArrived) BOOL arrived;


@property (nonatomic, copy) NSString * __nullable ratingToken;
@property (nonatomic, copy) NSString * __nullable ratingUrl;
@property (nonatomic, copy) NSString * __nullable phone;


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
       imageURL:(NSString *__nullable )dUrl;

/**
 *  init a Driver object with just uuid and geo location
 *
 *  @param dUUID driver uuid
 *  @param dLat  latitude
 *  @param dLng  longitude
 *
 *  @return a Driver object
 */
-(nonnull instancetype)initWithUUID:(NSString *__nonnull )dUUID
         latitude:(double)dLat
        longitude:(double)dLng;


/**
 *  inits the driver object with json date representing its properties
 *
 *  @param data the json data to init with
 *
 *  @return driver instance
 */
- (nonnull instancetype)initDriverWithData:(NSDictionary*__nullable)data;

/**
 *  init a Driver object with just uuid
 *
 *  @param dUUID driver uuid
 *
 *  @return a Driver object
 */
-(nonnull instancetype)initWithUUID:(NSString *__nonnull)dUUID;

/**
 *  updates the driver location
 *
 *  @param newlatitude  new latitude
 *  @param newlongitude new longitude
 */
- (void)updateLocationToLatitude:(double)newlatitude longtitude:(double)newlongitude;




// example data when order status update
/*
"driver": {
    "access_token": "",
    "active_shift_id": 23990,
    "admin": false,
    "authentication_token": "fjbhmct1gXbxSsJ_rq8q",
    "authorization_flags": "{}",
    "average_rating": 0,
    "battery": 0,
    "belongs_to_partner": "true",
    "beta": false,
    "blocked_email": "false",
    "confirmation_code": "",
    "confirmation_token": "",
    "created_at": "2015-08-03T12:40:07.000Z",
    "current_sign_in_ip": "",
    "current_task_id": "",
    "debug": false,
    "default_user_activity": "5",
    "delete_at": "",
    "dispatcher": false,
    "driver": true,
    "driver_current_sign_in_at": "2015-10-07T07:26:35.000Z",
    "driver_last_sign_in_at": "2015-10-07T07:26:35.000Z",
    "driver_sign_in_count": 2,
    "email": "matan@bringg.com",
    "encrypted_password": "$2a$10$1NL49kR/L5wkpdNVCljlbuRBPZ6GtMS01z5hbJg8DJtXFzd.0dIp2",
    "external_id": "14065",
    "feature_flags": null,
    "id": 14065,
    "job_description": "the MAC",
    "last_sign_in_at": "2015-08-03T12:42:10.000Z",
    "last_sign_in_ip": "",
    "lat": 0,
    "lng": 0,
    "merchant_id": 8250,
    "mobile_type": "2",
    "mobile_version": "1.8.6.1",
    "name": "Matan P",
    "original_phone_number": "054 -554-1748",
    "partner_user": false,
    "password_hash": "",
    "password_salt": "",
    "phone": "+972545541748",
    "profile_image": "https://task-images.s3.amazonaws.com/uploads/user/uploaded_profile_image/14065/265d775e-3953-48e6-9b88-6a0cd2efb313.png",
    "push_token": "(null)",
    "reset_password_token": "",
    "sign_in_count": "0",
    "status": "offline",
    "sub": "Free",
    "updated_at": "2015-10-07T07:26:38.000Z",
    "uploaded_profile_image": "265d775e-3953-48e6-9b88-6a0cd2efb313.png",
    "uuid": "3d000d93-d6d7-457e-af6e-4898fe35ebad"
}
*/

@end
