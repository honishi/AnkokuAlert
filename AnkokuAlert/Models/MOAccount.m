#import "MOAccount.h"


@interface MOAccount ()

// Private interface goes here.

@end


@implementation MOAccount

// Custom logic goes here.

+(MOAccount*)defaultAccount
{
    for (MOAccount* account in [MOAccount findAll]) {
        if ([account.isDefault isEqualToNumber:[NSNumber numberWithBool:YES]]) {
            return account;
        }
    }

    return nil;
}

@end
