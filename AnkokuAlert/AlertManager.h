//
//  AlertManager.h
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 7/25/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AlertManagerDelegate;

@interface AlertManager : NSObject

-(id)initWithDelegate:(id<AlertManagerDelegate>)delegate;
-(void)loginToAntennaWithEmail:(NSString*)email password:(NSString*)password;

@end

@protocol AlertManagerDelegate<NSObject>

@optional
-(void)AlertManagerDidLoginToAntennaWithTicket:(NSString*)ticket;
-(void)AlertManagerDidFailToLoginToAntennaWithError:(NSError*)error;

@end
