//
//  AlertManager.m
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 7/25/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import "AlertManager.h"

NSString* const kUrlLoginToAntenna = @"https://secure.nicovideo.jp/secure/login?site=nicolive_antenna";
NSString* const kUrlGetAlertStatus = @"http://live.nicovideo.jp/api/getalertstatus?ticket=";
NSString* const kUrlGetStreamInfo = @"http://live.nicovideo.jp/api/getstreaminfo/lv";
NSString* const kUrlLive = @"http://live.nicovideo.jp/watch/";
NSString* const kUrlCommunity = @"http://com.nicovideo.jp/community/";

NSString* const kRequestHeaderUserAgent = @"NicoLiveAlert 1.2.0";
NSString* const kRequestHeaderReferer = @"app:/NicoLiveAlert.swf";
NSString* const kRequestHeaderFlashVer = @"10,3,181,23";

NSString* const AlertManagerErrorDomain = @"com.honishi.AnkokuAlert";

NSString* const AlertManagerAlertStatusKeyUserId = @"AlertManagerAlertStatusKeyUserId";
NSString* const AlertManagerAlertStatusKeyUserName = @"AlertManagerAlertStatusKeyUserName";
NSString* const AlertManagerAlertStatusKeyIsPremium = @"AlertManagerAlertStatusKeyIsPremium";
NSString* const AlertManagerAlertStatusKeyCommunities = @"AlertManagerAlertStatusKeyCommunities";
NSString* const AlertManagerAlertStatusServerAddressKey = @"AlertManagerAlertStatusKeyServerAddress";
NSString* const AlertManagerAlertStatusServerPortKey = @"AlertManagerAlertStatusKeyServerPort";
NSString* const AlertManagerAlertStatusServerThreadKey = @"AlertManagerAlertStatusKeyServerThread";

NSString* const AlertManagerStreamInfoKeyLive = @"AlertManagerStreamInfoKeyLive";
NSString* const AlertManagerStreamInfoKeyLiveTitle = @"AlertManagerStreamInfoKeyLiveTitle";
NSString* const AlertManagerStreamInfoKeyLiveUrl = @"AlertManagerStreamInfoKeyLiveUrl";
NSString* const AlertManagerStreamInfoKeyCommunity = @"AlertManagerStreamInfoKeyCommunity";
NSString* const AlertManagerStreamInfoKeyCommunityName = @"AlertManagerStreamInfoKeyCommunityName";
NSString* const AlertManagerStreamInfoKeyCommunityUrl = @"AlertManagerStreamInfoKeyCommunityUrl";

NSString* const AlertManagerCommunityInfoKeyCommunityName = @"AlertManagerCommunityInfoKeyCommunityName";

NSUInteger const kMaxInputStreamBufferSize = 10240;

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

@interface AlertManager ()<NSStreamDelegate>

@property (nonatomic, copy) LoginCompletionBlock loginCompletionBlock;
@property (nonatomic, weak) id<AlertManagerStreamListener> streamListener;
@property (nonatomic, strong) NSInputStream* inputStream;
@property (nonatomic, strong) NSOutputStream* outputStream;

@end

@implementation AlertManager

#pragma mark - Object Lifecycle

+(AlertManager*)sharedManager
{
    static AlertManager* sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
            sharedManager = [[AlertManager alloc] init];
        });
    return sharedManager;
}

#pragma mark - Property Methods
#pragma mark - [ClassName] Overrides
#pragma mark - [ProtocolName] Methods
#pragma mark - Public Interface

-(void)loginWithEmail:(NSString*)email
             password:(NSString*)password
           completion:(LoginCompletionBlock)completion;
{
    if (self.loginCompletionBlock) {
        return;
    }
    self.loginCompletionBlock = completion;

    [self loginToAntennaWithEmail:email password:password];
}

-(void)openStreamWithAlertStatus:(NSDictionary*)alertStatus
                  streamListener:(id<AlertManagerStreamListener>)streamListener;
{
    self.streamListener = streamListener;
    [self openSocketWithAlertStatus:alertStatus];
    NSString* thread = [NSString stringWithFormat:@"<thread thread=\"%@\" version=\"20061206\" res_from=\"-1\"/>",
                        alertStatus[AlertManagerAlertStatusServerThreadKey]];
    [self sendStringToOutputStream:thread];
}

-(void)closeStream
{
    [self closeSocket];
}

