//
//  AnkokuAlertTests.m
//  AnkokuAlertTests
//
//  Created by Hiroyuki Onishi on 7/22/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import "AnkokuAlertTests.h"
#import "AlertManager.h"

@interface AnkokuAlertTests ()<AlertManagerDelegate>

@property (nonatomic, strong) AlertManager* alertManager;
@property (nonatomic, strong) NSString* email;
@property (nonatomic, strong) NSString* password;

@end

@implementation AnkokuAlertTests

-(void)setUp
{
    [super setUp];

    NSBundle* bundle = [NSBundle bundleForClass:[AnkokuAlertTests class]];
    NSString* path = [bundle pathForResource:@"TestAccount" ofType:@"plist"];
    NSDictionary* testAccount = [NSDictionary dictionaryWithContentsOfFile:path];
    self.email = testAccount[@"email"];
    self.password = testAccount[@"password"];

    self.alertManager = [[AlertManager alloc] initWithDelegate:self];
}

-(void)tearDown
{
    // Tear-down code here.

    [super tearDown];
}

-(void)testLoginToAnntena
{
    [self.alertManager openStreamWithEmail:self.email password:self.password];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10.0]];
    self.alertManager = nil;

}

#pragma mark - AlertManagerDelegate Methods

-(void)alertManager:(AlertManager*)alertManager didLoginToAntennaWithTicket:(NSString*)ticket
{
    NSLog(@"ticket: %@", ticket);
}

-(void)alertManager:(AlertManager*)alertManager didFailToLoginToAntennaWithError:(NSError*)error
{
}

-(void)alertManager:(AlertManager *)alertManager didGetAlertStatus:(NSDictionary *)alertStatus
{
    NSLog(@"alertStatus: %@", alertStatus);
}

-(void)alertManager:(AlertManager *)alertManager didFailToGetAlertStatusWithError:(NSError *)error
{
}

@end
