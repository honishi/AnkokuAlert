//
//  MainWindowController.m
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 7/27/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import "MainWindowController.h"
#import "ImportCommunityWindowController.h"
#import "ConfirmationWindowController.h"
#import "PreferencesWindowController.h"
#import "AlertManager.h"
#import "SSKeychain.h"
#import "MOAccount.h"
#import "MOCommunity.h"

//#define DEBUG_TRUNCATE_ALL_ACCOUNTS
//#define DEBUG_CREATE_DUMMY_ACCOUNTS
//#define DEBUG_TRUNCATE_ALL_COMMUNITIES
//#define DEBUG_CREATE_DUMMY_COMMUNITIES
//#define DEBUG_FORCE_ALERTING

#define DUMMY_ACCOUNT_COUNT 3
#define DUMMY_COMMUNITY_COUNT 20
#define FORCE_ALERTING_INTERVAL 20

float const kLiveStatTimerInterval = 0.5f;
int const kLiveStatSamplingCount = 20;
NSUInteger const kDefaultRatingValue = 3;

#pragma mark - Value Transformer

@interface LivePerSecondValueTransformer : NSValueTransformer {}
@end

@implementation LivePerSecondValueTransformer

+(Class)transformedValueClass
{
    return [NSString class];
}

+(BOOL)allowsReverseTransformation
{
    return NO;
}

-(id)transformedValue:(id)value
{
    NSNumber* rate = value;
    return (rate == nil) ? nil : [NSString stringWithFormat:@"%.1f", rate.doubleValue];
}

@end

#pragma mark - Main Window Controller

@interface MainWindowController ()<AlertManagerStreamListener, NSTableViewDataSource>

// NSTextVIew doesn't support weak reference in arc.
@property (strong) IBOutlet NSTextView* logTextView;
@property (weak) IBOutlet NSScrollView* logScrollView;
@property (weak) IBOutlet NSLevelIndicatorCell* liveLevelIndicatorCell;
@property (weak) IBOutlet NSTextFieldCell* liveTextFieldCell;
@property (unsafe_unretained) IBOutlet NSPanel* communityInputSheet;

@property (weak) IBOutlet NSArrayController* communityArrayController;
@property (weak) IBOutlet NSObjectController* defaultAccountObjectController;

@property (nonatomic) NSUInteger liveCount;
@property (nonatomic) NSMutableArray* liveStats;

@property (nonatomic) ImportCommunityWindowController* importCommunityWindowController;
@property (nonatomic) ConfirmationWindowController* confirmationWindowController;
@property (nonatomic) PreferencesWindowController* preferenceWindowController;

@end

@implementation MainWindowController

#pragma mark - Object Lifecycle

-(id)initWithWindow:(NSWindow*)window
{
    self = [super initWithWindow:window];

    if (self) {
        // Initialization code here.
        self.liveStats = NSMutableArray.new;
    }

    return self;
}

-(void)dealloc
{
    [self.defaultAccountObjectController removeObserver:self forKeyPath:@"content"];
}

-(void)windowDidLoad
{
    [super windowDidLoad];

    self.managedObjectContext = [NSManagedObjectContext MR_defaultContext];
    [self setupDebugData];
    [self.defaultAccountObjectController addObserver:self forKeyPath:@"content" options:NSKeyValueObservingOptionNew context:nil];

    [self.communityTableView registerForDraggedTypes:@[@"aRow"]];
    [self.communityTableView setDraggingSourceOperationMask:NSDragOperationAll forLocal:NO];

    [self updateWindowTitleAndPredicate];

    [NSTimer scheduledTimerWithTimeInterval:kLiveStatTimerInterval target:self selector:@selector(liveCounterTimerFired:) userInfo:nil repeats:YES];

    if (!MOAccount.hasAccounts) {
        double delayInSeconds = 0.5f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                [self showPreferences:self];
            });
    }
}

