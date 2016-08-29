//
//  GGRating.m
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import "GGRating.h"
#import "GGBringgUtils.h"

@implementation GGRating

@synthesize token, rating, ratingMessage;

-(nullable instancetype)initWithRatingToken:(NSString * _Nonnull)ratingToken{
    
    if (self = [super init]) {
        token = ratingToken;
    }
    
    return self;
}

-(void)rate:(int)driverRating{
    
    self.rating = driverRating;
}


//MARK: NSCoding
-(nullable instancetype)initWithCoder:(NSCoder * _Nonnull)aDecoder{
    if (self = [self init]) {
        
        self.token = [aDecoder decodeObjectForKey:GGRatingStoreKeyToken];
        self.ratingMessage = [aDecoder decodeObjectForKey:GGRatingStoreKeyMessage];
        self.rating =  [aDecoder decodeIntForKey:GGRatingStoreKeyRating];
        
        
    }
    
    return self;
    
}

-(void)encodeWithCoder:(NSCoder * _Nonnull)aCoder{
    
    [aCoder encodeObject:self.token forKey:GGRatingStoreKeyToken];
    [aCoder encodeObject:self.ratingMessage forKey:GGRatingStoreKeyMessage];
    
    [aCoder encodeInt:self.rating forKey:GGRatingStoreKeyRating];
    
}


@end
