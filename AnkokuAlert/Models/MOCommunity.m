#import "MOCommunity.h"
#import "MOAccount.h"

@interface MOCommunity ()

// Private interface goes here.

@end


@implementation MOCommunity

// Custom logic goes here.

#pragma mark - Internal Methods

#pragma mark Maintain Order Attribute

-(void)prepareForDeletion
{
    MOAccount* account = self.account;

    for (MOCommunity* community in account.communities) {
        if ([self.order compare:community.order] == NSOrderedAscending) {
            community.order = [NSNumber numberWithInteger:(community.order.integerValue-1)];
        }
    }
}

@end
