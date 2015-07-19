//
//  StackViewController.m
//  Stack
//
//  Created by Shaps Mohsenin on 02/08/2015.
//  Copyright (c) 2014 Shaps Mohsenin. All rights reserved.
//

#import "StackViewController.h"
#import "Stack.h"
#import "Person.h"

@interface StackViewController () <NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@end

@implementation StackViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  Stack *stack = [Stack memoryStack];
  StackQuery *query = stack.query(Person.class);
  
  [self createObjectsWithQuery:query];
  
  self.fetchedResultsController = query.sortByKey(@"name", YES).fetchedResultsController();
  self.fetchedResultsController.delegate = self;
  [self.fetchedResultsController performFetch:nil];
}

- (void)createObjectsWithQuery:(StackQuery *)query
{
  query.stack.transaction(^{
    Person *person = query.whereIdentifier(@"124").fetchOrCreate();
    person.name = @"Shaps";
    
    person = query.whereIdentifier(@"321").fetchOrCreate();
    person.name = @"Shaps";
    
    person = query.whereIdentifier(@"432").fetchOrCreate();
    person.name = @"Anne";
    
    person = query.whereIdentifier(@"987").fetchOrCreate();
    person.name = @"Lara";
  });
}


#pragma mark - TableView Datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
  
  Person *person = [self.fetchedResultsController objectAtIndexPath:indexPath];
  cell.textLabel.text = person.name;
  
  return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return self.fetchedResultsController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  id <NSFetchedResultsSectionInfo> info = [self.fetchedResultsController sections][section];
  return [info numberOfObjects];
}

#pragma mark - NSFetchedResultsController Delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
  [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
  switch (type) {
    case NSFetchedResultsChangeInsert:
      [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
      break;
    case NSFetchedResultsChangeDelete:
      [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
      break;
    default:
      [self.tableView reloadData];
      break;
  }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
  switch (type) {
    case NSFetchedResultsChangeInsert:
      [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
      break;
    case NSFetchedResultsChangeDelete:
      [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
      break;
    case NSFetchedResultsChangeMove:
      [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
      break;
    case NSFetchedResultsChangeUpdate:
      [self.tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
      break;
  }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
  [self.tableView endUpdates];
}

@end

