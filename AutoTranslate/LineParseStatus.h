//
//  LineParseStatus.h
//  AutoTranslate
//
//  Created by Chris Hulbert on 5/12/12.
//  Copyright (c) 2012 Chris Hulbert. All rights reserved.
//

typedef enum {
    LineParseStatusReading,
    LineParseStatusFoundSlash,
    LineParseStatusInSeparator,
} LineParseStatus;
