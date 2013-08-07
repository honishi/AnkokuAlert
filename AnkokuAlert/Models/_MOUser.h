// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MOUser.h instead.

#import <CoreData/CoreData.h>


extern const struct MOUserAttributes {
    __unsafe_unretained NSString* isDefault;
    __unsafe_unretained NSString* userId;
    __unsafe_unretained NSString* userName;
} MOUserAttributes;

extern const struct MOUserRelationships {
    __unsafe_unretained NSString* communities;
} MOUserRelationships;

extern const struct MOUserFetchedProperties {
} MOUserFetchedProperties;

@class MOCommunity;





@interface MOUserID : NSManagedObjectID {}
@end

@interface _MOUser : NSManagedObject {}
+(id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+(NSString*)entityName;
+(NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
-(MOUserID*)objectID;





@property (nonatomic, strong) NSNumber* isDefault;



@property BOOL isDefaultValue;
-(BOOL)isDefaultValue;
-(void)setIsDefaultValue:(BOOL)value_;

//- (BOOL)validateIsDefault:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* userId;



//- (BOOL)validateUserId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* userName;



//- (BOOL)validateUserName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet* communities;

-(NSMutableSet*)communitiesSet;





@end

@interface _MOUser (CoreDataGeneratedAccessors)

-(void)addCommunities:(NSSet*)value_;
-(void)removeCommunities:(NSSet*)value_;
-(void)addCommunitiesObject:(MOCommunity*)value_;
-(void)removeCommunitiesObject:(MOCommunity*)value_;

@end

@interface _MOUser (CoreDataGeneratedPrimitiveAccessors)


-(NSNumber*)primitiveIsDefault;
-(void)setPrimitiveIsDefault:(NSNumber*)value;

-(BOOL)primitiveIsDefaultValue;
-(void)setPrimitiveIsDefaultValue:(BOOL)value_;




-(NSString*)primitiveUserId;
-(void)setPrimitiveUserId:(NSString*)value;




-(NSString*)primitiveUserName;
-(void)setPrimitiveUserName:(NSString*)value;





-(NSMutableSet*)primitiveCommunities;
-(void)setPrimitiveCommunities:(NSMutableSet*)value;


@end
