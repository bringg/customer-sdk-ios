//
//  GGRating.h
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GGRating : NSObject

@property (nonatomic, readonly) NSString *token;
@property (nonatomic) int rating;


-(id)initWithRatingToken:(NSString *)ratingToken;
-(void)rate:(int)driverRating;

@end
