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

@interface MainWindowController ()<AlertManagerStreamListener>

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

    [self loginWithDefaultAccount];
}

//-(void)
// #pragma mark - Property Methods
// #pragma mark - [ClassName] Overrides
// #pragma mark - [ProtocolName] Methods
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

@end
