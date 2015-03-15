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

static NSMutableDictionary * __registeredStacks;
NSString *const __stackThreadContextKey = @"__stackContextKey";
NSString *const __stackTransactionKey = @"__stackTransactionKey";


@interface StackTransaction (Private)
@property (nonatomic, weak) Stack *stack;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, copy) void (^transactionBlock)();
@property (nonatomic, copy) void (^transactionCompletionBlock)();
@property (nonatomic, copy) void (^saveSynchronously)();
@property (nonatomic, copy) void (^saveAsynchronously)();
@end


@interface StackQuery (Private)
@property (nonatomic, weak) Stack *stack;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
+ (instancetype)queryForManagedObjectClass:(Class)managedObjectClass entityName:(NSString *)entityName;
@end


@interface Stack ()

@property (nonatomic, strong) NSDictionary *entityNameToClassMappings;
@property (nonatomic, strong) NSPersistentStoreCoordinator *coordinator;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;

@property (nonatomic, strong) NSManagedObjectContext *rootContext;
@property (nonatomic, strong) NSManagedObjectContext *mainThreadContext;
@property (nonatomic, strong) NSManagedObjectContext *transactionContext;
@property (nonatomic, strong) NSManagedObjectContext *currentThreadContext;

@end

@implementation Stack

@synthesize currentThreadContext = _currentThreadContext;

#pragma mark - Initializers

- (void)loadEntityMappings
{
  NSManagedObjectModel *model = self.managedObjectModel;
  NSMutableDictionary *mappings = [NSMutableDictionary new];
  
  [model.entitiesByName enumerateKeysAndObjectsUsingBlock:^(NSString *entityName, NSEntityDescription *entityDescription, BOOL *stop) {
    mappings[entityDescription.managedObjectClassName] = entityName;
  }];

  self.entityNameToClassMappings = mappings.copy;
}

+ (instancetype)defaultStack
{
  static Stack *_defaultStack = nil;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
    NSString *name = [NSBundle mainBundle].infoDictionary[@"CFBundleName"];
    name = [name stringByAppendingString:@"_Default"];
    _defaultStack = [Stack registerStackWithName:name model:Stack.defaultStackModel storeURL:Stack.defaultStackURL inMemoryOnly:NO];
  });
  
  return _defaultStack;
}

+ (instancetype)memoryStack
{
  static Stack *_memoryStack = nil;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
    NSString *name = [NSBundle mainBundle].infoDictionary[@"CFBundleName"];
    name = [name stringByAppendingString:@"_Memory"];
    _memoryStack = [Stack registerStackWithName:name model:Stack.defaultStackModel storeURL:Stack.defaultStackURL inMemoryOnly:YES];
  });
  
  return _memoryStack;
}

+ (instancetype)stackNamed:(NSString *)name
{
  return __registeredStacks[name];
}

+ (instancetype)registerStackWithName:(NSString *)name model:(NSManagedObjectModel *)model storeURL:(NSURL *)storeURL inMemoryOnly:(BOOL)memoryOnly
{
  SPXAssertTrueOrReturnNil(!__registeredStacks[name]);
  
  if (!__registeredStacks) {
    __registeredStacks = [NSMutableDictionary new];
  }
  
  if (__registeredStacks[name]) {
    return __registeredStacks[name];
  }
  
  Stack *stack = [[Stack alloc] initWithName:name model:model storeURL:storeURL inMemoryOnly:memoryOnly];
  __registeredStacks[name] = stack;
  
  return stack;
}