-(void)setupDebugData
{
#ifdef DEBUG_TRUNCATE_ALL_ACCOUNTS
    [MOAccount truncateAll];
    [self.managedObjectContext MR_saveOnlySelfAndWait];
#endif

#ifdef DEBUG_CREATE_DUMMY_ACCOUNTS
    for (NSUInteger i = 0; i < DUMMY_ACCOUNT_COUNT; i++) {
        MOAccount* account = [MOAccount accountWithNumberedOrderAttribute];
        account.userId = [NSString stringWithFormat:@"1%05ld", i];
        account.userName = [NSString stringWithFormat:@"テストユーザー(%ld).", i];
        account.email = [NSString stringWithFormat:@"%03ld@example.com", i];
        account.isDefault = [NSNumber numberWithBool:(i == 0)];
    }
    [self.managedObjectContext MR_saveOnlySelfAndWait];
#endif

#ifdef DEBUG_TRUNCATE_ALL_COMMUNITIES
    [MOCommunity MR_truncateAll];
    [self.managedObjectContext MR_saveOnlySelfAndWait];
#endif

#ifdef DEBUG_CREATE_DUMMY_COMMUNITIES
    NSUInteger j = 0;
    for (MOAccount* account in [MOAccount findAll]) {
        for (NSInteger i = 0; i < DUMMY_COMMUNITY_COUNT; i++) {
            MOCommunity* community = [account communityWithNumberedOrderAttribute];
            community.communityId = [NSString stringWithFormat:@"co%05ld", j];
            community.communityName = [NSString stringWithFormat:@"テストコミュニティ(%ld).", j];
            community.rating = [NSNumber numberWithInteger:(i%6)];

            [account addCommunitiesObject:community];
            j++;
        }
    }
    [self.managedObjectContext MR_saveOnlySelfAndWait];
#endif
}

// #pragma mark - Property Methods
// #pragma mark - [ClassName] Overrides

#pragma mark - AlertManagerStreamListener Methods

-(void)alertManager:(AlertManager*)alertManager didReceiveLive:(NSString*)liveId community:(NSString*)communityId user:(NSString*)userId url:(NSString*)liveUrl
{
    [[AlertManager sharedManager] requestStreamInfoForLive:liveId completion:^(NSDictionary* streamInfo, NSError* error) {
         NSString* info = [NSString stringWithFormat:@"community:%@, title:%@\n", streamInfo[AlertManagerStreamInfoKeyCommunityName], streamInfo[AlertManagerStreamInfoKeyLiveName]];
         [self logMessage:info];
     }];

    static NSString* lastAlertLiveId;
    NSArray* alertCommunities = self.communityArrayController.arrangedObjects;
    BOOL isForceAlerting = NO;  // for debug purpose
    for (MOCommunity* alertCommunity in alertCommunities) {
#ifdef DEBUG_FORCE_ALERTING
        isForceAlerting = (self.liveCount % FORCE_ALERTING_INTERVAL) == 0;
#endif
        if (isForceAlerting ||
            (![liveId isEqualToString:lastAlertLiveId] && [communityId isEqualToString:alertCommunity.communityId])) {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:liveUrl]];
            [self playChimeSound];
            lastAlertLiveId = liveId;
            break;
        }
    }

    self.liveCount++;
}

-(void)alertManagerDidCloseStream:(AlertManager*)alertManager
{
    LOG(@"stream closed.");
    self.isStreamOpened = NO;
}

#pragma mark NSTableViewDataSource Methods

#pragma mark Drag & Drop Reordering Support

-(BOOL)tableView:(NSTableView*)tableView writeRowsWithIndexes:(NSIndexSet*)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    // MOCommunity* community = self.communityArrayController.arrangedObjects[rowIndexes.firstIndex];
    LOG(@"%ld", rowIndexes.firstIndex);

    [pboard declareTypes:[NSArray arrayWithObject:@"aRow"] owner:self];
    // [pboard setValue:community forKey:@"aRow"];
    // [pboard setString:community.community forType:@"aRow"];
    [pboard setString:[NSNumber numberWithInteger:rowIndexes.firstIndex].stringValue forType:@"aRow"];

    return YES;
}

-(NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    return NSDragOperationMove; // NSDragOperationEvery;
}

-(BOOL)tableView:(NSTableView*)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
    NSPasteboard* pboard = info.draggingPasteboard;
    NSInteger fromIndex = [pboard stringForType:@"aRow"].integerValue;
    NSInteger toIndex = row;

    LOG(@"from: %ld, to: %ld", fromIndex, toIndex);

    // TODO: should update every displayOrder in for-loop.
