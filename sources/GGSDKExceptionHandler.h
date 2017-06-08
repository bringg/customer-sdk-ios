//
//  GGSDKExceptionHandler.h
//  BringgTracking
//
//  Created by Matan on 08/06/2017.
//  Copyright © 2017 Bringg. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GGSDKExceptionHandler : NSObject

+ (nonnull instancetype)sharedInstance;


/**
 stored exceptions
 */
@property (nonnull, nonatomic, strong, readonly) NSArray<NSString *> *cachedExceptions;


/**
 removes a stored exception

 @param exeptionData the data of the stored exception
 */
- (void)removeExceptionByData:(nonnull NSString *)exeptionData;

@end


/**
 add C handler for global uncaughtexceptions
 */
void SetupUncaughtExceptionHandler();
