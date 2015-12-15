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

#import <Kiwi/Kiwi.h>
#import "Stack.h"
#import "Person.h"
#import "SPXDefines.h"

@interface StackQuery (Testing)
@property (nonatomic, strong) NSFetchRequest *fetchRequest;
@end

SPEC_BEGIN(StackQuerySpec)

describe(@"StackQuery", ^{
  
  __block StackQuery *query = nil;
  __block NSArray *names = nil;
  
  beforeEach(^{
    names = @[ @"Shaps", @"Anne", @"Dave", @"Roger", @"Bethany", @"Cyndia", @"Steve" ];
    
    Stack.memoryStack.transaction(^{
      for (NSUInteger i = 0; i < names.count; i++) {
        NSString *identifier = [NSString stringWithFormat:@"%zd", i];
        Person *person = Stack.memoryStack.query(Person.class).whereIdentifier(identifier).fetchOrCreate();
        person.name = names[i];
      }
    });
    
    query = Stack.memoryStack.query(Person.class);
  });
  
  afterEach(^{
    Stack.memoryStack.query(Person.class).delete();
  });

  context(@"Sorting", ^{
    
    it(@"should have valid sort descriptor via key", ^{
      query.sortByKey(@"name", YES);
      NSSortDescriptor *sorting = query.fetchRequest.sortDescriptors.firstObject;
      [[sorting.key should] equal:@"name"];
      [[theValue(sorting.ascending) should] beTrue];
    });
    
    it(@"should have valid sort descriptor via descriptors", ^{
      query.sortWithDescriptors(@[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ]);
      NSSortDescriptor *sorting = query.fetchRequest.sortDescriptors.firstObject;
      [[sorting.key should] equal:@"name"];
      [[theValue(sorting.ascending) should] beTrue];
    });
    
    it(@"should be sorted correctly", ^{
      NSArray *people = query.sortByKey(@"identifier", YES).fetch();
      [[[people.firstObject name] should] equal:@"Shaps"];
      [[[people.lastObject name] should] equal:@"Steve"];
      
      people = query.sortByKey(@"name", YES).fetch();
      [[[people.firstObject name] should] equal:@"Anne"];
      [[[people.lastObject name] should] equal:@"Steve"];
    });
    
  });
  
  context(@"Filtering", ^{
    
    it(@"should have valid predicate via format", ^{
      query.whereFormat(@"%K == %@", @"identifier", @"1234");
      NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @"identifier", @"1234"];
      [[query.fetchRequest.predicate should] equal:predicate];
    });
    
    it(@"should have a valid predicate via predicate", ^{
      NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @"identifier", @"1234"];
      query.wherePredicate(predicate);
      [[query.fetchRequest.predicate should] equal:predicate];
    });
    
    it(@"fetchLimit should equal 10", ^{
      query.limit(10);
      [theValue(query.fetchRequest.fetchLimit) isEqual:theValue(10)];
    });
    
    it(@"fetchOffset should equal 10", ^{
      query.offset(10);
      [theValue(query.fetchRequest.fetchOffset) isEqual:theValue(10)];
    });
    
    it(@"fetchBatchSize should equal 10", ^{
      query.batchSize(10);
      [theValue(query.fetchRequest.fetchBatchSize) isEqual:theValue(10)];
    });
    
  });
  
  context(@"Results", ^{
    
    it(@"count should equal names.count", ^{
      [[theValue(query.count()) should] equal:theValue(names.count)];
    });
    
    it(@"should return (names.count) results", ^{
      NSArray *objects = query.fetch();
      [[theValue(objects.count) should] equal:theValue(names.count)];
    });
    
    it(@"should return Person objects", ^{
      NSArray *classes = [query.fetch() valueForKey:@"class"];
      NSString *className = NSStringFromClass(classes.firstObject);
      [[className should] equal:NSStringFromClass(Person.class)];
    });
    
    it(@"should return the first object", ^{
      NSArray *sortedNames = [names sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ]];
      Person *firstPerson = query.sortWithDescriptors(@[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ]).firstObject();
      [[firstPerson.name should] equal:sortedNames.firstObject];
    });
    
    it(@"should return the last object", ^{
      NSArray *sortedNames = [names sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ]];
      Person *lastPerson = query.sortWithDescriptors(@[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ]).lastObject();
      [[lastPerson.name should] equal:sortedNames.lastObject];
    });
    
    it(@"should return with (fault == NO)", ^{
      [[theValue(query.fetchRequest.returnsDistinctResults) should] equal:theValue(NO)];
    });
    
  });
  
  context(@"Deleting", ^{
    
    it(@"should delete all items", ^{
      Stack.memoryStack.transaction(^{
        query.delete();
      });
      
      [[theValue(query.count()) should] equal:theValue(0)];
    });
    
  });
  
  context(@"Identifiers", ^{
    
    it(@"should find 1 match", ^{
      Person *person = query.whereIdentifier(@"0").fetch();
      [[person shouldNot] beNil];
    });
    
    it(@"should find 0 matches", ^{
      Person *person = query.whereIdentifier(@"99").fetch();
      [[person should] beNil];
    });
    
    it(@"should find create a new record", ^{
      Person *person = query.whereIdentifier(@"99").fetchOrCreate();
      [[person shouldNot] beNil];
    });
    
    it(@"should find 3 matches", ^{
      NSArray *objects = query.whereIdentifiers(@[ @"0", @"1", @"2" ]).fetch();
      [[theValue(objects.count) should] equal:theValue(3)];
    });
    
    it(@"should create 1 new record", ^{
      NSArray *objects = query.whereIdentifiers(@[ @"0", @"1", @"2", @"99" ]).fetchOrCreate();
      [[theValue(objects.count) should] equal:theValue(4)];
    });
    
    it(@"should return an object with the specified objectID", ^{
      Person *person = query.whereIdentifier(@"1").fetch();
      
      Stack.memoryStack.transaction(^{
        Person *p = query.whereObjectID(person.objectID);
        [[p.managedObjectContext shouldNot] equal:person.managedObjectContext];
        [[p.objectID should] equal:person.objectID];
        [[p.name should] equal:person.name];
      });
    });
    
  });
  
  context(@"Fetched Results Controller", ^{
    
    it(@"should return a new fetchedResultsController configured with the current query", ^{
      id delegate = [NSObject new];
      
      query.whereFormat(@"name != nil").sortByKey(@"name", YES);
      NSFetchedResultsController *controller = query.fetchedResultsController(@"section", delegate);
      
      [[controller.sectionNameKeyPath should] equal:@"section"];
      [[((NSObject *)controller.delegate) should] equal:delegate];
      [[controller.fetchRequest.predicate should] equal:[NSPredicate predicateWithFormat:@"name != nil"]];
      [[theValue(controller.fetchRequest.sortDescriptors.count) should] equal:theValue(1)];
      NSSortDescriptor *sorting = controller.fetchRequest.sortDescriptors.firstObject;
      [[sorting.key should] equal:@"name"];
      [[theValue(sorting.ascending) should] equal:theValue(YES)];
    });
    
  });
  
});

SPEC_END