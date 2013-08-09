//
//  ImportCommunityWindowController.m
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 8/8/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import "ImportCommunityWindowController.h"
#import "AlertManager.h"

@interface ImportCommunityWindowController ()<NSWindowDelegate>

@property (nonatomic, copy) NSString* email;
@property (nonatomic, copy) NSString* password;
@property (nonatomic, copy) ImportCommunityCompletionBlock completion;

@property (nonatomic, weak) IBOutlet NSArrayController* communityArrayController;
@property (nonatomic) NSOperationQueue* fetchCommunityNameOperationQueue;

@end

@implementation ImportCommunityWindowController

#pragma mark - Object Lifecycle

+(ImportCommunityWindowController*)importCommunityWindowControllerWithEmail:(NSString*)email password:(NSString*)password completion:(ImportCommunityCompletionBlock)completion
{
    ImportCommunityWindowController* importCommunityWindowController = [[ImportCommunityWindowController alloc] initWithWindowNibName:@"ImportCommunityWindowController"];

    if (importCommunityWindowController) {
        importCommunityWindowController.fetchCommunityNameOperationQueue = NSOperationQueue.new;
        importCommunityWindowController.fetchCommunityNameOperationQueue.maxConcurrentOperationCount = 1;
        importCommunityWindowController.email = email;
        importCommunityWindowController.password = password;
        importCommunityWindowController.completion = completion;
    }

    return importCommunityWindowController;
}

-(void)windowDidLoad
{
    [super windowDidLoad];

    [[AlertManager sharedManager] loginWithEmail:self.email password:self.password completion:^(NSDictionary* alertStatus, NSError* error) {
         if (alertStatus) {
             NSUInteger order = 0;
             for (NSString* communityId in alertStatus[AlertManagerAlertStatusKeyCommunities]) {
                 NSMutableDictionary* community = NSMutableDictionary.new;
                 community[@"order"] = [NSNumber numberWithInteger:order];
                 community[@"communityId"] = communityId;
                 community[@"communityName"] = @"n/a";
                 [self.communityArrayController addObject:community];
             }
             LOG(@"%@", self.communityArrayController.arrangedObjects);
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
        NSBlockOperation* operation = [NSBlockOperation blockOperationWithBlock:^(void) {
                                           [self.fetchCommunityNameOperationQueue setSuspended:YES];
                                           [[AlertManager sharedManager] requestCommunityInfoForCommunity:community[@"communityId"] completion:^(NSDictionary* communityInfo, NSError* error) {
                                                if (!error) {
                                                    community[@"communityName"] = communityInfo[AlertManagerCommunityInfoKeyCommunityName];
                                                } else {
                                                    community[@"communityName"] = @"(request failed.)";
                                                }
                                                [self.fetchCommunityNameOperationQueue setSuspended:NO];
                                            }];
                                       }];
        [self.fetchCommunityNameOperationQueue addOperation:operation];
    }
}

#pragma mark Button Actions

-(IBAction)importCommunity:(id)sender
{
    [self.fetchCommunityNameOperationQueue cancelAllOperations];

    if (self.completion) {
        self.completion(NO, self.communityArrayController.arrangedObjects);
        // TODO: self.completion = nil;
    }
}

-(IBAction)cancelImportCommunity:(id)sender
{
    [self.fetchCommunityNameOperationQueue cancelAllOperations];

    if (self.completion) {
        self.completion(YES, nil);
        // TODO: self.completion = nil;
    }
}

@end
