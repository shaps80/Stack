# Stack

[![CI Status](http://img.shields.io/travis/Shaps Mohsenin/Stack.svg?style=flat)](https://travis-ci.org/Shaps Mohsenin/Stack)
[![Version](https://img.shields.io/cocoapods/v/Stack.svg?style=flat)](http://cocoadocs.org/docsets/Stack)
[![License](https://img.shields.io/cocoapods/l/Stack.svg?style=flat)](http://cocoadocs.org/docsets/Stack)
[![Platform](https://img.shields.io/cocoapods/p/Stack.svg?style=flat)](http://cocoadocs.org/docsets/Stack)

## Why is Stack better than other solutions?

The best way to understand why Stack is a safer, more simple implementation when dealing with CoreData, is to see some code.

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
        
        Person.query.sort(@"name", YES).groupBy(@"name").delete();
        NSArray *people = Person.query.sort(@"name", YES).groupBy(@"name").results();
        
        NSLog(@"%@", people);
      }
    });
  }
  
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

