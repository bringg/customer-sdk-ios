//
//  BringgCustomer.h
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>



#define BCNameKey @"name"
#define BCPhoneKey @"phone"
#define BCMerchantIdKey @"merchant_id"
#define BCCustomerTokenKey @"access_token"

@interface GGCustomer : NSObject


@property (nonatomic, readonly) NSString *customerToken;
@property (nonatomic, readonly) NSString *merchantId;
@property (nonatomic, readonly) NSString *phone;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *email;
@property (nonatomic, readonly) NSString *address;
@property (nonatomic, readonly) NSString *imageURL;

-(id)initWithData:(NSDictionary *)data;


@end
