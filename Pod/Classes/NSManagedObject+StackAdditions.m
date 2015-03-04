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

#import "Stack.h"
#import "NSManagedObject+StackAdditions.h"
#import "SPXDefines.h"

@interface Stack (Private)
- (NSString *)entityNameForClass:(Class)klass;
@end

@implementation NSManagedObject (StackAdditions)

- (void (^)(NSDictionary *))update
{
  __weak typeof(self) weakInstance = self;
  return ^(NSDictionary *attributes) {
    for (id key in attributes.allKeys) {
      [weakInstance setValue:attributes[key] forKey:key];
    }
  };
}

- (id)valueForUndefinedKey:(NSString *)key
{
  SPXLog(@"%@ doesn't recognise the keyPath: %@", self, key);
  return [super valueForUndefinedKey:key];
}

+ (NSString *)entityName
{
  return nil;
}

+ (StackQuery *)query
{
  return [StackQuery new];
}

- (void (^)())delete
{
  return nil;
}

@end
