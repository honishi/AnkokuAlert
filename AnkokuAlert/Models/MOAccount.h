#import "_MOAccount.h"

@interface MOAccount : _MOAccount {}

// Custom logic goes here.
+(MOAccount*)accountWithNumberedOrderAttribute;
+(MOAccount*)defaultAccount;
+(BOOL)hasAccounts;
-(MOCommunity*)communityWithNumberedOrderAttribute;

@end
