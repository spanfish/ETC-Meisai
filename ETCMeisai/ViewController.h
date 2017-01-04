//
//  ViewController.h
//  ETCMeisai
//
//  Created by Xiangwei Wang on 11/2/16.
//  Copyright © 2016 Xiangwei Wang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>
#import "AppDelegate.h"
#import "HTMLNode.h"
#import "HTMLParser.h"

@interface ViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, QLPreviewControllerDataSource>
@end

