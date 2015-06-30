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


-(id)initWithID:(NSInteger)dId
           uuid:(NSString *)dUUID
           name:(NSString *)dName
       latitude:(double)dLat
      longitude:(double)dLng
       activity:(int)dActivity
  averageRating:(double)dRating
       imageURL:(NSString *)dUrl;

-(id)initWithUUID:(NSString *)dUUID
         latitude:(double)dLat
        longitude:(double)dLng;


-(id)initWithUUID:(NSString *)dUUID;

- (void)updateLocationToLatitude:(double)newlatitude longtitude:(double)newlongitude;

+ (GGDriver *)driverFromData:(NSDictionary *)data;

@end
