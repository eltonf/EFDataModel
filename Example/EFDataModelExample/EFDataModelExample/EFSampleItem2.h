//
//  EFSampleItem2.h
//  EFDataModelExample
//
//  Created by Elton Faggett on 5/13/14.
//  Copyright (c) 2014 290 Design, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EFSampleItem2 : NSObject <DBModelProtocol>

@property (nonatomic, copy) NSString *somePrimaryKey;
@property (nonatomic, copy) NSString *stringValue;
@property (nonatomic, assign) NSInteger integerValue;
@property (nonatomic, assign) double doubleValue;
@property (nonatomic, assign) BOOL boolValue;
@property (nonatomic, strong) NSDate *dateValue;

@end
