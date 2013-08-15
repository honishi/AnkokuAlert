//
//  AlertLogScrollView.m
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 8/10/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import "AlertLogScrollView.h"

@interface AlertLogScrollView ()
@property (nonatomic) NSTextView* alertLogTextView;
@end

@implementation AlertLogScrollView

#pragma mark - NSView Overrides

-(void)viewDidMoveToSuperview
{
    self.alertLogTextView = self.contentView.documentView;
}

#pragma mark - Public Interface

-(void)logMessage:(NSString*)message
{
    NSAttributedString* attributedMessage = [[NSAttributedString alloc] initWithString:message];
    [self logToConsole:attributedMessage];
}

-(void)logLiveWithLiveName:(NSString*)liveName liveUrl:(NSString*)liveUrl communityName:(NSString*)communityName communityUrl:(NSString*)communityUrl
{
    if (!liveName || !liveUrl || !communityName || !communityUrl) {
        LOG(@"nil paramter found, liveName:%@, liveUrl:%@, communityName:%@, communityUrl:%@", liveName, liveUrl, communityName, communityUrl);
        return;
    }

    NSMutableAttributedString* message = NSMutableAttributedString.new;

    [message appendAttributedString:[[NSAttributedString alloc] initWithString:@"Live \""]];

    NSAttributedString* liveNameAttributedString = [[NSAttributedString alloc] initWithString:liveName attributes:[self attributeWithLinkUrl:liveUrl]];
    [message appendAttributedString:liveNameAttributedString];

    [message appendAttributedString:[[NSAttributedString alloc] initWithString:@"\" started in \""]];

    NSAttributedString* communityNameAttributedString = [[NSAttributedString alloc] initWithString:communityName attributes:[self attributeWithLinkUrl:communityUrl]];
    [message appendAttributedString:communityNameAttributedString];

    [message appendAttributedString:[[NSAttributedString alloc] initWithString:@"\"."]];

    [self logToConsole:message];
}

-(void)clearLog
{
    NSAttributedString* empty = [[NSAttributedString alloc] initWithString:@""];
    [self.alertLogTextView.textStorage setAttributedString:empty];
    [self logMessage:@"Cleared log."];
}

#pragma mark - Internal Methods

-(NSDictionary*)attributeWithLinkUrl:(NSString*)linkUrl
{
    if (!linkUrl) {
        return nil;
    }

    NSMutableDictionary* linkAttribute = NSMutableDictionary.new;
    [linkAttribute setObject:NSColor.blueColor forKey:NSForegroundColorAttributeName];
    [linkAttribute setObject:[NSNumber numberWithBool:YES] forKey:NSUnderlineStyleAttributeName];
    [linkAttribute setObject:linkUrl forKey:NSLinkAttributeName];

    return linkAttribute;
}

-(NSAttributedString*)dateTimeAttributedString
{
    NSDateFormatter* dateFormatter = NSDateFormatter.new;
    [dateFormatter setDateFormat:@"[yyyy/MM/dd HH:mm:ss] "];

    NSString* formattedDateString = [dateFormatter stringFromDate:NSDate.date];

    return [[NSAttributedString alloc] initWithString:formattedDateString];
}

-(void)logToConsole:(NSAttributedString*)message
{
    BOOL shouldScrollToBottom = NO;
    if (self.verticalScroller.floatValue == 1.0f) {
        shouldScrollToBottom = YES;
    }

    if (self.alertLogTextView.textStorage.length) {
        NSAttributedString* enter = [[NSAttributedString alloc] initWithString:@"\n"];
        [self.alertLogTextView.textStorage appendAttributedString:enter];
    }

    NSMutableAttributedString* attributedMessage = NSMutableAttributedString.new;
    [attributedMessage appendAttributedString:self.dateTimeAttributedString];
    [attributedMessage appendAttributedString:message];

    [self.alertLogTextView.textStorage appendAttributedString:attributedMessage];
    [self flashScrollers];

    if (shouldScrollToBottom) {
        [self.alertLogTextView scrollToEndOfDocument:self];
    }
}

@end
