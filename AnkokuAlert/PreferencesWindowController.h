//
//  PreferencesWindowController.h
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 7/27/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString* const kUserDefaultsAccounts;
extern NSString* const kUserDefaultsAccountsEmail;
extern NSString* const kUserDefaultsAccountsUsername;
extern NSString* const kUserDefaultsAccountsIsDefault;

@interface PreferencesWindowController : NSWindowController

+(PreferencesWindowController*)sharedController;
-(NSDictionary*)defaultAccount;

@end