//    MOCommunity* fromCommunity = [MOCommunity MR_findFirstByAttribute:@"order" withValue:[NSNumber numberWithInteger:fromIndex]];
//    MOCommunity* toCommunity = [MOCommunity MR_findFirstByAttribute:@"order" withValue:[NSNumber numberWithInteger:toIndex]];
    MOCommunity* fromCommunity = self.communityArrayController.arrangedObjects[fromIndex];
    MOCommunity* toCommunity = self.communityArrayController.arrangedObjects[toIndex];

    NSNumber* anOrder = fromCommunity.order;
    fromCommunity.order = toCommunity.order;
    toCommunity.order = anOrder;

    // TODO: should manipulate arrangedObjects, then save. you will have no need to fetch.
    [self.managedObjectContext MR_saveOnlySelfAndWait];
    [self.communityArrayController fetch:self];

    return YES;
}

#pragma mark - Public Interface

-(IBAction)showPreferences:(id)sender
{
    self.preferenceWindowController = [PreferencesWindowController preferenceWindowController];
    [self.preferenceWindowController.window center];
    [self.preferenceWindowController.window makeKeyAndOrderFront:self];
}

#pragma mark - Internal Methods

#pragma mark Log View

-(void)logMessage:(NSString*)message
{
    BOOL shouldScrollToBottom = NO;
    NSAttributedString* attributedMessage = [[NSAttributedString alloc] initWithString:message];

    if (self.logScrollView.verticalScroller.floatValue == 1.0f) {
        shouldScrollToBottom = YES;
    }

    [self.logTextView.textStorage appendAttributedString:attributedMessage];
    [self.logScrollView flashScrollers];

    if (shouldScrollToBottom) {
        [self.logTextView scrollToEndOfDocument:self];
    }
}

#pragma mark Live Level Indicator

-(void)liveCounterTimerFired:(NSTimer*)timer
{
    // LOG(@"target rating: %ld", self.targetRating);
    LOG(@"target rating: %@", self.targetRating);

    NSDictionary* stat = @{@"date" : [NSDate date], @"liveCount": [NSNumber numberWithInteger:self.liveCount]};
    [self.liveStats addObject:stat];

    if (2 < self.liveStats.count) {
        NSDictionary* oldest = self.liveStats[0];
        NSDictionary* newest = self.liveStats[self.liveStats.count-1];
        NSUInteger oldestLiveCount = ((NSNumber*)oldest[@"liveCount"]).integerValue;
        NSUInteger newestLiveCount = ((NSNumber*)newest[@"liveCount"]).integerValue;
        NSDate* oldestDate = oldest[@"date"];
        NSDate* newestDate = newest[@"date"];
        double rate = (newestLiveCount-oldestLiveCount)/([newestDate timeIntervalSinceDate:oldestDate]);
        self.livePerSecond = [NSNumber numberWithDouble:rate];
    }

    if (kLiveStatSamplingCount < self.liveStats.count) {
        [self.liveStats removeObjectAtIndex:0];
    }
}

#pragma mark Default Account Predicate

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if ([keyPath isEqualToString:@"content"] && object == self.defaultAccountObjectController) {
        [self updateWindowTitleAndPredicate];
    }
}

-(void)updateWindowTitleAndPredicate
{
    MOAccount* account = [MOAccount defaultAccount];
    self.windowTitle = [NSString stringWithFormat:@"Ankoku Alert: %@", account.userName ? account.userName:@"<No user selected.>"];

    if (account) {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"account.objectID == %@", account.objectID];
        self.accountFilterPredicate = predicate;
    }
}

#pragma mark - Button Actions

#pragma mark Start/Stop Stream

-(IBAction)startAlert:(id)sender
{
    MOAccount* account = [MOAccount defaultAccount];
    if (account) {
        self.isStreamOpened = YES;

        NSString* email = account.email;
        NSString* password = [SSKeychain passwordForService:[[NSBundle mainBundle] bundleIdentifier] account:email];

        [[AlertManager sharedManager] loginWithEmail:email password:password completion:^(NSDictionary* alertStatus, NSError* error) {
             if (error) {
                 self.isStreamOpened = NO;
             } else {
                 [[AlertManager sharedManager] openStreamWithAlertStatus:alertStatus streamListener:self];
             }
         }];
    }
}

-(IBAction)stopAlert:(id)sender
{
    [[AlertManager sharedManager] closeStream];
}

#pragma mark Add/Remove/Import Community

