//
//  MainWindowController.m
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 7/27/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import "MainWindowController.h"
#import "PreferencesWindowController.h"
#import "AlertManager.h"
#import "SSKeychain.h"
#import "MOAccount.h"
#import "MOCommunity.h"

#define DEBUG_TRUNCATE_ALL_ACCOUNTS
#define DEBUG_CREATE_DUMMY_ACCOUNTS
#define DEBUG_TRUNCATE_AND_CREATE_DUMMY_COMMUNITIES

#define DUMMY_ACCOUNT_COUNT 5
#define DUMMY_COMMUNITY_COUNT 5

float const kLiveStatTimerInterval = 0.5f;
int const kLiveStatSamplingCount = 20;


#pragma mark - Value Transformer

@interface WindowTitleValueTransformer : NSValueTransformer {}
@end

@implementation WindowTitleValueTransformer

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
    NSString* title = nil;
    MOAccount* account = value;

    if (account) {
        title = [NSString stringWithFormat:@"Ankoku Alert: %@", account.userName];
    }

    return title;
}

@end

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

@property (nonatomic, readwrite) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, readwrite) NSPredicate* accountFilterPredicate;

@property (weak) IBOutlet NSTableView* communityTableView;
// NSTextVIew doesn't support weak reference in arc.
@property (strong) IBOutlet NSTextView* logTextView;
@property (weak) IBOutlet NSScrollView* logScrollView;
@property (weak) IBOutlet NSLevelIndicatorCell* liveLevelIndicatorCell;
@property (weak) IBOutlet NSTextFieldCell* liveTextFieldCell;
@property (weak) IBOutlet NSArrayController* communitiesArrayController;

@property (weak) IBOutlet NSObjectController* defaultAccountObjectController;

@property (unsafe_unretained) IBOutlet NSPanel* communityInputSheet;

@property (nonatomic) NSUInteger liveCount;
@property (nonatomic) NSMutableArray* liveStats;

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

-(void)awakeFromNib
{
    // TODO: check whether the initialization way is correct, or not.
    // do not use this, awakeFromNib is called in initialization of every tableview cell.
}

-(void)windowDidLoad
{
    [super windowDidLoad];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    self.managedObjectContext = [NSManagedObjectContext MR_defaultContext];
    [self.defaultAccountObjectController addObserver:self forKeyPath:@"content" options:NSKeyValueObservingOptionNew context:nil];

    NSSortDescriptor* defaultSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
    [self.communitiesArrayController setSortDescriptors:@[defaultSortDescriptor]];

    // NSArray* array = [NSArray arrayWithObject:NSFilenamesPboardType];
    // [self.communityTableView registerForDraggedTypes:array];
    [self.communityTableView registerForDraggedTypes:@[@"aRow"]];
    [self.communityTableView setDraggingSourceOperationMask:NSDragOperationAll forLocal:NO];

    [NSTimer scheduledTimerWithTimeInterval:kLiveStatTimerInterval target:self selector:@selector(liveCounterTimerFired:) userInfo:nil repeats:YES];

#ifdef DEBUG_TRUNCATE_ALL_ACCOUNTS
    [MOAccount truncateAll];
    [self.managedObjectContext MR_saveOnlySelfAndWait];
#endif

#ifdef DEBUG_CREATE_DUMMY_ACCOUNTS
    for (NSUInteger i = 0; i < DUMMY_ACCOUNT_COUNT; i++) {
        MOAccount* account = [MOAccount MR_createEntity];
        account.userId = [NSString stringWithFormat:@"1%05ld", i];
        account.userName = [NSString stringWithFormat:@"テストユーザー(%ld).", i];
        account.email = [NSString stringWithFormat:@"%03ld@example.com", i];
        account.isDefault = [NSNumber numberWithBool:(i == 0)];

        [self.managedObjectContext MR_saveOnlySelfAndWait];
    }
#endif

#ifdef DEBUG_TRUNCATE_AND_CREATE_DUMMY_COMMUNITIES
    [MOCommunity MR_truncateAll];

    NSUInteger j = 0;
    for (MOAccount* account in [MOAccount findAll]) {
        for (NSInteger i = 0; i < DUMMY_COMMUNITY_COUNT; i++) {
            MOCommunity* community = [MOCommunity MR_createEntity];
            community.displayOrder = [NSNumber numberWithInt:i];
            community.community = [NSString stringWithFormat:@"co%05ld", j];
            community.communityName = [NSString stringWithFormat:@"テストコミュニティ(%ld).", j];

            [account addCommunitiesObject:community];
            j++;
        }
    }

    [self.managedObjectContext MR_saveOnlySelfAndWait];
#endif


    if (![MOAccount findAll].count) {
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                [self showPreferences:self];
            });
    }
}

