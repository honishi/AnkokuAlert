// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MOCommunity.m instead.

#import "_MOCommunity.h"

const struct MOCommunityAttributes MOCommunityAttributes = {
    .community = @"community",
    .communityName = @"communityName",
    .enabled = @"enabled",
    .useBrowser = @"useBrowser",
    .useSound = @"useSound",
};

const struct MOCommunityRelationships MOCommunityRelationships = {
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

    if ([key isEqualToString:@"enabledValue"]) {
        NSSet* affectingKey = [NSSet setWithObject:@"enabled"];
        keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
        return keyPaths;
    }
    if ([key isEqualToString:@"useBrowserValue"]) {
        NSSet* affectingKey = [NSSet setWithObject:@"useBrowser"];
        keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
        return keyPaths;
    }
    if ([key isEqualToString:@"useSoundValue"]) {
        NSSet* affectingKey = [NSSet setWithObject:@"useSound"];
        keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
        return keyPaths;
    }

    return keyPaths;
}




@dynamic community;






@dynamic communityName;






@dynamic enabled;



-(BOOL)enabledValue
{
    NSNumber* result = [self enabled];
    return [result boolValue];
}

-(void)setEnabledValue:(BOOL)value_
{
    [self setEnabled:[NSNumber numberWithBool:value_]];
}

-(BOOL)primitiveEnabledValue
{
    NSNumber* result = [self primitiveEnabled];
    return [result boolValue];
}

-(void)setPrimitiveEnabledValue:(BOOL)value_
{
    [self setPrimitiveEnabled:[NSNumber numberWithBool:value_]];
}





@dynamic useBrowser;



-(BOOL)useBrowserValue
{
    NSNumber* result = [self useBrowser];
    return [result boolValue];
}

-(void)setUseBrowserValue:(BOOL)value_
{
    [self setUseBrowser:[NSNumber numberWithBool:value_]];
}

-(BOOL)primitiveUseBrowserValue
{
    NSNumber* result = [self primitiveUseBrowser];
    return [result boolValue];
}

-(void)setPrimitiveUseBrowserValue:(BOOL)value_
{
    [self setPrimitiveUseBrowser:[NSNumber numberWithBool:value_]];
}





@dynamic useSound;



-(BOOL)useSoundValue
{
    NSNumber* result = [self useSound];
    return [result boolValue];
}

-(void)setUseSoundValue:(BOOL)value_
{
    [self setUseSound:[NSNumber numberWithBool:value_]];
}

-(BOOL)primitiveUseSoundValue
{
    NSNumber* result = [self primitiveUseSound];
    return [result boolValue];
}

-(void)setPrimitiveUseSoundValue:(BOOL)value_
{
    [self setPrimitiveUseSound:[NSNumber numberWithBool:value_]];
}










@end
