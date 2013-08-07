//
//  AppDelegate.m
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 7/22/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import "AppDelegate.h"
#import "PreferencesWindowController.h"
#import "MainWindowController.h"

@interface AppDelegate ()

@property (nonatomic, strong) MainWindowController* mainWindowController;

@end
@implementation AppDelegate

-(void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
    // Insert code here to initialize your application
    [MagicalRecord setupCoreDataStack];
    // LOG(@"%@", [MagicalRecord currentStack]);

    self.mainWindowController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindowController"];
    [self.mainWindowController showWindow:self];
    [self.mainWindowController.window makeKeyAndOrderFront:self];
}

-(void)applicationWillTerminate:(NSNotification*)notification
{
    [MagicalRecord cleanUp];
}

#pragma mark - Action

-(IBAction)showPreferencesWindow:(id)sender
{
    [[PreferencesWindowController sharedController] showWindow:nil];
}

@end
