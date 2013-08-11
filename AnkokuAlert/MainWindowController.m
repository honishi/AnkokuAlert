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
#import "AlertLogScrollView.h"

//#define DEBUG_TRUNCATE_ALL_ACCOUNTS
//#define DEBUG_CREATE_DUMMY_ACCOUNTS
//#define DEBUG_TRUNCATE_ALL_COMMUNITIES
//#define DEBUG_CREATE_DUMMY_COMMUNITIES
//#define DEBUG_FORCE_ALERTING

#define DUMMY_ACCOUNT_COUNT 3
#define DUMMY_COMMUNITY_COUNT 20
#define FORCE_ALERTING_INTERVAL 20

NSString* const kCommunityTableViewDraggedType = @"kCommunityTableViewDraggedType";

NSString* const kUserDefaultsKeySoundVolume = @"SoundVolume";
NSString* const kUserDefaultsKeyLogAllLive = @"LogAllLive";

NSString* const kRegExpLiveId = @".*(lv\\d+)";
NSString* const kRegExpCommunityId = @".*(co\\d+)";

float const kLiveStatTimerInterval = 0.5f;
int const kLiveStatSamplingCount = 20;

#pragma mark - Value Transformer

@interface LiveLevelValueTransformer : NSValueTransformer {}
@end

@implementation LiveLevelValueTransformer

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

typedef NS_ENUM (NSInteger, CommunityInputType) {
    CommunityInputTypeUnknown,
    CommunityInputTypeLiveId,
    CommunityInputTypeCommunityId
};

@interface MainWindowController ()<AlertManagerStreamListener, NSTableViewDataSource, NSTextFieldDelegate>

@property (weak) IBOutlet NSScrollView* communityScrollView;
@property (nonatomic, weak) IBOutlet NSTableView* communityTableView;
// NSTextVIew doesn't support weak reference in arc.
@property (strong) IBOutlet NSTextView* logTextView;
// @property (weak) IBOutlet NSScrollView* logScrollView;
@property (weak) IBOutlet AlertLogScrollView* alertLogScrollView;
@property (weak) IBOutlet NSLevelIndicatorCell* liveLevelIndicatorCell;
@property (weak) IBOutlet NSTextFieldCell* liveLevelTextFieldCell;
@property (unsafe_unretained) IBOutlet NSPanel* communityInputSheet;
@property (weak) IBOutlet NSTextField* communityInputTextField;
@property (nonatomic) CommunityInputType communityInputType;
@property (nonatomic) NSString* communityInputValue;

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

    [self.communityTableView registerForDraggedTypes:@[kCommunityTableViewDraggedType]];
    [self.communityTableView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];

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
        MOAccount* account = [MOAccount accountWithDefaultAttributes];
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
            MOCommunity* community = [account communityWithDefaultAttributes];
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
    NSArray* targetCommunities = self.communityArrayController.arrangedObjects;
    BOOL isForceAlerting = NO;  // for debug purpose
    BOOL shouldLogLiveInfo = NO;
    for (MOCommunity* targetCommunity in targetCommunities) {
#ifdef DEBUG_FORCE_ALERTING
        isForceAlerting = (self.liveCount % FORCE_ALERTING_INTERVAL) == 0;
#endif
        // TODO: add other condition, like target rating level.
        if (!targetCommunity.isEnabled.boolValue) {
            continue;
        }

        if (isForceAlerting ||
            ([communityId isEqualToString:targetCommunity.communityId])) {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:liveUrl]];
            [self playChimeSound];
            shouldLogLiveInfo = YES;
            break;
        }
    }

    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSNumber* logAllLive = [defaults valueForKey:kUserDefaultsKeyLogAllLive];
    if (shouldLogLiveInfo || logAllLive.boolValue) {
        [[AlertManager sharedManager] requestStreamInfoForLive:liveId completion:^(NSDictionary* streamInfo, NSError* error) {
             if (error) {
                 // TODO: do something
             } else {
                 [self.alertLogScrollView logLiveWithLiveName:streamInfo[AlertManagerStreamInfoKeyLiveName]
                                                      liveUrl:streamInfo[AlertManagerStreamInfoKeyLiveUrl]
                                                communityName:streamInfo[AlertManagerStreamInfoKeyCommunityName]
                                                 communityUrl:streamInfo[AlertManagerStreamInfoKeyCommunityUrl]];
             }
         }];
    }

    self.liveCount++;
}