//-(void)
// #pragma mark - Property Methods
// #pragma mark - [ClassName] Overrides

#pragma mark - AlertManagerStreamListener Methods

-(void)alertManager:(AlertManager*)alertManager didReceiveLive:(NSString*)live community:(NSString*)community user:(NSString*)user
{
    // NSString* message = [NSString stringWithFormat:@"live:%@, co:%@, user:%@\n", live, community, user];
    // [self logMessage:message];

    [[AlertManager sharedManager] streamInfoForLive:live completion:^(NSDictionary* streamInfo, NSError* error) {
         NSString* info = [NSString stringWithFormat:@"community:%@, title:%@\n", streamInfo[AlertManagerStreamInfoKeyCommunityName], streamInfo[AlertManagerStreamInfoKeyLiveTitle]];
         [self logMessage:info];
     }];

    [[AlertManager sharedManager] communityInfoForCommunity:community completion:^(NSDictionary* communityInfo, NSError* error) {
         LOG(@"communityInfo: %@", communityInfo[AlertManagerCommunityInfoKeyCommunityName]);
     }];

    NSArray* alertCommunities = self.communitiesArrayController.arrangedObjects;
    for (MOCommunity* alertCommunity in alertCommunities) {
        if ([community isEqualToString:alertCommunity.community]) {
            // alert!
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
    // LOG_CURRENT_METHOD;

    NSPasteboard* pboard = info.draggingPasteboard;
    NSInteger fromIndex = [pboard stringForType:@"aRow"].integerValue;
    NSInteger toIndex = row;

    MOCommunity* fromCommunity = [MOCommunity MR_findFirstByAttribute:@"displayOrder" withValue:[NSNumber numberWithInteger:fromIndex]];
    MOCommunity* toCommunity = [MOCommunity MR_findFirstByAttribute:@"displayOrder" withValue:[NSNumber numberWithInteger:toIndex]];

    fromCommunity.displayOrder = [NSNumber numberWithInteger:toIndex];
    toCommunity.displayOrder = [NSNumber numberWithInteger:fromIndex];

    [self.managedObjectContext MR_saveOnlySelfAndWait];
    [self.communitiesArrayController fetch:self];
    // [self.communityTableView reloadData];

    // LOG(@"from %ld --> to %ld", fromIndex, toIndex);

//    [appDelegate_ moveAccountFrom:fromIndex to:toIndex];
//    [accountTableView_ reloadData];

    return YES;
}

// #pragma mark - Public Interface

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
    NSDictionary* stat = @{@"date":[NSDate date], @"liveCount": [NSNumber numberWithInteger:self.liveCount]};
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
        [self updateDefaultAccountPredicate];
    }
}

-(void)updateDefaultAccountPredicate
{
    MOAccount* account = [MOAccount defaultAccount];
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
        NSString* password = [SSKeychain passwordForService:[[NSBundle mainBundle] bundleIdentifier] account:account.email];

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

#pragma mark Add/Remove Community

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

    NSManagedObjectContext* context = [NSManagedObjectContext MR_defaultContext];

    MOCommunity* community = [MOCommunity MR_createEntity];
    community.community = @"co12345";
    community.communityName = @"テストです.";

    [context MR_saveOnlySelfAndWait];
}

-(IBAction)removeCommunity:(id)sender
{
}

-(IBAction)showPreferences:(id)sender
{
    [[PreferencesWindowController sharedController] showWindow:nil];
}

#pragma mark Actions in Community Table View

-(IBAction)enableCommunityButtonClicked:(id)sender
{
    [[NSManagedObjectContext MR_defaultContext] MR_saveOnlySelfAndWait];
}

@end
