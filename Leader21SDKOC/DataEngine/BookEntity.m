//
//  NSManagedObject+BookEntity.m
//  Leader21SDKOC
//
//  Created by leader on 15/7/1.
//  Copyright (c) 2015年 leader. All rights reserved.
//

#import "BookEntity.h"

@implementation BookEntity

@dynamic bookId;
@dynamic bookCover;
@dynamic bookTitle;
@dynamic bookTitleCN;
@dynamic fileId;
@dynamic grade;
@dynamic unit;
@dynamic theme;
@dynamic bookSort;
@dynamic bookLevel;
@dynamic bookType;
@dynamic bookSRNO;
@dynamic bookUrl;
@dynamic hasDown;

@dynamic download;

+ (BookEntity*)itemWithDictionary:(NSDictionary*)dic
{
    
    NSNumber* bookId = [dic numberForKey:@"ID"];
    BookEntity* entity = nil;
    
    if (bookId != nil) {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"bookId = %d", bookId];
        entity = (BookEntity*)[CoreDataHelper getOrCreateEntity:@"BookEntity" withPredicate:predicate];
    }
    else {
        return entity;
    }
    entity.bookId = bookId;
    
    entity.bookTitle = [dic stringForKey:@"BOOK_TITLE"];
    entity.bookCover = [dic stringForKey:@"BOOK_COVER"];
    entity.bookTitleCN = [dic stringForKey:@"BOOK_TITLE_CN"];
    entity.fileId = [dic stringForKey:@"FILE_ID"];
    entity.grade = [dic numberForKey:@"GRADE"];
    entity.unit = [dic numberForKey:@"UNIT"];
    entity.theme = [dic stringForKey:@"THEME"];
    entity.bookSort = [dic numberForKey:@"BOOK_SORT"];
    entity.bookLevel = [dic stringForKey:@"BOOK_LEVEL"];
    entity.bookType = [dic stringForKey:@"BOOK_TYPE"];
    entity.bookSRNO = [dic stringForKey:@"BOOK_SRNO"];
    
    return entity;
}

@end
