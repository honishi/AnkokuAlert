// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MOCommunity.h instead.

#import <CoreData/CoreData.h>


extern const struct MOCommunityAttributes {
    __unsafe_unretained NSString* community;
    __unsafe_unretained NSString* communityName;
    __unsafe_unretained NSString* enabled;
    __unsafe_unretained NSString* useBrowser;
    __unsafe_unretained NSString* useSound;
} MOCommunityAttributes;

extern const struct MOCommunityRelationships {
} MOCommunityRelationships;

extern const struct MOCommunityFetchedProperties {
} MOCommunityFetchedProperties;








@interface MOCommunityID : NSManagedObjectID {}
@end

@interface _MOCommunity : NSManagedObject {}
+(id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+(NSString*)entityName;
+(NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
-(MOCommunityID*)objectID;





@property (nonatomic, strong) NSString* community;



//- (BOOL)validateCommunity:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* communityName;



//- (BOOL)validateCommunityName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* enabled;



@property BOOL enabledValue;
-(BOOL)enabledValue;
-(void)setEnabledValue:(BOOL)value_;

//- (BOOL)validateEnabled:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* useBrowser;



@property BOOL useBrowserValue;
-(BOOL)useBrowserValue;
-(void)setUseBrowserValue:(BOOL)value_;

//- (BOOL)validateUseBrowser:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* useSound;



@property BOOL useSoundValue;
-(BOOL)useSoundValue;
-(void)setUseSoundValue:(BOOL)value_;

//- (BOOL)validateUseSound:(id*)value_ error:(NSError**)error_;






@end

@interface _MOCommunity (CoreDataGeneratedAccessors)

@end

@interface _MOCommunity (CoreDataGeneratedPrimitiveAccessors)


-(NSString*)primitiveCommunity;
-(void)setPrimitiveCommunity:(NSString*)value;




-(NSString*)primitiveCommunityName;
-(void)setPrimitiveCommunityName:(NSString*)value;




-(NSNumber*)primitiveEnabled;
-(void)setPrimitiveEnabled:(NSNumber*)value;

-(BOOL)primitiveEnabledValue;
-(void)setPrimitiveEnabledValue:(BOOL)value_;




-(NSNumber*)primitiveUseBrowser;
-(void)setPrimitiveUseBrowser:(NSNumber*)value;

-(BOOL)primitiveUseBrowserValue;
-(void)setPrimitiveUseBrowserValue:(BOOL)value_;




-(NSNumber*)primitiveUseSound;
-(void)setPrimitiveUseSound:(NSNumber*)value;

-(BOOL)primitiveUseSoundValue;
-(void)setPrimitiveUseSoundValue:(BOOL)value_;




@end
