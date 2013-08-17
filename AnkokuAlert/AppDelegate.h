//
//  AppDelegate.h
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 7/22/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MainWindowController;

@interface AppDelegate : NSObject<NSApplicationDelegate>

@property (nonatomic, weak) IBOutlet NSWindow* window;
@property (nonatomic) MainWindowController* mainWindowController;

-(IBAction)showPreferencesWindow:(id)sender;

@end
