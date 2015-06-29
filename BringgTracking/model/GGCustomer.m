//
//  BringgCustomer.m
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import "GGCustomer.h"

@implementation GGCustomer

@synthesize customerToken,merchantId,phone, name, email,address, imageURL;




-(id)initWithData:(NSDictionary *)data {
    
    if (self = [super init]) {
        
        customerToken = [data objectForKey:BCCustomerTokenKey];
        merchantId = [data objectForKey:BCMerchantIdKey];
        phone = [data objectForKey:BCPhoneKey];
        name = [data objectForKey:BCNameKey];
        email = [data objectForKey:@"email"];
        address = [data objectForKey:@"address"];
        imageURL = [data objectForKey:@"image"];
        
        if ( !customerToken || [customerToken isEqual:[NSNull null]]) {
            customerToken = @"xyxqLH7dmjZaDL1S2zZw";
        }
    }
    
#warning TODO HACK
    
    
    return self;
    
}

@end
