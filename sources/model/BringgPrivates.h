//
//  BringgPrivates.h
//  BringgTracking
//
//  Created by Matan on 14/02/2017.
//  Copyright © 2017 Bringg. All rights reserved.
//

#ifndef BringgPrivates_h
#define BringgPrivates_h

@class GGHTTPClientManager;

@protocol PrivateClientConnectionDelegate <NSObject>

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

@optional

/**
 *  asks the delegate for a custom domain host for the tracker manager.
 *  if no domain is provided the tracker manager will resolve to its default
 *
 *  @param trackerManager the tracker manager request
 *
 *  @return the domain to connect the tracker manager
 */
-(NSString * _Nullable)hostDomainForTrackerManager:(GGTrackerManager *_Nonnull)trackerManager;


@end


@protocol NetworkClientUpdateDelegate <NSObject>

@optional
- (void)networkClient:(nonnull id)networkClient didReciveUpdateEventAtDate:(nonnull NSDate *)eventDate;

@end

#endif /* BringgPrivates_h */
