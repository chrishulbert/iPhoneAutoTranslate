//
//  AutoTranslate.m
//  AutoTranslate
//
//  Created by Chris Hulbert on 2/12/12.
//  Copyright (c) 2012 Chris Hulbert. All rights reserved.
//

#import "AutoTranslate.h"

#import "AzureAccessToken.h"
#import "LineParseStatus.h"
#import "MicrosoftTranslator.h"

NSString *startFolder = @"."; // Where to look for the xx.lproj folders.
NSString *originalFolder = @"en.lproj"; // Which is the original language to translate from.
NSString *stringsFile = @"Localizable.strings";

@interface AutoTranslate() {
    NSMutableDictionary *originalStrings;
    BOOL anythingNeededTranslation;
    NSString *azureToken;
}
@end

@implementation AutoTranslate

+ (void)go {
    [[[self alloc] init] go];
}

- (void)go {
    [self loadOriginalStrings];
    [self translateFolders];
    
    if (anythingNeededTranslation) {
        NSLog(@"Translations complete.");
    } else {
        NSLog(@"Nothing needed to be translated; all up-to-date.");
    }
}

// Translate all the folders for any strings that need it.
- (void)translateFolders {
    for (NSString *folder in [self lprojFolders]) {
        if (![folder isEqualToString:originalFolder]) {
            [self translateFolder:folder];
        }
    }
}

// Checks to see if any of the strings in a given folder need translating.
- (void)translateFolder:(NSString *)folder {
    NSMutableDictionary *translatedStrings = [self loadStringsFile:[self stringsPathForFolder:folder]];
    
    // Check if any need translating
    NSArray *keysNeedingTranslation = [self keysNeedingTranslationFor:translatedStrings];
    for (NSString *key in keysNeedingTranslation) {
        [self doTranslate:key inFolder:folder];
    }
}

// Translate a single key
- (void)doTranslate:(NSString *)key inFolder:(NSString *)folder {
    anythingNeededTranslation = YES;
    
    NSString *fromLang = [self languageCode:originalFolder];
    NSString *toLang = [self languageCode:folder];
    NSString *original = [originalStrings objectForKey:key];
    
    NSLog(@"Translating '%@' from %@ to %@", original, fromLang, toLang);
    if (!azureToken) {
        azureToken = [AzureAccessToken getToken];
    }
    
    NSString *translated = [MicrosoftTranslator translate:original from:fromLang to:toLang token:azureToken];
    NSLog(@"Result: '%@'", translated);

    // Save it
    if (translated.length) {
        [self appendTranslationFor:key translation:translated folder:folder];
    }
}

