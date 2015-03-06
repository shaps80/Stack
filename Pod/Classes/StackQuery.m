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
@end

@interface StackTransaction (Private)
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@end

@interface StackQuery ()
@property (nonatomic, weak) Stack *stack;
@property (nonatomic, assign) Class managedObjectClass;
@property (nonatomic, strong) NSFetchRequest *fetchRequest;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@end

@implementation StackQuery

+ (instancetype)queryForManagedObjectClass:(Class)managedObjectClass entityName:(NSString *)entityName
{
  StackQuery *query = [StackQuery new];
  query.managedObjectClass = managedObjectClass;
  query.fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
  return query;
}

- (NSManagedObjectContext *)managedObjectContext
{
  return self.stack.currentThreadContext;
}

- (NSFetchedResultsController *(^)(NSString *, id<NSFetchedResultsControllerDelegate>))fetchedResultsController
{
  return ^(NSString *sectionNameKeyPath, id <NSFetchedResultsControllerDelegate> delegate) {
    SPXCAssertTrueOrPerformAction([NSThread isMainThread], return (NSFetchedResultsController *)nil);
    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest managedObjectContext:self.stack.mainThreadContext sectionNameKeyPath:sectionNameKeyPath cacheName:nil];
    controller.delegate = delegate;
    return controller;
  };
}

- (id (^)(NSString *, BOOL))whereIdentifier
{
  return ^(NSString *identifier, BOOL createIfNil) {
    NSUInteger limit = self.fetchRequest.fetchLimit;
    NSError *error = nil;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", [self.managedObjectClass identifierKey], identifier];
    self.fetchRequest.predicate = predicate;
    self.fetchRequest.fetchLimit = 1;
    
    NSArray *results = [self.managedObjectContext executeFetchRequest:self.fetchRequest error:&error];
    
    if (error) {
      SPXLog(@"%@", error);
    }
    
    if (results.count || !createIfNil) {
      self.fetchRequest.fetchLimit = limit;
      return results.firstObject;
    }
    
    id object = [NSEntityDescription insertNewObjectForEntityForName:self.fetchRequest.entityName inManagedObjectContext:self.managedObjectContext];
    [object setValue:identifier forKey:[self.managedObjectClass identifierKey]];
    
    [self resetFetchRequest];
    return object;
  };
}

- (NSArray *(^)(NSArray *, BOOL))whereIdentifiers
{
  return ^(NSArray *identifiers, BOOL createIfNil) {
    NSError *error = nil;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K IN %@", [self.managedObjectClass identifierKey], identifiers];
    self.fetchRequest.predicate = predicate;
    
    NSArray *objects = [self.managedObjectContext executeFetchRequest:self.fetchRequest error:&error];
    
    if (error) {
      SPXLog(@"%@", error);
    }
    
    if (objects.count == identifiers.count || !createIfNil) {
      [self resetFetchRequest];
      return objects;
    }
    
    NSMutableArray *results = [NSMutableArray new];
    [results addObjectsFromArray:objects];
    
    NSMutableSet *identifiersSet = [NSMutableSet setWithArray:identifiers];
    NSSet *existingIdentifiersSet = [NSSet setWithArray:[objects valueForKey:[self.managedObjectClass identifierKey]]];
    
    [identifiersSet minusSet:existingIdentifiersSet];
    
    for (id identifier in identifiersSet) {
      id newObject = [NSEntityDescription insertNewObjectForEntityForName:self.fetchRequest.entityName inManagedObjectContext:self.managedObjectContext];
      [newObject setValue:identifier forKey:[self.managedObjectClass identifierKey]];
      [results addObject:newObject];
    }
    
    objects = [results sortedArrayUsingDescriptors:self.fetchRequest.sortDescriptors];
    [self resetFetchRequest];
    
    return objects;
  };
}

- (id (^)(NSManagedObjectID *))whereObjectID
{
  return ^(NSManagedObjectID *objectID) {
    return [self.managedObjectContext objectWithID:objectID];
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

- (StackQuery *(^)(NSString *, ...))whereFormat
{
  return ^(NSString *format, ...) {
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
    self.fetchRequest.predicate = predicate;
    return self;
  };
}

- (StackQuery *(^)())faultFilled
{
  return ^{
    self.fetchRequest.returnsObjectsAsFaults = NO;
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
    __block NSError *error = nil;
    __block NSUInteger count = [self.managedObjectContext countForFetchRequest:self.fetchRequest error:&error];
    
    if (error) {
      SPXLog(@"%@", error);
    }
    
    [self resetFetchRequest];
    return count;
  };
}

- (void (^)())delete
{
  return ^{
    __block NSError *error = nil;
    __block NSArray *objects = [self.managedObjectContext executeFetchRequest:self.fetchRequest error:&error];
    
    for (id object in objects) {
      [self.managedObjectContext deleteObject:object];
    }
    
    [self resetFetchRequest];
  };
}

- (void (^)(NSArray *))deleteObjects
{
  return ^(NSArray *objects) {
    for (id object in objects) {
      SPXAssertTrueOrReturn([object isKindOfClass:[NSManagedObject class]]);
      [self.managedObjectContext deleteObject:object];
    }
    
    [self resetFetchRequest];
  };
}

- (NSArray *(^)())fetch
{
  return ^{
    NSError *error = nil;
    NSArray *objects = [self.managedObjectContext executeFetchRequest:self.fetchRequest error:&error];
    
    if (error) {
      SPXLog(@"%@", error);
    }
    
    [self resetFetchRequest];
    return objects;
  };
}

- (void)resetFetchRequest
{
  self.fetchRequest = [NSFetchRequest fetchRequestWithEntityName:self.fetchRequest.entityName];
}

- (NSString *)description
{
  return SPXDescription(SPXKeyPath(fetchRequest));
}

@end
