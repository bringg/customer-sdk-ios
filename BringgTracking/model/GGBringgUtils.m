//
//  GGBringgUtils.m
//  BringgTracking
//
//  Created by Matan on 8/24/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import "GGBringgUtils.h"
#import "BringgGlobals.h"

#define HTTP_FORMAT @"http://%@"
#define HTTPS_FORMAT @"https://%@"

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

+ (nullable id )userPrintSafeDataFromData:(id __nullable)data{
    
    if (!data) {
        return nil;
    }
    
    
    if ([data isKindOfClass:[NSString class]]) {
        
        NSString *key = data;
        
        // return either orignal or obfuscated result
        if ([key rangeOfString:@"password"].location != NSNotFound || [key rangeOfString:@"token"].location != NSNotFound ) {
            
            return @"#######################";
            
        }else{
            return data;
        }
        
    }else if ([data isKindOfClass:[NSArray class]]){
        NSArray *arr = (NSArray *)data;
        __block NSMutableArray *muarr = [NSMutableArray array];
        
        [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            //
            // return an array of obuscated results
            id result = [self userPrintSafeDataFromData:obj];
            
            if (result) {
                [muarr addObject:result];
            }else{
                [muarr addObject:obj];
            }
            
        }];
        
        return muarr;
        
    }else if ([data isKindOfClass:[NSDictionary class]]){
        
        NSDictionary *dict = (NSDictionary *)data;
        __block NSMutableDictionary *mudict = [NSMutableDictionary new];
        
        [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            //
            
            id result = [self userPrintSafeDataFromData:obj];
            
            if (result) {
                [mudict setObject:result forKey:key];
            }else{
                [mudict setObject:obj forKey:key];
            }
            
            if ([key rangeOfString:@"password"].location != NSNotFound || [key rangeOfString:@"token"].location != NSNotFound ) {
                
                [mudict setObject:@"#######################" forKey:key];
                
            }
            
        }];
        
        return mudict;
    }else{
        return data;
    }
    
}

+ (void)parseDriverCompoundKey:(NSString *)key toDriverUUID:(NSString *__autoreleasing  _Nonnull *)driverUUID andSharedUUID:(NSString *__autoreleasing  _Nonnull *)sharedUUID{
    
    NSArray *pair = [key componentsSeparatedByString:DRIVER_COMPOUND_SEPERATOR];
    
    @try {
        *driverUUID = [pair objectAtIndex:0];
        *sharedUUID = [pair objectAtIndex:1];
    }
    @catch (NSException *exception) {
        //
        NSLog(@"cant parse driver comound key %@ - error:%@", key, exception);
    }
    
}

+ (void)parseOrderCompoundUUID:(NSString * _Nonnull)compoundUUID toOrderUUID:(NSString *_Nonnull*_Nonnull)orderUUID andSharedUUID:(NSString *_Nonnull*_Nonnull)sharedUUID error:(NSError * _Nullable *_Nullable)errorPointer{
    
    if (!compoundUUID) {
        if (errorPointer) {
            *errorPointer = [NSError errorWithDomain:@"BringgData" code:GGErrorTypeUUIDNotFound userInfo:@{NSLocalizedDescriptionKey:@"missing compound UUID"}];
        }
        return;
    }
    
    NSArray *pair = [compoundUUID componentsSeparatedByString:ORDER_UUID_COMPOUND_SEPERATOR];
    
    if (!pair || pair.count != 2) {
        if (errorPointer) {
            *errorPointer = [NSError errorWithDomain:@"BringgData" code:GGErrorTypeInvalidUUID userInfo:@{NSLocalizedDescriptionKey:@"invalid compound uuid"}];
            
        }
        
        return;
    }
    
    *orderUUID = [pair objectAtIndex:0];
    *sharedUUID = [pair objectAtIndex:1];
    
    if ([*orderUUID length] == 0 || [*sharedUUID length] == 0) {
        // parsing is invalid if one of the uuid's are empty
        *orderUUID = nil;
        *sharedUUID = nil;
        
        if (errorPointer) {
            *errorPointer = [NSError errorWithDomain:@"BringgData" code:GGErrorTypeInvalidUUID userInfo:@{NSLocalizedDescriptionKey:@"invalid compound uuid"}];
            
        }
        
        return;
    }
    
}

+ (void)parseWaypointCompoundKey:(NSString *)key toOrderUUID:(NSString *__autoreleasing  _Nonnull *)orderUUID andWaypointId:(NSString *__autoreleasing  _Nonnull *)waypointId{
    
    NSArray *pair = [key componentsSeparatedByString:WAYPOINT_COMPOUND_SEPERATOR];
    
    @try {
        *orderUUID = [pair objectAtIndex:0];
        *waypointId = [pair objectAtIndex:1];
    }
    @catch (NSException *exception) {
        //
        NSLog(@"cant parse waypoint comound key %@ - error:%@", key, exception);
    }
    
}

+ (BOOL)isValidUrlString:(nonnull NSString *)urlTest{
    NSString *urlRegEx =
    @"^(https?://)?([da-z.-]+).([a-z.]{2,6})([/w.-]*)*/?$";
    NSPredicate *test = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [test evaluateWithObject:urlTest];
}

+ (BOOL)isValidCoordinatesWithLat:(double)lat lng:(double)lng{
    // lat/lng of both ZERO are considered invalid
    if (lat == 0.0 && lng == 0.0) {
        return NO;
    }
    
    // validate real world latitude (N/S) ranges
    if (lat < -90 || lat > 90) {
        return NO;
    }
    
    // validate real world longitude (W/E) ranges
    if (lng < -180 || lng > 180) {
        return NO;
    }
    
    return YES;

}

+ (void)fixURLString:(NSString *__autoreleasing _Nonnull*_Nonnull)urlString forSSL:(BOOL)useSSL{
    // remove existing prefixes
    [self removeSchemeFromURLString:urlString];
    
    
    // add prefix according to ssl configuration
    [self addSchemeFromURLString:urlString withSSL:useSSL];
    
}

+ (BOOL)isPathSchemeSSL:(nonnull NSString *)path{
    return [path hasPrefix:@"https://"];
}

+ (void)addSchemeFromURLString:(NSString *__autoreleasing _Nonnull*_Nonnull)urlString withSSL:(BOOL)useSSL{
    
    if (useSSL) {
        *urlString = [NSString stringWithFormat:HTTPS_FORMAT, *urlString];
    }else{
        *urlString = [NSString stringWithFormat:HTTP_FORMAT, *urlString];
    }
}


+ (void)removeSchemeFromURLString:(NSString *__autoreleasing _Nonnull*_Nonnull)urlString{
    // remove existing prefixes
    if ([self isPathSchemeSSL:*urlString]) {
        *urlString = [*urlString stringByReplacingOccurrencesOfString:@"https://" withString:@""];
    }else{
        *urlString = [*urlString stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    }
    
    
}


@end
