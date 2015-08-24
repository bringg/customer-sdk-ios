//
//  GGBringgUtils.h
//  BringgTracking
//
//  Created by Matan on 8/24/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GGBringgUtils : UIView

+(NSInteger)integerFromJSON:(id)jsonObject defaultTo:(NSInteger)defaultValue;
+(double)doubleFromJSON:(id)jsonObject defaultTo:(double)defaultValue;
+(BOOL)boolFromJSON:(id)jsonObject defaultTo:(BOOL)defaultValue;
+(NSString *)stringFromJSON:(id)jsonObject defaultTo:(NSString *)defaultValue;

@end
