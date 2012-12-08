//
//  MicrosoftTranslator.h
//  AutoTranslate
//
//  Created by Chris Hulbert on 4/12/12.
//  Copyright (c) 2012 Chris Hulbert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MicrosoftTranslator : NSObject

+ (NSString *)translate:(NSString *)text from:(NSString *)from to:(NSString *)to token:(NSString *)token;

@end