- (instancetype)initWithName:(NSString *)name model:(NSManagedObjectModel *)model storeURL:(NSURL *)storeURL inMemoryOnly:(BOOL)memoryOnly
{
  self = [super init];
  SPXAssertTrueOrReturnNil(self);
  
  _managedObjectModel = model;
  _coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
  SPXAssertTrueOrReturnNil(_coordinator);
  
  NSError *error = nil;
  NSDictionary *autoMigratingOptions = self.class.autoMigratingOptions;
  NSPersistentStore *store = nil;
  
  if (memoryOnly) {
    store = [_coordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:autoMigratingOptions error:&error];
  } else {
    store = [_coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:autoMigratingOptions error:&error];
  }
  
  if (error) {
    SPXLog(@"%@", error);
    error = nil;
  }
  
  if (!store && !memoryOnly) {
    if (![[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error]) {
      SPXLog(@"%@", error);
    }
    
    store = [_coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:autoMigratingOptions error:&error];
    
    if (error) {
      SPXLog(@"%@", error);
    }
    
    SPXAssertTrueOrReturnNil(store);
  }
  
  _rootContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
  _rootContext.persistentStoreCoordinator = _coordinator;
  [self loadEntityMappings];
  
  return self;
}

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

+ (NSDictionary *)autoMigratingOptions
{
  return @{  NSMigratePersistentStoresAutomaticallyOption : @(YES),
             NSInferMappingModelAutomaticallyOption       : @(YES),
             };
}

+ (void)handleError:(NSError *)error
{
  if (!error) {
    return;
  }
  
  for (NSArray *detailedError in error.userInfo.allValues) {
    if ([detailedError isKindOfClass:[NSArray class]]) {
      for (NSError *err in detailedError) {
        if ([err respondsToSelector:@selector(userInfo)]) {
          SPXLog(@"Error Details: %@", err.userInfo);
        } else {
          SPXLog(@"Error Details: %@", err);
        }
      }
    } else {
      SPXLog(@"Error: %@", detailedError);
    }
  }
  
  SPXLog(@"Error Message: %@", [error localizedDescription]);
  SPXLog(@"Error Domain: %@", [error domain]);
  SPXLog(@"Recovery Suggestion: %@", [error localizedRecoverySuggestion]);
}

#pragma mark - Contexts

- (NSManagedObjectContext *)mainThreadContext
{
  return _mainThreadContext ?: ({
    NSManagedObjectContext *mainThreadContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    mainThreadContext.parentContext = self.rootContext;
    _mainThreadContext = mainThreadContext;
  });
}

- (void)setCurrentThreadContext:(NSManagedObjectContext *)context
{
  NSThread *thread = NSThread.currentThread;
  
  if (context) {
    thread.threadDictionary[__stackThreadContextKey] = context;
  } else {
    [thread.threadDictionary removeObjectForKey:__stackThreadContextKey];
  }
}

- (NSManagedObjectContext *)currentThreadContext
{
  NSManagedObjectContext *context = nil;
  NSThread *thread = NSThread.currentThread;
  
  context = thread.threadDictionary[__stackThreadContextKey];
  
  if (!context) {
    if (NSThread.isMainThread) {
      context = self.mainThreadContext;
    } else {
      context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
      context.parentContext = self.mainThreadContext;
    }
    
    self.currentThreadContext = context;
  }
  
  return context;
}

- (NSManagedObjectContext *)transactionContext
{
  NSManagedObjectContext *context = [[self transactionStack].lastObject managedObjectContext];
  
  if (!context) {
    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = self.mainThreadContext;
    [self.transactionStack.lastObject setManagedObjectContext:context];
  }

  return context;
}

#pragma mark - Deletes

- (void (^)(NSArray *))deleteObjects
{
  return ^(NSArray *objects) {
    for (id object in objects) {
      SPXAssertTrueOrReturn([object isKindOfClass:[NSManagedObject class]]);
      [self.currentThreadContext deleteObject:object];
    }
  };
}

- (void (^)(NSManagedObjectID *))deleteWhereObjectID
{
  return ^(NSManagedObjectID *objectID) {
    [self.currentThreadContext deleteObject:[self.transactionContext objectWithID:objectID]];
  };
}

#pragma mark - Queries

- (NSString *(^)(__unsafe_unretained Class))entityNameForClass
{
  return ^(__unsafe_unretained Class managedObjectClass) {
    return self.entityNameToClassMappings[NSStringFromClass(managedObjectClass)];
  };
}

- (StackQuery *(^)(__unsafe_unretained Class))query
{
  return ^(__unsafe_unretained Class managedObjectClass) {
    SPXAssertTrueOrPerformAction([managedObjectClass isSubclassOfClass:[NSManagedObject class]], return (StackQuery *)nil);
    StackQuery *query = [StackQuery queryForManagedObjectClass:managedObjectClass entityName:self.entityNameForClass(managedObjectClass)];
    query.stack = self;
    return query;
  };
}

#pragma mark - Transactions

- (NSMutableArray *)transactionStack
{
  NSThread *thread = NSThread.currentThread;
  NSMutableArray *stack = thread.threadDictionary[__stackTransactionKey];
  
  if (!stack) {
    stack = [NSMutableArray new];
    thread.threadDictionary[__stackTransactionKey] = stack;
  }
  
  return stack;
}

- (StackTransaction *)pushTransaction
{
  NSMutableArray *stack = [self transactionStack];
  StackTransaction *transaction = [StackTransaction new];
  transaction.stack = self;
  [stack addObject:transaction];
  return transaction;
}

- (void)popTransaction
{
  NSMutableArray *stack = [self transactionStack];
  [stack removeLastObject];
}

- (void (^)(void (^transactionBlock)()))transaction
{  
  __weak typeof(self) weakInstance = self;
  return ^(void (^transactionBlock)()) {
    StackTransaction *transaction = [weakInstance pushTransaction];
    
    transaction.transactionCompletionBlock = ^{
      [weakInstance popTransaction];
    };
    
    transaction.transactionBlock = transactionBlock;
    transaction.saveSynchronously();
  };  
}

- (void (^)(void (^)(), void (^)()))asyncTransaction
{
  __weak typeof(self) weakInstance = self;
  return ^(void (^transactionBlock)(), void (^completionBlock)()) {
    StackTransaction *transaction = [weakInstance pushTransaction];
    
    transaction.transactionCompletionBlock = ^{
      [weakInstance popTransaction];
      !completionBlock ?: completionBlock();
    };
    
    transaction.transactionBlock = transactionBlock;
    transaction.saveAsynchronously();
  };
}

@end
