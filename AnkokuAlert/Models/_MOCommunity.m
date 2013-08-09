// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MOCommunity.m instead.

#import "_MOCommunity.h"

const struct MOCommunityAttributes MOCommunityAttributes = {
    .communityId = @"communityId",
    .communityName = @"communityName",
    .isEnabled = @"isEnabled",
    .order = @"order",
    .rating = @"rating",
};

const struct MOCommunityRelationships MOCommunityRelationships = {
    .account = @"account",
};

const struct MOCommunityFetchedProperties MOCommunityFetchedProperties = {
};

@implementation MOCommunityID
@end

@implementation _MOCommunity

+(id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_
{
    NSParameterAssert(moc_);
    return [NSEntityDescription insertNewObjectForEntityForName:@"Community" inManagedObjectContext:moc_];
}

+(NSString*)entityName
{
    return @"Community";
}

+(NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_
{
    NSParameterAssert(moc_);
    return [NSEntityDescription entityForName:@"Community" inManagedObjectContext:moc_];
}

-(MOCommunityID*)objectID
{
    return (MOCommunityID*)[super objectID];
}

+(NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key
{
    NSSet* keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

    if ([key isEqualToString:@"isEnabledValue"]) {
        NSSet* affectingKey = [NSSet setWithObject:@"isEnabled"];
        keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
        return keyPaths;
    }
    if ([key isEqualToString:@"orderValue"]) {
        NSSet* affectingKey = [NSSet setWithObject:@"order"];
        keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
        return keyPaths;
    }
    if ([key isEqualToString:@"ratingValue"]) {
        NSSet* affectingKey = [NSSet setWithObject:@"rating"];
        keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
        return keyPaths;
    }

    return keyPaths;
}




@dynamic communityId;






@dynamic communityName;






@dynamic isEnabled;



-(BOOL)isEnabledValue
{
    NSNumber* result = [self isEnabled];
    return [result boolValue];
}

-(void)setIsEnabledValue:(BOOL)value_
{
    [self setIsEnabled:[NSNumber numberWithBool:value_]];
}

-(BOOL)primitiveIsEnabledValue
{
    NSNumber* result = [self primitiveIsEnabled];
    return [result boolValue];
}

-(void)setPrimitiveIsEnabledValue:(BOOL)value_
{
    [self setPrimitiveIsEnabled:[NSNumber numberWithBool:value_]];
}





@dynamic order;



-(int32_t)orderValue
{
    NSNumber* result = [self order];
    return [result intValue];
}

-(void)setOrderValue:(int32_t)value_
{
    [self setOrder:[NSNumber numberWithInt:value_]];
}

-(int32_t)primitiveOrderValue
{
    NSNumber* result = [self primitiveOrder];
    return [result intValue];
}

-(void)setPrimitiveOrderValue:(int32_t)value_
{
    [self setPrimitiveOrder:[NSNumber numberWithInt:value_]];
}





@dynamic rating;



-(int32_t)ratingValue
{
    NSNumber* result = [self rating];
    return [result intValue];
}

-(void)setRatingValue:(int32_t)value_
{
    [self setRating:[NSNumber numberWithInt:value_]];
}

-(int32_t)primitiveRatingValue
{
    NSNumber* result = [self primitiveRating];
    return [result intValue];
}

-(void)setPrimitiveRatingValue:(int32_t)value_
{
    [self setPrimitiveRating:[NSNumber numberWithInt:value_]];
}





@dynamic account;








@end
