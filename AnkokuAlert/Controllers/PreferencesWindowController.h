//
//  PreferencesWindowController.h
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 7/27/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesWindowController : NSWindowController

@property (nonatomic) NSManagedObjectContext* managedObjectContext;

@property (nonatomic, weak) IBOutlet NSTableView* accountTableView;
@property (nonatomic, weak) IBOutlet NSTextField* emailTextField;
@property (nonatomic, weak) IBOutlet NSSecureTextField* passwordTextField;
@property (nonatomic) NSArray* accountSortDescriptors;
@property (nonatomic) BOOL hasValidEmailAndPassword;
@property (nonatomic) BOOL isAddingAccountInProgress;

+(PreferencesWindowController*)preferenceWindowController;

@end
