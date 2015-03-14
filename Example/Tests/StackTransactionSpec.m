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

SPEC_BEGIN(StackTransactionSpec)

describe(@"StackTransaction", ^{
  
  Stack *stack = [Stack memoryStack];
  
  __block StackQuery *query = nil;
  __block NSArray *names = nil;
  
  beforeEach(^{
    names = @[ @"Shaps", @"Anne", @"Dave", @"Roger", @"Bethany", @"Cyndia", @"Steve" ];
    
    Stack.memoryStack.transaction(^{
      for (NSUInteger i = 0; i < names.count; i++) {
        NSString *identifier = [NSString stringWithFormat:@"%zd", i];
        Person *person = Stack.memoryStack.query(Person.class).whereIdentifier(identifier, YES);
        person.name = names[i];
      }
    });
    
    query = Stack.memoryStack.query(Person.class);
  });
  
  afterEach(^{
    Stack.memoryStack.query(Person.class).delete();
  });

  context(@"Operations", ^{
    
    it(@"should perform a synchronous operation", ^{
      __block NSUInteger count = 0;
      
      stack.transaction(^{
        count = query.count();
      });
      
      [[theValue(count) should] equal:theValue(names.count)];
    });
    
    it(@"should perform an asynchronous operation", ^{
      __block NSUInteger count = 0;
      
      stack.asyncTransaction(^{
        count = query.count();
      }, ^{
        [[theValue(count) should] equal:theValue(names.count)];
      });
      
      [[theValue(count) should] equal:theValue(0)];
    });
    
  });
  
  context(@"Threading", ^{
    
    it(@"context should see updates from another thread", ^{
      __block Person *person = query.whereIdentifier(@"0", NO);
      
      stack.asyncTransaction(^{
        
      }, ^{
        
      });
      
      stack.asyncTransaction(^{
        @stack_copy(person);
        person.name = @"Jeff";
      }, ^{
        person = query.whereIdentifier(@"0", NO);
        [[person.name should] equal:@"Jeff"];
      });
    });
    
    it(@"context should exist per thread", ^{
      __block Person *person = query.whereIdentifier(@"0", NO);
      __block NSManagedObjectContext *context1 = nil, *context2 = nil;
      
      stack.asyncTransaction(^{
        @stack_copy(person);
        context1 = person.managedObjectContext;
      }, ^{
        person = query.whereIdentifier(@"0", NO);
        context2 = person.managedObjectContext;
        [[context1 shouldNot] equal:context2];
      });
    });
    
    it(@"inner context's parent should be the same as outer context's parent", ^{
      __block Person *person = query.whereIdentifier(@"0", NO);
      __block NSManagedObjectContext *context1 = nil, *context2 = nil;
      
      stack.asyncTransaction(^{
        @stack_copy(person);
        context1 = person.managedObjectContext;
      }, ^{
        person = query.whereIdentifier(@"0", NO);
        context2 = person.managedObjectContext;
        [[context1.parentContext should] equal:context2.parentContext];
      });
    });
    
    it(@"context thread should be the current thread", ^{
      stack.transaction(^{
        NSThread *thread = [NSThread currentThread];
        NSManagedObjectContext *threadContext = thread.threadDictionary[__stackThreadContextKey];
        
        Person *person = query.whereIdentifier(@"0", NO);
        [[person.managedObjectContext should] equal:threadContext];
      });
    });
    
    it(@"object context should be from a different thread when @stack_copy is NOT used", ^{
      __block Person *person = query.whereIdentifier(@"0", NO);
      __block NSManagedObjectContext *context1 = nil, *context2 = nil;
      
      stack.asyncTransaction(^{
        context1 = person.managedObjectContext;
        context2 = [NSThread currentThread].threadDictionary[__stackThreadContextKey];
        [[context1 shouldNot] equal:context2];
      }, nil);
    });
    
  });
  
});

SPEC_END
