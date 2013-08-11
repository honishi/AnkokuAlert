#import "_MOAccount.h"

@interface MOAccount : _MOAccount {}

// Custom logic goes here.
+(MOAccount*)accountWithDefaultAttributes;
+(MOAccount*)defaultAccount;
+(BOOL)hasAccounts;
-(MOCommunity*)communityWithDefaultAttributes;

@end
