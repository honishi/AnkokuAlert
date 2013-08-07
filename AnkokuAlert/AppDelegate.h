//
//  AppDelegate.h
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 7/22/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject<NSApplicationDelegate>

@property (assign) IBOutlet NSWindow* window;

-(IBAction)showPreferencesWindow:(id)sender;

@end
