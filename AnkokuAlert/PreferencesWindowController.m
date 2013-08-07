//
//  PreferencesWindowController.m
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 7/27/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "AlertManager.h"
#import "SSKeychain.h"
#import "MOAccount.h"

// #define DEBUG_ALLOW_EMPTY_ADD_ACCOUNT

#define DUMMY_USERID    @"12345"
#define DUMMY_USERNAME  @"DUMMY_USER"
#define DUMMY_EMAIL     @"dummy@example.com"
#define DUMMY_PASSWORD  @"dummy_password"

@interface PreferencesWindowController ()

@property (nonatomic, readwrite) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, readwrite) BOOL addingAccountInProgress;

@property (nonatomic, weak) IBOutlet NSTableView* accountTableView;
@property (nonatomic, weak) IBOutlet NSPanel* accountInputSheet;
@property (weak) IBOutlet NSTextField* messageTextField;
@property (weak) IBOutlet NSTextField* emailTextField;
@property (weak) IBOutlet NSSecureTextField* passwordTextField;
@property (weak) IBOutlet NSButton* loginButton;

@property (weak) IBOutlet NSArrayController* accountsArrayController;

@end

@implementation PreferencesWindowController

#pragma mark - Object Lifecycle

+(PreferencesWindowController*)sharedController
{
    static PreferencesWindowController* sharedController;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
            sharedController = [[PreferencesWindowController alloc] initWithWindowNibName:@"PreferencesWindowController"];
        });
    return sharedController;
}

-(id)initWithWindow:(NSWindow*)window
{
    // TODO: delete later
    //NSAssert(NO, @"this method should not be called");

    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }

    return self;
}

-(void)awakeFromNib
{
}

-(void)windowDidLoad
{
    [super windowDidLoad];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    self.managedObjectContext = [NSManagedObjectContext MR_defaultContext];

    if (![MOAccount findAll].count) {
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                [self inputAccount:self];
            });
    }
}

// #pragma mark - Property Methods
// #pragma mark - [ClassName] Overrides
// #pragma mark - [ProtocolName] Methods

#pragma mark - Public Interface

-(NSDictionary*)defaultAccount
{
//    NSArray* accounts = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsAccounts];
//
//    for (NSDictionary* account in accounts) {
//        if ([account[kUserDefaultsAccountsIsDefault] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
//            return account;
//        }
//    }
//
    return nil;
}

#pragma mark - Internal Methods

#pragma mark - Action

#pragma mark Add/Remove Account

-(IBAction)inputAccount:(id)sender
{
    [self beginAccountInputSheetWithMessage:@"Please enter your email address and password."];
}

-(IBAction)cancelInputAccount:(id)sender
{
    [self endAccountInputSheet];
}

-(void)beginAccountInputSheetWithMessage:(NSString*)message
{
    self.messageTextField.stringValue = message;
    [NSApp beginSheet:self.accountInputSheet modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
}

-(void)endAccountInputSheet
{
    [NSApp endSheet:self.accountInputSheet];
    [self.accountInputSheet orderOut:self];
}

-(IBAction)addAccount:(id)sender
{
    NSString* email = self.emailTextField.stringValue;
    NSString* password = self.passwordTextField.stringValue;

    [self endAccountInputSheet];
    self.addingAccountInProgress = YES;

    [[AlertManager sharedManager] loginWithEmail:email password:password completion:^
         (NSDictionary* alertStatus, NSError* error) {
         self.addingAccountInProgress = NO;
#ifndef DEBUG_ALLOW_EMPTY_ADD_ACCOUNT
         if (error) {
             NSLog(@"login error.");
             [self beginAccountInputSheetWithMessage:@"Login failed. Please try again..."];
         } else {
#endif
         NSLog(@"login completed: %@", alertStatus);

         BOOL isDefault = [MOAccount findAll].count ? NO : YES;

         MOAccount* account = [MOAccount MR_createEntity];
#ifndef DEBUG_ALLOW_EMPTY_ADD_ACCOUNT
         account.userId = alertStatus[AlertManagerAlertStatusKeyUserId];
         account.userName = alertStatus[AlertManagerAlertStatusKeyUserName];
         account.email = email;
#else
         account.userId = DUMMY_USERID;
         account.userName = DUMMY_USERNAME;
         account.email = DUMMY_EMAIL;
#endif
         account.isDefault = [NSNumber numberWithBool:isDefault];
         [SSKeychain setPassword:password forService:[[NSBundle mainBundle] bundleIdentifier] account:email];

         [self.accountsArrayController addObject:account];
         [self.managedObjectContext MR_saveOnlySelfAndWait];

         [self.accountTableView scrollRowToVisible:(self.accountTableView.numberOfRows-1)];
#ifndef DEBUG_ALLOW_EMPTY_ADD_ACCOUNT
     }
#endif
     }];
}

-(IBAction)removeAccount:(id)sender
{
    [self.accountsArrayController removeObjectsAtArrangedObjectIndexes:self.accountsArrayController.selectionIndexes];
    [self.managedObjectContext MR_saveOnlySelfAndWait];
}

-(IBAction)changeDefaultAccount:(id)sender
{
    NSUInteger defaultRow = [self.accountTableView rowForView:sender];

    NSUInteger index = 0;
    for (MOAccount* account in self.accountsArrayController.arrangedObjects) {
        account.isDefault = [NSNumber numberWithBool:(index == defaultRow ? YES : NO)];
        index++;
    }

    [self.managedObjectContext MR_saveOnlySelfAndWait];
}

@end
