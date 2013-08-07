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
#import "MOCommunity.h"

#define DEBUG_CLEAR_AND_FEED_DUMMY_COMMUNITIES

float const kLiveStatTimerInterval = 0.5f;
int const kLiveStatSamplingCount = 20;

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

@property (weak) IBOutlet NSTableView* communityTableView;
// NSTextVIew doesn't support weak reference in arc.
@property (strong) IBOutlet NSTextView* logTextView;
@property (weak) IBOutlet NSScrollView* logScrollView;
@property (weak) IBOutlet NSLevelIndicatorCell* liveLevelIndicatorCell;
@property (weak) IBOutlet NSTextFieldCell* liveTextFieldCell;
@property (weak) IBOutlet NSArrayController* communityArrayController;

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

#ifdef DEBUG_CLEAR_AND_FEED_DUMMY_COMMUNITIES
        for (MOCommunity* community in [MOCommunity MR_findAll]) {
            [community deleteEntity];
        }

        for (NSInteger i = 0; i < 20; i++) {
            MOCommunity* community = [MOCommunity MR_createEntity];
            community.displayOrder = [NSNumber numberWithInt:i];
            community.community = [NSString stringWithFormat:@"co%05ld", i];
            community.communityName = [NSString stringWithFormat:@"テストコミュニティ(%ld).", i];
        }

        [[NSManagedObjectContext MR_defaultContext] MR_saveOnlySelfAndWait];
#endif
    }

    return self;
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
    NSSortDescriptor* defaultSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
    [self.communityArrayController setSortDescriptors:@[defaultSortDescriptor]];

    // NSArray* array = [NSArray arrayWithObject:NSFilenamesPboardType];
    // [self.communityTableView registerForDraggedTypes:array];
    [self.communityTableView registerForDraggedTypes:@[@"aRow"]];
    [self.communityTableView setDraggingSourceOperationMask:NSDragOperationAll forLocal:NO];

    [NSTimer scheduledTimerWithTimeInterval:kLiveStatTimerInterval target:self selector:@selector(liveCounterTimerFired:) userInfo:nil repeats:YES];
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

    NSArray* alertCommunities = self.communityArrayController.arrangedObjects;
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

    [[NSManagedObjectContext MR_defaultContext] MR_saveOnlySelfAndWait];
    [self.communityArrayController fetch:self];
    // [self.communityTableView reloadData];

    // LOG(@"from %ld --> to %ld", fromIndex, toIndex);

//    [appDelegate_ moveAccountFrom:fromIndex to:toIndex];
//    [accountTableView_ reloadData];

    return YES;
}

// #pragma mark - Public Interface

#pragma mark - Internal Methods

-(void)loginWithDefaultAccount
{
    NSDictionary* account = [PreferencesWindowController sharedController].defaultAccount;
    if (account) {
        NSString* email = account[kUserDefaultsAccountsEmail];
        NSString* password = [SSKeychain passwordForService:[[NSBundle mainBundle] bundleIdentifier] account:email];
        [[AlertManager sharedManager] loginWithEmail:email password:password completion:^(NSDictionary* alertStatus, NSError* error) {
             if (!error) {
                 [[AlertManager sharedManager] openStreamWithAlertStatus:alertStatus streamListener:self];
             }
         }];
    }
}

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

#pragma mark - Button Actions

#pragma mark Start/Stop Stream

-(IBAction)startAlert:(id)sender
{
    [self loginWithDefaultAccount];
    self.isStreamOpened = YES;
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

#pragma mark Actions in Community Table View

-(IBAction)enableCommunityButtonClicked:(id)sender
{
    [[NSManagedObjectContext MR_defaultContext] MR_saveOnlySelfAndWait];
}

@end
