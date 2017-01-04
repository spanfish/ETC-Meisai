//
//  HtmlUtil.m
//  ETCMeisai
//
//  Created by Xiangwei Wang on 11/14/16.
//  Copyright © 2016 Xiangwei Wang. All rights reserved.
//

#import "HtmlUtil.h"


@interface HtmlUtil()
{
    
}
@property(nonatomic, strong) AFHTTPSessionManager *sessionManager;
@end

@implementation HtmlUtil

+(instancetype) sharedInstance
{
    static HtmlUtil *util;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        util = [[HtmlUtil alloc] init];
        util.sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        
        AFHTTPResponseSerializer *serializer = [AFHTTPResponseSerializer serializer];
        [serializer setAcceptableContentTypes:[NSSet setWithObjects:@"text/html",
                                               @"application/pdf",
                                               @"application/x-pdf", nil]];
        [util.sessionManager setResponseSerializer:serializer];
        [[util.sessionManager requestSerializer] setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/54.0.2840.87 Safari/537.36"
                                       forHTTPHeaderField:@"User-Agent"];

    });
    return util;
}

-(void) GET:(NSString *)URLString
 parameters:(id)parameters
    success:(void (^)(NSString *html))success
    failure:(void (^)(NSError * error))failure {
    [self.sessionManager GET:[HOST_NAME stringByAppendingString:URLString]
                  parameters:parameters
                    progress:^(NSProgress * _Nonnull downloadProgress) {
                        
                    }
                     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                         NSString *htmlString = [[NSString alloc] initWithData:responseObject
                                                                      encoding:NSJapaneseEUCStringEncoding];
                         dispatch_async(dispatch_get_main_queue(), ^{
                             success(htmlString);
                         });
                     }
                     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                         dispatch_async(dispatch_get_main_queue(), ^{
                             failure(error);
                         });
                     }];
}

-(void) submit:(NSString *) suburl
          page:(NSString *) html
    parameters:(id)parameters
successWithData:(void (^)(NSData *data))success
       failure:(void (^)(NSError * error))failure
{
    NSError *error = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:html error:&error];
    if(error)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            failure(error);
        });
        return;
    }
    
    HTMLNode *body = [parser body];
    NSMutableDictionary *submitParams = [NSMutableDictionary dictionaryWithDictionary:parameters];
    for (HTMLNode *inputNode in [body findChildTags:@"input"])
    {
        if ([[inputNode getAttributeNamed:@"type"] isEqualToString:@"hidden"])
        {
            NSString *name = [inputNode getAttributeNamed:@"name"];
            NSString *value = [inputNode getAttributeNamed:@"value"];
            [submitParams setObject:value forKey:name];
        }
    }
    
    [self.sessionManager POST:[HOST_NAME stringByAppendingString:suburl]
                   parameters:submitParams
                     progress:nil
                      success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                          dispatch_async(dispatch_get_main_queue(), ^{
                              success(responseObject);
                          });
                      }
                      failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                          dispatch_async(dispatch_get_main_queue(), ^{
                              failure(error);
                          });
                      }];
}

-(void) submit:(NSString *)suburl
          page:(NSString *)html
    parameters:(id)parameters
       success:(void (^)(NSString *html))success
       failure:(void (^)(NSError * error))failure
{
    NSError *error = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:html error:&error];
    if(error)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            failure(error);
        });
        return;
    }
    
    HTMLNode *body = [parser body];
    NSMutableDictionary *submitParams = [NSMutableDictionary dictionaryWithDictionary:parameters];
    for (HTMLNode *inputNode in [body findChildTags:@"input"])
    {
        if ([[inputNode getAttributeNamed:@"type"] isEqualToString:@"hidden"])
        {
            NSString *name = [inputNode getAttributeNamed:@"name"];
            NSString *value = [inputNode getAttributeNamed:@"value"];
            [submitParams setObject:value forKey:name];
        }
    }
    
    [self.sessionManager POST:[HOST_NAME stringByAppendingString:suburl]
                   parameters:submitParams
                     progress:nil
                      success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                          NSString *htmlString = [[NSString alloc] initWithData:responseObject
                                                                       encoding:NSJapaneseEUCStringEncoding];
                          dispatch_async(dispatch_get_main_queue(), ^{
                              success(htmlString);
                          });
                      }
                      failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                          dispatch_async(dispatch_get_main_queue(), ^{
                              failure(error);
                          });
                      }];
}
@end
