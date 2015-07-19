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

SPEC_BEGIN(StackSpec)

describe(@"Stack", ^{
  
  context(@"Initializing", ^{
    it(@"defaultStack should NOT be nil", ^{
      [[[Stack defaultStack] shouldNot] beNil];
    });
    
    it(@"memoryStack should NOT be nil", ^{
      [[[Stack memoryStack] shouldNot] beNil];
    });
    
    it(@"stack should be registered successfully", ^{
      NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:nil];
      [Stack registerStackWithName:@"Stack" model:model storeURL:nil inMemoryOnly:YES];
      [[[Stack stackNamed:@"Stack"] shouldNot] beNil];
    });
  });
  
  context(@"Entities", ^{
    it(@"should return valid entity", ^{
      NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:nil];
      NSMutableDictionary *mappings = [NSMutableDictionary new];
      
      [model.entitiesByName enumerateKeysAndObjectsUsingBlock:^(NSString *entityName, NSEntityDescription *entityDescription, BOOL *stop) {
        mappings[entityDescription.managedObjectClassName] = entityName;
      }];
      
      NSString *entityName = mappings[NSStringFromClass(Person.class)];
      [[[Stack memoryStack].entityNameForClass(Person.class) should] equal:entityName];
    });
  });
  
  context(@"Deletes", ^{

    Stack *stack = [Stack memoryStack];
    __block StackQuery *query = nil;
    __block NSArray *names = nil;
    
    beforeEach(^{
      names = @[ @"Shaps", @"Anne", @"Dave", @"Roger", @"Bethany", @"Cyndia", @"Steve" ];
      
      stack.transaction(^{
        for (NSUInteger i = 0; i < names.count; i++) {
          NSString *identifier = [NSString stringWithFormat:@"%zd", i];
          Person *person = Stack.memoryStack.query(Person.class).whereIdentifier(identifier).fetchOrCreate();
          person.name = names[i];
        }
      });
      
      query = stack.query(Person.class);
    });
    
    afterEach(^{
      stack.query(Person.class).delete();
    });
    
    it(@"Should delete specific items", ^{
      [[theValue(query.count()) should] equal:theValue(names.count)];
      
      stack.transaction(^{
        id object = query.whereIdentifier(@"1").fetch();
        stack.deleteObjects(@[ object ]);
      });
      
      query.wherePredicate(nil);
      [[theValue(query.count()) should] equal:theValue(names.count - 1)];
    });
    
    it(@"should delete a specific NSManagedObjectID", ^{
      stack.transaction(^{
        NSManagedObjectID *objectID = [query.sortByKey(@"name", YES).lastObject() objectID];
        stack.deleteWhereObjectID(objectID);
        [[theValue(query.count()) should] equal:theValue(names.count - 1)];
      });
    });
    
  });
  
  context(@"Queries", ^{
    it(@"should return a new query", ^{
      [[[Stack memoryStack].query(Person.class) shouldNot] beNil];
    });
  });
  
  context(@"Transactions", ^{
    it(@"should return a new transaction", ^{
      NSManagedObjectContext *threadContext = [NSThread currentThread].threadDictionary[__stackThreadContextKey];
      
      Stack.memoryStack.transaction(^{
        NSManagedObjectContext *transactionContext = [NSThread currentThread].threadDictionary[__stackThreadContextKey];
        [[transactionContext shouldNot] beNil];
        [[threadContext shouldNot] equal:transactionContext];
      });
    });
  });

});

SPEC_END
