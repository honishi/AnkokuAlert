// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MOAccount.m instead.

#import "_MOAccount.h"

const struct MOAccountAttributes MOAccountAttributes = {
    .displayOrder = @"displayOrder",
    .email = @"email",
    .isDefault = @"isDefault",
    .userId = @"userId",
    .userName = @"userName",
};

const struct MOAccountRelationships MOAccountRelationships = {
    .communities = @"communities",
};

const struct MOAccountFetchedProperties MOAccountFetchedProperties = {
};

@implementation MOAccountID
@end

@implementation _MOAccount

+(id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_
{
    NSParameterAssert(moc_);
    return [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:moc_];
}

+(NSString*)entityName
{
    return @"Account";
}

+(NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_
{
    NSParameterAssert(moc_);
    return [NSEntityDescription entityForName:@"Account" inManagedObjectContext:moc_];
}

-(MOAccountID*)objectID
{
    return (MOAccountID*)[super objectID];
}

+(NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key
{
    NSSet* keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

    if ([key isEqualToString:@"displayOrderValue"]) {
        NSSet* affectingKey = [NSSet setWithObject:@"displayOrder"];
        keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
        return keyPaths;
    }
    if ([key isEqualToString:@"isDefaultValue"]) {
        NSSet* affectingKey = [NSSet setWithObject:@"isDefault"];
        keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
        return keyPaths;
    }

    return keyPaths;
}




@dynamic displayOrder;



-(int32_t)displayOrderValue
{
    NSNumber* result = [self displayOrder];
    return [result intValue];
}

-(void)setDisplayOrderValue:(int32_t)value_
{
    [self setDisplayOrder:[NSNumber numberWithInt:value_]];
}

-(int32_t)primitiveDisplayOrderValue
{
    NSNumber* result = [self primitiveDisplayOrder];
    return [result intValue];
}

-(void)setPrimitiveDisplayOrderValue:(int32_t)value_
{
    [self setPrimitiveDisplayOrder:[NSNumber numberWithInt:value_]];
}





@dynamic email;






@dynamic isDefault;



-(BOOL)isDefaultValue
{
    NSNumber* result = [self isDefault];
    return [result boolValue];
}

-(void)setIsDefaultValue:(BOOL)value_
{
    [self setIsDefault:[NSNumber numberWithBool:value_]];
}

-(BOOL)primitiveIsDefaultValue
{
    NSNumber* result = [self primitiveIsDefault];
    return [result boolValue];
}

-(void)setPrimitiveIsDefaultValue:(BOOL)value_
{
    [self setPrimitiveIsDefault:[NSNumber numberWithBool:value_]];
}





@dynamic userId;






@dynamic userName;






@dynamic communities;


-(NSMutableSet*)communitiesSet
{
    [self willAccessValueForKey:@"communities"];

    NSMutableSet* result = (NSMutableSet*)[self mutableSetValueForKey:@"communities"];

    [self didAccessValueForKey:@"communities"];
    return result;
}







@end
