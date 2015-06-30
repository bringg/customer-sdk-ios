//
//  GGRating.h
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GGRating : NSObject

@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *ratingMessage;
@property (nonatomic, assign) int rating;


-(id)initWithRatingToken:(NSString *)ratingToken;
-(void)rate:(int)driverRating;

@end
