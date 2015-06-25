//
//  BringgCustomer.m
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Ilya Kalinin. All rights reserved.
//

#import "GGCustomer.h"

@implementation GGCustomer

@synthesize customerToken,merchantId,phone, name;




-(id)initWithData:(NSDictionary *)data {
    
    if (self = [super init]) {
        
        customerToken = [data objectForKey:BCCustomerTokenKey];
        merchantId = [data objectForKey:BCMerchantIdKey];
        phone = [data objectForKey:BCPhoneKey];
        name = [data objectForKey:BCNameKey];
        
    }
    
    return self;
    
}

@end
