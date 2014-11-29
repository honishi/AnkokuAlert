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
NSString* const kUrlGetStreamInfo = @"http://live.nicovideo.jp/api/getstreaminfo/";
NSString* const kUrlLive = @"http://live.nicovideo.jp/watch/";
NSString* const kUrlCommunity = @"http://com.nicovideo.jp/community/";
NSString* const kUrlChannel = @"http://ch.nicovideo.jp/";

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

NSString* const AlertManagerStreamInfoKeyLiveId = @"AlertManagerStreamInfoKeyLiveId";
NSString* const AlertManagerStreamInfoKeyLiveName = @"AlertManagerStreamInfoKeyLiveName";
NSString* const AlertManagerStreamInfoKeyLiveUrl = @"AlertManagerStreamInfoKeyLiveUrl";
NSString* const AlertManagerStreamInfoKeyCommunityId = @"AlertManagerStreamInfoKeyCommunityId";
NSString* const AlertManagerStreamInfoKeyCommunityName = @"AlertManagerStreamInfoKeyCommunityName";
NSString* const AlertManagerStreamInfoKeyCommunityUrl = @"AlertManagerStreamInfoKeyCommunityUrl";

NSString* const AlertManagerCommunityInfoKeyCommunityName = @"AlertManagerCommunityInfoKeyCommunityName";

NSUInteger const kMaxInputStreamBufferSize = 10240;
NSUInteger const kMaxRecentLiveIdsCount = 100;

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
@property (nonatomic) NSInputStream* inputStream;
@property (nonatomic) NSOutputStream* outputStream;

@end

@implementation AlertManager

#pragma mark - Object Lifecycle

-(id)init
{
    self = [super init];

    if (self) {
        [self deleteAllCookies];
    }

    return self;
}

+(AlertManager*)sharedManager
{
    static AlertManager* sharedManager;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
            sharedManager = [[AlertManager alloc] init];
        });

    return sharedManager;
}

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

-(void)requestStreamInfoForLive:(NSString*)liveId completion:(StreamInfoCompletionBlock)completion
{
    // LOG(@"%@", liveId);

    NSURL* url = [NSURL URLWithString:[kUrlGetStreamInfo stringByAppendingString:liveId]];
    FakedMutableURLRequest* request = [FakedMutableURLRequest requestWithURL:url];

    asyncRequestCompletionBlock requestCompletion = ^(NSURLResponse* response, NSData* data, NSError* error) {
        if (error) {
            if (completion) {
                completion(nil, [NSError errorWithDomain:AlertManagerErrorDomain code:AlertManagerErrorCodeStreamInfoRequestFailed userInfo:nil]);
            }
        } else {
            // LOG(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            NSDictionary* streamInfo = [self parseStreamInfo:data];

            if (!streamInfo) {
                if (completion) {
                    completion(nil, [NSError errorWithDomain:AlertManagerErrorDomain code:AlertManagerErrorCodeStreamInfoParseFailed userInfo:nil]);
                }
            } else {
                if (completion) {
                    completion(streamInfo, nil);
                }
            }
        }
    };

    [NSURLConnection sendAsynchronousRequest:request queue:NSOperationQueue.mainQueue completionHandler:requestCompletion];
}

-(void)requestCommunityInfoForCommunity:(NSString*)communityId completion:(CommunityInfoCompletionBlock)completion
{
    NSURL* url = [NSURL URLWithString:[kUrlCommunity stringByAppendingString:communityId]];
    FakedMutableURLRequest* request = [FakedMutableURLRequest requestWithURL:url];

    asyncRequestCompletionBlock requestCompletion = ^(NSURLResponse* response, NSData* data, NSError* error) {
        if (error) {
            if (completion) {
                completion(nil, [NSError errorWithDomain:AlertManagerErrorDomain code:AlertManagerErrorCodeCommunityInfoRequestFailed userInfo:nil]);
            }
        } else {
            // LOG(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            NSDictionary* communityInfo = [self parseCommunityInfo:data];

            if (!communityInfo) {
                if (completion) {
                    completion(nil, [NSError errorWithDomain:AlertManagerErrorDomain code:AlertManagerErrorCodeCommunityInfoParseFailed userInfo:nil]);
                }
            } else {
                if (completion) {
                    completion(communityInfo, nil);
                }
            }
        }
    };

    [NSURLConnection sendAsynchronousRequest:request queue:NSOperationQueue.mainQueue completionHandler:requestCompletion];
}

+(NSString*)communityUrlStringWithCommunithId:(NSString*)communityId
{
    return [kUrlCommunity stringByAppendingString:communityId];
}

