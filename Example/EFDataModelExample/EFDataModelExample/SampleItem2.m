//
//  SampleItem2.m
//  EFDataModelExample
//
//  Created by Elton Faggett on 5/13/14.
//  Copyright (c) 2014 290 Design, LLC. All rights reserved.
//

#import "SampleItem2.h"

@implementation SampleItem2

+ (NSString *)dbModelDataType
{
    return NSStringFromClass([self class]);
}

+ (EFDataModel *)dbModel
{
    return [[EFDataModel alloc] initWithDataType:[self dbModelDataType]];
}

@end