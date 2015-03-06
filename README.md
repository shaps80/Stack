# Stack

[![CI Status](http://img.shields.io/travis/shaps80/Stack.svg?style=flat)](https://travis-ci.org/shaps80/Stack)
[![Version](https://img.shields.io/cocoapods/v/Stack.svg?style=flat)](http://cocoadocs.org/docsets/Stack)
[![License](https://img.shields.io/cocoapods/l/Stack.svg?style=flat)](http://cocoadocs.org/docsets/Stack)
[![Platform](https://img.shields.io/cocoapods/p/Stack.svg?style=flat)](http://cocoadocs.org/docsets/Stack)

Stack was created to provide a more expressive, safe and clean implementation for a CoreData stack implementation.

Stack provides block chaining to allow you to better construct your queries, as well as a transaction block to allow you to better batch a series of requests, improving performance.

Stack also provides cleaner implementations for specifying sort descriptors and predicates.

## Goal

Stack aims to provide a clean and safe abstraction from Core Data that gives your the flexibility and power of CoreData without all the context/thread-safety concerns. This is achieved by having complete thread and transaction based context management built right in.

You wouldn't manage the storage and usage of a CATransaction would you? So why do we still have to think about NSManagedObjectContext?

This is an idea or concept for how I wish CoreData worked out of the box. I'm really keen to get thoughts, suggestions and ideas so please generate a PR or post any issues if you want to contribute ;)

## Features

* Extremely lightweight -- yet powerful -- CoreData stack -- just 3 classes!!!
* Full NSManagedObjectContext management -- you don't have to think about it and should never hold a reference to one
* Clean block based API
* Chain based API allowing you to chain multiple commands together
* Transaction blocks -- supporting nesting, siblings and reentrancy
* @stack_copy(...) convenience macro for passing objects across threads -- my fave feature!
* NSFetchedResultsController convenience method for creating them for you

## Safer

I am not someone who typically likes to abstract away too many details but with simple and common CoreData configurations, understanding the context, threading and other issues just seemed crazy to me.

With Stack, you can use a transaction block at anytime to make changes safely. In fact if you have an object from another context/thread you can safely update that too using the Stack macro `@stack_copy(...)` which takes multiple arguments so you can pass an array, an NSManagedObject instance or a combination of the two. They don't even have to share the same entity type ;)

You can even use Stack queries in, out and around the transaction because Stack automatically uses the right context for you.

```objc
Stack *stack = [Stack defaultStack];
  Person *person = stack.query(Person.class).whereIdentifier(@"1234", YES);
  // person.name is 'Shaps'
  
  dispatch_async(dispatch_get_global_queue(0, 0), ^{
    stack.transaction(^{
      
      @stack_copy(person);
      person.name = @"Anne";
      
    }).synchronous(YES); // person.name is safely updated
  });
```

## Cleaner

The best way to understand why Stack is a safer, much simpler implementation for working with CoreData, is to see some code.

```objc
NSDictionary *attributes = @
{
	@"name" : @"Shaps",
	@"phone" : @"555-2321"
};

Stack *stack = [Stack defaultStack];
stack.transaction(^{    
    Person *person = stack.query(Person.class).whereIdentifier(@"124", YES);
    person.update(attributes);    
    NSLog(@"%@", person);
 });
}
```

Lets contrast this with a naive approach we might normally see implemented.

```objc
NSDictionary *attributes = @
{
	@"name" : @"Shaps",
	@"phone" : @"555-2321"
};

NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
  
[context performBlockAndWait:^{
  NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:Person.entityName];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", @"identifier", identifier];
    
  request.predicate = predicate;
  request.fetchLimit = 1;
    
  Person *person = (Person *)[context executeFetchRequest:request error:nil].firstObject;
    
  if (!person) {
    person = [NSEntityDescription insertNewObjectForEntityForName:Person.entityName inManagedObjectContext:context];
  }
    
  [person setValue:identifier forKey:@"identifier"]
  [person setValue:attributes[@"name"] forKey:@"name"];
  [person setValue:attributes[@"phone"] forKey:@"phone"];
    
  NSLog(@"%@", person);
    
  [context save:nil];
}];
```

## NSFetchedResultsController

You can easily create a NSFetchedResultsController from any query in Stack.

```objc
controller = stack.query(Account.class).sortByKey(@"email", YES).fetchedResultsController(section, delegate);
```

Stack will automatically setup the context and fetch request for you.

## Interface

Hopefully now its a little more obvious how much simpler it is to work with CoreData.
Stack makes this easy by providing a simple interface compared to most other implementations.

```objc
@property ... StackQuery *(^wherePredicate)(NSPredicate *predicate);
@property ... StackQuery *(^where)(NSString *format, ...);
@property ... StackQuery *(^sortByKey)(NSString *key, BOOL ascending);
@property ... StackQuery *(^sortWithDescriptors)(NSArray *sortDescriptors);
@property ... void (^delete)();
@property ... NSUInteger (^count)();
@property ... NSArray *(^fetch)();
@property ... id (^whereIdentifier)(NSString *identifier, BOOL createIfNil);
@property ... NSArray *(^whereIdentifiers)(NSArray *identifiers, BOOL createIfNil);
```

Notice most of the implementations return an instance of `StackQuery`, allowing you to chain in any combination. 

>Note when calling any of the `sort`, `predicate` or `where` methods multiple times, the last call will be used.

Even my own previous implementations were much more cumbersome than this. Stack provides just a few block-based methods for maximum flexibility, whereas the previous implementation had over 20+ and even then not all combinations or features were accounted for. Here's just a few for comparison:

```objc
+ (void)deleteAllMatching:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;
+ (NSArray *)objectsWithIdentifiers:(NSArray *)identifiers sorting:(NSArray *)sortDescriptors faulted:(BOOL)faulted create:(BOOL)create inContext:(NSManagedObjectContext *)context;
+ (instancetype)objectWithIdentifier:(id)identifier faulted:(BOOL)faulted create:(BOOL)create inContext:(NSManagedObjectContext *)context;
+ (NSUInteger)countAllSorted:(NSArray *)sortDescriptors predicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;
+ (NSArray *)allSorted:(NSArray *)sortDescriptors predicate:(NSPredicate *)predicate faulted:(BOOL)faulted inContext:(NSManagedObjectContext *)context;
```

All methods require you to pass in the current `NSManagedObjectContext` as well. This helped the implementer to keep their code safe from threading issues, but still allowed you to make silly decisions at times. 

>And that's not even including all the variations of those methods.

## How is Stack safer

CoreData is unfortunately terrible when it comes to multi-threading. Apple made things a little easier with the introduction of `-performBlock:` but this still requires the implementer to think about their thread usage.

Stack attempts to go one step further by removing the necessity for the implementer to know about the context at all.

Instead all `write` actions _must_ be performed inside a transaction block, where the context is managed for you.
`Stack.defaultStack.transaction(^{  ...  })`

Read actions can occur anywhere, since those are not a concern. By forcing you to use a transaction block for all saves, Stack can provide better exception and error handling. In fact if you attempt to write to any context outside of a transaction block (even if you're not using Stack directly), an exception will be thrown, making it much easier to find threading issues in your project.

Sometimes however you need to `read` on one thread but want to `write` on another. Stack provides a convenient method macro for copying your objects into the current context for you:

```objc
@stack_copy(...)
@stack_copy(people)
@stack_copy(person1, person2)
```

This allows you to copy an array, a single object, or some variation since the macro uses variadic arguments.

>Just make sure you do any updates inside the transaction, otherwise your changes won't persist.

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.	

## Installation

Stack is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "Stack"

## Author

Shaps Mohsenin, shaps@theappbusiness.com

## License

Stack is available under the MIT license. See the LICENSE file for more info.

## Attribution

* All code is my own, no 3rd party code is used in this project at all. 
* Thanks to [Nick Lockwood](http://github.com/nicklockwood) for help around the transaction API
* Thanks to [Krzysztof Zablocki](https://github.com/krzysztofzablocki) for the block based inspiration

