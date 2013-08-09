//
//  NSString+CompareCommunityId.h
//  AnkokuAlert
//
//  Created by Hiroyuki Onishi on 8/9/13.
//  Copyright (c) 2013 Hiroyuki Onishi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (CompareCommunityId)

+(NSNumber*)extractCommunityNumberFromCommunityId:(NSString*)communityId;
-(NSComparisonResult)compareAsCommunityId:(NSString*)string;

@end
