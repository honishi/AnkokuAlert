//
//  ConfirmationWindowController.h
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 8/8/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void (^ ConfirmationCompletionBlock)(BOOL isCancelled);

@interface ConfirmationWindowController : NSWindowController

@property (nonatomic) NSString* confirmationMessage;
@property (nonatomic) NSString* titleOfOkButton;
@property (nonatomic) NSString* titleOfCancelButton;

+(ConfirmationWindowController*)confirmationWindowControllerWithMessage:(NSString*)message
                                                             completion:(ConfirmationCompletionBlock)completion;

@end