-(void)requestChannelCommunityIdForChannelName:(NSString*)channelName completion:(ChannelCommunityIdCompletionBlock)completion
{
    NSURL* url = [NSURL URLWithString:[kUrlChannel stringByAppendingString:channelName]];
    FakedMutableURLRequest* request = [FakedMutableURLRequest requestWithURL:url];

    asyncRequestCompletionBlock requestCompletion = ^(NSURLResponse* response, NSData* data, NSError* error) {
        if (error) {
            if (completion) {
                completion(nil, [NSError errorWithDomain:AlertManagerErrorDomain code:AlertManagerErrorCodeChannelCommunityIdRequestFailed userInfo:nil]);
            }
        } else {
            // LOG(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            NSString* communityId = [self parseChannelCommunityId:data];

            if (!communityId) {
                if (completion) {
                    completion(nil, [NSError errorWithDomain:AlertManagerErrorDomain code:AlertManagerErrorCodeChannelCommunityIdParseFailed userInfo:nil]);
                }
            } else {
                if (completion) {
                    completion(communityId, nil);
                }
            }
        }
    };

    [NSURLConnection sendAsynchronousRequest:request queue:NSOperationQueue.mainQueue completionHandler:requestCompletion];
}

#pragma mark - Internal Methods

-(void)deleteAllCookies
{
    NSHTTPCookieStorage* storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];

    for (NSHTTPCookie* cookie in [storage cookies]) {
        [storage deleteCookie:cookie];
    }

    [[NSUserDefaults standardUserDefaults] synchronize];
}

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
                    self.loginCompletionBlock(nil, [NSError errorWithDomain:AlertManagerErrorDomain code:AlertManagerErrorCodeLoginRequestFailed userInfo:nil]);
                    self.loginCompletionBlock = nil;
                }
            } else {
                [self getAlertStatusWithTicket:ticket];
            }
        }
    };

    [NSURLConnection sendAsynchronousRequest:request queue:NSOperationQueue.mainQueue completionHandler:requestCompletion];
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

    [NSURLConnection sendAsynchronousRequest:request queue:NSOperationQueue.mainQueue completionHandler:requestCompletion];
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

    return alertStatus;
}

#pragma mark Open Socket

