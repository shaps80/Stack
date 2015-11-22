/*
   Copyright (c) 2015 Shaps Mohsenin. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY Shaps Mohsenin `AS IS' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL Shaps Mohsenin OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "StackQuery.h"
#import "NSManagedObject+StackAdditions.h"
#import "SPXDefines.h"
#import "Stack.h"

@interface Stack (Private)
@property (nonatomic, readonly) NSManagedObjectContext *mainThreadContext;
@property (nonatomic, readonly) NSManagedObjectContext *currentThreadContext;
+ (void)handleError:(NSError *)error;
@end

@interface StackTransaction (Private)
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@end

@interface StackQuery ()
@property (nonatomic, weak) Stack *stack;
@property (nonatomic, assign) Class managedObjectClass;
@property (nonatomic, strong) NSFetchRequest *fetchRequest;
@property (nonatomic, strong) NSString *entityName;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSArray *identifiers;
@property (nonatomic, strong) NSString *sectionNameKeyPath;
@end

@implementation StackQuery

+ (instancetype)queryForManagedObjectClass:(Class)managedObjectClass entityName:(NSString *)entityName
{
  StackQuery *query = [StackQuery new];
  query.managedObjectClass = managedObjectClass;
  query.entityName = entityName;
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-method-access"
  if (!entityName) {
    query.entityName = entityName ?: [managedObjectClass entityName];
  }
#pragma clang diagnostic pop
  
  return query;
}

- (NSManagedObjectContext *)managedObjectContext
{
  return self.stack.currentThreadContext;
}

- (NSFetchedResultsController *(^)())fetchedResultsController
{
  return ^{
    SPXCAssertTrueOrPerformAction([NSThread isMainThread], return (NSFetchedResultsController *)nil);
    __block NSFetchedResultsController *controller = nil;
    
    [self.managedObjectContext performBlockAndWait:^{
      controller = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest managedObjectContext:self.stack.mainThreadContext sectionNameKeyPath:self.sectionNameKeyPath cacheName:nil];
    }];
    
    return controller;
  };
}

- (StackQuery *(^)(NSString *))groupBy
{
  return ^(NSString *sectionNameOrKeyPath) {
    self.sectionNameKeyPath = sectionNameOrKeyPath;
    return self;
  };
}

- (StackQuery* (^)(id))whereIdentifier
{
  return ^(id identifier) {
    SPXCAssertTrueOrPerformAction(!self.fetchRequest.predicate, SPXLog(@"You cannot specify another predicate. You currently have the following predicate defined: %@", self.fetchRequest.predicate); return (StackQuery *)nil);
    
    self.identifiers = @[ identifier ];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", [self.managedObjectClass identifierKey], identifier];
    self.fetchRequest.predicate = predicate;
    self.fetchRequest.fetchLimit = 1;
    return self;
  };
}

- (StackQuery *(^)(NSArray *))whereIdentifiers
{
  return ^(NSArray *identifiers) {
    SPXCAssertTrueOrPerformAction(!self.fetchRequest.predicate, SPXLog(@"You cannot specify another predicate. You currently have the following predicate defined: %@", self.fetchRequest.predicate); return (StackQuery *)nil);

    self.identifiers = identifiers.copy;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K IN %@", [self.managedObjectClass identifierKey], identifiers];
    self.fetchRequest.predicate = predicate;
    return self;
  };
}

- (id (^)(NSManagedObjectID *))whereObjectID
{
  return ^(NSManagedObjectID *objectID) {
    return [self.managedObjectContext objectWithID:objectID];
  };
}

- (StackQuery *(^)(NSString *, ...))whereFormat
{
  return ^(NSString *format, ...) {
    SPXCAssertTrueOrPerformAction(!self.fetchRequest.predicate, SPXLog(@"You cannot specify another predicate. You currently have the following predicate defined: %@", self.fetchRequest.predicate); return (StackQuery *)nil);

    va_list args;
    va_start(args, format);
    self.fetchRequest.predicate = [NSPredicate predicateWithFormat:format arguments:args];
    va_end(args);
    
    return self;
  };
}

- (StackQuery *(^)(NSPredicate *))wherePredicate
{
  return ^(NSPredicate *predicate) {
    SPXCAssertTrueOrPerformAction(!self.fetchRequest.predicate, SPXLog(@"You cannot specify another predicate. You currently have the following predicate defined: %@", self.fetchRequest.predicate); return (StackQuery *)nil);

    self.fetchRequest.predicate = predicate;
    return self;
  };
}

- (StackQuery *(^)(NSString *, BOOL))sortByKey
{
  return ^(NSString *sortKey, BOOL ascending) {
    self.fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:sortKey ascending:ascending] ];
    return self;
  };
}

- (StackQuery *(^)(NSArray *))sortWithDescriptors
{
  return ^(NSArray *sortDescriptors) {
    self.fetchRequest.sortDescriptors = sortDescriptors;
    return self;
  };
}

- (StackQuery *(^)())faultFilled
{
  return ^{
    self.fetchRequest.resultType = NSManagedObjectResultType;
    [self.fetchRequest setReturnsObjectsAsFaults:NO];
    return self;
  };
}

- (StackQuery *(^)(NSUInteger))limit
{
  return ^(NSUInteger value) {
    self.fetchRequest.fetchLimit = value;
    return self;
  };
}

- (StackQuery *(^)(NSUInteger))offset
{
  return ^(NSUInteger value) {
    self.fetchRequest.fetchOffset = value;
    return self;
  };
}

- (StackQuery *(^)(NSUInteger))batchSize
{
  return ^(NSUInteger value) {
    self.fetchRequest.fetchBatchSize = value;
    return self;
  };
}

- (NSUInteger (^)())count
{
  return ^{
    __block NSUInteger count = 0;
    
    [self.managedObjectContext performBlockAndWait:^{
      __block NSError *error = nil;
      count = [self.managedObjectContext countForFetchRequest:self.fetchRequest error:&error];
      [Stack handleError:error];
    }];
    
    self.fetchRequest = nil;
    return count;
  };
}

- (void (^)())delete
{
  return ^{
    __block NSArray *objects = [self executeFetchRequest];
    
    [self.managedObjectContext performBlockAndWait:^{
      for (id object in objects) {
        [self.managedObjectContext deleteObject:object];
      }
    }];
  };
}

- (NSArray* (^)())fetchOrCreate
{
  return ^NSArray*{
    NSArray *objects = [self executeFetchRequest];
    
    if (objects.count == self.identifiers.count) {
      self.fetchRequest = nil;
      return objects;
    }
    
    NSMutableArray *results = [NSMutableArray new];
    [results addObjectsFromArray:objects];
    
    NSMutableSet *identifiersSet = [NSMutableSet setWithArray:self.identifiers];
    NSSet *existingIdentifiersSet = [NSSet setWithArray:[objects valueForKey:[self.managedObjectClass identifierKey]]];
    
    [identifiersSet minusSet:existingIdentifiersSet];
    
    for (id identifier in identifiersSet) {
      id newObject = [NSEntityDescription insertNewObjectForEntityForName:self.fetchRequest.entityName inManagedObjectContext:self.managedObjectContext];
      [newObject setValue:identifier forKey:[self.managedObjectClass identifierKey]];
      [results addObject:newObject];
    }
    
    return [results sortedArrayUsingDescriptors:self.fetchRequest.sortDescriptors];
  };
}

- (NSArray* (^)())fetch
{
  return ^NSArray* {
    return [self executeFetchRequest];
  };
}

- (id (^)())firstObject
{
  return ^id{
    self.fetchRequest.fetchOffset = 0;
    self.fetchRequest.fetchBatchSize = 1;
    self.fetchRequest.fetchLimit = 1;
    return [self executeFetchRequest].firstObject;
  };
}

- (id (^)())lastObject
{
  return ^id {
    __block NSUInteger count = 0;
    
    [self.managedObjectContext performBlockAndWait:^{
      NSError *error = nil;
      count = [self.managedObjectContext countForFetchRequest:self.fetchRequest error:&error];
      [Stack handleError:error];
    }];
    
    self.fetchRequest.fetchOffset = count - 1;
    self.fetchRequest.fetchBatchSize = 1;
    self.fetchRequest.fetchLimit = 1;
    
    return [self executeFetchRequest].lastObject;
  };
}

- (NSArray *)executeFetchRequest
{
  __block NSArray *results = nil;
  
  [self.managedObjectContext performBlockAndWait:^{
    NSError *error = nil;
    results = [self.managedObjectContext executeFetchRequest:self.fetchRequest error:&error];
    [Stack handleError:error];
  }];
  
  self.fetchRequest = nil;
  return results;
}

- (NSFetchRequest *)fetchRequest
{
  return _fetchRequest ?: ({
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:self.entityName];
    _fetchRequest = request;
  });
}

- (NSString *)description
{
  return SPXDescription(SPXKeyPath(fetchRequest));
}

@end
