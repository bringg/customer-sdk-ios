//
//  BringgCustomer_Private.h
//  BringgTracking
//
//  Created by Matan Poreh on 4/14/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import "GGHTTPClientManager.h"


@interface GGHTTPClientManager ()
@property (nullable, nonatomic, strong) NSString *developerToken;
@property (nullable, nonatomic, strong) GGCustomer *customer;


@property (nonatomic, strong) NSOperationQueue * _Nonnull serviceOperationQueue;
@property (nonatomic, strong) NSURLSessionConfiguration * _Nonnull sessionConfiguration;
@property (nonatomic, strong) NSDictionary * _Nullable customHeaders;
@property (nonatomic, assign) BOOL useSSL;


/**
 *  adds authentication params to the regular params of a call
 *
 *  @param params a pointer to the actual params
 */
-(void)addAuthinticationToParams:(NSMutableDictionary *_Nonnull* _Nonnull)params;


/**
 *  adds custom extra params to params group
 *
 *  @param extras the extra dictionary
 *  @param params  pointer to the actual params
 */
-(void)injectCustomExtras:(NSDictionary *_Nonnull)extras toParams:(NSMutableDictionary *_Nonnull *_Nonnull)params;



/**
 *  returns an authentication header to use
 *
 *  @return NSDictionary
 */
- (NSDictionary * _Nonnull)authenticationHeaders;

/**
 *  parses and returns a mutated path base on the method and SSL configuration
 *
 *  @param method http method
 *  @param path   path of call
 *
 *  @return modifed and final path of call
 */
- (nonnull NSString *)getServerURLWithMethod:(NSString * _Nonnull)method path:(NSString * _Nonnull * _Nonnull)path;

/**
 *  create and adds a http request to the service Q
 *
 *  @param method            HTTP method (GET/POST etc)
 *  @param path              path of request
 *  @param params            params to pass into the request
 *  @param completionHandler completion handler block
 *
 *  @return an NSOperation object that handles the http request
 */
- (NSOperation * _Nullable)httpRequestWithMethod:(NSString * _Nonnull)method
                                            path:(NSString *_Nonnull)path
                                          params:(NSDictionary * _Nullable)params
                               completionHandler:(void (^ _Nullable)(BOOL success, id _Nullable JSON, NSError * _Nullable error))completionHandler;


@end
