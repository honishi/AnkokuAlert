//
//  MainWindowController.h
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 7/27/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MainWindowController : NSWindowController

@property (nonatomic) NSManagedObjectContext* managedObjectContext;
@property (nonatomic) NSString* windowTitle;
@property (nonatomic) NSPredicate* accountFilterPredicate;
@property (nonatomic) NSString* communityInputMessage;
@property (nonatomic) BOOL hasValidCommunityInput;
@property (nonatomic) NSNumber* liveLevel;
@property (nonatomic) BOOL isStreamOpened;

@property (nonatomic, weak) IBOutlet NSArrayController* communityArrayController;

-(IBAction)startAlert:(id)sender;
-(IBAction)stopAlert:(id)sender;
-(IBAction)inputCommunity:(id)sender;
-(IBAction)confirmCommunityRemoval:(id)sender;
-(IBAction)showImportCommunityWindow:(id)sender;
-(IBAction)showPreferences:(id)sender;

-(NSString*)firstMatchStringWithRegexpPattern:(NSString*)regexpPattern inString:(NSString*)inString;

@end
