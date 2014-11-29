//
//  AnkokuAlertTests.m
//  AnkokuAlertTests
//
//  Created by Hiroyuki Onishi on 7/22/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "AlertManager.h"

@interface AnkokuAlertTests : XCTestCase

@end

// convenience macro for waiting async process
#define waitForCondition(CONDITION, TIMEOUT) { \
        NSDate* waitDate = [NSDate dateWithTimeIntervalSinceNow:TIMEOUT]; \
        do { \
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1f]]; \
        } while ( !(CONDITION) && 0 < waitDate.timeIntervalSinceNow ); \
}
#define waitForTime(TIME) { [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:TIME]]; }

@interface AnkokuAlertTests ()<AlertManagerStreamListener>

@property (nonatomic, strong) AlertManager* alertManager;
@property (nonatomic, strong) NSString* email;
@property (nonatomic, strong) NSString* password;
@property (nonatomic, assign) BOOL streamOpened;

@end

@implementation AnkokuAlertTests

-(void)setUp
{
    [super setUp];

    NSBundle* bundle = [NSBundle bundleForClass:[AnkokuAlertTests class]];
    NSString* path = [bundle pathForResource:@"TestAccount" ofType:@"plist"];
    NSDictionary* testAccount = [NSDictionary dictionaryWithContentsOfFile:path];
    self.email = testAccount[@"email"];
    self.password = testAccount[@"password"];

    self.alertManager = AlertManager.sharedManager;
}

-(void)tearDown
{
    // Tear-down code here.

    [super tearDown];
}

-(void)testLogin
{
    // login
    __block NSDictionary* fetchedAlertStatus;
    LoginCompletionBlock completion = ^(NSDictionary* alertStatus, NSError* error) {
        if (error) {
            NSLog(@"error in login: %@", error);
        }
        NSLog(@"login completed with alert status: %@", alertStatus);
        fetchedAlertStatus = alertStatus;
    };
    [self.alertManager loginWithEmail:self.email password:self.password completion:completion];

    waitForCondition(fetchedAlertStatus != nil, 5.0f);
    XCTAssertNotNil(fetchedAlertStatus, @"");

    // open stream
    [self.alertManager openStreamWithAlertStatus:fetchedAlertStatus streamListener:self];
    waitForCondition(self.streamOpened == YES, 5.0f);

    self.alertManager = nil;
}

#pragma mark - AlertManagerListener Methods

-(void)alertManagerDidOpenStream:(AlertManager*)alertManager
{
    NSLog(@"LOG: %s:%d: %@", __PRETTY_FUNCTION__, __LINE__, @"");
    self.streamOpened = YES;
}

-(void)alertManager:(AlertManager*)alertManager didFailToOpenStreamWithError:(NSError*)error
{
    NSLog(@"LOG: %s:%d: %@", __PRETTY_FUNCTION__, __LINE__, @"");
}

-(void)alertManager:(AlertManager*)alertManager didReceiveLive:(NSString*)live community:(NSString*)community user:(NSString*)user
{
    NSLog(@"LOG: %s:%d: %@", __PRETTY_FUNCTION__, __LINE__, @"");
}

#pragma mark - Community Info (resolves community name from community id)

-(void)testCommunityInfo
{
    [self examineCommunityNameWithCommunity:@"co367128" expectedName:@"アイマス24時間放送"];
    [self examineCommunityNameWithCommunity:@"co1902299" expectedName:@"＠ねこチーム"];
    [self examineCommunityNameWithCommunity:@"co25623" expectedName:@"PITACore Box - ニコ生ツール開発・無人リクエスト放送"];
}

-(void)examineCommunityNameWithCommunity:(NSString*)community expectedName:(NSString*)expectedName
{
    __block NSString* communityName = nil;

    [self.alertManager requestCommunityInfoForCommunity:community completion:^(NSDictionary* communityInfo, NSError* error) {
         if (error) {
             NSLog(@"error in request community info: %@", error);
             return;
         }

         communityName = communityInfo[AlertManagerCommunityInfoKeyCommunityName];
     }];

    waitForCondition(communityName != nil, 5.0f);
    NSLog(@"[%@], expected[%@], actual[%@]", community, expectedName, communityName);
    XCTAssert([communityName isEqualToString:expectedName] == true, @"");
}

#pragma mark - Channel Info (resolves community id from channel name)

-(void)testChannelInfo
{
    [self examineChannelNameWithChannelName:@"gurikan" expectedCommunityId:@"ch2590739"];
    [self examineChannelNameWithChannelName:@"noriradi" expectedCommunityId:@"ch2597951"];
    [self examineChannelNameWithChannelName:@"iiotonatati" expectedCommunityId:@"ch2598414"];
}

-(void)examineChannelNameWithChannelName:(NSString*)channelName expectedCommunityId:(NSString*)expectedCommunityId
{
    __block NSString* resolvedCommunityId = nil;

    [self.alertManager requestChannelCommunityIdForChannelName:channelName completion:^(NSString* communityId, NSError* error) {
         if (error) {
             NSLog(@"error in request channel community id: %@", error);
             return;
         }

         resolvedCommunityId = communityId;
     }];

    waitForCondition(resolvedCommunityId != nil, 5.0f);
    NSLog(@"[%@], expected[%@], actual[%@]", channelName, expectedCommunityId, resolvedCommunityId);
    XCTAssert([resolvedCommunityId isEqualToString:expectedCommunityId] == true, @"");
}

@end
