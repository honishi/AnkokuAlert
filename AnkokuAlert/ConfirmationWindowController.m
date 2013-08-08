//
//  ConfirmationWindowController.m
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 8/8/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import "ConfirmationWindowController.h"

@interface ConfirmationWindowController ()

@property (nonatomic, copy) ConfirmationCompletionBlock completion;

@end

@implementation ConfirmationWindowController

#pragma mark - Object Lifecycle

+(ConfirmationWindowController*)confirmationWindowControllerWithMessage:(NSString*)message
                                                             completion:(ConfirmationCompletionBlock)completion;
{
    ConfirmationWindowController* confirmationWindowController = [[ConfirmationWindowController alloc] initWithWindowNibName:@"ConfirmationWindowController"];

    if (confirmationWindowController) {
        confirmationWindowController.confirmationMessage = message;
        confirmationWindowController.completion = completion;
        confirmationWindowController.titleOfOkButton = @"OK";
        confirmationWindowController.titleOfCancelButton = @"Cancel";
    }

    return confirmationWindowController;
}

#pragma mark - Internal Methods

-(void)invokeCompletion:(BOOL)isCancelled
{
    if (self.completion) {
        self.completion(isCancelled);
        self.completion = nil;
    }
}

-(IBAction)okButtonPressed:(id)sender
{
    [self invokeCompletion:NO];
}

-(IBAction)cancelButtonPressed:(id)sender
{
    [self invokeCompletion:YES];
}

@end
