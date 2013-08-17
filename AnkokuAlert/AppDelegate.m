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

@end

@implementation AppDelegate

-(void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
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

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender
{
    return YES;
}

#pragma mark - Public Methods, Menu Actions

-(IBAction)startAlert:(id)sender
{
    [self.mainWindowController startAlert:self];
}

-(IBAction)stopAlert:(id)sender
{
    [self.mainWindowController stopAlert:self];
}

-(IBAction)addCommunity:(id)sender
{
    [self.mainWindowController inputCommunity:self];
}

-(IBAction)removeCommunity:(id)sender
{
    [self.mainWindowController confirmCommunityRemoval:self];
}

-(IBAction)importCommunity:(id)sender
{
    [self.mainWindowController showImportCommunityWindow:self];
}

-(IBAction)showPreferencesWindow:(id)sender
{
    [self.mainWindowController showPreferences:self];
}

@end