-(void)alertManagerdidOpenStream:(AlertManager*)alertManager
{
    [self.alertLogScrollView logMessage:@"Connected."];
}

-(void)alertManagerDidCloseStream:(AlertManager*)alertManager
{
    [self.alertLogScrollView logMessage:@"Disconnected."];
    self.isStreamOpened = NO;
}

#pragma mark NSTableViewDataSource Methods

#pragma mark Drag & Drop Reordering Support

-(BOOL)tableView:(NSTableView*)tableView writeRowsWithIndexes:(NSIndexSet*)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    // LOG(@"%ld", rowIndexes.firstIndex);

    [pboard declareTypes:@[kCommunityTableViewDraggedType] owner:self];
    NSString* fromIndex = [NSNumber numberWithInteger:rowIndexes.firstIndex].stringValue;
    [pboard setString:fromIndex forType:kCommunityTableViewDraggedType];

    return YES;
}

-(NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    return NSDragOperationMove;
}

-(BOOL)tableView:(NSTableView*)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
    NSPasteboard* pboard = info.draggingPasteboard;
    NSInteger fromIndex = [pboard stringForType:kCommunityTableViewDraggedType].integerValue;
    NSInteger toIndex = row;
    // LOG(@"from: %ld, to: %ld", fromIndex, toIndex);

    MOCommunity* fromCommunity = self.communityArrayController.arrangedObjects[fromIndex];
    MOCommunity* toCommunity = self.communityArrayController.arrangedObjects[toIndex];
    [fromCommunity exchangeCommunityWithCommunity:toCommunity];
    [self.managedObjectContext MR_saveOnlySelfAndWait];

    return YES;
}

#pragma mark - Public Interface

-(IBAction)showPreferences:(id)sender
{
    self.preferenceWindowController = [PreferencesWindowController preferenceWindowController];
    [self.preferenceWindowController.window center];
    [self.preferenceWindowController.window makeKeyAndOrderFront:self];
}

#pragma mark - Internal Methods, Button Actions

#pragma mark Start/Stop Stream

