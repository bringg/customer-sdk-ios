//
//  GGNetworkUtils.h
//  BringgTracking
//
//  Created by Matan on 07/07/2016.
//  Copyright © 2016 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BringgGlobals.h"

@interface GGNetworkUtils : NSObject

/**
 *  takes request parameters dictionary and converts it to querry string
 *
 *  @param params dictionary params
 *
 *  @return string
 */
+ (nonnull NSString *)queryStringFromParams:(nullable NSDictionary *)params;


/**
 *  takes a json response and infers if the resonse was successfull , if not it will pass the error implied in the json response
 *
 *  @param responseObject json response object
 *  @param successResult  pointer to success ivar
 *  @param error          pointer to error ivar
 */
+ (void)parseStatusOfJSONResponse:(nonnull NSDictionary *)responseObject
                        toSuccess:(BOOL  * _Nonnull )successResult
                         andError:(NSError *__autoreleasing __nonnull* __nonnull)error;


/**
 *  handles cases where data tasks failed
 *
 *  @param response          failure response
 *  @param error             error in response
 *  @param completionHandler callback handler
 */
+ (void)handleDataFailureResponse:(nullable NSURLResponse *)response
                            error:(nonnull NSError*)error
                completionHandler:(nullable GGNetworkResponseHandler)completionHandler;

/**
 *  handles cases where data task was successfull
 *
 *  @param data              response data object
 *  @param completionHandler callback handler
 */
+ (void)handleDataSuccessResponseWithData:(nullable NSData*)data
                        completionHandler:(nullable GGNetworkResponseHandler)completionHandler;

/**
 *  creates a json url request with for update actions (POST, PUT, PATCH, DELETE)
 *
 *  @param server  server
 *  @param method  method
 *  @param path    path
 *  @param params  params
 *  @param error   error in creation
 *  @throws error if arguemnts are invalid
 
 *  @return URLRequest
 */
+ (NSMutableURLRequest * _Nullable)jsonUpdateRequestWithServer:(NSString * _Nonnull)server
                                                        method:(NSString * _Nonnull)method
                                                          path:(NSString *_Nonnull)path
                                                        params:(NSDictionary * _Nullable)params
                                                         error:(NSError *__autoreleasing __nonnull* __nonnull)error;


/**
 *  creates a json url request with for GET action (GET)
 *
 *  @param server  server
 *  @param method  method
 *  @param path    path
 *  @param params  params
 *  @throws error if arguemnts are invalid
 *
 *  @return URLRequest
 */
+ (NSMutableURLRequest * _Nullable)jsonGetRequestWithServer:(NSString * _Nonnull)server
                                                     method:(NSString * _Nonnull)method
                                                       path:(NSString *_Nonnull)path
                                                     params:(NSDictionary * _Nullable)params;

/**
 *  generates an http request action
 *
 *  @param session           session responsible for request
 *  @param server            server
 *  @param method            method
 *  @param path              path
 *  @param params            params
 *  @param completionHandler callback handler
 *
 *  @return session data task
 */
+ (NSURLSessionDataTask * _Nullable) httpRequestWithSession:(NSURLSession * _Nonnull)session
                                                     server:(NSString * _Nonnull)server
                                                     method:(NSString * _Nonnull)method
                                                       path:(NSString *_Nonnull)path
                                                     params:(NSDictionary * _Nullable)params
                                          completionHandler:(nullable GGNetworkResponseHandler)completionHandler;




@end
