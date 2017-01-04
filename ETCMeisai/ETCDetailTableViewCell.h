//
//  ETCDetailTableViewCell.h
//  ETCMeisai
//
//  Created by Xiangwei Wang on 11/5/16.
//  Copyright © 2016 Xiangwei Wang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ETCDetailTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *tollLabel;
@property (weak, nonatomic) IBOutlet UILabel *carNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *toICLabel;
@property (weak, nonatomic) IBOutlet UILabel *fromICLabel;
@property (weak, nonatomic) IBOutlet UILabel *toDateTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *fromDateTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;
@property (weak, nonatomic) IBOutlet UILabel *cardNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *discountLabel;
@end
