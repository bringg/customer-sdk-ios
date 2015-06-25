//
//  GGRating.m
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Ilya Kalinin. All rights reserved.
//

#import "GGRating.h"

@implementation GGRating

@synthesize token, rating;

- (id)initWithRatingToken:(NSString *)ratingToken{
    
    if (self = [super init]) {
        token = ratingToken;
    }
    
    return self;
}

-(void)rate:(int)driverRating{
    
    self.rating = driverRating;
}

@end
