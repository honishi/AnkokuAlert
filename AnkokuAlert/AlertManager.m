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

//NSString* const kUrlGetStreamInfo = @"http://live.nicovideo.jp/api/getstreaminfo/";
//NSString* const kUrlLive = @"http://live.nicovideo.jp/watch/";
//NSString* const kUrlCommunity =@"http://com.nicovideo.jp/community/";

NSString* const kRequestHeaderUserAgent = @"NicoLiveAlert 1.2.0";
NSString* const kRequestHeaderReferer = @"app:/NicoLiveAlert.swf";
NSString* const kRequestHeaderFlashVer = @"10,3,181,23";

NSString* const AlertManagerErrorDomain = @"com.honishi.AnkokuAlert";

NSString* const AlertManagerAlertStatusUserNameKey = @"AlertManagerAlertStatusUserNameKey";
NSString* const AlertManagerAlertStatusIsPremiumKey = @"AlertManagerAlertStatusIsPremiumKey";
NSString* const AlertManagerAlertStatusCommunitiesKey = @"AlertManagerAlertStatusCommunitiesKey";
NSString* const AlertManagerAlertStatusServerAddressKey = @"AlertManagerAlertStatusServerAddressKey";
NSString* const AlertManagerAlertStatusServerPortKey = @"AlertManagerAlertStatusServerPortKey";
NSString* const AlertManagerAlertStatusServerThreadKey = @"AlertManagerAlertStatusServerThreadKey";

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

    asyncRequestCompletionBlock completion = ^(NSURLResponse* response, NSData* data, NSError* error) {
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
                           completionHandler:completion];
}

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

#pragma mark Get Alert Status

-(void)getAlertStatusWithTicket:(NSString*)ticket
{
    NSURL* url = [NSURL URLWithString:[kUrlGetAlertStatus stringByAppendingString:ticket]];
    FakedMutableURLRequest* request = [FakedMutableURLRequest requestWithURL:url];

    asyncRequestCompletionBlock completion = ^(NSURLResponse* response, NSData* data, NSError* error) {
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
                           completionHandler:completion];
}

-(NSDictionary*)parseAlertStatus:(NSData*)data
{
    NSError* error = nil;
    NSXMLDocument* xml = [[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyXML error:&error];
    NSXMLNode* rootElement = xml.rootElement;

    NSString* userName = ((NSXMLNode*)[rootElement nodesForXPath:@"/getalertstatus/user_name" error:&error][0]).stringValue;
    BOOL isPremium = [rootElement nodesForXPath:@"/getalertstatus/is_premium" error:&error].count ? YES : NO;

    NSMutableArray* communities = NSMutableArray.new;
    for (NSXMLNode* node in [rootElement nodesForXPath : @"/getalertstatus/communities/community_id" error : &error]) {
        [communities addObject:node.stringValue];
    }

    NSString* serverAddress = ((NSXMLNode*)[rootElement nodesForXPath:@"/getalertstatus/ms/addr" error:&error][0]).stringValue;
    NSString* serverPort = ((NSXMLNode*)[rootElement nodesForXPath:@"/getalertstatus/ms/port" error:&error][0]).stringValue;
    NSString* serverThread = ((NSXMLNode*)[rootElement nodesForXPath:@"/getalertstatus/ms/thread" error:&error][0]).stringValue;

    return @{AlertManagerAlertStatusUserNameKey: userName,
             AlertManagerAlertStatusIsPremiumKey:[NSNumber numberWithBool:isPremium],
             AlertManagerAlertStatusCommunitiesKey:communities,
             AlertManagerAlertStatusServerAddressKey:serverAddress,
             AlertManagerAlertStatusServerPortKey:serverPort,
             AlertManagerAlertStatusServerThreadKey:serverThread};
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
                LOG(@"stream event none");
                break;

            case NSStreamEventOpenCompleted:
                LOG(@"stream event open completed");
                if (stream == self.inputStream) {
                    if ([self.streamListener respondsToSelector:@selector(alertManagerdidOpenStream:)]) {
                        [self.streamListener alertManagerdidOpenStream:self];
                    }
                }
                break;

            case NSStreamEventHasBytesAvailable:
            {
                // LOG(@"stream event has bytes available");
                NSMutableData* data = [[NSMutableData alloc] init];

                uint8_t buf[10240];
                unsigned long len = 0;
                len = [(NSInputStream*)stream read : buf maxLength : 10240];

                // test code
                if ( !(0 < len && len < 5000) ) LOG(@"abnormal data detected, length: %ld (bytes)", len);

                if(len) {
                    [data appendBytes:(const void*)buf length:len];
                } else {
                    LOG(@"No data.");
                }

                // LOG(@"inputstream length: %ld mutabledata length: %ld", len, [data length]);

                //
                LOG(@"received: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
//                NSArray* entries = [self splitReceivedData:data];
//
//                for( NSString* str in entries ){
//                    // LOG(@"received text: %@", str);
//                    [self checkNewLive:str];
//                }

                data = nil;

                break;
            }

            case NSStreamEventHasSpaceAvailable:
                LOG(@"stream event has space available");
                break;

            case NSStreamEventErrorOccurred:
                LOG(@"stream event error occurred");

//                NSString *message = [[[NSString alloc] initWithFormat:NSLocalizedString(@"ConnectionLost", nil)] autorelease];
//                LOG(@"%@", message);
//                [mainMenuController_ printLog:message withDate:NO withEnter:YES];

                // reconnect
//                [self kickReconnectTimer];

                break;

            case NSStreamEventEndEncountered:
                LOG(@"stream event end encountered");
                break;

            default:
                LOG(@"unexpected stream event...");
        }
    }
}

#pragma mark Get Stream Info

// TODO: implementation

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
