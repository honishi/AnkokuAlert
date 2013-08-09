//
//  PreferencesWindowController.m
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 7/27/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "ConfirmationWindowController.h"
#import "AlertManager.h"
#import "SSKeychain.h"
#import "MOAccount.h"

// #define DEBUG_ALLOW_EMPTY_ADD_ACCOUNT
// #define DEBUG_SKIP_CONFIRMATION_WHEN_ACCOUNT_REMOVED

#define DUMMY_USERID    @"12345"
#define DUMMY_USERNAME  @"DUMMY_USER"
#define DUMMY_EMAIL     @"dummy@example.com"
#define DUMMY_PASSWORD  @"dummy_password"

NSString* const kAccountTableViewDraggedType = @"kAccountTableViewDraggedType";

@interface PreferencesWindowController ()<NSTextFieldDelegate>

@property (nonatomic, readwrite) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, readwrite) BOOL addingAccountInProgress;

@property (nonatomic, weak) IBOutlet NSPanel* accountInputPanel;
@property (nonatomic, weak) IBOutlet NSTextField* messageTextField;
@property (nonatomic) ConfirmationWindowController* confirmationWindowController;
@property (nonatomic, weak) IBOutlet NSArrayController* accountArrayController;

@end

@implementation PreferencesWindowController

#pragma mark - Object Lifecycle

+(PreferencesWindowController*)preferenceWindowController
{
    return [[PreferencesWindowController alloc] initWithWindowNibName:@"PreferencesWindowController"];
}

// TODO: delete this.
-(id)initWithWindow:(NSWindow*)window
{
    self = [super initWithWindow:window];

    if (self) {
        // do nothing
    }

    return self;
}

// use windowDidLoad instead of awakeFromNib. http://stackoverflow.com/a/15780876
-(void)windowDidLoad
{
    [super windowDidLoad];

    self.managedObjectContext = [NSManagedObjectContext MR_defaultContext];

    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES];
    self.accountSortDescriptors = @[sortDescriptor];
    [self.accountArrayController setSortDescriptors:self.accountSortDescriptors];

    [self.accountTableView registerForDraggedTypes:@[kAccountTableViewDraggedType]];
    [self.accountTableView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];

    if (!MOAccount.hasAccounts) {
        double delayInSeconds = 0.5f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                [self inputAccount:self];
            });
    }
}

// #pragma mark - Property Methods
// #pragma mark - [ClassName] Overrides
// #pragma mark - [ProtocolName] Methods

#pragma mark NSTableViewDataSource Methods

#pragma mark Drag & Drop Reordering Support

-(BOOL)tableView:(NSTableView*)tableView writeRowsWithIndexes:(NSIndexSet*)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    // LOG(@"fromIndex: %ld", rowIndexes.firstIndex);

    NSString* fromIndex = [NSNumber numberWithInteger:rowIndexes.firstIndex].stringValue;
    [pboard declareTypes:@[kAccountTableViewDraggedType] owner:self];
    [pboard setString:fromIndex forType:kAccountTableViewDraggedType];

    return YES;
}

-(NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    return NSDragOperationMove;
}

-(BOOL)tableView:(NSTableView*)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
    NSPasteboard* pboard = info.draggingPasteboard;
    NSInteger fromIndex = [pboard stringForType:kAccountTableViewDraggedType].integerValue;
    NSInteger toIndex = row;
    // LOG(@"fromIndex: %ld, toIndex: %ld", fromIndex, toIndex);

    MOAccount* fromAccount = self.accountArrayController.arrangedObjects[fromIndex];
    MOAccount* toAccount = self.accountArrayController.arrangedObjects[toIndex];

    NSNumber* anOrder = fromAccount.order;
    fromAccount.order = toAccount.order;
    toAccount.order = anOrder;
    [self.accountArrayController rearrangeObjects];

    [self.managedObjectContext MR_saveOnlySelfAndWait];

    return YES;
}

// #pragma mark - Public Interface

#pragma mark - Internal Methods, Action

#pragma mark Add Account (Utility)

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
    self.emailTextField.stringValue = @"";
    self.passwordTextField.stringValue = @"";
    [self validateEmailAndPassword];
    [self.emailTextField becomeFirstResponder];
    [NSApp beginSheet:self.accountInputPanel modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
}

-(void)endAccountInputSheet
{
    [NSApp endSheet:self.accountInputPanel];
    [self.accountInputPanel orderOut:self];
}

-(void)validateEmailAndPassword
{
    BOOL hasValidEmail = NO;
    NSString* email = self.emailTextField.stringValue;
    NSError* error = nil;
    NSRegularExpression* emailRegexp = [NSRegularExpression regularExpressionWithPattern:@".+@.+\\..+" options:0 error:&error];

    if ([emailRegexp numberOfMatchesInString:email options:0 range:NSMakeRange(0, email.length)]) {
        hasValidEmail = YES;
    }

    if (hasValidEmail && 0 < self.passwordTextField.stringValue.length) {
        self.hasValidEmailAndPassword = YES;
    } else {
        self.hasValidEmailAndPassword = NO;
    }
}

-(void)controlTextDidChange:(NSNotification*)obj
{
    [self validateEmailAndPassword];
}

#pragma mark Add Account (Main)

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
             LOG(@"login error.");
             [self beginAccountInputSheetWithMessage:@"Login failed. Please try again..."];
         } else {
#endif
         LOG(@"login completed: %@", alertStatus);

         BOOL isDefault = MOAccount.hasAccounts ? NO : YES;

         MOAccount* account = [MOAccount accountWithNumberedOrderAttribute];
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

         [self.accountArrayController addObject:account];
         [self.managedObjectContext MR_saveOnlySelfAndWait];

         [self.accountTableView scrollRowToVisible:(self.accountTableView.numberOfRows-1)];
#ifndef DEBUG_ALLOW_EMPTY_ADD_ACCOUNT
     }
#endif
     }];
}

#pragma mark Remove Account

-(IBAction)confirmAccountRemoval:(id)sender
{
#ifndef DEBUG_SKIP_CONFIRMATION_WHEN_ACCOUNT_REMOVED
    self.confirmationWindowController = [ConfirmationWindowController confirmationWindowControllerWithMessage:@"Are you really sure to remove selected account(s)?" completion:^
                                             (BOOL isCancelled) {
                                             [NSApp endSheet:self.confirmationWindowController.window];
                                             [self.confirmationWindowController.window orderOut:self];
                                             if (!isCancelled) {
                                                 [self removeAccount];
                                             }
                                         }];
    self.confirmationWindowController.titleOfOkButton = @"Remove";
    [NSApp beginSheet:self.confirmationWindowController.window modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
#else
    [self removeAccount];
#endif
}

-(void)removeAccount
{
    [self.accountArrayController removeObjectsAtArrangedObjectIndexes:self.accountArrayController.selectionIndexes];
    [self.managedObjectContext MR_saveOnlySelfAndWait];
}

#pragma mark Change Default Account

-(IBAction)changeDefaultAccount:(id)sender
{
    NSUInteger selectedRow = [self.accountTableView rowForView:sender];

    for (MOAccount* account in self.accountArrayController.arrangedObjects) {
        account.isDefault = [NSNumber numberWithBool:NO];
    }

    MOAccount* account = self.accountArrayController.arrangedObjects[selectedRow];
    account.isDefault = [NSNumber numberWithBool:YES];

    [self.managedObjectContext MR_saveOnlySelfAndWait];
}

@end