-(IBAction)startAlert:(id)sender
{
    MOAccount* account = [MOAccount defaultAccount];
    NSString* message = [NSString stringWithFormat:@"Connecting to the server as user %@.", account.userName];
    [self.alertLogScrollView logMessage:message];

    if (account) {
        self.isStreamOpened = YES;

        NSString* email = account.email;
        NSString* password = [self cachedPasswordForAccount:account];

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
    self.communityInputTextField.stringValue = @"";
    self.hasValidCommunityInput = NO;
    [NSApp beginSheet:self.communityInputSheet modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
}

-(void)controlTextDidChange:(NSNotification*)obj
{
    NSTextView* inputView = obj.userInfo[@"NSFieldEditor"];
    NSString* inputContent = inputView.textStorage.string;

    NSError* error = nil;
    NSRegularExpression* liveIdRegexp = [NSRegularExpression regularExpressionWithPattern:kRegExpLiveId options:0 error:&error];
    NSTextCheckingResult* result = [liveIdRegexp firstMatchInString:inputContent options:0 range:NSMakeRange(0, inputContent.length)];

    if (0 < result.numberOfRanges) {
        self.hasValidCommunityInput = YES;
        self.communityInputType = CommunityInputTypeLiveId;
        self.communityInputValue = [inputContent substringWithRange:[result rangeAtIndex:1]];
        return;
    }

    NSRegularExpression* communityIdRegexp = [NSRegularExpression regularExpressionWithPattern:kRegExpCommunityId options:0 error:&error];
    result = [communityIdRegexp firstMatchInString:inputContent options:0 range:NSMakeRange(0, inputContent.length)];

    if (0 < result.numberOfRanges) {
        self.hasValidCommunityInput = YES;
        self.communityInputType = CommunityInputTypeCommunityId;
        self.communityInputValue = [inputContent substringWithRange:[result rangeAtIndex:1]];
        return;
    }

    self.hasValidCommunityInput = NO;
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

    switch (self.communityInputType) {
        case CommunityInputTypeLiveId: {
            [[AlertManager sharedManager] requestStreamInfoForLive:self.communityInputValue completion:^
                 (NSDictionary* streamInfo, NSError* error) {
                 if (error) {
                     //
                 } else {
                     MOCommunity* community = [[MOAccount defaultAccount] communityWithDefaultAttributes];
                     community.communityId = streamInfo[AlertManagerStreamInfoKeyCommunityId];
                     community.communityName = streamInfo[AlertManagerStreamInfoKeyCommunityName];
                     [[MOAccount defaultAccount] addCommunitiesObject:community];

                     [self.managedObjectContext MR_saveOnlySelfAndWait];
                     [self.communityArrayController rearrangeObjects];
                     [self.communityScrollView flashScrollers];
                 }
             }];

            break;
        }

        case CommunityInputTypeCommunityId: {
            [[AlertManager sharedManager] requestCommunityInfoForCommunity:self.communityInputValue completion:^
                 (NSDictionary* communityInfo, NSError* error) {
                 if (error) {
                     //
                 } else {
                     MOCommunity* community = [[MOAccount defaultAccount] communityWithDefaultAttributes];
                     community.communityId = self.communityInputValue;
                     community.communityName = communityInfo[AlertManagerCommunityInfoKeyCommunityName];
                     [[MOAccount defaultAccount] addCommunitiesObject:community];

                     [self.managedObjectContext MR_saveOnlySelfAndWait];
                     [self.communityArrayController rearrangeObjects];
                     [self.communityScrollView flashScrollers];
                 }
             }];
            break;
        }

        default:
            break;
    }

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
    [self.communityScrollView flashScrollers];
}

-(IBAction)showImportCommunityWindow:(id)sender
{
    MOAccount* account = [MOAccount defaultAccount];
    if (!account) {
        return;
    }

    NSString* email = account.email;
    NSString* password = [self cachedPasswordForAccount:account];
    NSMutableArray* registeredCommunities = NSMutableArray.new;
    for (MOCommunity* community in account.communities) {
        [registeredCommunities addObject:community.communityId];
    }

    self.importCommunityWindowController =
        [ImportCommunityWindowController importCommunityWindowControllerWithEmail:email
                                                                         password:password
                                                             communitiesExcluding:registeredCommunities
                                                                       completion:^(BOOL isCancelled, NSArray* importedCommunities) {
             [NSApp endSheet:self.importCommunityWindowController.window];
             [self.importCommunityWindowController.window orderOut:self];
             if (isCancelled) {
                 LOG(@"import cancelled.")
             } else {
                 LOG(@"import done.");
                 MOAccount* defaultAccount = [MOAccount defaultAccount];
                 for (NSDictionary* importedCommunity in importedCommunities) {
                     MOCommunity* community = [defaultAccount communityWithDefaultAttributes];
                     community.communityId = importedCommunity[kImportCommunityKeyCommunityId];
                     community.communityName = importedCommunity[kImportCommunityKeyCommunityName];
                     [defaultAccount addCommunitiesObject:community];
                 }
                 [self.managedObjectContext MR_saveOnlySelfAndWait];

                 [self.communityScrollView flashScrollers];
             }
             // TODO:
             self.importCommunityWindowController = nil;
         }];

    [NSApp beginSheet:self.importCommunityWindowController.window modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
}

#pragma mark - Internal Methods, Actions in Community Table View

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

-(IBAction)changeSoundVolume:(id)sender
{
    [self playChimeSound];
}

#pragma mark - Internal Methods, Misc Utility

#pragma mark Live Level Indicator

-(void)liveCounterTimerFired:(NSTimer*)timer
{
    // TODO: delete
    // LOG(@"target rating: %ld", self.targetRating);
    // LOG(@"target rating: %@", self.targetRating);

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
        self.liveLevel = [NSNumber numberWithDouble:rate];
    }

    if (kLiveStatSamplingCount < self.liveStats.count) {
        [self.liveStats removeObjectAtIndex:0];
    }

    // TODO: auto reopen stream logic here.
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

#pragma mark Misc

-(NSString*)cachedPasswordForAccount:(MOAccount*)account
{
    static NSMutableDictionary* cachedPasswords;

    if (!cachedPasswords) {
        cachedPasswords = NSMutableDictionary.new;
    }

    NSString* email = account.email;
    NSString* password = cachedPasswords[email];
    if (!password) {
        password = [SSKeychain passwordForService:[[NSBundle mainBundle] bundleIdentifier] account:email];
        cachedPasswords[email] = password;
    }

    return password;
}

-(void)playChimeSound
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSNumber* soundVolume = [defaults valueForKey:kUserDefaultsKeySoundVolume];

    if (0 < soundVolume.integerValue) {
        NSSound* sound = [[NSSound alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultSound" ofType:@"mp3"] byReference:NO];
        [sound setVolume:soundVolume.floatValue/100];

        [sound play];
    }
}


@end
