//
//  LoginViewController.m
//  ETCMeisai
//
//  Created by Xiangwei Wang on 11/4/16.
//  Copyright © 2016 Xiangwei Wang. All rights reserved.
//

#import "LoginViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <AFNetworking/AFNetworking.h>
#import "HTMLNode.h"
#import "HTMLParser.h"
#import "ViewController.h"
#import "MBProgressHUD.h"
#import "HtmlUtil.h"
#import "UICKeyChainStore.h"
#import <LocalAuthentication/LAContext.h>
@interface LoginViewController ()
@end

@implementation LoginViewController
-(void) viewDidLoad
{
    [super viewDidLoad];
    self.loginView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.loginView.layer.borderWidth = 1;
    self.loginView.layer.cornerRadius = 8;
    self.loginView.layer.masksToBounds = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    
    self.loginButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.loginButton.layer.borderWidth = 1;
    self.loginButton.layer.cornerRadius = 4;
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self showLogin];
}

-(void) showLogin
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    [MBProgressHUD showHUDAddedTo:appDelegate.window animated:TRUE];
    [[HtmlUtil sharedInstance] GET:LOGIN_URL
                        parameters:nil
                           success:^(NSString *html) {
                               appDelegate.htmlString = html;
                               [MBProgressHUD hideHUDForView:appDelegate.window animated:YES];
                               
                               NSString *userId = [[UICKeyChainStore keyChainStore] stringForKey:@"userId"];
                               NSString *password = [[UICKeyChainStore keyChainStore] stringForKey:@"password"];
                               NSError *authError = nil;
                               LAContext *context = [[LAContext alloc] init];
                               if(userId!=nil && password != nil && NSClassFromString(@"LAContext") &&
                                  [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError])
                               {
                                   [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                                           localizedReason:@"Touch IDでログイン"
                                                     reply:^(BOOL success, NSError * _Nullable error) {
                                                         if(success)
                                                         {
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 [self loginWithId:userId pass:password];
                                                             });
                                                         }
                                                     }];
                               }
                           }
                           failure:^(NSError *error) {
                               [MBProgressHUD hideHUDForView:appDelegate.window animated:YES];
                               //TODO
                           }];
}

-(void) keyboardDidShow:(NSNotification *) notification
{
    CGRect rect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

    rect = [self.containerView convertRect:rect fromView:nil];
    CGFloat y = CGRectGetMaxY(self.loginButton.frame);
    if(rect.origin.y < y)
    {
        self.bottomConstraint.constant = rect.origin.y - y;
        [UIView animateWithDuration:0.2 animations:^{
            [self.view layoutIfNeeded];
        } completion:nil];
    }
    
}

-(void) keyboardDidHide:(NSNotification *) notification
{
    self.bottomConstraint.constant = 0;
    [UIView animateWithDuration:0.2 animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];

}

