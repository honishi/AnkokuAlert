// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MOCommunity.h instead.

#import <CoreData/CoreData.h>


extern const struct MOCommunityAttributes {
    __unsafe_unretained NSString* communityId;
    __unsafe_unretained NSString* communityName;
    __unsafe_unretained NSString* isEnabled;
    __unsafe_unretained NSString* order;
    __unsafe_unretained NSString* rating;
} MOCommunityAttributes;

extern const struct MOCommunityRelationships {
    __unsafe_unretained NSString* account;
} MOCommunityRelationships;

extern const struct MOCommunityFetchedProperties {
} MOCommunityFetchedProperties;

@class MOAccount;







@interface MOCommunityID : NSManagedObjectID {}
@end

@interface _MOCommunity : NSManagedObject {}
+(id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+(NSString*)entityName;
+(NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
-(MOCommunityID*)objectID;





@property (nonatomic, strong) NSString* communityId;



//- (BOOL)validateCommunityId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* communityName;



//- (BOOL)validateCommunityName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* isEnabled;



@property BOOL isEnabledValue;
-(BOOL)isEnabledValue;
-(void)setIsEnabledValue:(BOOL)value_;

//- (BOOL)validateIsEnabled:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* order;



@property int32_t orderValue;
-(int32_t)orderValue;
-(void)setOrderValue:(int32_t)value_;

//- (BOOL)validateOrder:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* rating;



@property int32_t ratingValue;
-(int32_t)ratingValue;
-(void)setRatingValue:(int32_t)value_;

//- (BOOL)validateRating:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) MOAccount* account;

//- (BOOL)validateAccount:(id*)value_ error:(NSError**)error_;





@end

@interface _MOCommunity (CoreDataGeneratedAccessors)

@end

@interface _MOCommunity (CoreDataGeneratedPrimitiveAccessors)


-(NSString*)primitiveCommunityId;
-(void)setPrimitiveCommunityId:(NSString*)value;




-(NSString*)primitiveCommunityName;
-(void)setPrimitiveCommunityName:(NSString*)value;




-(NSNumber*)primitiveIsEnabled;
-(void)setPrimitiveIsEnabled:(NSNumber*)value;

-(BOOL)primitiveIsEnabledValue;
-(void)setPrimitiveIsEnabledValue:(BOOL)value_;




-(NSNumber*)primitiveOrder;
-(void)setPrimitiveOrder:(NSNumber*)value;

-(int32_t)primitiveOrderValue;
-(void)setPrimitiveOrderValue:(int32_t)value_;




-(NSNumber*)primitiveRating;
-(void)setPrimitiveRating:(NSNumber*)value;

-(int32_t)primitiveRatingValue;
-(void)setPrimitiveRatingValue:(int32_t)value_;





-(MOAccount*)primitiveAccount;
-(void)setPrimitiveAccount:(MOAccount*)value;


@end