-(void)streamInfoForLive:(NSString*)live completion:(StreamInfoCompletionBlock)completion
{
    NSURL* url = [NSURL URLWithString:[kUrlGetStreamInfo stringByAppendingString:live]];
    FakedMutableURLRequest* request = [FakedMutableURLRequest requestWithURL:url];

    asyncRequestCompletionBlock requestCompletion = ^(NSURLResponse* response, NSData* data, NSError* error) {
        if (error) {
            if (completion) {
                completion(nil,
                    [NSError errorWithDomain:AlertManagerErrorDomain
                                        code:AlertManagerErrorCodeStreamInfoFailed
                                    userInfo:nil]);
            }
        } else {
            // LOG(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            NSDictionary* streamInfo = [self parseStreamInfo:data];

            if (completion) {
                completion(streamInfo, nil);
            }
        }
    };

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:NSOperationQueue.mainQueue
                           completionHandler:requestCompletion];
}

-(void)communityInfoForCommunity:(NSString*)community completion:(CommunityInfoCompletionBlock)completion
{
    NSURL* url = [NSURL URLWithString:[kUrlCommunity stringByAppendingString:community]];
    FakedMutableURLRequest* request = [FakedMutableURLRequest requestWithURL:url];

    asyncRequestCompletionBlock requestCompletion = ^(NSURLResponse* response, NSData* data, NSError* error) {
        if (error) {
            if (completion) {
                completion(nil,
                    [NSError errorWithDomain:AlertManagerErrorDomain
                                        code:AlertManagerErrorCodeCommunityInfoFailed
                                    userInfo:nil]);
            }
        } else {
            // LOG(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            NSDictionary* communityInfo = [self parseCommunityInfo:data];

            if (completion) {
                completion(communityInfo, nil);
            }
        }
    };

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:NSOperationQueue.mainQueue
                           completionHandler:requestCompletion];
}

#pragma mark - Internal Methods

#pragma mark Login to Antenna

-(void)loginToAntennaWithEmail:(NSString*)email password:(NSString*)password
{
    NSURL* url = [NSURL URLWithString:kUrlLoginToAntenna];
    FakedMutableURLRequest* request = [FakedMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];

    NSString* encodedEmail = [AlertManager urlencode:email];
    NSString* encodedPassword = [AlertManager urlencode:password];
    NSString* body = [NSString stringWithFormat:@"mail=%@&password=%@", encodedEmail, encodedPassword];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];

    asyncRequestCompletionBlock requestCompletion = ^(NSURLResponse* response, NSData* data, NSError* error) {
        if (error) {
            if (self.loginCompletionBlock) {
                self.loginCompletionBlock(nil, error);
                self.loginCompletionBlock = nil;
            }
        } else {
            // LOG(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            NSString* ticket = [self parseTicket:data];
            if (!ticket) {
                if (self.loginCompletionBlock) {
                    self.loginCompletionBlock(nil,
                        [NSError errorWithDomain:AlertManagerErrorDomain
                                            code:AlertManagerErrorCodeLoginFailed
                                        userInfo:nil]);
                    self.loginCompletionBlock = nil;
                }
            } else {
                [self getAlertStatusWithTicket:ticket];
            }
        }
    };

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:NSOperationQueue.mainQueue
                           completionHandler:requestCompletion];
}

-(NSString*)parseTicket:(NSData*)data
{
    NSString* ticket = nil;

    @try {
        NSError* error = nil;
        NSXMLDocument* xml = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyXML error:&error];
        NSXMLNode* rootElement = xml.rootElement;

        NSArray* nodes = [rootElement nodesForXPath:@"/nicovideo_user_response/ticket" error:&error];

        if( nodes.count ) {
            ticket = ((NSXMLNode*)nodes[0]).stringValue;
            LOG(@"ticket: %@", ticket);
        } else {
            LOG(@"ticket not found.");
        }
    }
    @catch (NSException* exception) {
        LOG(@"caught exception in parsing ticket: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }
    @finally {
        // do nothing
    }

    return ticket;
}

#pragma mark Get Alert Status

-(void)getAlertStatusWithTicket:(NSString*)ticket
{
    NSURL* url = [NSURL URLWithString:[kUrlGetAlertStatus stringByAppendingString:ticket]];
    FakedMutableURLRequest* request = [FakedMutableURLRequest requestWithURL:url];

    asyncRequestCompletionBlock requestCompletion = ^(NSURLResponse* response, NSData* data, NSError* error) {
        if (error) {
            if (self.loginCompletionBlock) {
                self.loginCompletionBlock(nil, error);
            }
        } else {
            // LOG(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            NSDictionary* alertStatus = [self parseAlertStatus:data];

            if (self.loginCompletionBlock) {
                self.loginCompletionBlock(alertStatus.copy, nil);
            }
        }
        self.loginCompletionBlock = nil;
    };

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:NSOperationQueue.mainQueue
                           completionHandler:requestCompletion];
}

