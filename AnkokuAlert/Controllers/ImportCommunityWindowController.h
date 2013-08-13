//
//  ImportCommunityWindowController.h
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 8/8/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString* const kImportCommunityKeyOrder;
extern NSString* const kImportCommunityKeyCommunityId;
extern NSString* const kImportCommunityKeyCommunityName;
extern NSString* const kImportCommunityKeyIsExcluding;
extern NSString* const kImportCommunityKeyShouldImport;
extern NSString* const kImportCommunityKeyIsCommunityNameUpdated;

typedef void (^ ImportCommunityCompletionBlock)(BOOL isCancelled, NSArray* communities);

@interface ImportCommunityWindowController : NSWindowController

@property (weak) IBOutlet NSTableView* communityTableView;
@property (nonatomic) BOOL isAllCommunityNameUpdated;

+(ImportCommunityWindowController*)importCommunityWindowControllerWithEmail:(NSString*)email
                                                                   password:(NSString*)password
                                                       communitiesExcluding:(NSArray*)communitiesExcluding
                                                                 completion:(ImportCommunityCompletionBlock)completion;

@end
