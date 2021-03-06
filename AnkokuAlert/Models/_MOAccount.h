// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MOAccount.h instead.

#import <CoreData/CoreData.h>


extern const struct MOAccountAttributes {
    __unsafe_unretained NSString* email;
    __unsafe_unretained NSString* isDefault;
    __unsafe_unretained NSString* order;
    __unsafe_unretained NSString* userId;
    __unsafe_unretained NSString* userName;
} MOAccountAttributes;

extern const struct MOAccountRelationships {
    __unsafe_unretained NSString* communities;
} MOAccountRelationships;

extern const struct MOAccountFetchedProperties {
} MOAccountFetchedProperties;

@class MOCommunity;







@interface MOAccountID : NSManagedObjectID {}
@end

@interface _MOAccount : NSManagedObject {}
+(id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+(NSString*)entityName;
+(NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
-(MOAccountID*)objectID;





@property (nonatomic, strong) NSString* email;



//- (BOOL)validateEmail:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* isDefault;



@property BOOL isDefaultValue;
-(BOOL)isDefaultValue;
-(void)setIsDefaultValue:(BOOL)value_;

//- (BOOL)validateIsDefault:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* order;



@property int32_t orderValue;
-(int32_t)orderValue;
-(void)setOrderValue:(int32_t)value_;

//- (BOOL)validateOrder:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* userId;



//- (BOOL)validateUserId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* userName;



//- (BOOL)validateUserName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet* communities;

-(NSMutableSet*)communitiesSet;





@end

@interface _MOAccount (CoreDataGeneratedAccessors)

-(void)addCommunities:(NSSet*)value_;
-(void)removeCommunities:(NSSet*)value_;
-(void)addCommunitiesObject:(MOCommunity*)value_;
-(void)removeCommunitiesObject:(MOCommunity*)value_;

@end

@interface _MOAccount (CoreDataGeneratedPrimitiveAccessors)


-(NSString*)primitiveEmail;
-(void)setPrimitiveEmail:(NSString*)value;




-(NSNumber*)primitiveIsDefault;
-(void)setPrimitiveIsDefault:(NSNumber*)value;

-(BOOL)primitiveIsDefaultValue;
-(void)setPrimitiveIsDefaultValue:(BOOL)value_;




-(NSNumber*)primitiveOrder;
-(void)setPrimitiveOrder:(NSNumber*)value;

-(int32_t)primitiveOrderValue;
-(void)setPrimitiveOrderValue:(int32_t)value_;




-(NSString*)primitiveUserId;
-(void)setPrimitiveUserId:(NSString*)value;




-(NSString*)primitiveUserName;
-(void)setPrimitiveUserName:(NSString*)value;





-(NSMutableSet*)primitiveCommunities;
-(void)setPrimitiveCommunities:(NSMutableSet*)value;


@end
