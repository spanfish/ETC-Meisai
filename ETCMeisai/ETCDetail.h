//
//  ETCDetail.h
//  ETCMeisai
//
//  Created by Xiangwei Wang on 11/5/16.
//  Copyright © 2016 Xiangwei Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ETCDetail : NSObject
@property(nonatomic, strong) NSString *checkValue;
@property(nonatomic, strong) NSArray *useFromArray;
@property(nonatomic, strong) NSArray *useToArray;
@property(nonatomic, strong) NSArray *tollArray;
@property(nonatomic, strong) NSArray *payArray;
@property(nonatomic, strong) NSArray *carInfoArray;
@property(nonatomic, strong) NSArray *commentArray;
@end
