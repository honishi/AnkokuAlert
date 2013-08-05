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

NSString* const kUserDefaultsAccounts = @"Accounts";
NSString* const kUserDefaultsAccountsEmail = @"Email";
NSString* const kUserDefaultsAccountsUsername = @"Username";
NSString* const kUserDefaultsAccountsIsDefault = @"IsDefault";

@interface PreferencesWindowController ()

@property (nonatomic, weak) IBOutlet NSTableView* accountTableView;
@property (nonatomic, weak) IBOutlet NSButton* addAccountButton;
@property (nonatomic, weak) IBOutlet NSButton* editAccountButton;
@property (nonatomic, weak) IBOutlet NSButton* defaultAccountButton;
@property (nonatomic, weak) IBOutlet NSButton* removeAccountButton;

@property (nonatomic, weak) IBOutlet NSPanel* accountInputSheet;
@property (weak) IBOutlet NSTextField* emailTextField;
@property (weak) IBOutlet NSSecureTextField* passwordTextField;
@property (weak) IBOutlet NSButton* loginButton;
@property (weak) IBOutlet NSProgressIndicator* loginProgressIndicator;

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
//    // test code for user defaults
//    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//    NSArray* accounts = @[
//                          @{kUserDefaultsAccountsUsername:@"kato", kUserDefaultsAccountsIsDefault:[NSNumber numberWithBool:NO]},
//                          @{kUserDefaultsAccountsUsername:@"tanaka", kUserDefaultsAccountsIsDefault:[NSNumber numberWithBool:YES]},
//                          @{kUserDefaultsAccountsUsername:@"sato", kUserDefaultsAccountsIsDefault:[NSNumber numberWithBool:NO]}
//                          ];
//    [defaults setObject:accounts forKey:@"Accounts"];
//    [defaults synchronize];
}

-(void)windowDidLoad
{
    [super windowDidLoad];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

// #pragma mark - Property Methods
// #pragma mark - [ClassName] Overrides
// #pragma mark - [ProtocolName] Methods

#pragma mark - Public Interface

-(NSDictionary*)defaultAccount
{
    NSArray* accounts = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsAccounts];

    for (NSDictionary* account in accounts) {
        if ([account[kUserDefaultsAccountsIsDefault] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
            return account;
        }
    }

    return nil;
}

#pragma mark - Internal Methods

#pragma mark - Action

-(IBAction)beginAddAccount:(id)sender
{
    [NSApp beginSheet:self.accountInputSheet modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
}

#pragma mark Add Account

-(IBAction)cancelAddAccount:(id)sender
{
    [NSApp endSheet:self.accountInputSheet];
    [self.accountInputSheet orderOut:sender];
}

-(IBAction)loginUsingAccount:(id)sender
{
    [self.loginProgressIndicator startAnimation:self];

    NSString* email = self.emailTextField.stringValue;
    NSString* password = self.passwordTextField.stringValue;

    [[AlertManager sharedManager] loginWithEmail:email password:password completion:^
         (NSDictionary* alertStatus, NSError* error) {
         // [self.loginProgressIndicator setHidden:YES];
         [self.loginProgressIndicator stopAnimation:self];
         if (error) {
             NSLog(@"login error.");
         } else {
             NSLog(@"login completed: %@", alertStatus);

             [NSApp endSheet:self.accountInputSheet];
             [self.accountInputSheet orderOut:self];

             BOOL isDefault = ((NSArray*)self.accountsArrayController.arrangedObjects).count ? YES : NO;
             NSDictionary* newAccount = @{kUserDefaultsAccountsEmail:email,
                                          kUserDefaultsAccountsUsername:alertStatus[AlertManagerAlertStatusUserNameKey],
                                          kUserDefaultsAccountsIsDefault:[NSNumber numberWithBool:isDefault]};
             [self.accountsArrayController addObject:newAccount];

             [SSKeychain setPassword:password forService:[[NSBundle mainBundle] bundleIdentifier] account:email];
         }
     }];
}

-(IBAction)setDefaultAccount:(id)sender
{
    // http://stackoverflow.com/a/5807971
    NSIndexSet* indexSet = self.accountsArrayController.selectionIndexes;

    NSUInteger selectedIndex = self.accountsArrayController.selectionIndex;
    NSDictionary* selectedAccount = self.accountsArrayController.arrangedObjects[selectedIndex];
    NSString* selectedUsername = selectedAccount[kUserDefaultsAccountsUsername];

    NSUInteger index = 0;
    for (NSDictionary* account in self.accountsArrayController.arrangedObjects) {
        NSMutableDictionary* newAccount = account.mutableCopy;
        if ([account[kUserDefaultsAccountsUsername] isEqualToString:selectedUsername]) {
            newAccount[kUserDefaultsAccountsIsDefault] = [NSNumber numberWithBool:YES];
        } else {
            newAccount[kUserDefaultsAccountsIsDefault] = [NSNumber numberWithBool:NO];
        }
        [self.accountsArrayController removeObjectAtArrangedObjectIndex:index];
        [self.accountsArrayController insertObject:newAccount atArrangedObjectIndex:index];
        index++;
    }

    [self.accountsArrayController setSelectionIndexes:indexSet];
}

-(IBAction)removeAccount:(id)sender
{
    [self.accountsArrayController removeObjectAtArrangedObjectIndex:self.accountsArrayController.selectionIndex];
}

@end
