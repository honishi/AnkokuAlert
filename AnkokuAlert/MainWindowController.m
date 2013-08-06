//
//  MainWindowController.m
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 7/27/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import "MainWindowController.h"
#import "PreferencesWindowController.h"
#import "AlertManager.h"
#import "SSKeychain.h"
#import "MOCommunity.h"

float const kLiveCounterTimerInterval = 0.5f;

#pragma mark - Value Transformer

@interface LivePerSecondValueTransformer : NSValueTransformer {}
@end

@implementation LivePerSecondValueTransformer

+(Class)transformedValueClass
{
    return [NSString class];
}

+(BOOL)allowsReverseTransformation
{
    return NO;
}

-(id)transformedValue:(id)value
{
    NSNumber* rate = value;
    return (rate == nil) ? nil : [NSString stringWithFormat:@"%.1f", rate.doubleValue];
}

@end

#pragma mark - Main Window Controller

@interface MainWindowController ()<AlertManagerStreamListener>

// NSTextVIew doesn't support weak reference in arc.
@property (strong) IBOutlet NSTextView* logTextView;
@property (weak) IBOutlet NSScrollView* logScrollView;
@property (weak) IBOutlet NSLevelIndicatorCell* liveLevelIndicatorCell;
@property (weak) IBOutlet NSTextFieldCell* liveTextFieldCell;

@property (nonatomic) NSUInteger previousReceivedLiveCount;
@property (nonatomic) NSUInteger receivedLiveCount;

@property (unsafe_unretained) IBOutlet NSPanel* communityInputSheet;

@end

@implementation MainWindowController

#pragma mark - Object Lifecycle

-(id)initWithWindow:(NSWindow*)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }

    return self;
}

-(void)windowDidLoad
{
    [super windowDidLoad];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [NSTimer scheduledTimerWithTimeInterval:kLiveCounterTimerInterval target:self selector:@selector(liveCounterTimerFired:) userInfo:nil repeats:YES];
}

//-(void)
// #pragma mark - Property Methods
// #pragma mark - [ClassName] Overrides

#pragma mark - AlertManagerStreamListener Methods

-(void)alertManager:(AlertManager*)alertManager didReceiveLive:(NSString*)live community:(NSString*)community user:(NSString*)user
{
    // NSString* message = [NSString stringWithFormat:@"live:%@, co:%@, user:%@\n", live, community, user];
    // [self logMessage:message];

    [[AlertManager sharedManager] streamInfoForLive:live completion:^(NSDictionary* streamInfo, NSError* error) {
         NSString* info = [NSString stringWithFormat:@"community:%@, title:%@\n", streamInfo[AlertManagerStreamInfoKeyCommunityName], streamInfo[AlertManagerStreamInfoKeyLiveTitle]];
         [self logMessage:info];
     }];

    [[AlertManager sharedManager] communityInfoForCommunity:community completion:^(NSDictionary* communityInfo, NSError* error) {
         LOG(@"communityInfo: %@", communityInfo[AlertManagerCommunityInfoKeyCommunityName]);
     }];

    self.receivedLiveCount++;
}

-(void)alertManagerDidCloseStream:(AlertManager*)alertManager
{
    LOG(@"stream closed.");
    self.isStreamOpened = NO;
}

// #pragma mark - Public Interface

#pragma mark - Internal Methods

-(void)loginWithDefaultAccount
{
    NSDictionary* account = [PreferencesWindowController sharedController].defaultAccount;
    if (account) {
        NSString* email = account[kUserDefaultsAccountsEmail];
        NSString* password = [SSKeychain passwordForService:[[NSBundle mainBundle] bundleIdentifier] account:email];
        [[AlertManager sharedManager] loginWithEmail:email password:password completion:^(NSDictionary* alertStatus, NSError* error) {
             if (!error) {
                 [[AlertManager sharedManager] openStreamWithAlertStatus:alertStatus streamListener:self];
             }
         }];
    }
}

#pragma mark Log View

-(void)logMessage:(NSString*)message
{
    BOOL shouldScrollToBottom = NO;
    NSAttributedString* attributedMessage = [[NSAttributedString alloc] initWithString:message];

    if (self.logScrollView.verticalScroller.floatValue == 1.0f) {
        shouldScrollToBottom = YES;
    }

    [self.logTextView.textStorage appendAttributedString:attributedMessage];
    [self.logScrollView flashScrollers];

    if (shouldScrollToBottom) {
        [self.logTextView scrollToEndOfDocument:self];
    }
}

#pragma mark Live Level Indicator

-(void)liveCounterTimerFired:(NSTimer*)timer
{
    self.livePerSecond = [NSNumber numberWithDouble:(self.receivedLiveCount-self.previousReceivedLiveCount)/kLiveCounterTimerInterval];
    self.previousReceivedLiveCount = self.receivedLiveCount;
}

#pragma mark - Button Actions

#pragma mark Start/Stop Stream

-(IBAction)startAlert:(id)sender
{
    [self loginWithDefaultAccount];
    self.isStreamOpened = YES;
}

-(IBAction)stopAlert:(id)sender
{
    [[AlertManager sharedManager] closeStream];
}

#pragma mark Add/Remove Community

-(IBAction)inputCommunity:(id)sender
{
    [NSApp beginSheet:self.communityInputSheet modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
}

-(IBAction)cancelInputCommunity:(id)sender
{
    [NSApp endSheet:self.communityInputSheet];
    [self.communityInputSheet orderOut:sender];
}

-(IBAction)addCommunity:(id)sender
{
    [NSApp endSheet:self.communityInputSheet];
    [self.communityInputSheet orderOut:sender];

    NSManagedObjectContext* context = [NSManagedObjectContext MR_defaultContext];

    MOCommunity* community = [MOCommunity MR_createEntity];
    community.community = @"co12345";
    community.communityName = @"テストです.";

    [context MR_saveOnlySelfAndWait];
}

-(IBAction)removeCommunity:(id)sender
{
}

#pragma mark Actions in Community Table View

-(IBAction)enableCommunityButtonClicked:(id)sender
{
    LOG(@"aaa:%@", sender);

}

@end
