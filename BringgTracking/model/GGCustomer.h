//
//  BringgCustomer.h
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>



#define GGCustomerStoreKeyToken @"customerToken"
#define GGCustomerStoreKeyPhone @"customerPhone"
#define GGCustomerStoreKeyName @"customerName"
#define GGCustomerStoreKeyEmail @"customerEmail"
#define GGCustomerStoreKeyAddress @"customerAddress"
#define GGCustomerStoreKeyImageURL @"customerImageUrl"
#define GGCustomerStoreKeyFBID @"customerFBiD"
#define GGCustomerStoreKeyMerchantID @"customerMerchantId"
#define GGCustomerStoreKeyID @"customerId"
#define GGCustomerStoreKeyLAT @"customerLat"
#define GGCustomerStoreKeyLNG @"customerLng"



@interface GGCustomer : NSObject<NSCoding>


@property (nonatomic, strong) NSString * _Nullable customerToken;
@property (nonatomic, strong) NSString * _Nullable phone;
@property (nonatomic, strong) NSString * _Nullable name;
@property (nonatomic, strong) NSString * _Nullable email;
@property (nonatomic, strong) NSString * _Nullable address;
@property (nonatomic, strong) NSString * _Nullable imageURL;
@property (nonatomic, strong) NSString * _Nullable facebookId;
@property (nonatomic, strong) NSNumber * _Nullable merchantId;

@property (nonatomic, assign) NSInteger customerId;
@property (nonatomic, assign) double lat;
@property (nonatomic, assign) double lng;


/**
 *  init a Customer object using json data recieved from a server response
 *
 *  @param data a dictionary representing the json response object
 *
 *  @return a Customer object
 */
-(nonnull instancetype)initWithData:(NSDictionary * _Nullable)data;


/**
 *  retrieves an authentication identifer for authenticating web calls
 *
 *  @return an authentication identifer
 */
- (nullable NSString *)getAuthIdentifier;


@end
