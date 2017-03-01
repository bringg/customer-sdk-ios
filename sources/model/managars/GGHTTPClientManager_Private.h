//
//  BringgCustomer_Private.h
//  BringgTracking
//
//  Created by Matan Poreh on 4/14/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

 
#import "GGHTTPClientManager.h"
#import "BringgPrivates.h"  

#define POLLING_SEC 30
#define MAX_WITHOUT_POLLING_SEC 240

#define BCRealtimeServer @"realtime2-api.bringg.com"


#define BCNameKey @"name"
#define BCConfirmationCodeKey @"confirmation_code"
#define BCDeveloperTokenKey @"developer_access_token"

#define BCRatingTokenKey @"token"
#define BCRatingKey @"rating"


#define BCRESTMethodPost @"POST"
#define BCRESTMethodGet @"GET"
#define BCRESTMethodPut @"PUT"
#define BCRESTMethodDelete @"DELETE"

#define API_PATH_SIGN_IN @"/api/customer/sign_in"//method: POST; phone, name, confirmation_code, merchant_id, dev_access_token
#define API_PATH_SHARED_LOCATION @"/shared/%@/location/"
#define API_PATH_ORDER @"/api/customer/task/%@" // method: GET ; task id
#define API_PATH_ORDER_CREATE @"/api/customer/task/create" // method: POST
#define API_PATH_RATE @"/api/rate/%@" // method: POST; shared_location_uuid, rating token, rating
#define API_PATH_ORDER_UUID @"/shared/orders/%@/" //method: GET; order_uuid !!!!! creates new shared_location object !!!!
#define API_PATH_WATCH_ORDER @"/watch/shared/%@/" //method: GET; shared_location_uuid,  params - order_uuid
#define API_PATH_DRIVER_PHONE @"api/customer/task/%@/way_point/%@/phone" // method: GET ; task id, waypoint id

//PRIVATE
#define API_PATH_REQUEST_CONFIRMATION @"/api/customer/confirmation/request" //method:Post ;merchant_id, phone


#define HTTP_FORMAT @"http://%@"
#define HTTPS_FORMAT @"https://%@"

@interface GGHTTPClientManager ()
@property (nullable, nonatomic, strong) NSString *developerToken;
@property (nullable, nonatomic, strong) GGCustomer *customer;


@property (nonatomic, strong) NSOperationQueue * _Nonnull serviceOperationQueue;
@property (nonatomic, strong) NSURLSessionConfiguration * _Nonnull sessionConfiguration;
@property (nonatomic, strong) NSURLSession * _Nonnull session;
@property (nonatomic, strong) NSDictionary * _Nullable customHeaders;
@property (nonatomic, assign) BOOL useSSL;

@property (nullable, nonatomic, weak) id<PrivateClientConnectionDelegate> connectionDelegate;

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
- (nonnull NSString *)getServerURL;



/**
 *  creates and adds a REST request to the service Q to be executed asynchronously
 *
 *  @usage                   it is recommended to use with subclasses of  the http manager or when writing requests for known BRINGG API calls that have not yet been implemented in this SDK
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

/**
 *  check if it has been too long since a polling REST event
 *
 *  @usage if no http client exists this will always return NO
 *  @return BOOL
 */
- (BOOL)isWaitingTooLongForHTTPEvent;


@end
