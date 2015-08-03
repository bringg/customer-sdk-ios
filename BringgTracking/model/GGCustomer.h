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


@property (nonatomic, strong) NSString *customerToken;
@property (nonatomic, strong) NSNumber *merchantId;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *imageURL;

/**
 *  init a Customer object using json data recieved from a server response
 *
 *  @param data a dictionary representing the json response object
 *
 *  @return a Customer object
 */
-(id)initWithData:(NSDictionary *)data;


@end
