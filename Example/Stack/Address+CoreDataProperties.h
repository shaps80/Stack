//
//  Address+CoreDataProperties.h
//  
//
//  Created by Shaps Mohsenin on 13/08/2015.
//
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

#import "Address.h"

NS_ASSUME_NONNULL_BEGIN

@interface Address (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *street;
@property (nullable, nonatomic, retain) NSString *city;
@property (nullable, nonatomic, retain) NSString *postcode;
@property (nullable, nonatomic, retain) Person *person;

@end

NS_ASSUME_NONNULL_END
