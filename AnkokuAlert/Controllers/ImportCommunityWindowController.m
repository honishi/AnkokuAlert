//
//  ImportCommunityWindowController.m
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 8/8/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import "ImportCommunityWindowController.h"
#import "AlertManager.h"

NSString* const kImportCommunityKeyOrder = @"order";
NSString* const kImportCommunityKeyCommunityId = @"communityId";
NSString* const kImportCommunityKeyCommunityName = @"communityName";
NSString* const kImportCommunityKeyIsExcluding = @"isExcluding";
NSString* const kImportCommunityKeyShouldImport = @"shouldImport";
NSString* const kImportCommunityKeyIsCommunityNameUpdated = @"isCommunityNameUpdated";

NSUInteger const kMaxRequestCommunityInfoConcurrency = 20;

#pragma mark - Value Transformer

@interface ExcludingFontColorValueTransformer : NSValueTransformer {}
@end

@implementation ExcludingFontColorValueTransformer

+(Class)transformedValueClass
{
    return [NSColor class];
}

+(BOOL)allowsReverseTransformation
{
    return NO;
}

-(id)transformedValue:(id)value
{
    BOOL isExcluding = ((NSNumber*)value).boolValue;
    return (isExcluding ? [NSColor disabledControlTextColor] : [NSColor textColor]);
}

@end

#pragma mark - Community Info Request Block Operation

@interface CommunityInfoRequestBlockOperation : NSBlockOperation

@property (nonatomic) BOOL isConcurrent;
@property (nonatomic) BOOL isExecuting;
@property (nonatomic) BOOL isFinished;
@property (nonatomic) NSMutableDictionary* community;
@property (nonatomic, copy) void (^ completion)();

-(void)start;

@end

@implementation CommunityInfoRequestBlockOperation

+(CommunityInfoRequestBlockOperation*)operationWithCommunity:(NSMutableDictionary*)community completion:(void (^)())completion
{
    CommunityInfoRequestBlockOperation* communityInfoRequestBlockOperation = CommunityInfoRequestBlockOperation.new;

    if (communityInfoRequestBlockOperation != nil) {
        communityInfoRequestBlockOperation.isConcurrent = YES;
        communityInfoRequestBlockOperation.community = community;
        communityInfoRequestBlockOperation.completion = completion;
    }

    return communityInfoRequestBlockOperation;
}

-(void)start
{
    // need to manually write these; http://stackoverflow.com/a/4755536
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];

    self.isExecuting = YES;
    self.isFinished = NO;

    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];

    [[AlertManager sharedManager] requestCommunityInfoForCommunity:self.community[kImportCommunityKeyCommunityId]
                                                        completion:^(NSDictionary* communityInfo, NSError* error) {
         if (!error) {
             self.community[kImportCommunityKeyCommunityName] = communityInfo[AlertManagerCommunityInfoKeyCommunityName];
         } else {
             self.community[kImportCommunityKeyCommunityName] = @"(request failed.)";
         }
         self.community[kImportCommunityKeyIsCommunityNameUpdated] = [NSNumber numberWithBool:YES];

         if (self.completion) {
             self.completion();
             self.completion = nil;
         }

         [self willChangeValueForKey:@"isExecuting"];
         [self willChangeValueForKey:@"isFinished"];

         self.isExecuting = NO;
         self.isFinished = YES;

         [self didChangeValueForKey:@"isExecuting"];
         [self didChangeValueForKey:@"isFinished"];
     }];
}

@end

#pragma mark - Import Window Controller

@interface ImportCommunityWindowController ()<NSWindowDelegate>

@property (nonatomic, copy) NSString* email;
@property (nonatomic, copy) NSString* password;
@property (nonatomic, copy) NSArray* communitiesExcluding;
@property (nonatomic, copy) ImportCommunityCompletionBlock completion;

@property (nonatomic, weak) IBOutlet NSArrayController* communityArrayController;
@property (nonatomic) NSOperationQueue* fetchCommunityNameOperationQueue;

@end

@implementation ImportCommunityWindowController

#pragma mark - Object Lifecycle

