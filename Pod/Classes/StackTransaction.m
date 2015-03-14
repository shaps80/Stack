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

#import <CoreData/CoreData.h>
#import "NSManagedObjectContext+StackAdditions.h"
#import "StackTransaction.h"
#import "Stack.h"

@interface Stack ()
- (NSManagedObjectContext *)transactionContext;
@property (nonatomic, strong) NSManagedObjectContext *currentThreadContext;
@end

@interface StackTransaction ()

@property (nonatomic, weak) Stack *stack;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, copy) void (^transactionCompletionBlock)();
@property (nonatomic, copy) void (^transactionBlock)();

@end

@implementation StackTransaction

- (void (^)())saveSynchronously
{
  __weak typeof(self) weakInstance = self;
  return ^() {
    NSManagedObjectContext *context = [weakInstance.stack transactionContext];
    
    [context performBlockAndWait:^{
      weakInstance.stack.currentThreadContext = context;
      !weakInstance.transactionBlock ?: weakInstance.transactionBlock();
      [context saveSynchronously:YES completion:nil];
    }];
    
    weakInstance.stack.currentThreadContext = nil;
    !weakInstance.transactionCompletionBlock ?: weakInstance.transactionCompletionBlock();
  };
}

- (void (^)())saveAsynchronously
{
  __weak typeof(self) weakInstance = self;
  return ^ {
    NSManagedObjectContext *context = [weakInstance.stack transactionContext];
    
    [context performBlock:^{
      weakInstance.stack.currentThreadContext = context;
      !weakInstance.transactionBlock ?: weakInstance.transactionBlock();
      
      [context saveSynchronously:NO completion:^(BOOL success, NSError *error) {
        !weakInstance.transactionCompletionBlock ?: weakInstance.transactionCompletionBlock();
      }];
      
    }];
    
    weakInstance.stack.currentThreadContext = nil;
  };
}

@end
