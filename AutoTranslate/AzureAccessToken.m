//
//  AzureAccessToken.m
//  AutoTranslate
//
//  Created by Chris Hulbert on 4/12/12.
//  Copyright (c) 2012 Chris Hulbert. All rights reserved.
//

#import "AzureAccessToken.h"

NSString *clientId = @"splinter-com-au";
NSString *clientSecret = @"rUeKCc0qv86ekxuE6iv9";

@implementation AzureAccessToken

+ (NSString *)myEscape:(NSString *)text {
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
        (CFStringRef)text,
        NULL,
        (CFStringRef)@"!*'();:@&=+$,/?%#[]",
        kCFStringEncodingUTF8);
}

+ (NSString *)getToken {
    NSString *bodyString = [NSString stringWithFormat:
        @"grant_type=client_credentials&client_id=%@&client_secret=%@&scope=http://api.microsofttranslator.com",
        [self myEscape:clientId],
        [self myEscape:clientSecret]];
    NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *bodyLen = [NSString stringWithFormat:@"%ld", bodyData.length];

    NSURL *url = [NSURL URLWithString:@"https://datamarket.accesscontrol.windows.net/v2/OAuth2-13"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:bodyLen forHTTPHeaderField:@"Content-Length"];
    request.HTTPMethod = @"POST";
    request.HTTPBody = bodyData;
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *output = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error) {
        NSLog(@"getToken error: %@", error.localizedDescription);
        exit(1);
    }
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:output options:0 error:nil];
    NSString *access_token = [json objectForKey:@"access_token"];

    if (!access_token) {
        NSLog(@"getToken error; returned no token: %@", json);
        exit(1);
    }

    return access_token;
}

@end
