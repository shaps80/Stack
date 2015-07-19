//
//  StackViewController.h
//  Stack
//
//  Created by Shaps Mohsenin on 02/08/2015.
//  Copyright (c) 2014 Shaps Mohsenin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StackViewController : UIViewController <UITableViewDataSource>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@end
