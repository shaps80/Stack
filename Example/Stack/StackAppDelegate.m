//
//  StackAppDelegate.m
//  Stack
//
//  Created by CocoaPods on 02/08/2015.
//  Copyright (c) 2014 Shaps Mohsenin. All rights reserved.
//

#import "StackAppDelegate.h"
#import <SpriteKit/SpriteKit.h>

#define fadeTo(value)

@implementation StackAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  UIView *view;
  
  [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
    view.alpha = 1;
  } completion:^(BOOL finished) {
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
      view.transform = CGAffineTransformMakeScale(0.5, 0.5);
    } completion:^(BOOL finished) {
      [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        view.transform = CGAffineTransformMakeRotation(45 * M_PI / 180);
      } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
          view.alpha = 0;
        } completion:nil];
      }];
    }];
  }];
  
  return YES;
}

- (void)anotherTry
{
  
}

@end
