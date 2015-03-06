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
    }).synchronous(YES);
    
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
      }).synchronous(NO);
      
      [[theValue(count) should] equal:theValue(names.count)];
    });
    
    it(@"should perform an asynchronous operation", ^{
      __block NSUInteger count = 0;
      
      stack.transaction(^{
        count = query.count();
      }).asynchronous(NO, ^{
        [[theValue(count) should] equal:theValue(names.count)];
      });
      
      [[theValue(count) should] equal:theValue(0)];
    });
    
  });
  
});

SPEC_END
