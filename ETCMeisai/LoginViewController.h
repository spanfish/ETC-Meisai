//
//  LoginViewController.h
//  ETCMeisai
//
//  Created by Xiangwei Wang on 11/4/16.
//  Copyright © 2016 Xiangwei Wang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface LoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property(nonatomic, weak) IBOutlet UIView *containerView;
@property(nonatomic, weak) IBOutlet UIView *loginView;
@property(nonatomic, weak) IBOutlet UIButton *loginButton;
@property(nonatomic, weak) IBOutlet UITextField *userIdField;
@property(nonatomic, weak) IBOutlet UITextField *passwordField;

@end


@interface LoginTableViewCell : UITableViewCell
@property(nonatomic, weak) IBOutlet UITextField *inputField;
@end
