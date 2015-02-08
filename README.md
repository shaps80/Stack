# Stack

[![CI Status](http://img.shields.io/travis/Shaps Mohsenin/Stack.svg?style=flat)](https://travis-ci.org/Shaps Mohsenin/Stack)
[![Version](https://img.shields.io/cocoapods/v/Stack.svg?style=flat)](http://cocoadocs.org/docsets/Stack)
[![License](https://img.shields.io/cocoapods/l/Stack.svg?style=flat)](http://cocoadocs.org/docsets/Stack)
[![Platform](https://img.shields.io/cocoapods/p/Stack.svg?style=flat)](http://cocoadocs.org/docsets/Stack)

## Why is Stack better than other solutions?

The best way to understand why Stack is a safer, much simpler implementation when dealing with CoreData, is to see some code.

```objc
for (int i = 0; i < 1000; i++) {
    Stack.defaultStack.transaction(^{
    
      for (int j = 0; j < 1000; j++) {
        NSString *identifier = [NSString stringWithFormat:@"10%zd%dz", i, j];
        Person *person = Person.query.whereIdentifier(identifier, YES);
        
        person.update(@
        {
          @"name" : @"firstName",
          @"phone" : @"phoneNumber",
        });
        
        Person.query.where(@"name == nil").delete();
        NSArray *people = Person.query.sort(@"name", YES).groupBy(@"name").results();
        
        NSLog(@"%@", people);
      }
      
    });
  }
```

Lets break down the code to understand the benefits.

First we grab the defaultStack and create a transaction to improve performance and limit our hits to disk:
```objc
Stack.defaultStack.transaction();
```

We then query CoreData for an instance of Person with the specified identifier:
```objc
Person *person = Person.query.whereIdentifier(identifier, YES);
```

Now we have our `Person` we can update some (or all) of its attributes:
```objc
person.update(@
        {
          @"name" : @"firstName",
          @"phone" : @"phoneNumber",
        });
```

Now we delete all `Person` objects where the name is empty.
```objc
Person.query.where(@"name == nil").delete();
```

Finally we fetch all current `Person` results, sorted by name in ascending order and grouped by role.
```objc
NSArray *people = Person.query.sort(@"name", YES).groupBy(@"role").results();
NSLog(@"%@", people);
```

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

Stack is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "Stack"

## Author

Shaps Mohsenin, shaps@theappbusiness.com

## License

Stack is available under the MIT license. See the LICENSE file for more info.

