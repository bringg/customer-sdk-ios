//
//  GGRealTimeManager.h
//  BringgTracking
//
//  Created by Matan on 6/25/15.
//  Copyright (c) 2015 Matan Poreh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocketIO.h"

#define BTRealtimeServer @"realtime-api.bringg.com"



@interface GGRealTimeMontior : NSObject<SocketIODelegate>

-(void)useSecureConnection:(BOOL)shouldUse;

@end
