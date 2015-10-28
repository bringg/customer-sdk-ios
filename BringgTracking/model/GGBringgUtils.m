//
//  GGBringgUtils.m
//  BringgTracking
//
//  Created by Matan on 8/24/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import "GGBringgUtils.h"

@implementation GGBringgUtils

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+(NSInteger)integerFromJSON:(nullable id)jsonObject defaultTo:(NSInteger)defaultValue{
    return jsonObject && jsonObject != [NSNull null] ? [jsonObject integerValue] : defaultValue;
}

+(double)doubleFromJSON:(nullable id)jsonObject defaultTo:(double)defaultValue{
    return jsonObject && jsonObject != [NSNull null] ? [jsonObject doubleValue] : defaultValue;
}

+(BOOL)boolFromJSON:(nullable id)jsonObject defaultTo:(BOOL)defaultValue{
    return jsonObject && jsonObject != [NSNull null] ? [jsonObject boolValue] : defaultValue;
}

+(NSString *_Nullable)stringFromJSON:(nullable id)jsonObject defaultTo:(NSString * _Nullable)defaultValue{
    return jsonObject && jsonObject != [NSNull null] ? jsonObject : defaultValue;
}

+(NSNumber *_Nullable)numberFromJSON:(nullable id)jsonObject defaultTo:(NSNumber *_Nullable)defaultValue{
    return jsonObject && jsonObject != [NSNull null] ? jsonObject : defaultValue;
}



+(BOOL)isValidLatitude:(double)latitude andLongitude:(double)longitude{
    BOOL retVal = YES;
    
    if (latitude > 90 || latitude < -90) retVal = NO;
    if (longitude > 180 || longitude < -180) retVal = NO;
    if (latitude == 0 && latitude == 0) retVal = NO;
    
    return retVal;
}

@end
