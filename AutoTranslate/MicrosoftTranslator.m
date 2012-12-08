//
//  MicrosoftTranslator.m
//  AutoTranslate
//
//  Created by Chris Hulbert on 4/12/12.
//  Copyright (c) 2012 Chris Hulbert. All rights reserved.
//

#import "MicrosoftTranslator.h"

#import "LineParseStatus.h"

@implementation MicrosoftTranslator

+ (NSString *)translate:(NSString *)text from:(NSString *)from to:(NSString *)to token:(NSString *)token {
    
    // If there are no escapes, translate as-is
    if (![text rangeOfString:@"\\"].length) {
        return [self doTranslate:text from:from to:to token:token];
    } else {
        // Split it up into sections
        NSMutableString *result = [NSMutableString string];
        for (NSString *section in [self splitUp:text]) {
            if ([section hasPrefix:@"\\"]) {
                [result appendString:section];
            } else {
                [result appendString:[self doTranslate:section from:from to:to token:token]];
            }
        }
        return result.copy;
    }
    
}

// Actually hit the API to do a translation for us.
+ (NSString *)doTranslate:(NSString *)text from:(NSString *)from to:(NSString *)to token:(NSString *)token {
    NSString *url = [NSString stringWithFormat:@"http://api.microsofttranslator.com/V2/Ajax.svc/Translate?"
        "appId=Bearer+%@&from=%@&to=%@&text=%@",
        [self myEscape:token], [self mapLanguage:from], [self mapLanguage:to], [self myEscape:text]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
    if (error) {
        NSLog(@"Translate error: %@", error.localizedDescription);
        exit(1);
    }
    if (!data.length) {
        NSLog(@"Translate error: No data returned");
        exit(1);
    }

    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"API returned: %@", dataString);

    // Unfortunately the API doesn't give us a nice 4xx error if anything's wrong, so we need to guess...
    // Apologies if this lets any errors through to your strings files undetected!
    if ([dataString hasPrefix:@"\"ArgumentOutOfRangeException:"]) {
        NSLog(@"API error");
        exit(1);
    }

    if ([dataString hasPrefix:@"\""] && [dataString hasSuffix:@"\""]) {
        return [dataString substringWithRange:NSMakeRange(1, dataString.length - 2)];
    } else {
        NSLog(@"API error, return is not quoted.");
        exit(1);
    }
}

// Escapes *properly* unlike stringByAddingPercentEscapesUsingEncoding
+ (NSString *)myEscape:(NSString *)text {
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
        (CFStringRef)text,
        NULL,
        (CFStringRef)@"!*'();:@&=+$,/?%#[]",
        kCFStringEncodingUTF8);
}

// Splits up eg "blah\nyada" into "blah" "\n" "yada"
+ (NSArray *)splitUp:(NSString *)text {
    NSMutableArray *results = [NSMutableArray array];
    NSMutableString *substring = nil;
    LineParseStatus status = LineParseStatusReading;
    for (int i=0; i<text.length; i++) {
        unichar c = [text characterAtIndex:i];
        switch (status) {
            case LineParseStatusReading:
                if (c == '\\') {
                    // Save what we've got so far, if anything
                    if (substring.length) {
                        [results addObject:[substring copy]];
                    }
                    substring = nil;
                    
                    // Go to slash mode
                    status = LineParseStatusFoundSlash;
                } else {
                    // Normal character, add it to what we've got so far
                    if (!substring) {
                        substring = [NSMutableString string];
                    }
                    [substring appendString:[NSString stringWithCharacters:&c length:1]];
                }
                break;
            case LineParseStatusFoundSlash:
                [results addObject:[@"\\" stringByAppendingString:[NSString stringWithCharacters:&c length:1]]];
                status = LineParseStatusReading;
                break;
            default:
                break;
        }
    }
    
    // Save the last substring
    if (substring.length) {
        [results addObject:[substring copy]];
    }
    
    return [results copy];
}

// Maps the language code from what xcode knows to what the API knows.
+ (NSString *)mapLanguage:(NSString *)xcodeLanguage {
    if ([xcodeLanguage isEqualToString:@"nb"]) return @"no"; // Norwegian bokmal (most common norwegian language).
    return xcodeLanguage;
}

@end
