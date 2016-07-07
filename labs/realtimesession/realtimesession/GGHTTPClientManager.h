//
//  BringgCustomer.h
//  BringgTracking
//
//  Created by Matan Poreh on 3/9/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BringgGlobals.h"



@class GGHTTPClientManager;


@protocol GGHTTPClientConnectionDelegate <NSObject>

@optional

/**
 *  asks the delegate for a custom domain host for the http manager.
 *  if no domain is provided the http manager will resolve to its default
 *
 *  @param clientManager the client manager request
 *
 *  @return the domain to connect the http manager
 */
-(NSString * _Nullable)hostDomainForClientManager:(GGHTTPClientManager *_Nonnull)clientManager;

@end

@interface GGHTTPClientManager : NSObject

@property (nullable, nonatomic, weak) id<GGHTTPClientConnectionDelegate> delegate;
@property (nullable, nonatomic, strong) NSDate *lastEventDate;


/**
 *  return an initialized http manager singelton
 *  @warning make sure the singleton is already intiialized before using this accessor
 *  @return the http manager singelton
 */
+ (nonnull id)manager;

/**
 *  get a singelton reference to the http client manager
 *  @param developerToken   the developer token acquired when registering as a developer in Bringg website
 *  @return the http manager singelton
 */
+ (nonnull id)managerWithDeveloperToken:(NSString *_Nullable)developerToken;

/**
 *  set the developer token for the singelton
 *  @warning it is prefered to init the singelton with a developer token instead of using this method
 *  @param devToken
 */
- (void)setDeveloperToken:(NSString * _Nullable)devToken;


/**
 *  tells the manager to use or not use HTTPS
 *  @usage default is set to YES
 *  @param isSecured BOOL
 */
- (void)useSecuredConnection:(BOOL)isSecured;



/**
 *  perform a sign in request with a specific customers credentials
 *  @warning do not call this method before setting a valid developer token. also notice method call won't work without valid confirmation code and merchant Id
 *  @param name              name of customer (don't use email here)
 *  @param phone             phone number of customer
 *  @param confirmationCode  sms confirmation code
 *  @param merchantId        merchant id registered for the customer
 *  @param extras            additional arguments to add to the call
 *  @param completionHandler block to handle async service response
 */
- (void)signInWithName:(NSString * _Nullable)name
                 phone:(NSString * _Nullable)phone
                 email:(NSString * _Nullable)email
              password:(NSString * _Nullable)password
      confirmationCode:(NSString * _Nullable)confirmationCode
            merchantId:(NSString * _Nonnull)merchantId
                extras:(NSDictionary * _Nullable)extras
     completionHandler:(nullable GGNetworkResponseHandler)completionHandler;




 
@end
