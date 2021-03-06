#import "MOAccount.h"
#import "MOCommunity.h"

NSUInteger const kDefaultRatingValue = 3;

@interface MOAccount ()

// Private interface goes here.

@end


@implementation MOAccount

// Custom logic goes here.

#pragma mark - Public Interface

+(MOAccount*)accountWithDefaultAttributes
{
    MOAccount* account = MOAccount.MR_createEntity;
    account.order = MOAccount.nextAccountOrder;

    return account;
}

+(MOAccount*)defaultAccount
{
    for (MOAccount* account in MOAccount.findAll) {
        if ([account.isDefault isEqualToNumber:[NSNumber numberWithBool:YES]]) {
            return account;
        }
    }

    return nil;
}

+(BOOL)hasAccounts
{
    return 0 < MOAccount.findAll.count;
}

-(MOCommunity*)communityWithDefaultAttributes
{
    MOCommunity* community = MOCommunity.MR_createEntity;
    community.order = self.nextCommunityOrder;
    community.isEnabled = [NSNumber numberWithBool:YES];
    community.rating = [NSNumber numberWithInteger:kDefaultRatingValue];

    return community;
}

#pragma mark - Internal Methods

#pragma mark Maintain Order Attribute

+(NSNumber*)nextAccountOrder
{
    NSInteger maxOrder = 0;

    for (MOAccount* account in MOAccount.findAll) {
        if (maxOrder < account.orderValue) {
            maxOrder = account.orderValue;
        }
    }

    return [NSNumber numberWithInteger:(maxOrder + 1)];
}

-(NSNumber*)nextCommunityOrder
{
    NSInteger maxOrder = 0;

    for (MOCommunity* community in self.communities) {
        if (maxOrder < community.orderValue) {
            maxOrder = community.orderValue;
        }
    }

    return [NSNumber numberWithInteger:(maxOrder + 1)];
}

-(void)prepareForDeletion
{
    for (MOAccount* account in MOAccount.findAll) {
        if ([self.order compare:account.order] == NSOrderedAscending) {
            account.order = [NSNumber numberWithInteger:(account.order.integerValue-1)];
        }
    }
}

@end
