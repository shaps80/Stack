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
#import "SPXDefines.h"

static NSMutableDictionary * RegisteredStacks;

static NSString *const DefaultStackName = @"_DefaultStack";
static NSString *const ManualStackName = @"_ManualStack";
static NSString *const MemoryStackName = @"_MemoryStack";

@interface Stack ()
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSDictionary *entityToClassNameMappings;
@end

@implementation Stack

#pragma mark - Initializers

- (NSDictionary *)entityToClassNameMappings
{
  return _entityToClassNameMappings ?: (_entityToClassNameMappings = [NSDictionary new]);
}

- (NSString *)entityNameForClass:(Class)klass
{
  return self.entityToClassNameMappings[NSStringFromClass(klass)];
}

- (void)loadEntityMappings
{
  NSManagedObjectModel *model = self.managedObjectModel;
  NSMutableDictionary *mappings = [NSMutableDictionary new];
  
  [model.entitiesByName enumerateKeysAndObjectsUsingBlock:^(NSString *entityName, NSEntityDescription *entityDescription, BOOL *stop) {
    mappings[entityDescription.managedObjectClassName] = entityName;
  }];
  
  self.entityToClassNameMappings = mappings.copy;
}

+ (instancetype)defaultStack
{
  static Stack *_defaultStack = nil;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
    _defaultStack = [Stack registerStackWithName:DefaultStackName model:Stack.defaultStackModel storeURL:Stack.defaultStackURL inMemoryOnly:NO];
  });
  
  return _defaultStack;
}

+ (instancetype)memoryStack
{
  static Stack *_memoryStack = nil;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
    _memoryStack = [Stack registerStackWithName:MemoryStackName model:Stack.defaultStackModel storeURL:Stack.defaultStackURL inMemoryOnly:YES];
  });
  
  return _memoryStack;
}

+ (instancetype)stackNamed:(NSString *)name
{
  return RegisteredStacks[name];
}

+ (instancetype)registerStackWithName:(NSString *)name model:(NSManagedObjectModel *)model storeURL:(NSURL *)storeURL inMemoryOnly:(BOOL)memoryOnly
{
  SPXAssertTrueOrReturnNil(!RegisteredStacks[name]);
  
  if (!RegisteredStacks) {
    RegisteredStacks = [NSMutableDictionary new];
  }
  
  Stack *stack = [[Stack alloc] initWithName:name model:model storeURL:storeURL inMemoryOnly:memoryOnly];
  RegisteredStacks[name] = stack;
  
  return stack;
}

- (instancetype)initWithName:(NSString *)name model:(NSManagedObjectModel *)model storeURL:(NSURL *)storeURL inMemoryOnly:(BOOL)memoryOnly
{
  self = [super init];
  SPXAssertTrueOrReturnNil(self);
  
  if (memoryOnly) {
    
  }
  
  return self;
}

#pragma mark - Transactions


#pragma mark - Helpers

+ (NSManagedObjectModel *)defaultStackModel
{
  return [NSManagedObjectModel mergedModelFromBundles:nil];
}

+ (NSURL *)defaultStackURL
{
  NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
  NSString *storeName = [NSBundle mainBundle].infoDictionary[@"CFBundleName"];
  return [url URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", storeName]];
}

@end
