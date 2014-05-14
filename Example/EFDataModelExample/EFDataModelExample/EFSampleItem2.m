//
//  EFSampleItem2.m
//  EFDataModelExample
//
//  Created by Elton Faggett on 5/13/14.
//  Copyright (c) 2014 290 Design, LLC. All rights reserved.
//

#import "EFSampleItem2.h"

@implementation EFSampleItem2

#pragma mark - DBModelProtocol

+ (NSString *)tableName
{
    return NSStringFromClass([self class]);
}

+ (NSArray *)primaryKeys
{
    return @[@"primaryKeyPart1", @"primaryKeyPart2", @"primaryKeyPart3"];
}

+ (NSDictionary *)columnsByPropertyKey
{
    NSMutableDictionary *columns = [NSMutableDictionary new];
    [columns setObject:@"primary_key" forKey:@"somePrimaryKey"];
    [columns setObject:@"string_value" forKey:@"stringValue"];
    [columns setObject:@"integer_value" forKey:@"integerValue"];
    [columns setObject:@"double_value" forKey:@"doubleValue"];
    [columns setObject:@"bool_value" forKey:@"boolValue"];
    [columns setObject:@"date_value" forKey:@"dateValue"];
    
    return columns;
}

@end
