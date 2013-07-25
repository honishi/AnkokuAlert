//
//  AlertManager.m
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 7/25/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import "AlertManager.h"

NSString* const kUrlLoginToAntenna = @"https://secure.nicovideo.jp/secure/login?site=nicolive_antenna";

//NSString* const kUrlAlertStatus = @"http://live.nicovideo.jp/api/getalertstatus?ticket=";
//NSString* const kUrlStreamInfo = @"http://live.nicovideo.jp/api/getstreaminfo/";
//NSString* const kUrlLive = @"http://live.nicovideo.jp/watch/";
//NSString* const kUrlCommunity =@"http://com.nicovideo.jp/community/";

NSString* const kRequestHeaderUserAgent = @"NicoLiveAlert 1.2.0";
NSString* const kRequestHeaderReferer = @"app:/NicoLiveAlert.swf";
NSString* const kRequestHeaderFlashVer = @"10,3,181,23";

typedef void (^ asyncRequestCompletionBlock)(NSURLResponse* response, NSData* data, NSError* error);

@interface FakedMutableURLRequest : NSMutableURLRequest

@end

@implementation FakedMutableURLRequest

-(id)initWithURL:(NSURL*)URL
{
    self = [super initWithURL:URL];

    if (self) {
        [self setValue:kRequestHeaderUserAgent forHTTPHeaderField:@"User-Agent"];
        [self setValue:kRequestHeaderReferer forHTTPHeaderField:@"Referer"];
        [self setValue:kRequestHeaderFlashVer forHTTPHeaderField:@"X-Flash-Version"];
    }

    return self;
}

@end

@interface AlertManager ()

@property (nonatomic, weak) id<AlertManagerDelegate> delegate;

@end

@implementation AlertManager

#pragma mark - Object Lifecycle

-(id)initWithDelegate:(id<AlertManagerDelegate>)delegate
{
    self = [super init];

    if (self != nil) {
        self.delegate = delegate;
    }

    return self;
}

#pragma mark - Property Methods
#pragma mark - [ClassName] Overrides
#pragma mark - [ProtocolName] Methods
#pragma mark - Public Interface

-(void)loginToAntennaWithEmail:(NSString*)email password:(NSString*)password
{
    NSURL* url = [NSURL URLWithString:kUrlLoginToAntenna];
    FakedMutableURLRequest* request = [FakedMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];

    NSString* encodedEmail = [AlertManager urlencode:email];
    NSString* encodedPassword = [AlertManager urlencode:password];
    NSString* body = [NSString stringWithFormat:@"mail=%@&password=%@", encodedEmail, encodedPassword];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];

    asyncRequestCompletionBlock completion = ^(NSURLResponse* response, NSData* data, NSError* error) {
        if (error) {
            if ([self.delegate respondsToSelector:@selector(AlertManagerDidFailToLoginToAntennaWithError:)]) {
                [self.delegate AlertManagerDidFailToLoginToAntennaWithError:error];
            }
        } else {
            LOG(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            NSString* ticket = [self parseTicket:data];

            if ([self.delegate respondsToSelector:@selector(AlertManagerDidLoginToAntennaWithTicket:)]) {
                [self.delegate AlertManagerDidLoginToAntennaWithTicket:ticket];
            }
        }
    };

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:NSOperationQueue.mainQueue
                           completionHandler:completion];
}

#pragma mark - Internal Methods

#pragma mark xpath utility

-(NSString*)parseTicket:(NSData*)data
{
    NSError* error = nil;
    NSXMLDocument* xml = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyXML error:&error];
    NSXMLNode* rootElement = xml.rootElement;

    NSString* ticket = nil;
    NSArray* nodes = [rootElement nodesForXPath:@"/nicovideo_user_response/ticket" error:&error];

    if( nodes.count ) {
        ticket = ((NSXMLNode*)nodes[0]).stringValue;
        LOG(@"ticket: %@", ticket);
    } else {
        LOG(@"ticket not found.");
    }

    return ticket;
}

#pragma mark encoding/decoding utility

+(NSString*)urlencode:(NSString*)plainString
{
    return (__bridge_transfer NSString*)CFURLCreateStringByAddingPercentEscapes(NULL,
        (__bridge CFStringRef)plainString,
        NULL,
        (CFStringRef)@"!*'();:@&=+$,/?%#[]",
        kCFStringEncodingUTF8);
}

+(NSString*)urldecode:(NSString*)escapedUrlString
{
    return (__bridge_transfer NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
        (__bridge CFStringRef)escapedUrlString,
        CFSTR(""),
        kCFStringEncodingUTF8);
}

@end
