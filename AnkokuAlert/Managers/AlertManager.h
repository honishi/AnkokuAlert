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
    AlertManagerErrorCodeLoginRequestFailed,
    AlertManagerErrorCodeStreamInfoRequestFailed,
    AlertManagerErrorCodeStreamInfoParseFailed,
    AlertManagerErrorCodeCommunityInfoRequestFailed,
    AlertManagerErrorCodeCommunityInfoParseFailed,
    AlertManagerErrorCodeChannelCommunityIdRequestFailed,
    AlertManagerErrorCodeChannelCommunityIdParseFailed
};

extern NSString* const AlertManagerAlertStatusKeyUserId;
extern NSString* const AlertManagerAlertStatusKeyUserName;
extern NSString* const AlertManagerAlertStatusKeyIsPremium;
extern NSString* const AlertManagerAlertStatusKeyCommunities;

extern NSString* const AlertManagerStreamInfoKeyLiveId;
extern NSString* const AlertManagerStreamInfoKeyLiveName;
extern NSString* const AlertManagerStreamInfoKeyLiveUrl;
extern NSString* const AlertManagerStreamInfoKeyCommunityId;
extern NSString* const AlertManagerStreamInfoKeyCommunityName;
extern NSString* const AlertManagerStreamInfoKeyCommunityUrl;

extern NSString* const AlertManagerCommunityInfoKeyCommunityName;

typedef void (^ LoginCompletionBlock)(NSDictionary* alertStatus, NSError* error);
typedef void (^ StreamInfoCompletionBlock)(NSDictionary* streamInfo, NSError* error);
typedef void (^ CommunityInfoCompletionBlock)(NSDictionary* communityInfo, NSError* error);
typedef void (^ ChannelCommunityIdCompletionBlock)(NSString* communityId, NSError* error);

@protocol AlertManagerStreamListener;

@interface AlertManager : NSObject

+(AlertManager*)sharedManager;

-(void)loginWithEmail:(NSString*)email
             password:(NSString*)password
           completion:(LoginCompletionBlock)completion;
-(void)openStreamWithAlertStatus:(NSDictionary*)alertStatus
                  streamListener:(id<AlertManagerStreamListener>)streamListener;
-(void)closeStream;
-(void)requestStreamInfoForLive:(NSString*)liveId completion:(StreamInfoCompletionBlock)completion;
-(void)requestCommunityInfoForCommunity:(NSString*)communityId completion:(CommunityInfoCompletionBlock)completion;
+(NSString*)communityUrlStringWithCommunithId:(NSString*)communityId;
-(void)requestChannelCommunityIdForChannelName:(NSString*)channelName completion:(ChannelCommunityIdCompletionBlock)completion;

@end

@protocol AlertManagerStreamListener<NSObject>

@optional
-(void)alertManagerDidOpenStream:(AlertManager*)alertManager;
-(void)alertManager:(AlertManager*)alertManager didFailToOpenStreamWithError:(NSError*)error;
-(void)alertManager:(AlertManager*)alertManager didReceiveLive:(NSString*)liveId community:(NSString*)communityId user:(NSString*)userId url:(NSString*)liveUrl;
-(void)alertManagerDidCloseStream:(AlertManager*)alertManager;

@end