-(IBAction)inputCommunity:(id)sender
{
    [NSApp beginSheet:self.communityInputSheet modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
}

-(IBAction)cancelInputCommunity:(id)sender
{
    [NSApp endSheet:self.communityInputSheet];
    [self.communityInputSheet orderOut:sender];
}

-(IBAction)addCommunity:(id)sender
{
    [NSApp endSheet:self.communityInputSheet];
    [self.communityInputSheet orderOut:sender];

//    MOCommunity* community = [MOCommunity MR_createEntity];
//    community.communityId = @"co12345";
//    community.communityName = @"テストです.";
//
//    [self.managedObjectContext MR_saveOnlySelfAndWait];
}

-(IBAction)confirmCommunityRemoval:(id)sender
{
    self.confirmationWindowController = [ConfirmationWindowController confirmationWindowControllerWithMessage:@"Are you really sure to remove selected community(s)?" completion:^
                                             (BOOL isCancelled) {
                                             [NSApp endSheet:self.confirmationWindowController.window];
                                             [self.confirmationWindowController.window orderOut:self];
                                             if (!isCancelled) {
                                                 [self removeCommunity];
                                             }
                                         }];
    self.confirmationWindowController.titleOfOkButton = @"Remove";
    [NSApp beginSheet:self.confirmationWindowController.window modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
}

-(void)removeCommunity
{
    [self.communityArrayController removeObjectsAtArrangedObjectIndexes:self.communityArrayController.selectionIndexes];
    [self.managedObjectContext MR_saveOnlySelfAndWait];
}

-(IBAction)showImportCommunityWindow:(id)sender
{
    MOAccount* account = [MOAccount defaultAccount];
    if (!account) {
        return;
    }

    NSString* email = account.email;
    NSString* password = [SSKeychain passwordForService:[[NSBundle mainBundle] bundleIdentifier] account:email];

    self.importCommunityWindowController = [ImportCommunityWindowController importCommunityWindowControllerWithEmail:email password:password completion:^(BOOL isCancelled, NSArray* importedCommunities) {
                                                [NSApp endSheet:self.importCommunityWindowController.window];
                                                [self.importCommunityWindowController.window orderOut:self];
                                                if (isCancelled) {
                                                    LOG(@"import cancelled.")
                                                } else {
                                                    LOG(@"import done.");
                                                    MOAccount* defaultAccount = [MOAccount defaultAccount];
                                                    for (NSDictionary* importedCommunity in importedCommunities) {
                                                        MOCommunity* community = [defaultAccount communityWithNumberedOrderAttribute];
                                                        community.communityId = importedCommunity[@"communityId"];
                                                        community.communityName = importedCommunity[@"communityName"];
                                                        community.rating = [NSNumber numberWithInteger:kDefaultRatingValue];
                                                        [defaultAccount addCommunitiesObject:community];
                                                    }
                                                    [self.managedObjectContext MR_saveOnlySelfAndWait];
                                                }
                                                // TODO:
                                                self.importCommunityWindowController = nil;
                                            }];

    [NSApp beginSheet:self.importCommunityWindowController.window modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
}

#pragma mark Actions in Community Table View

-(IBAction)changeCommunityEnabled:(id)sender
{
    [self.managedObjectContext MR_saveOnlySelfAndWait];
}

-(IBAction)enableAllCommunity:(id)sender
{
    for (MOCommunity* community in self.communityArrayController.arrangedObjects) {
        community.isEnabled = [NSNumber numberWithBool:YES];
    }
    [self.managedObjectContext MR_saveOnlySelfAndWait];
}

-(IBAction)disableAllCommunity:(id)sender
{
    for (MOCommunity* community in self.communityArrayController.arrangedObjects) {
        community.isEnabled = [NSNumber numberWithBool:NO];
    }
    [self.managedObjectContext MR_saveOnlySelfAndWait];
}

-(IBAction)changeCommunityRating:(id)sender
{
    // [self.communityArrayController rearrangeObjects];
    [self.managedObjectContext MR_saveOnlySelfAndWait];
}

-(IBAction)openCommunityHomepage:(id)sender
{
    NSUInteger selectedRow = [self.communityTableView rowForView:sender];
    MOCommunity* selectedCommunity = self.communityArrayController.arrangedObjects[selectedRow];

    NSString* url = [AlertManager communityUrlStringWithCommunithId:selectedCommunity.communityId];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

-(IBAction)selectTargetRating:(id)sender
{
}

#pragma mark Misc

-(void)playChimeSound
{
    NSSound* sound = [[NSSound alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultSound" ofType:@"mp3"] byReference:NO];
    [sound play];
}

@end
