//
//  EFSampleItem1.m
//  EFDataModelExample
//
//  Created by Elton Faggett on 5/13/14.
//  Copyright (c) 2014 290 Design, LLC. All rights reserved.
//

#import "EFSampleItem1.h"

@implementation EFSampleItem1

- (instancetype)initWithPrimaryKey1:(NSInteger)primaryKey1 primaryKey2:(NSInteger)primaryKey2 primaryKey3:(NSInteger)primaryKey3
{
    self = [super init];
    if (self) {
        _primaryKeyPart1 = primaryKey1;
        _primaryKeyPart2 = primaryKey2;
        _primaryKeyPart3 = primaryKey3;
    }
    return self;
}

#pragma mark - DBModelProtocol

+ (NSString *)tableName
{
    return NSStringFromClass([self class]);
}

+ (NSArray *)primaryKeys
{
    return @[@"primaryKeyPart1", @"primaryKeyPart2", @"primaryKeyPart3"];
}

+ (NSDictionary *)databaseColumnsByPropertyKey
{
    NSMutableDictionary *columns = [NSMutableDictionary new];
    [columns setObject:@"primary_key_part1" forKey:@"primaryKeyPart1"];
    [columns setObject:@"primary_key_part2" forKey:@"primaryKeyPart2"];
    [columns setObject:@"primary_key_part3" forKey:@"primaryKeyPart3"];
    [columns setObject:@"string_value" forKey:@"stringValue"];
    [columns setObject:@"integer_value" forKey:@"integerValue"];
    [columns setObject:@"double_value" forKey:@"doubleValue"];
    [columns setObject:@"bool_value" forKey:@"boolValue"];
    [columns setObject:@"date_value" forKey:@"dateValue"];
    //    [columns setObject:NSNull.null forKey:@"version"];
    return columns;
}

@end
