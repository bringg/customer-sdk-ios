//
//  BringgCustomer_Private.h
//  BringgTracking
//
//  Created by Ilya Kalinin on 4/14/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import "GGHTTPClientManager.h"


@interface GGHTTPClientManager ()
@property (nonatomic, strong) NSString *developerToken;
@property (nonatomic, strong) GGCustomer *customer;


@end
