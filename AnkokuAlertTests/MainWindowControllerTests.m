//
//  MainWindowControllerTests.m
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 11/28/14.
//  Copyright (c) 2014 Hiroyuki Onishi. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "MainWindowController.h"

@interface MainWindowControllerTests : XCTestCase

@end

@implementation MainWindowControllerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/*
- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}
*/

- (MainWindowController *)instance
{
    return [[MainWindowController alloc] init];
}

- (void)testFirstMatchStringWithRegexpPattern
{
    NSString *matched = [[self instance] firstMatchStringWithRegexpPattern:@"(b.d)" inString:@"abcde"];
    XCTAssert([matched isEqualToString:@"bcd"], @"");
}

@end
