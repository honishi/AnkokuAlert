#import "MOCommunity.h"
#import "MOAccount.h"

@interface MOCommunity ()

// Private interface goes here.

@end


@implementation MOCommunity

// Custom logic goes here.

#pragma mark - Public Methods

-(void)exchangeCommunityWithCommunity:(MOCommunity*)community
{
    NSString* workCommunityId = community.communityId;
    NSString* workCommunityName = community.communityName;
    NSNumber* workIsEnabled = community.isEnabled;
    NSNumber* workRating = community.rating;

    community.communityId = self.communityId;
    community.communityName = self.communityName;
    community.isEnabled = self.isEnabled;
    community.rating = self.rating;

    self.communityId = workCommunityId;
    self.communityName = workCommunityName;
    self.isEnabled = workIsEnabled;
    self.rating = workRating;
}

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