//登录
-(void) loginWithId:(NSString *) userId pass:(NSString *) pass
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if([userId isEqualToString:@"demo"] && [pass isEqualToString:@"123456"])
    {
        appDelegate.demo = YES;
        appDelegate.htmlString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"201610" ofType:@"html"]
                                                           encoding:NSUTF8StringEncoding
                                                              error:nil];
        [self performSegueWithIdentifier:@"Detail" sender:self];
        return;
    }
    NSError *error = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:appDelegate.htmlString error:&error];
    if(error)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"確認できませんでした"
                                                                       message:@"しばらくお待ちください"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showLogin];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    [MBProgressHUD showHUDAddedTo:appDelegate.window animated:YES];
    HTMLNode *bodyNode = [parser body];
    NSArray *inputNodes = [bodyNode findChildTags:@"input"];
    for (HTMLNode *inputNode in inputNodes)
    {
        if ([[inputNode getAttributeNamed:@"value"] isEqualToString:@"ログイン"])
        {
            //submitPage('frm','/etc/R;jsessionid=0001uZ5VF-ULzxUEmE8ZUVzwYeS:15fqqsc48?funccode=1013000000&nextfunc=1013000000');
            NSString *tmp = [inputNode getAttributeNamed:@"onclick"];
            NSUInteger i = [tmp rangeOfString:@"/etc/R;jsessionid="].location;
            NSUInteger j = [tmp rangeOfString:@"nextfunc=1013000000"].location;
            if(i != NSNotFound && j != NSNotFound)
            {
                NSString *suburl = [tmp substringWithRange:NSMakeRange(i, j + [@"nextfunc=1013000000" length] - i)];
                [[HtmlUtil sharedInstance] submit:suburl
                                             page:appDelegate.htmlString
                                       parameters:@{@"risPassword": pass,
                                                    @"risLoginId" : userId}
                                          success:^(NSString *html) {
                                              [MBProgressHUD hideHUDForView:appDelegate.window animated:YES];
                                              appDelegate.htmlString = html;
                                              
                                              NSError *loginError = nil;
                                              HTMLParser *loginParser = [[HTMLParser alloc] initWithString:appDelegate.htmlString
                                                                                                     error:&loginError];
                                              if(loginError)
                                              {
                                                  HTMLNode *bodyNode = [loginParser body];
                                                  for(HTMLNode *errorTable in [bodyNode findChildrenWithAttribute:@"class"
                                                                                                     matchingName:@"error"
                                                                                                     allowPartial:NO])
                                                      if([[errorTable.tagName lowercaseString] isEqualToString:@"table"])
                                                      {
                                                          UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"確認できませんでした"
                                                                                                                         message:@"ユーザーＩＤ、またはパスワードに誤りがあります。"
                                                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                                                          [alert addAction:[UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                                              [self showLogin];
                                                          }]];
                                                          [self presentViewController:alert animated:YES completion:^{
                                                              
                                                          }];
                                                          return;
                                                      }
                                              }
                                              else
                                              {
                                                  HTMLNode *meisaiinfo = [[loginParser body] findChildOfClass:@"meisaiinfo"];
                                                  if(meisaiinfo)
                                                  {
                                                      [[UICKeyChainStore keyChainStore] setString:userId forKey:@"userId"];
                                                      [[UICKeyChainStore keyChainStore] setString:pass forKey:@"password"];
                                                      [self performSegueWithIdentifier:@"Detail" sender:self];

                                                  }
                                                  else
                                                  {
                                                      UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"確認できませんでした"
                                                                                                                     message:@"ユーザーＩＤ、またはパスワードに誤りがあります。"
                                                                                                              preferredStyle:UIAlertControllerStyleAlert];
                                                      [alert addAction:[UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                                          [self showLogin];
                                                      }]];
                                                      [self presentViewController:alert animated:YES completion:^{
                                                          
                                                      }];
                                                  }
                                              }
                                          }
                                          failure:^(NSError *error) {
                                              [MBProgressHUD hideHUDForView:appDelegate.window animated:YES];
                                              
                                              UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"確認できませんでした"
                                                                                                             message:@"ユーザーＩＤ、またはパスワードに誤りがあります。"
                                                                                                      preferredStyle:UIAlertControllerStyleAlert];
                                              [alert addAction:[UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                                  [self showLogin];
                                              }]];
                                              [self presentViewController:alert animated:YES completion:^{
                                                  
                                              }];
                                          }];
                return;
            }
            else
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"確認できませんでした"
                                                                               message:@"ユーザーＩＤ、またはパスワードに誤りがあります。"
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self showLogin];
                }]];
                [self presentViewController:alert animated:YES completion:^{
                    
                }];
                
            }
            break;
        }
    } //end for
    
    [MBProgressHUD hideHUDForView:appDelegate.window animated:YES];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"確認できませんでした"
                                                                   message:@"しばらくお待ちください"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showLogin];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
    return;
}
-(IBAction)loginTouched:(id)sender
{
    if([self.userIdField isFirstResponder])
    {
        [self.userIdField resignFirstResponder];
    }
    if([self.passwordField isFirstResponder])
    {
        [self.passwordField resignFirstResponder];
    }
    NSString *userId = [self.userIdField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *password = [self.passwordField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if([userId length] == 0 || [password length] == 0)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:@"ユーザーＩＤとパスワードを入力してください"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"確定"
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];
        [self presentViewController:alert
                           animated:YES
                         completion:nil];
        return;
    }


    [self loginWithId:userId pass:password];
}


-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"Detail"])
    {

    }
}
@end


@implementation LoginTableViewCell
@end
