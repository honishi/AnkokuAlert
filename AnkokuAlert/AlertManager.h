//
//  AlertManager.h
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 7/25/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const AlertManagerAlertStatusUserNameKey;
extern NSString* const AlertManagerAlertStatusIsPremiumKey;
extern NSString* const AlertManagerAlertStatusCommunitiesKey;
extern NSString* const AlertManagerAlertStatusServerAddressKey;
extern NSString* const AlertManagerAlertStatusServerPortKey;
extern NSString* const AlertManagerAlertStatusServerThreadKey;

@protocol AlertManagerDelegate;

@interface AlertManager : NSObject

-(id)initWithDelegate:(id<AlertManagerDelegate>)delegate;
-(void)openStreamWithEmail:(NSString*)email password:(NSString*)password;

@end

@protocol AlertManagerDelegate<NSObject>

@optional
-(void)alertManager:(AlertManager*)alertManager didLoginToAntennaWithTicket:(NSString*)ticket;
-(void)alertManager:(AlertManager*)alertManager didFailToLoginToAntennaWithError:(NSError*)error;
-(void)alertManager:(AlertManager*)alertManager didGetAlertStatus:(NSDictionary*)alertStatus;
-(void)alertManager:(AlertManager*)alertManager didFailToGetAlertStatusWithError:(NSError*)error;

@end
