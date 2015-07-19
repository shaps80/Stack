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

#ifndef __STACK_DEFINES_H
#define __STACK_DEFINES_H

@import Foundation;
#import "metamacros.h"

extern NSString *const __stackThreadContextKey;


/**
 * Creates \c local shadow variables for each of the variables provided as arguments, which can later be made strong again with stack_copy(...)
 */
#define stack_prepare(...) \
metamacro_foreach_cxt(_stack_prepare,, _stack_, __VA_ARGS__)




/**
 * Imports the local shadow copies into the current NSManagedObjectContext
 */
#define stack_copy(...) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
metamacro_foreach_cxt(_stack_copy,, _stack_, __VA_ARGS__) \
_Pragma("clang diagnostic pop") \


/**
 *  Fetches the objects into the current threads context to remove thread-safety issues
 *  @note The excess casting is just to remove compiler warnings since we don't know if we're getting an array or individual objects
 */
#define _stack_prepare(INDEX, CONTEXT, VAR) \
__typeof__(VAR) metamacro_concat(CONTEXT, VAR) = VAR;


/**
 *  Fetches the objects into the current threads context to remove thread-safety issues
 *  @note The excess casting is just to remove compiler warnings since we don't know if we're getting an array or individual objects
 */
#define _stack_copy(INDEX, CONTEXT, VAR) \
__typeof__(metamacro_concat(CONTEXT, VAR)) VAR = nil; \
id metamacro_concat(_stack_object_, VAR) = [metamacro_concat(CONTEXT, VAR) valueForKey:@"objectID"]; \
\
if ([metamacro_concat(_stack_object_, VAR) isKindOfClass:[NSArray class]]) { \
  NSMutableArray *_stack_objects = [NSMutableArray new]; \
  \
  for (NSManagedObjectID *objectID in metamacro_concat(_stack_object_, VAR)) { \
    [_stack_objects addObject:[NSThread.currentThread.threadDictionary[__stackThreadContextKey] objectWithID:objectID]]; \
  } \
  \
  VAR = _stack_objects.copy; \
} \
\
if ([metamacro_concat(_stack_object_, VAR) isKindOfClass:[NSManagedObjectID class]]) { \
  VAR = (__typeof__(metamacro_concat(CONTEXT, VAR)))[NSThread.currentThread.threadDictionary[__stackThreadContextKey] objectWithID:metamacro_concat(_stack_object_, VAR)]; \
} \


#endif

