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
    AlertManagerErrorCodeLoginFailed,
    AlertManagerErrorCodeStreamInfoFailed,
    AlertManagerErrorCodeCommunityInfoFailed
};

extern NSString* const AlertManagerAlertStatusKeyUserId;
extern NSString* const AlertManagerAlertStatusKeyUserName;
extern NSString* const AlertManagerAlertStatusKeyIsPremium;
extern NSString* const AlertManagerAlertStatusKeyCommunities;

extern NSString* const AlertManagerStreamInfoKeyLive;
extern NSString* const AlertManagerStreamInfoKeyLiveTitle;
extern NSString* const AlertManagerStreamInfoKeyLiveUrl;
extern NSString* const AlertManagerStreamInfoKeyCommunity;
extern NSString* const AlertManagerStreamInfoKeyCommunityName;
extern NSString* const AlertManagerStreamInfoKeyCommunityUrl;

extern NSString* const AlertManagerCommunityInfoKeyCommunityName;

typedef void (^ LoginCompletionBlock)(NSDictionary* alertStatus, NSError* error);
typedef void (^ StreamInfoCompletionBlock)(NSDictionary* streamInfo, NSError* error);
typedef void (^ CommunityInfoCompletionBlock)(NSDictionary* communityInfo, NSError* error);

@protocol AlertManagerStreamListener;

@interface AlertManager : NSObject

+(AlertManager*)sharedManager;
-(void)loginWithEmail:(NSString*)email
             password:(NSString*)password
           completion:(LoginCompletionBlock)completion;
-(void)openStreamWithAlertStatus:(NSDictionary*)alertStatus
                  streamListener:(id<AlertManagerStreamListener>)streamListener;
-(void)closeStream;
-(void)streamInfoForLive:(NSString*)live completion:(StreamInfoCompletionBlock)completion;
-(void)communityInfoForCommunity:(NSString*)community completion:(CommunityInfoCompletionBlock)completion;

@end

@protocol AlertManagerStreamListener<NSObject>

@optional
-(void)alertManagerdidOpenStream:(AlertManager*)alertManager;
-(void)alertManager:(AlertManager*)alertManager didFailToOpenStreamWithError:(NSError*)error;
-(void)alertManager:(AlertManager*)alertManager didReceiveLive:(NSString*)live community:(NSString*)community user:(NSString*)user;
-(void)alertManagerDidCloseStream:(AlertManager*)alertManager;

@end
