//
//  PreferencesWindowController.m
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 7/27/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import "PreferencesWindowController.h"

@interface PreferencesWindowController () <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, weak) IBOutlet NSTableView *accountTableView;
@property (nonatomic, weak) IBOutlet NSButton *addAccountButton;
@property (nonatomic, weak) IBOutlet NSButton *editAccountButton;
@property (nonatomic, weak) IBOutlet NSButton *defaultAccountButton;
@property (nonatomic, weak) IBOutlet NSButton *removeAccountButton;
@property (nonatomic, weak) IBOutlet NSPanel *accountInputSheet;

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

- (id)initWithWindow:(NSWindow *)window
{
    // TODO: delete later
    //NSAssert(NO, @"this method should not be called");
    
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

#pragma mark - Account

#pragma mark tableview datasource

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return 3;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if ([tableColumn.identifier isEqualToString:@"NoColumn"]) {
        return @"no";
    }
    
    return nil;
}

#pragma mark - Action

- (IBAction)beginAddAccount:(id)sender
{
    [NSApp beginSheet:self.accountInputSheet modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (IBAction)cancelAddAccount:(id)sender
{
    [NSApp endSheet:self.accountInputSheet];
    [self.accountInputSheet orderOut:sender];
}

@end
