//
//  AlertManager.h
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 7/25/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const AlertManagerErrorDomain;

typedef NS_ENUM (NSInteger, AlertManagerErrorCode) {
    AlertManagerErrorCodeUnknownError,
    AlertManagerErrorCodeLoginFailed
};

extern NSString* const AlertManagerAlertStatusUserNameKey;
extern NSString* const AlertManagerAlertStatusIsPremiumKey;
extern NSString* const AlertManagerAlertStatusCommunitiesKey;

typedef void (^ LoginCompletionBlock)(NSDictionary* alertStatus, NSError* error);

@protocol AlertManagerStreamListener;

@interface AlertManager : NSObject

+(AlertManager*)sharedManager;
-(void)loginWithEmail:(NSString*)email
             password:(NSString*)password
           completion:(LoginCompletionBlock)completion;
-(void)openStreamWithAlertStatus:(NSDictionary*)alertStatus
                  streamListener:(id<AlertManagerStreamListener>)streamListener;

@end

@protocol AlertManagerStreamListener<NSObject>

@optional
-(void)alertManagerdidOpenStream:(AlertManager*)alertManager;
-(void)alertManager:(AlertManager*)alertManager didFailToOpenStreamWithError:(NSError*)error;
-(void)alertManager:(AlertManager*)alertManager didReceiveLiveInfo:(NSDictionary*)live;

@end