-(void)openSocketWithAlertStatus:(NSDictionary*)alertStatus
{
    if (self.inputStream || self.outputStream) {
        [self closeSocket];
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
    if (!self.inputStream && !self.outputStream) {
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
                    if ([self.streamListener respondsToSelector:@selector(alertManagerDidOpenStream:)]) {
                        [self.streamListener alertManagerDidOpenStream:self];
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
                    [self handleChat:[self parseChat:data]];
                }
                break;
            }

            case NSStreamEventHasSpaceAvailable:
                // LOG(@"*** stream event has space available");
                break;

            case NSStreamEventErrorOccurred:
                LOG(@"*** stream event error occurred");
                [self closeSocket];
                break;

            case NSStreamEventEndEncountered:
                LOG(@"*** stream event end encountered");
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
        // check possible tcp fragmentation
        if (data) {
            LOG(@"tcp segmentation lost? : %@, %@",
                data,
                [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }
    } else {
        LOG(@"no data.");
    }
    // LOG(@"found %ld chunk(s)", chunks.count);

    return chunks;
}

-(NSArray*)parseChat:(NSData*)data
{
    NSArray* chatArray;

    @try {
        NSError* error = nil;
        NSXMLDocument* xml = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyXML error:&error];
        NSXMLNode* rootElement = xml.rootElement;
        NSArray* nodes = [rootElement nodesForXPath:@"/chat" error:&error];

        if (nodes.count) {
            NSString* chatString = ((NSXMLNode*)nodes[0]).stringValue;
            // LOG(@"parsed: %@", chatString);
            NSArray* chatsSeparated = [chatString componentsSeparatedByString:@","];

            if (chatsSeparated.count == 3) {
                NSString* liveId = [@"lv" stringByAppendingString : chatsSeparated[0]];
                chatArray = @[liveId, chatsSeparated[1], chatsSeparated[2]];
            }
        }
    }
    @catch (NSException* exception) {
        LOG(@"caught exception in parsing chat: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }

    return chatArray;
}

-(BOOL)isLiveIdDuplicated:(NSString*)liveId
{
    static NSMutableArray* recentLiveIds = nil;

    if (!recentLiveIds) {
        recentLiveIds = NSMutableArray.new;
    }

    BOOL isDuplicated = NO;
    for (NSString* pastliveId in recentLiveIds) {
        if ([liveId isEqualToString:pastliveId]) {
            isDuplicated = YES;
            break;
        }
    }

    [recentLiveIds addObject:liveId];
    if (kMaxRecentLiveIdsCount < recentLiveIds.count) {
        [recentLiveIds removeObjectAtIndex:0];
    }

    return isDuplicated;
}

-(void)handleChat:(NSArray*)chats
{
    if (!chats) {
        return;
    }

    if (![self isLiveIdDuplicated:chats[0]]) {
        if ([self.streamListener respondsToSelector:@selector(alertManager:didReceiveLive:community:user:url:)]) {
            NSString* url = [kUrlLive stringByAppendingString:chats[0]];
            [self.streamListener alertManager:self didReceiveLive:chats[0] community:chats[1] user:chats[2] url:url];
        }

    } else {
        // LOG(@"live is duplicated. liveId %@ is in %@.", liveId, recentLiveIds);
    }
}

#pragma mark Stream Info

-(NSDictionary*)parseStreamInfo:(NSData*)data
{
    NSDictionary* streamInfo;

    @try {
        NSError* error = nil;
        NSXMLDocument* xml = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyXML error:&error];
        NSXMLNode* rootElement = xml.rootElement;

        NSString* communityId = ((NSXMLNode*)[rootElement nodesForXPath:@"/getstreaminfo/streaminfo/default_community" error:&error][0]).stringValue;
        NSString* communityName = ((NSXMLNode*)[rootElement nodesForXPath:@"/getstreaminfo/communityinfo/name" error:&error][0]).stringValue;
        NSString* communityUrl = [kUrlCommunity stringByAppendingString:communityId];
        NSString* liveId = ((NSXMLNode*)[rootElement nodesForXPath:@"/getstreaminfo/request_id" error:&error][0]).stringValue;
        NSString* liveName = ((NSXMLNode*)[rootElement nodesForXPath:@"/getstreaminfo/streaminfo/title" error:&error][0]).stringValue;
        NSString* liveUrl = [kUrlLive stringByAppendingString:liveId];

        streamInfo = @{AlertManagerStreamInfoKeyLiveId: liveId,
                       AlertManagerStreamInfoKeyLiveName: liveName,
                       AlertManagerStreamInfoKeyLiveUrl: liveUrl,
                       AlertManagerStreamInfoKeyCommunityId: communityId,
                       AlertManagerStreamInfoKeyCommunityName: communityName,
                       AlertManagerStreamInfoKeyCommunityUrl: communityUrl};
    }
    @catch (NSException* exception) {
        LOG(@"caught exception in parsing stream info: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
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

        NSString* communityName = nil;
        NSArray* nodes = [rootElement nodesForXPath:@"//*[@id=\"community_name\"]" error:&error];
        if (nodes.count) {
            // open community case
            communityName = ((NSXMLNode*)nodes[0]).stringValue;
        } else {
            // closed/channel community case
            NSArray* titleNodes = [rootElement nodesForXPath:@"//*/title" error:&error];
            if (titleNodes.count) {
                NSRegularExpression* regexp = [NSRegularExpression regularExpressionWithPattern:@"(.+)-.*?" options:0 error:&error];
                NSString* title = ((NSXMLNode*)titleNodes[0]).stringValue;
                NSTextCheckingResult* result = [regexp firstMatchInString:title options:0 range:NSMakeRange(0, title.length)];
                communityName = [title substringWithRange:[result rangeAtIndex:1]];
            }
        }

        communityInfo = @{AlertManagerCommunityInfoKeyCommunityName: communityName};
    }
    @catch (NSException* exception) {
        // parse error, or not community member
        LOG(@"caught exception in parsing community info");
        // LOG(@"caught exception in parsing community info: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }

    return communityInfo;
}

#pragma mark Community Id from Channel Name

-(NSString*)parseChannelCommunityId:(NSData*)data
{
    NSString* communityId = nil;

    @try {
        NSError* error = nil;
        NSXMLDocument* xml = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyHTML error:&error];
        NSXMLNode* rootElement = xml.rootElement;

        NSString* found = nil;
        NSString* cleansed = nil;

        NSArray* nodes = [rootElement nodesForXPath:@"//*[@id=\"cp_symbol\"]/span/a/@href" error:&error];

        if (nodes.count) {
            found = ((NSXMLNode*)nodes[0]).stringValue;

            NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"\\/" options:0 error:nil];
            cleansed = [regex stringByReplacingMatchesInString:found options:0 range:NSMakeRange(0, found.length) withTemplate:@""];
        }

        communityId = cleansed;
    }
    @catch (NSException* exception) {
        // parse error
        LOG(@"caught exception in parsing channel community id");
        // LOG(@"caught exception in parsing channel community id: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }

    return communityId;
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
