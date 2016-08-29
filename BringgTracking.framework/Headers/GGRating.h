//
//  GGRating.h
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>


#define GGRatingStoreKeyToken @"token"
#define GGRatingStoreKeyMessage @"ratingMessage"
#define GGRatingStoreKeyRating @"rating"

@interface GGRating : NSObject<NSCoding>

@property (nonatomic, copy) NSString  * _Nonnull token;
@property (nonatomic, copy) NSString * _Nullable ratingMessage;
@property (nonatomic, assign) int rating;

/**
 *  initializes the rating object of a driver
 *
 *  @param ratingToken the token needed to validate which driver
 *
 *  @return the rating object
 */
-(nullable instancetype)initWithRatingToken:(NSString * _Nonnull)ratingToken;

/**
 *  give the a driver rating between (1-5)
 *
 *  @param driverRating
 */
-(void)rate:(int)driverRating;

@end
