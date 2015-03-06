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


/**
 *  A StackQuery instance is used for querying CoreData entities
 */
@interface StackQuery : NSObject


/**
 *  Returns a new configured NSFetchedResultsController
 */
@property (nonatomic, readonly) NSFetchedResultsController *(^fetchedResultsController)(NSString *sectionNameKeyPath, id <NSFetchedResultsControllerDelegate> delegate);


/**
 *  Adds a predicate to this query
 *  @param predicate  The predicate to apply
 */
@property (nonatomic, readonly) StackQuery *(^wherePredicate)(NSPredicate *predicate);


/**
 *  Adds a predicate to this query, via a format string
 *  @param format The format string to use to build the predicate
 */
@property (nonatomic, readonly) StackQuery *(^whereFormat)(NSString *format, ...);


/**
 *  Adds a sort descriptor to the query
 *  @param key        The sortkey to sort by
 *  @param ascending  If YES, sorting will be in ascending order, otherwise descending will be used
 */
@property (nonatomic, readonly) StackQuery *(^sortByKey)(NSString *key, BOOL ascending);


/**
 *  Adds an array of sort descriptos to the query
 *  @param sortDescriptors  The array of NSSortDescriptors to add to this query
 */
@property (nonatomic, readonly) StackQuery *(^sortWithDescriptors)(NSArray *sortDescriptors);


/**
 *  Ensures all returned objects are faulted when fetched
 */
@property (nonatomic, readonly) StackQuery *(^faultFilled)();


/**
 *  Limits the number of fetched results to cache when fetched
 */
@property (nonatomic, readonly) StackQuery *(^limit)(NSUInteger limit);


/**
 *  Offsets the start index for the fetched results to cacht when fetched
 */
@property (nonatomic, readonly) StackQuery *(^offset)(NSUInteger offset);


/**
 *  Limits the size of the cache when fetched
 */
@property (nonatomic, readonly) StackQuery *(^batchSize)(NSUInteger size);


/**
 *  Deletes the objects returned from this query
 */
@property (nonatomic, readonly) void (^delete)();


/**
 *  Deletes the specified objects from this query
 */
@property (nonatomic, readonly) void (^deleteObjects)(NSArray *objects);


/**
 *  Returns the number of objects that would be returned for this query. This will not fetch the objects themselves.
 */
@property (nonatomic, readonly) NSUInteger (^count)();


/**
 *  Performs the query and returns the results
 */
@property (nonatomic, readonly) NSArray *(^fetch)();


/**
 *  Returns the object for the specified identifier. If createIfNil == YES and the identifier doesn't exist, the object will be created.
 *  @param identifier   The identifier of the object to return
 *  @param createIfNil  If YES, creates the object where it doesn't exist. If NO, the object will not be created, instead nil will be returned
 */
@property (nonatomic, readonly) id (^whereIdentifier)(NSString *identifier, BOOL createIfNil);


/**
 *  Returns the objects for the specified identifiers. If createIfNil == YES and an identifier doesn't exist, an object will be created.
 *  @param identifier   The identifier of the objects to return
 *  @param createIfNil  If YES, creates the objects where they don't exist. If NO, the objects will not be created. If no objects are found or create, nil will be returned
 */
@property (nonatomic, readonly) NSArray *(^whereIdentifiers)(NSArray *identifiers, BOOL createIfNil);


@end


