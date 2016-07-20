//
//  GGNetworkUtils.m
//  BringgTracking
//
//  Created by Matan on 07/07/2016.
//  Copyright © 2016 Matan Poreh. All rights reserved.
//

#import "GGNetworkUtils.h"
#import "BringgGlobals.h"
#import "GGBringgUtils.h"

@interface GGNetworkUtils ()<NSURLSessionDelegate>

@end

@implementation GGNetworkUtils


//MARK: - Helper

+(void)parseFullPath:(nonnull NSString*)fullPath toServer:(NSString *__autoreleasing __nonnull* __nonnull)server relativePath:(NSString *__autoreleasing __nonnull* __nonnull)relativePath{
    
    // break down full path to server and path
    NSURL *tmpURL = [NSURL URLWithString:fullPath];
    if (tmpURL) {
        *relativePath = [NSString stringWithFormat:@"%@", tmpURL.path];
        *server = [fullPath stringByReplacingOccurrencesOfString:*relativePath withString:@""];
    }else{
        *relativePath = nil;
        *server = nil;
    }

    
}

+ (BOOL)isFullPath:(nonnull NSString *)path{
    
    
    if (!path) {
        return NO;
    }
    
    // use the util to determin valid full url
    return [GGBringgUtils isValidUrlString:path];

}

+ (nonnull NSString *)queryStringFromParams:(nullable NSDictionary *)params{
    
    if (!params || params.allKeys.count == 0) {
        return @"";
    }
    __block NSMutableArray<NSString *> *urlVars = [NSMutableArray new];
    
    [params enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull k, id  _Nonnull obj, BOOL * _Nonnull stop) {
        
        // for query strings to work - key must be string
        if ([k isKindOfClass:[NSString class]]) {
            // for url vars to work we must convert the value object to a string
            id value = obj;
            if (![obj isKindOfClass:[NSString class]]) {
                value = [obj stringValue];
            }
            
            // get url encoded string value
            NSString *encodedValue =  [value stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            
            if (encodedValue) {
                // build the url var it self (k=v)
                NSString *urlVar = [NSString stringWithFormat:@"%@=%@", k, encodedValue];
                [urlVars addObject:urlVar];
            }

        }
        
        
    }];
    
    if (urlVars.count == 0) {
        return @"";
    }
    
    // return query string
    return [NSString stringWithFormat:@"?%@", [urlVars componentsJoinedByString:@"&"]];
    
    
}

+ (void)parseStatusOfJSONResponse:(nonnull NSDictionary *)responseObject
                        toSuccess:(BOOL  * _Nonnull )successResult
                         andError:(NSError *__autoreleasing __nonnull* __nonnull)error{
    
    
    *successResult = NO;
    
    //protect agains nil response
    if (!responseObject) {
        *error = [NSError errorWithDomain:kSDKDomainData code:GGErrorTypeInvalid
                                 userInfo:@{NSLocalizedDescriptionKey: @"can not parse nil response"}];
        
        return;
    }
    
    // there are two params that represent success
    id success = [responseObject objectForKey:BCSuccessKey];
    
    BOOL successObjValid = YES;
    
    // if it's "success" then then check for valid data (should be bool)
    if (success != nil) {
        
        if ([success isKindOfClass:[NSNumber class]] || [success isKindOfClass:[NSString class]]) {
            *successResult = [success boolValue];
        }else{
            successObjValid = NO;
        }
    }else{
        
        // "status" could also represent a succesfull call - status here will be a string
        success = [responseObject objectForKey:BCSuccessAlternateKey];
        
        // check if status field is valid and if success
        if ([success isKindOfClass:[NSString class]] &&
            [success isEqualToString:@"ok"]) {
            
            *successResult = YES;
            
        }else{
            successObjValid = NO;
        }
    }
 
    
    // check if there is another success params to indicate response status
    if (success == nil || !*successResult || !successObjValid) {
        
        // for sure we have a failed response - both success params tests failed
        
        id message = [responseObject objectForKey:BCMessageKey];
        
        // if success response is valid and is false and no message - create a message
        if (!message && *successResult == NO && successObjValid) {
            message = @"Undefined Error";
        }
        
        // some times the success key is part of a legitimate response object - so no message will exits
        // but other data will be present so we should conisder it
        
        if (message && [message isKindOfClass:[NSString class]]) {
            
            // check if response has also response code
            NSInteger rc = [responseObject objectForKey:@"rc"] ?  [[responseObject objectForKey:@"rc"] integerValue] : 0;
            
            *error = [NSError errorWithDomain:kSDKDomainResponse code:rc
                                     userInfo:@{NSLocalizedDescriptionKey: message,
                                                NSLocalizedRecoverySuggestionErrorKey: message}];
            
        } else {
            
            *successResult = YES;
            
        }
    }
    
}

