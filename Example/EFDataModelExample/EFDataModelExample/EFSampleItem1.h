//
//  EFSampleItem1.h
//  EFDataModelExample
//
//  Created by Elton Faggett on 5/13/14.
//  Copyright (c) 2014 290 Design, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EFSampleItem1 : NSObject <DBModelProtocol>

@property (nonatomic, readonly) NSInteger primaryKeyPart1;
@property (nonatomic, readonly) NSInteger primaryKeyPart2;
@property (nonatomic, readonly) NSInteger primaryKeyPart3;
@property (nonatomic, copy) NSString *stringValue;
@property (nonatomic, assign) NSInteger integerValue;
@property (nonatomic, assign) double doubleValue;
@property (nonatomic, assign) BOOL boolValue;
@property (nonatomic, strong) NSDate *dateValue;

- (instancetype)initWithPrimaryKey1:(NSInteger)primaryKey1 primaryKey2:(NSInteger)primaryKey2 primaryKey3:(NSInteger)primaryKey3;

@end
