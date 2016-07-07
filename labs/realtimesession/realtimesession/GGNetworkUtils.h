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

+ (void)parseStatusOfJSONResponse:(nonnull NSDictionary *)responseObject
                        toSuccess:(BOOL  * _Nonnull )successResult
                         andError:(NSError *__autoreleasing __nonnull* __nonnull)error;


+ (void)handleDataFailureResponse:(nullable NSURLResponse *)response
                            error:(nonnull NSError*)error
                         completionHandler:(nullable GGNetworkResponseHandler)completionHandler;

+ (void)handleDataSuccessResponseWithData:(nullable NSData*)data
                        completionHandler:(nullable GGNetworkResponseHandler)completionHandler;

+ (NSMutableURLRequest * _Nullable)jsonRequestForServer:(NSString * _Nonnull)server
                                                 method:(NSString * _Nonnull)method
                                                    path:(NSString *_Nonnull)path
                                                 headers:(NSDictionary * _Nonnull)headers
                                                  params:(NSDictionary * _Nullable)params
                                                  error:(NSError *__autoreleasing __nonnull* __nonnull)error;


+ (NSURLSessionDataTask * _Nullable) httpRequestWithSession:(NSURLSession * _Nonnull)session
                                                     server:(NSString * _Nonnull)server
                                                     method:(NSString * _Nonnull)method
                                                       path:(NSString *_Nonnull)path
                                                    headers:(NSDictionary * _Nonnull)headers
                                                     params:(NSDictionary * _Nullable)params
                                          completionHandler:(nullable GGNetworkResponseHandler)completionHandler;




@end