+ (NSMutableURLRequest * _Nullable)jsonGetRequestWithServer:(NSString * _Nonnull)server
                                                     method:(NSString * _Nonnull)method
                                                        path:(NSString *_Nonnull)path
                                                      params:(NSDictionary * _Nullable)params{
    
    
    // guard against invalid method arguments
    if ( !server || !method || !path) {

        NSException *exp = [NSException exceptionWithName:@"InvalidArgumentsException" reason:@"arguments can not be nil" userInfo:nil];
        
        @throw exp;
        
        
        return nil;
    }

    
    // url is a combination of server path and query string
    NSURL *CTSURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",server,path,[self queryStringFromParams:params] ]];
    
    
    if (!CTSURL) {
        NSException *exp = [NSException exceptionWithName:@"InvalidArgumentsException" reason:@"URL can not be nil" userInfo:nil];
        
        @throw exp;
        
        
        return nil;
    }
    
    // build mutable request with url
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:CTSURL
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:30.0];
    
    // set method
    [request setHTTPMethod:method];
    
    // return request
    return request;
    
}

+ (NSMutableURLRequest * _Nullable)jsonUpdateRequestWithServer:(NSString * _Nonnull)server
                                                        method:(NSString * _Nonnull)method
                                                           path:(NSString *_Nonnull)path
                                                         params:(NSDictionary * _Nullable)params
                                                          error:(NSError *__autoreleasing __nonnull* __nonnull)error{
    
    
    // guard against invalid method arguments
    if ( !server || !method || !path) {
        
        NSException *exp = [NSException exceptionWithName:@"InvalidArgumentsException" reason:@"arguments can not be nil" userInfo:nil];
        
        @throw exp;
        
        
        return nil;
    }

    
    NSURL *CTSURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",server,path]];
    
    
    
    if (!CTSURL) {
        NSException *exp = [NSException exceptionWithName:@"InvalidArgumentsException" reason:@"URL can not be nil" userInfo:nil];
        
        @throw exp;
        
        
        return nil;
    }

    
    // build mutable request with url
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:CTSURL
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:30.0];
    
    
    // add content headers
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    //[request addValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
    //[request addValue:@"text/plain" forHTTPHeaderField:@"Accept"];
    
    // set method
    [request setHTTPMethod:method];
    
    // build the params as json serialized
    NSError *jsonParamsError;
    
    NSData *paramsData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&jsonParamsError];
    
    if (jsonParamsError) {
        
        *error = jsonParamsError;
        return nil;
    }
    
    // add params data to body
    [request setHTTPBody:paramsData];
    
    
    
    
    return request;
}


+ (void)handleDataSuccessResponseWithData:(nullable NSData*)data
                        completionHandler:(nullable GGNetworkResponseHandler)completionHandler{
    
    if (data) {
        NSError *jsonError = nil;
        
        
        __block NSError *responseError = nil;
        __block BOOL responseSuccess = NO;
        
        __block id responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
        
        
        if (jsonError) {
            responseError = jsonError;
        }else{
            // check that response is json is of calid structure
            if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
                
                // parse json response
                [self parseStatusOfJSONResponse:responseObject toSuccess:&responseSuccess andError:&responseError];
                
                
            }
            
        }

        // execute completion handler
        if (completionHandler){
            dispatch_async(dispatch_get_main_queue(), ^{
                
                completionHandler(responseSuccess, [responseObject isKindOfClass:[NSDictionary class]] ? responseObject : nil, responseError);
            });
        }
        
        
    }
}

