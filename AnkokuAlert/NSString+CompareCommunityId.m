//
//  NSString+CompareCommunityId.m
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 8/9/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import "NSString+CompareCommunityId.h"

@implementation NSString (CompareCommunityId)

+(NSNumber*)extractCommunityNumberFromCommunityId:(NSString*)communityId
{
    NSError* error = nil;
    NSRegularExpression* communityNumberRegexp = [NSRegularExpression regularExpressionWithPattern:@"co(.+)" options:0 error:&error];

    NSTextCheckingResult* match = [communityNumberRegexp firstMatchInString:communityId options:0 range:NSMakeRange(0, communityId.length)];
    NSString* communityNumber = [communityId substringWithRange:[match rangeAtIndex:1]];

    return [NSNumber numberWithInteger:communityNumber.integerValue];
}

-(NSComparisonResult)compareAsCommunityId:(NSString*)string
{
    NSNumber* selfNumber = [NSString extractCommunityNumberFromCommunityId:self];
    NSNumber* otherNumber = [NSString extractCommunityNumberFromCommunityId:string];

    NSComparisonResult result = NSOrderedSame;
    if (selfNumber && otherNumber) {
        result = [selfNumber compare:otherNumber];
    } else {
        result = [self compare:string];
    }

    return result;
}

@end
