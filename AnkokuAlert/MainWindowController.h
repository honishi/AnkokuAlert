//
//  MainWindowController.h
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 7/27/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MainWindowController : NSWindowController

@property (nonatomic, readonly) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, readonly) NSPredicate* accountFilterPredicate;

@property (nonatomic) NSNumber* livePerSecond;
@property (nonatomic) BOOL isStreamOpened;

@end