-(NSDictionary*)parseAlertStatus:(NSData*)data
{
    NSDictionary* alertStatus;

    @try {
        NSError* error = nil;
        NSXMLDocument* xml = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyXML error:&error];
        NSXMLNode* rootElement = xml.rootElement;

        NSString* userId = ((NSXMLNode*)[rootElement nodesForXPath:@"/getalertstatus/user_id" error:&error][0]).stringValue;
        NSString* userName = ((NSXMLNode*)[rootElement nodesForXPath:@"/getalertstatus/user_name" error:&error][0]).stringValue;
        BOOL isPremium = [rootElement nodesForXPath:@"/getalertstatus/is_premium" error:&error].count ? YES : NO;

        NSMutableArray* communities = NSMutableArray.new;
        for (NSXMLNode* node in [rootElement nodesForXPath : @"/getalertstatus/communities/community_id" error : &error]) {
            [communities addObject:node.stringValue];
        }

        NSString* serverAddress = ((NSXMLNode*)[rootElement nodesForXPath:@"/getalertstatus/ms/addr" error:&error][0]).stringValue;
        NSString* serverPort = ((NSXMLNode*)[rootElement nodesForXPath:@"/getalertstatus/ms/port" error:&error][0]).stringValue;
        NSString* serverThread = ((NSXMLNode*)[rootElement nodesForXPath:@"/getalertstatus/ms/thread" error:&error][0]).stringValue;

        alertStatus = @{AlertManagerAlertStatusKeyUserId: userId,
                        AlertManagerAlertStatusKeyUserName: userName,
                        AlertManagerAlertStatusKeyIsPremium:[NSNumber numberWithBool:isPremium],
                        AlertManagerAlertStatusKeyCommunities:communities,
                        AlertManagerAlertStatusServerAddressKey:serverAddress,
                        AlertManagerAlertStatusServerPortKey:serverPort,
                        AlertManagerAlertStatusServerThreadKey:serverThread};
    }
    @catch (NSException* exception) {
        LOG(@"caught exception in parsing alert status: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }
    @finally {
        // do nothing
    }

    return alertStatus;
}

#pragma mark Open Socket

-(void)openSocketWithAlertStatus:(NSDictionary*)alertStatus
{
    if (self.inputStream && self.outputStream) {
        return;
    }

    NSInputStream* inputStream;
    NSOutputStream* outputStream;

    [NSStream getStreamsToHost:[NSHost hostWithName:alertStatus[AlertManagerAlertStatusServerAddressKey]]
                          port:((NSString*)alertStatus[AlertManagerAlertStatusServerPortKey]).intValue
                   inputStream:&inputStream
                  outputStream:&outputStream];

    self.inputStream = inputStream;
    self.outputStream = outputStream;

    [self.inputStream setDelegate:self];
    [self.outputStream setDelegate:self];

    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    [self.inputStream open];
    [self.outputStream open];
}

-(void)closeSocket
{
    if (!self.inputStream || !self.outputStream) {
        return;
    }

    [self.inputStream close];
    [self.outputStream close];
    self.inputStream = nil;
    self.outputStream = nil;

    if ([self.streamListener respondsToSelector:@selector(alertManagerDidCloseStream:)]) {
        [self.streamListener alertManagerDidCloseStream:self];
    }
}

-(void)sendStringToOutputStream:(NSString*)string
{
    if (!self.outputStream) {
        return;
    }

    // Note: We need to send '\0' at the very last of the string. Following '+1' is trick to do it.
    const uint8_t* rawstring = (const uint8_t*)[string UTF8String];
    [self.outputStream write:rawstring maxLength:strlen((char*)rawstring)+1];
}

-(void)stream:(NSStream*)stream handleEvent:(NSStreamEvent)eventCode
{
    @autoreleasepool {
        switch(eventCode) {
            case NSStreamEventNone:
                LOG(@"*** stream event none");
                break;

            case NSStreamEventOpenCompleted:
                LOG(@"*** stream event open completed");
                if (stream == self.inputStream) {
                    if ([self.streamListener respondsToSelector:@selector(alertManagerdidOpenStream:)]) {
                        [self.streamListener alertManagerdidOpenStream:self];
                    }
                }
                break;

            case NSStreamEventHasBytesAvailable:
            {
                // LOG(@"*** stream event has bytes available");
                NSArray* chunks = [self chunksFromInputStream:(NSInputStream*)stream];

                for (NSData* data in chunks) {
                    // LOG(@"data: %@", data);
                    // LOG(@"string: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                    NSArray* live = [self parseChat:data];

                    if (live) {
                        if ([self.streamListener respondsToSelector:@selector(alertManager:didReceiveLive:community:user:)]) {
                            [self.streamListener alertManager:self didReceiveLive:live[0] community:live[1] user:live[2]];
                        }
                    }
                }
                break;
            }

            case NSStreamEventHasSpaceAvailable:
                LOG(@"*** stream event has space available");
                break;

            case NSStreamEventErrorOccurred:
                LOG(@"*** stream event error occurred");
                break;

            case NSStreamEventEndEncountered:
                LOG(@"*** stream event end encountered");
                if ([self.streamListener respondsToSelector:@selector(alertManagerDidCloseStream:)]) {
                    [self.streamListener alertManagerDidCloseStream:self];
                }
                break;

            default:
                LOG(@"*** unexpected stream event...");
        }
    }
}

-(NSArray*)chunksFromInputStream:(NSInputStream*)inputStream
{
    uint8_t buffer[kMaxInputStreamBufferSize];
    NSUInteger readLength = 0;
    readLength = [inputStream read:buffer maxLength:kMaxInputStreamBufferSize];
    // LOG(@"readLength: %ld", readLength);

    if ( !(0 < readLength && readLength < 5000) ) {
        LOG(@"abnormal data detected, length: %ld", readLength);
    }

    NSMutableArray* chunks = nil;
    if (readLength) {
        chunks = NSMutableArray.new;
        NSMutableData* data = nil;
        NSUInteger p = 0;
        while ( p < readLength ) {
            if (!data) {
                data = NSMutableData.new;
            }
            if (buffer[p] != 0) {
                [data appendBytes:(const void*)(buffer+p) length:1];
            } else {
                [chunks addObject:data];
                data = nil;
            }
            p++;
        }
        // check tcp fragmentation
        if (data) {
            LOG(@"tcp segmentation lost? : %@", data);
        }
    } else {
        LOG(@"no data.");
    }
    // LOG(@"found %ld chunk(s)", chunks.count);

    return chunks;
}

-(NSArray*)parseChat:(NSData*)data
{
    NSArray* liveArray;

    @try {
        NSError* error = nil;
        NSXMLDocument* xml = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyXML error:&error];
        NSXMLNode* rootElement = xml.rootElement;
        NSArray* nodes = [rootElement nodesForXPath:@"/chat" error:&error];

        if (nodes.count) {
            NSString* liveString = ((NSXMLNode*)nodes[0]).stringValue;
            // LOG(@"parsed: %@", liveString);
            liveArray = [liveString componentsSeparatedByString:@","];
        }
    }
    @catch (NSException* exception) {
        LOG(@"caught exception in parsing chat: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }
    @finally {
        // do nothing
    }

    return (liveArray.count == 3 ? liveArray : nil);
}

#pragma mark Stream Info

-(NSDictionary*)parseStreamInfo:(NSData*)data
{
    NSDictionary* streamInfo;

    @try {
        NSError* error = nil;
        NSXMLDocument* xml = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyXML error:&error];
        NSXMLNode* rootElement = xml.rootElement;

        NSString* community = ((NSXMLNode*)[rootElement nodesForXPath:@"/getstreaminfo/streaminfo/default_community" error:&error][0]).stringValue;
        NSString* communityName = ((NSXMLNode*)[rootElement nodesForXPath:@"/getstreaminfo/communityinfo/name" error:&error][0]).stringValue;
        NSString* communityUrl = [kUrlCommunity stringByAppendingString:community];
        NSString* live = ((NSXMLNode*)[rootElement nodesForXPath:@"/getstreaminfo/request_id" error:&error][0]).stringValue;
        NSString* liveTitle = ((NSXMLNode*)[rootElement nodesForXPath:@"/getstreaminfo/streaminfo/title" error:&error][0]).stringValue;
        NSString* liveUrl = [kUrlLive stringByAppendingString:live];

        streamInfo = @{AlertManagerStreamInfoKeyLive: live,
                       AlertManagerStreamInfoKeyLiveTitle: liveTitle,
                       AlertManagerStreamInfoKeyLiveUrl: liveUrl,
                       AlertManagerStreamInfoKeyCommunity: community,
                       AlertManagerStreamInfoKeyCommunityName: communityName,
                       AlertManagerStreamInfoKeyCommunityUrl: communityUrl};
    }
    @catch (NSException* exception) {
        LOG(@"caught exception in parsing stream info: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }
    @finally {
        // do nothing
    }

    return streamInfo;
}

#pragma mark Community Info

-(NSDictionary*)parseCommunityInfo:(NSData*)data
{
    NSDictionary* communityInfo;

    @try {
        NSError* error = nil;
        NSXMLDocument* xml = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyXML error:&error];
        NSXMLNode* rootElement = xml.rootElement;

        NSString* communityName = ((NSXMLNode*)[rootElement nodesForXPath:@"//*[@id=\"community_name\"]" error:&error][0]).stringValue;

        communityInfo = @{AlertManagerCommunityInfoKeyCommunityName: communityName};
    }
    @catch (NSException* exception) {
        // parse error, or not community member
        LOG(@"caught exception in parsing community info");
        // LOG(@"caught exception in parsing community info: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }
    @finally {
        // do nothing
    }

    return communityInfo;
}

#pragma mark Encoding/Decoding Utility

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
