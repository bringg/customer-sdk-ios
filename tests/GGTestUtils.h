//
//  GGTestUtils.h
//  BringgTracking
//
//  Created by Matan on 05/11/2015.
//  Copyright © 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ARC4RANDOM_MAX 0x100000000


@class GGOrder, GGDriver;

@interface GGTestUtils : NSObject

+(nullable NSDictionary *)parseJsonFile:(NSString * _Nonnull)fileName;
+(void)parseUpdateData:(NSDictionary * _Nonnull)eventData intoOrder:(GGOrder *_Nonnull *_Nonnull)order andDriver:(GGDriver *_Nonnull  *_Nonnull)driver;
+(nonnull NSString *)exampleOrderJsonData;
+(nonnull NSString *)exampleLocationJsonData;
+(double)randomBetweenMin:(double)min andMax:(double)max;
@end
