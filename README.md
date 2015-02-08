# Stack

[![CI Status](http://img.shields.io/travis/Shaps Mohsenin/Stack.svg?style=flat)](https://travis-ci.org/Shaps Mohsenin/Stack)
[![Version](https://img.shields.io/cocoapods/v/Stack.svg?style=flat)](http://cocoadocs.org/docsets/Stack)
[![License](https://img.shields.io/cocoapods/l/Stack.svg?style=flat)](http://cocoadocs.org/docsets/Stack)
[![Platform](https://img.shields.io/cocoapods/p/Stack.svg?style=flat)](http://cocoadocs.org/docsets/Stack)

## A quick comparison

The best way to understand why Stack is a safer, much simpler implementation for working with CoreData, is to see some code.

```objc
for (int i = 0; i < 1000; i++) {
    Stack.defaultStack.transaction(^{
    
      for (int j = 0; j < 1000; j++) {
        NSString *identifier = [NSString stringWithFormat:@"10%zd%dz", i, j];
        Person *person = Person.query.whereIdentifier(identifier, YES);
        
        person.update(@
        {
          @"name" : attributes[@"name"],
          @"phone" : attributes[@"phone_number"],
        });
        
        Person.query.where(@"name == nil").delete();
        NSArray *people = Person.query.sort(@"name", YES).fetch();
        
        NSLog(@"%@", people);
      }
      
    });
  }
```

Lets contrast this with a naive approach we might normally see implemented.

```objc
for (int i = 0; i < 1000; i++) {
    NSManagedObjectContext *context = [NSManagedObjectContext new];
    
    [context performBlockAndWait:^{
      
      for (int j = 0; j < 1000; j++) {
        NSString *identifier = [NSString stringWithFormat:@"10%zd%dz", i, j];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:Person.entityName];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", @"identifier", identifier];
        
        request.predicate = predicate;
        request.fetchLimit = 1;
        
        Person *person = (Person *)[context executeFetchRequest:request error:nil].firstObject;
        
        if (!person) {
          person = [NSEntityDescription insertNewObjectForEntityForName:Person.entityName inManagedObjectContext:context];
        }
        
        [person setValue:attributes[@"name"] forKey:@"name"];
        [person setValue:attributes[@"phone_number"] forKey:@"phone"];
        
        request = [NSFetchRequest fetchRequestWithEntityName:Person.entityName];
        request.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ];
        request.predicate = [NSPredicate predicateWithFormat:@"name == nil"];
        
        NSArray *people = [context executeFetchRequest:request error:nil];
        
        for (Person *person in people) {
          [context deleteObject:person];
        }
        
        request = [NSFetchRequest fetchRequestWithEntityName:Person.entityName];
        request.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ];
        
        people = [context executeFetchRequest:request error:nil];
        NSLog(@"%@", people);
      }
      
      [context save:nil];
      
    }];
  }
```

## Interface

Hopefully now its a little more obvious how much simpler it is to work with CoreData.
Stack makes this easy by providing a simple interface compared to most other implementations.

```objc
@property ... StackQuery *(^wherePredicate)(NSPredicate *predicate);
@property ... StackQuery *(^where)(NSString *format, ...);
@property ... StackQuery *(^sort)(NSString *key, BOOL ascending);
@property ... StackQuery *(^sortWithDescriptors)(NSArray *sortDescriptors);
@property ... void (^delete)();
@property ... NSUInteger (^count)();
@property ... NSArray *(^fetch)();
@property ... id (^whereIdentifier)(NSString *identifier, BOOL createIfNil);
@property ... NSArray *(^whereIdentifiers)(NSArray *identifiers, BOOL createIfNil);
```

Even my own previous implementations were much more cumbersome than this. Stack provides just 9 block-based methods for maximum flexibility, whereas the previous implementation had over 20+ and even then not all combinations were accounted for. Here's just a few for comparison:

```objc
+ (void)deleteAllMatching:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;
+ (NSArray *)objectsWithIdentifiers:(NSArray *)identifiers sorting:(NSArray *)sortDescriptors faulted:(BOOL)faulted create:(BOOL)create inContext:(NSManagedObjectContext *)context;
+ (instancetype)objectWithIdentifier:(id)identifier faulted:(BOOL)faulted create:(BOOL)create inContext:(NSManagedObjectContext *)context;
+ (NSUInteger)countAllSorted:(NSArray *)sortDescriptors predicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;
+ (NSArray *)allSorted:(NSArray *)sortDescriptors predicate:(NSPredicate *)predicate faulted:(BOOL)faulted inContext:(NSManagedObjectContext *)context;
```

>And that's not even including all the variations of those methods.

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

Stack is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "Stack"

## Author

Shaps Mohsenin, shaps@theappbusiness.com

## License

Stack is available under the MIT license. See the LICENSE file for more info.

