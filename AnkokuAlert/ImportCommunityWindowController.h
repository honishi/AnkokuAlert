//
//  ImportCommunityWindowController.h
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 8/8/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void (^ ImportCommunityCompletionBlock)(BOOL isCancelled, NSArray* communities);

@interface ImportCommunityWindowController : NSWindowController

@property (weak) IBOutlet NSTableView* communityTableView;

+(ImportCommunityWindowController*)importCommunityWindowControllerWithEmail:(NSString*)email
                                                                   password:(NSString*)password
                                                                 completion:(ImportCommunityCompletionBlock)completion;

@end
