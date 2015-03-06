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

#import "metamacros.h"

extern NSString *const __stackThreadContextKey;


/**
 * Creates \c __weak shadow variables for each of the variables provided as
 * arguments, which can later be made strong again with #strongify.
 *
 * This is typically used to weakly reference variables in a block, but then
 * ensure that the variables stay alive during the actual execution of the block
 * (if they were live upon entry).
 *
 * See #strongify for an example of usage.
 */
#define stack_copy(...) \
_stack_keywordify \
metamacro_foreach_cxt(_stack_copy,, _ID, __VA_ARGS__)



/**
 *  Fetches the objects into the current threads context to remove thread-safety issues
 *  @note The excess casting is just to remove compiler warnings since we don't know if we're getting an array or individual objects
 */
#define _stack_copy(INDEX, CONTEXT, VAR) \
id metamacro_concat(VAR, CONTEXT) = [VAR valueForKey:@"objectID"]; \
__typeof__(VAR) VAR = nil; \
\
if ([metamacro_concat(VAR, CONTEXT) isKindOfClass:[NSArray class]]) { \
  NSMutableArray *_objects = [NSMutableArray new]; \
  \
  for (NSManagedObjectID *objectID in metamacro_concat(VAR, CONTEXT)) { \
    [_objects addObject:[NSThread.currentThread.threadDictionary[__stackThreadContextKey] objectWithID:objectID]]; \
  } \
  \
  VAR = _objects.copy; \
} \
\
if ([metamacro_concat(VAR, CONTEXT) isKindOfClass:[NSManagedObjectID class]]) { \
  VAR = (__typeof__(VAR))[NSThread.currentThread.threadDictionary[__stackThreadContextKey] objectWithID:metamacro_concat(VAR, CONTEXT)]; \
} \


// Details about the choice of backing keyword:
//
// The use of @try/@catch/@finally can cause the compiler to suppress
// return-type warnings.
// The use of @autoreleasepool {} is not optimized away by the compiler,
// resulting in superfluous creation of autorelease pools.
//
// Since neither option is perfect, and with no other alternatives, the
// compromise is to use @autorelease in DEBUG builds to maintain compiler
// analysis, and to use @try/@catch otherwise to avoid insertion of unnecessary
// autorelease pools.
#if DEBUG
#define _stack_keywordify autoreleasepool {}
#else
#define _stack_keywordify try {} @catch (...) {}
#endif


#endif

