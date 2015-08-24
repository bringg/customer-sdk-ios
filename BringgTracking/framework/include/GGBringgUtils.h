//
//  GGBringgUtils.h
//  BringgTracking
//
//  Created by Matan on 8/24/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GGBringgUtils : UIView

/**
 *  takes a json object and tries to parse it as 'NSInteger'. if it fails it should
 *  @usage this method is also good for parsing simple 'int' . to do that just cast the result to (int)
 *  @param jsonObject   the Json object to parse
 *  @param defaultValue default value to return if parsing failes
 *
 *  @return the final result of the parsing
 */
+(NSInteger)integerFromJSON:(id)jsonObject defaultTo:(NSInteger)defaultValue;

/**
 *  takes a json object and tries to parse it as 'double'. if it fails it should
 *
 *  @param jsonObject   the Json object to parse
 *  @param defaultValue default value to return if parsing failes
 *
 *  @return the final result of the parsing
 */
+(double)doubleFromJSON:(id)jsonObject defaultTo:(double)defaultValue;

/**
 *  takes a json object and tries to parse it as 'BOOL'. if it fails it should
 *
 *  @param jsonObject   the Json object to parse
 *  @param defaultValue default value to return if parsing failes
 *
 *  @return the final result of the parsing
 */
+(BOOL)boolFromJSON:(id)jsonObject defaultTo:(BOOL)defaultValue;

/**
 *  takes a json object and tries to parse it as 'NSString'. if it fails it should
 *
 *  @param jsonObject   the Json object to parse
 *  @param defaultValue default value to return if parsing failes
 *
 *  @return the final result of the parsing
 */
+(NSString *)stringFromJSON:(id)jsonObject defaultTo:(NSString *)defaultValue;

/**
 *  validates lat/lng coordinates. Latitude must be max/min +90 to -90
 *  Longitude : max/min +180 to -180 . 0/0 is an invalid location on earth
 *  @param latitude  double
 *  @param longitude double
 *
 *  @return is coordinate valid
 */
+(BOOL)isValidLatitude:(double)latitude andLongitude:(double)longitude;

@end
