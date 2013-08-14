//
//  AlertLogScrollView.h
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 8/10/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AlertLogScrollView : NSScrollView

-(void)logMessage:(NSString*)message;
-(void)logLiveWithLiveName:(NSString*)liveName liveUrl:(NSString*)liveUrl communityName:(NSString*)communityName communityUrl:(NSString*)communityUrl;
-(void)clearLog;

@end