+(ImportCommunityWindowController*)importCommunityWindowControllerWithEmail:(NSString*)email password:(NSString*)password communitiesExcluding:(NSArray*)communitiesExcluding completion:(ImportCommunityCompletionBlock)completion
{
    ImportCommunityWindowController* importCommunityWindowController = [[ImportCommunityWindowController alloc] initWithWindowNibName:@"ImportCommunityWindowController"];

    if (importCommunityWindowController) {
        importCommunityWindowController.fetchCommunityNameOperationQueue = NSOperationQueue.new;
        importCommunityWindowController.fetchCommunityNameOperationQueue.maxConcurrentOperationCount = kMaxRequestCommunityInfoConcurrency;
        importCommunityWindowController.email = email;
        importCommunityWindowController.password = password;
        importCommunityWindowController.communitiesExcluding = communitiesExcluding;
        importCommunityWindowController.completion = completion;
    }

    return importCommunityWindowController;
}

-(void)windowDidLoad
{
    [super windowDidLoad];

    [[AlertManager sharedManager] loginWithEmail:self.email password:self.password completion:^(NSDictionary* alertStatus, NSError* error) {
         if (alertStatus) {
             NSUInteger order = 1;
             for (NSString* communityId in alertStatus[AlertManagerAlertStatusKeyCommunities]) {
                 NSMutableDictionary* community = NSMutableDictionary.new;
                 community[kImportCommunityKeyOrder] = [NSNumber numberWithInteger:order++];
                 community[kImportCommunityKeyCommunityId] = communityId;
                 community[kImportCommunityKeyCommunityName] = @"n/a";
                 community[kImportCommunityKeyIsCommunityNameUpdated] = [NSNumber numberWithBool:NO];
                 for (NSString* excludingCommunityId in self.communitiesExcluding) {
                     if ([communityId isEqualToString:excludingCommunityId]) {
                         community[kImportCommunityKeyIsExcluding] = [NSNumber numberWithBool:YES];
                         break;
                     }
                 }
                 BOOL shouldImport = ((NSNumber*)community[kImportCommunityKeyIsExcluding]).boolValue ? NO : YES;
                 community[kImportCommunityKeyShouldImport] = [NSNumber numberWithBool:shouldImport];
                 [self.communityArrayController addObject:community];
             }
             // LOG(@"%@", self.communityArrayController.arrangedObjects);
             [self updateCommunityName];
         }
     }];
}

// #pragma mark - Property Methods
// #pragma mark - [ClassName] Overrides
// #pragma mark - NSWindowDelegate Methods
// #pragma mark - Public Interface

#pragma mark - Internal Methods

#pragma mark Utility

-(void)updateCommunityName
{
    for (NSMutableDictionary* community in self.communityArrayController.arrangedObjects) {
        CommunityInfoRequestBlockOperation* operation =
            [CommunityInfoRequestBlockOperation operationWithCommunity:community completion:^() {
                 BOOL updateInProgress = NO;
                 for (NSDictionary* community in self.communityArrayController.arrangedObjects) {
                     if (((NSNumber*)community[kImportCommunityKeyIsCommunityNameUpdated]).boolValue == NO) {
                         updateInProgress = YES;
                         break;
                     }
                 }

                 if (!updateInProgress) {
                     self.isAllCommunityNameUpdated = YES;
                 }
             }];
        [self.fetchCommunityNameOperationQueue addOperation:operation];
    }
}

#pragma mark Button Actions

-(IBAction)importCommunity:(id)sender
{
    [self.fetchCommunityNameOperationQueue cancelAllOperations];

    if (self.completion) {
        NSMutableArray* communities = NSMutableArray.new;
        for (NSDictionary* community in self.communityArrayController.arrangedObjects) {
            if (((NSNumber*)community[kImportCommunityKeyShouldImport]).boolValue) {
                [communities addObject:community];
            }
        }

        self.completion(NO, communities.copy);
        self.completion = nil;
    }
}

-(IBAction)cancelImportCommunity:(id)sender
{
    [self.fetchCommunityNameOperationQueue cancelAllOperations];

    if (self.completion) {
        self.completion(YES, nil);
        self.completion = nil;
    }
}

#pragma mark Actions in Community Table View

-(void)setShouldImportForAllCommunities:(BOOL)flag
{
    for (NSMutableDictionary* community in self.communityArrayController.arrangedObjects) {
        if (((NSNumber*)community[kImportCommunityKeyIsExcluding]).boolValue) {
            continue;
        }
        community[kImportCommunityKeyShouldImport] = [NSNumber numberWithBool:flag];
    }
}

-(IBAction)checkAllCommunities:(id)sender
{
    [self setShouldImportForAllCommunities:YES];
}

-(IBAction)uncheckAllCommunities:(id)sender
{
    [self setShouldImportForAllCommunities:NO];
}

@end
