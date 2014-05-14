//
//  SampleItem1.m
//  EFDataModelExample
//
//  Created by Elton Faggett on 5/13/14.
//  Copyright (c) 2014 290 Design, LLC. All rights reserved.
//

#import "SampleItem1.h"

@implementation SampleItem1

+ (NSString *)dbModelDataType
{
    return NSStringFromClass([self class]);
}

+ (EFDataModel *)dbModel
{
    return [[EFDataModel alloc] initWithDataType:[self dbModelDataType]];
}

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

@end
