//
//  BringgOrder.h
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BringgGlobals.h"

@class GGSharedLocation;

@interface GGOrder : NSObject

@property (nonatomic) NSInteger orderid;
@property (nonatomic) OrderStatus status;
@property (nonatomic, readonly) NSString *uuid;
@property (nonatomic, readonly) GGSharedLocation *sharedLocation;

-(id)initOrderWithData:(NSDictionary*)data;
-(id)initOrderWithUUID:(NSString *)ouuid atStatus:(OrderStatus)ostatus;


@end