// Append a translation to the strings file in the given folder
- (void)appendTranslationFor:(NSString *)key translation:(NSString *)translation folder:(NSString *)folder {
    NSString *path = [self stringsPathForFolder:folder];
    
    // Read the original
    NSStringEncoding encoding;
    NSError *error = nil;
    NSString *original = [NSString stringWithContentsOfFile:path usedEncoding:&encoding error:&error];
    if (error) {
        NSLog(@"Error reading in appendTranslationFor: %@", error.localizedDescription);
        exit(1);
    }
    
    // Append
    NSString *keyEscaped = [key stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString *translationEscaped = [translation stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString *line = [NSString stringWithFormat:@"\"%@\" = \"%@\";", keyEscaped, translationEscaped];
    NSString *newContents = [original stringByAppendingFormat:@"\n%@\n", line];
    
    // Write it
    // The apple docs recommend utf16 for strings files.
    [newContents writeToFile:path atomically:YES encoding:NSUTF16StringEncoding error:&error];
    if (error) {
        NSLog(@"Error writing in appendTranslationFor: %@", error.localizedDescription);
        exit(1);
    }
}

// Gets the language code from folder eg 'en.lproj' -> 'en'
- (NSString *)languageCode:(NSString *)folder {
    NSRange range = [folder rangeOfString:@"."];
    if (!range.length) {
        NSLog(@"Could not get language code from: %@", folder);
        exit(1);
    }
    return [folder substringToIndex:range.location];
}

// Find any keys in the original strings that aren't in this translation
- (NSArray *)keysNeedingTranslationFor:(NSDictionary *)translatedStrings {
    NSMutableArray *keysNeedingTranslation = [NSMutableArray array];
    for (NSString *originalKey in [originalStrings allKeys]) {
        NSString *translatedValue = [translatedStrings objectForKey:originalKey];
        if (!translatedValue.length) {
            [keysNeedingTranslation addObject:originalKey];
        }
    }
    return keysNeedingTranslation;
}

// Load the current strings in the original language (english)
- (void)loadOriginalStrings {
    originalStrings = [self loadStringsFile:[self stringsPathForFolder:originalFolder]];
    if (!originalStrings.count) {
        NSLog(@"Error in loadOriginalStrings: No strings found in %@/%@", originalFolder, stringsFile);
        exit(1);
    }
}

// Given eg 'en.lproj' makes the full path startFolder/en.lproj/Localized.strings
- (NSString *)stringsPathForFolder:(NSString *)folder {
    return [[startFolder stringByAppendingPathComponent:folder] stringByAppendingPathComponent:stringsFile];
}

// Load the key/value pairs from a .strings file
- (NSMutableDictionary *)loadStringsFile:(NSString *)path {
    NSError *error = nil;
    NSStringEncoding encoding;
    NSString *contents = [NSString stringWithContentsOfFile:path usedEncoding:&encoding error:&error];
    if (error) {
        NSLog(@"Error in loadStringsFile: %@", [error localizedDescription]);
        exit(1);
    }
    
    NSMutableDictionary *lines = [NSMutableDictionary dictionary];
    for (NSString *line in [contents componentsSeparatedByString:@"\n"]) {
        [self parseLine:line intoDictionary:lines];
    }
    return lines;
}

// See if it's a '"key" = "value";' line, if so, add it to the dictionary
- (void)parseLine:(NSString *)fullLine intoDictionary:(NSMutableDictionary *)lines {
    NSString *line = [fullLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([line hasPrefix:@"/*"]) return;
    if (![line hasPrefix:@"\""]) return;
    if (![line hasSuffix:@"\";"]) return;
    
    // Trim the end bits off: '"' and '";'
    line = [line substringWithRange:NSMakeRange(1, line.length - 3)];

    // Scan through the line, allowing escapes through. Nice little state machine :)
    NSMutableString *key = [NSMutableString string];
    NSMutableString *value = [NSMutableString string];
    NSMutableString *currentlyParsing = key;
    LineParseStatus status = LineParseStatusReading;
    for (int i=0; i<line.length; i++) {
        unichar c = [line characterAtIndex:i];
        switch (status) {
            case LineParseStatusReading:
                if (c == '\\') {
                    status = LineParseStatusFoundSlash;
                } else if (c== '"') {
                    status = LineParseStatusInSeparator;
                } else {
                    [currentlyParsing appendString:[NSString stringWithCharacters:&c length:1]];
                }
                break;
            case LineParseStatusFoundSlash:
                [currentlyParsing appendString:@"\\"];
                [currentlyParsing appendString:[NSString stringWithCharacters:&c length:1]];
                status = LineParseStatusReading;
                break;
            case LineParseStatusInSeparator:
                if (c == '"') {
                    currentlyParsing = value;
                    status = LineParseStatusReading;
                }
                break;
        }        
    }
    if (key.length && value.length) {
        [lines setObject:[value copy] forKey:[key copy]];
    }
}

// Look for any *.lproj folders
- (NSArray *)lprojFolders {
    NSMutableArray *folders = [NSMutableArray array];
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:startFolder error:nil]) {
        if ([file hasSuffix:@".lproj"]) {
            [folders addObject:file];
        }
    }
    return folders;
}

@end
