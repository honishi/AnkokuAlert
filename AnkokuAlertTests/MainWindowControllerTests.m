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

-(void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

-(void)tearDown
{
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

-(MainWindowController*)instance
{
    return [[MainWindowController alloc] init];
}

-(void)testFirstMatchStringWithRegexpPattern
{
    [self examinePattern:@"(b.d)" inString:@"abcde" expected:@"bcd"];

    [self examinePattern:@".*(lv\\d+)" inString:@"http://live.nicovideo.jp/watch/lv201600109" expected:@"lv201600109"];
    [self examinePattern:@".*(lv\\d+)" inString:@"lv201600109" expected:@"lv201600109"];

    [self examinePattern:@".*(co\\d+)" inString:@"http://com.nicovideo.jp/community/co105127" expected:@"co105127"];
    [self examinePattern:@".*(co\\d+)" inString:@"co105127" expected:@"co105127"];

    [self examinePattern:@"https?:\\/\\/ch\\..+\\/([ -~]{4,})" inString:@"http://ch.nicovideo.jp/noriradi" expected:@"noriradi"];
    // [self examinePattern:@"([ -~]{4,})" inString:@"noriradi" expected:@"noriradi"];
}

-(void)examinePattern:(NSString*)pattern inString:(NSString*)inString expected:(NSString*)expected
{
    NSString* matched = [[self instance] firstMatchStringWithRegexpPattern:pattern inString:inString];
    XCTAssert([matched isEqualToString:expected], @"");
    NSLog(@"pattern[%@],string[%@],expected[%@],matched[%@]", pattern, inString, expected, matched);
}

@end
