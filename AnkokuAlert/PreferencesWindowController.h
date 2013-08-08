//
//  PreferencesWindowController.h
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 7/27/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesWindowController : NSWindowController

@property (nonatomic, readonly) NSManagedObjectContext* managedObjectContext;
//@property (nonatomic) NSArray* accountSortDescriptors;
@property (nonatomic, readonly, getter = isAddingAccountInProgress) BOOL addingAccountInProgress;

@property (nonatomic, weak) IBOutlet NSTableView* accountTableView;
@property (nonatomic, weak) IBOutlet NSTextField* emailTextField;
@property (nonatomic, weak) IBOutlet NSSecureTextField* passwordTextField;
@property (nonatomic) BOOL hasValidEmailAndPassword;

+(PreferencesWindowController*)preferenceWindowController;

@end
