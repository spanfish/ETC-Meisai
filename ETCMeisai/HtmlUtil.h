//
//  HtmlUtil.h
//  ETCMeisai
//
//  Created by Xiangwei Wang on 11/14/16.
//  Copyright © 2016 Xiangwei Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "HTMLNode.h"
#import "HTMLParser.h"

#define HOST_NAME @"https://www2.etc-meisai.jp"
#define LOGIN_URL @"/etc/R?funccode=1013000000&nextfunc=1013000000"


@interface HtmlUtil : NSObject

+(instancetype) sharedInstance;

-(void) GET:(NSString *)suburl
                   parameters:(id)parameters
                      success:(void (^)(NSString *html))success
    failure:(void (^)(NSError * error))failure;

-(void) submit:(NSString *) suburl
          page:(NSString *) html
    parameters:(id)parameters
       success:(void (^)(NSString *html))success
       failure:(void (^)(NSError * error))failure;

-(void) submit:(NSString *) suburl
          page:(NSString *) html
    parameters:(id)parameters
successWithData:(void (^)(NSData *data))success
       failure:(void (^)(NSError * error))failure;
@end
