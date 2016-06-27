//
//  GGSharedLocation.h
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GGDriver.h"
#import "GGRating.h"
#import "GGFindMe.h"

#define GGSharedLocationStoreKeyUUID @"locationUUID"
#define GGSharedLocationStoreKeyOrderUUID @"orderUUID"
#define GGSharedLocationStoreKeyETA @"eta"
#define GGSharedLocationStoreKeyTrackingURL @"trackingURL"
#define GGSharedLocationStoreKeyRatingURL @"ratingURL"

#define GGSharedLocationStoreKeyDriver @"driver"
#define GGSharedLocationStoreKeyRating @"rating"

#define GGSharedLocationStoreKeyOrderID @"orderID"
#define GGSharedLocationStoreKeyWaypointID @"waypointID"

#define GGSharedLocationStoreKeyFindMe @"findMe"

@interface GGSharedLocation : NSObject<NSCoding>

@property (nonatomic, strong) NSString * _Nullable locationUUID;
@property (nonatomic, strong) NSString * _Nullable orderUUID;

@property (nonatomic, strong) NSString * _Nullable eta;
@property (nonatomic, strong) NSString * _Nullable trackingURL;
@property (nonatomic, strong) NSString * _Nullable ratingURL;


@property (nonatomic, assign) NSInteger orderID;
@property (nonatomic) NSInteger waypointID;

@property (nonatomic, strong) GGDriver *_Nullable driver;
@property (nonatomic, strong) GGRating *_Nullable rating;

@property (nonatomic, strong) GGFindMe *_Nullable findMe;



/**
 *  init a SharedLocation object using json data recieved from a server response
 *
 *  @param data a dictionary representing the json response object
 *
 *  @return a SharedLocation object
 */
-(nullable instancetype)initWithData:(NSDictionary * _Nullable)data;


/**
 *  tries to update current object with data from new object
 *
 *  @param newLocation new shared location to updated data from
 */
- (void)update:(GGSharedLocation *__nullable)newLocation;

/**
 *  check if location find me is valid for request sending
 *
 *  @return BOOL
 */
- (BOOL)canSendFindMe;



@end
