//
//  StackAppDelegate.m
//  Stack
//
//  Created by CocoaPods on 02/08/2015.
//  Copyright (c) 2014 Shaps Mohsenin. All rights reserved.
//

#import "StackAppDelegate.h"
#import "Stack.h"
#import "Person.h"
#import "EXTScope.h"


@implementation StackAppDelegate



- (void)threading
{
  Stack *stack = [Stack defaultStack];
  NSArray *people = Person.query.fetch();
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    stack.syncTransaction(^{
      @stack_copy(people);
      self.window.backgroundColor = [UIColor redColor];
      
      Person *person = people.firstObject;
      person.name = @"";
    });
  });
}




- (void)stack
{
  NSDictionary *attributes = @{ @"name" : @"shaps", @"phone" : @"555 2321" };
  Stack *stack = [Stack defaultStack];
  
  for (int i = 0; i < 1000; i++) {
    stack.syncTransaction(^{
      for (int j = 0; j < 1000; j++) {
        NSString *identifier = [NSString stringWithFormat:@"10%zd%dz", i, j];
        Person *person = Person.query.whereIdentifier(identifier, YES);
        
        person.update(@{ @"name" : @"Shaps Mohsenin" });
        person.update(attributes);
        
        Person.query.whereFormat(@"name == nil").count();
        Person.query.whereFormat(@"name == nil").sortByKey(@"name", YES).fetch();
        
        NSArray *people = Person.query.sortByKey(@"name", YES).fetch();
        NSLog(@"%@", people);
      }
    });
  }
}




- (void)naive
{
  NSDictionary *attributes = @{ @"name" : @"shaps", @"phone" : @"555 2321" };
  
  for (int i = 0; i < 1000; i++) {
    NSManagedObjectContext *context = [NSManagedObjectContext new];
    
    [context performBlockAndWait:^{
      
      for (int j = 0; j < 1000; j++) {
        NSString *identifier = [NSString stringWithFormat:@"10%zd%dz", i, j];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:Person.entityName];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", @"identifier", identifier];
        
        request.predicate = predicate;
        request.fetchLimit = 1;
        
        Person *person = (Person *)[context executeFetchRequest:request error:nil].firstObject;
        
        if (!person) {
          person = [NSEntityDescription insertNewObjectForEntityForName:Person.entityName inManagedObjectContext:context];
        }
        
        [person setValue:attributes[@"Shaps"] forKey:@"name"];
        [person setValue:attributes[@"555 2321"] forKey:@"phone"];
        
        request = [NSFetchRequest fetchRequestWithEntityName:Person.entityName];
        request.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ];
        request.predicate = [NSPredicate predicateWithFormat:@"name == nil"];
        
        NSArray *people = [context executeFetchRequest:request error:nil];
        
        for (Person *person in people) {
          [context deleteObject:person];
        }
        
        request = [NSFetchRequest fetchRequestWithEntityName:Person.entityName];
        request.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ];
        
        people = [context executeFetchRequest:request error:nil];
        NSLog(@"%@", people);
      }
      
      [context save:nil];
      
    }];
  }
}



@end
