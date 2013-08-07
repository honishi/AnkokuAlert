// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MOUser.m instead.

#import "_MOUser.h"

const struct MOUserAttributes MOUserAttributes = {
    .isDefault = @"isDefault",
    .userId = @"userId",
    .userName = @"userName",
};

const struct MOUserRelationships MOUserRelationships = {
    .communities = @"communities",
};

const struct MOUserFetchedProperties MOUserFetchedProperties = {
};

@implementation MOUserID
@end

@implementation _MOUser

+(id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_
{
    NSParameterAssert(moc_);
    return [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:moc_];
}

+(NSString*)entityName
{
    return @"User";
}

+(NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_
{
    NSParameterAssert(moc_);
    return [NSEntityDescription entityForName:@"User" inManagedObjectContext:moc_];
}

-(MOUserID*)objectID
{
    return (MOUserID*)[super objectID];
}

+(NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key
{
    NSSet* keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

    if ([key isEqualToString:@"isDefaultValue"]) {
        NSSet* affectingKey = [NSSet setWithObject:@"isDefault"];
        keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
        return keyPaths;
    }

    return keyPaths;
}




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