+ (void)handleDataFailureResponse:(nullable NSURLResponse *)response
                            error:(nonnull NSError*)error
                completionHandler:(nullable GGNetworkResponseHandler)completionHandler{
    
    
    NSString *path = [error.userInfo objectForKey:NSURLErrorFailingURLErrorKey];
    if (!path) {
        path = response.URL.absoluteString;
    }
    
#if DEBUG
    NSLog(@"GOT HTTP ERROR (%@) For Path %@:", error, path);
#endif
    
    if (completionHandler) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // check if error code implies server unavailable
            if (error && error.code >= 500 && error.code < 600) {
                
                NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
                [info setObject:@"server temporarily unavailable, please try again later." forKey:NSLocalizedDescriptionKey];
                
                // create new error object and send it
                NSError *newError = [NSError errorWithDomain:error.domain code:error.code userInfo:info];
                completionHandler(NO, nil, newError);
                
            }else{
                // execute failure completion
                completionHandler(NO, nil, error);
            }
            
        });
        
    }
    
}


+ (NSURLSessionDataTask * _Nullable) httpRequestWithSession:(NSURLSession * _Nonnull)session
                                                     server:(NSString * _Nonnull)server
                                                     method:(NSString * _Nonnull)method
                                                       path:(NSString *_Nonnull)path
                                                     params:(NSDictionary * _Nullable)params
                                          completionHandler:(nullable GGNetworkResponseHandler)completionHandler{
    
    
    // guard against invalid method arguments
    if (!session || !server || !method || !path) {
        
        NSError *error = [NSError errorWithDomain:kSDKDomainData code:GGErrorTypeInvalid userInfo:@{NSLocalizedDescriptionKey:@"invalid method arguments. arguments can not be nil"}];
        
        if (completionHandler) {
            completionHandler(NO, nil, error);
        }
        
        return nil;
    }
    
    NSError *jsonRequestError;
    
    // build mutable request with url
    NSMutableURLRequest *request;
    
    @try {
        if ([method isEqualToString:@"GET"]) {
            request = [self jsonGetRequestWithServer:server method:method path:path params:params];
        }else{
            request = [self jsonUpdateRequestWithServer:server method:method path:path params:params error:&jsonRequestError];
        }

    } @catch (NSException *exception) {
        // convert the exception to an error
        jsonRequestError = [NSError errorWithDomain:kSDKDomainData code:GGErrorTypeInvalid userInfo:@{NSLocalizedDescriptionKey:exception.name, NSLocalizedFailureReasonErrorKey:exception.reason}];
    }
    
    
    
    if (jsonRequestError) {
        NSLog(@" error creating json params for request request in %s : %@", __PRETTY_FUNCTION__, jsonRequestError);
        
        if (completionHandler) {
            completionHandler(NO, nil, jsonRequestError);
        }
        
        return nil;
    }
    
    
    // create data task for session
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
    
        // handle competion for data task
        if (error) {
            // handle error
            [self handleDataFailureResponse:response error:error completionHandler:completionHandler];
        }else{
            
            
#ifdef DEBUG
            NSLog(@"Got response for %@ %@\n%@", method, path, [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil]);
#endif
            
            // handle success response
            [self handleDataSuccessResponseWithData:data completionHandler:completionHandler];
        }
        
    }];
    
    NSLog(@"created data task for path %@ %@", server,  path);
    
    return dataTask;
    
    
    
    
}

//MARK: - Session Delegate
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler{
    
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
    
    NSLog(@"session received challange %@", challenge);
}


- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error{
    
    NSLog(@"session invalidated with %@", error ?: @"no error");
}


@end
