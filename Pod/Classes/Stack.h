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

#import "StackDefines.h"
#import "StackTransaction.h"
#import "NSManagedObject+StackAdditions.h"


/**
 *  An object representing a CoreData stack. Multiple configurations are available.
 */
@interface Stack : NSObject


/**
 *  A transaction can be used to batch mutliple queries, improving performance in some cases. Can be nested and called reentrantly
 *
 *  @note Thanks to Nick Lockwood for the solution around this approach
 */
@property (nonatomic, readonly) StackTransaction* (^transaction)(void (^transactionBlock)());


/**
 *  Returns a new query instance, allowing you to run queries on the specified managedObjectClass
 *
 *  @return A new StackQuery instance
 */
@property (nonatomic, readonly) StackQuery* (^query)(Class managedObjectClass);


/**
 *  Returns the entity name for the specified NSManagedObjectClass in this stack.
 */
@property (nonatomic, readonly) NSString* (^entityNameForClass)(Class managedObjectClass);


/**
 *  Returns the default stack configuration. This implementation uses a parent-child based stack. The defaultStack is persisted to disk.
 *  @return A shared instance
 */
+ (instancetype)defaultStack;


/**
 *  Returns the default stack configuration. This implementation uses a parent-child based stack. The defaultStack is loaded into memory only.
 *  @return A shared in-memory instance
 */
+ (instancetype)memoryStack;


/**
 *  Registers a new stack
 *
 *  @param name       The name representing an identifier for this stack
 *  @param model      The model to be represented by this stack
 *  @param storeURL   The URL for persisting this stack to disk. This can be nil if you are registering a memory-only stack
 *  @param memoryOnly If YES, persistence to disk will not be used.
 *
 *  @return The registered instance
 */
+ (instancetype)registerStackWithName:(NSString *)name model:(NSManagedObjectModel *)model storeURL:(NSURL *)storeURL inMemoryOnly:(BOOL)memoryOnly;


/**
 *  Returns the stack registered with the specified name if it exits, nil otherwise
 *
 *  @param name The name of the stack to return
 *
 *  @return An existing stack if it exists, nil otherwise
 */
+ (instancetype)stackNamed:(NSString *)name;


@end

