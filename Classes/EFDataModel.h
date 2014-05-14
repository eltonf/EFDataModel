//
//  DBModel.h
//  MobilePRISM
//
//  Created by Elton Faggett on 3/19/14.
//  Copyright (c) 2014 Dallas Cowboys FC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EFDataManager.h"
#import "EFDataUtility.h"

#ifndef EFDataModel

static NSString *const DBModelKey = @"key";
static NSString *const DBModelType = @"type";
static NSString *const DBModelClass = @"class";

typedef NS_ENUM(NSInteger, DBModelValueType)
{
    DBModelValueTypeUnknown,
    DBModelValueTypeDefault,
    DBModelValueTypeInteger,
    DBModelValueTypeString,
    DBModelValueTypeBoolean,
    DBModelValueTypeDate,
    DBModelValueTypeDouble,
    DBModelValueTypeImage,
};

#endif

@class FMResultSet;
@interface EFDataModel : NSObject

@property (copy, nonatomic, readonly) NSString *dataType;
@property (copy, nonatomic) NSString *table;

+ (EFDataModel *)modelForDataType:(NSString *)dataType;
- (id)initWithDataType:(NSString *)dataType;
- (Class)classForDBModelObject;
- (NSString *)columnForKey:(NSString *)key;
- (BOOL)isColumnKeyPrimary:(NSString *)columnKey;
- (NSSet *)primaryKeys;
- (NSSet *)columns;
- (NSArray *)columnKeys;
- (void)setValuesOnTarget:(id)target fromResultSet:(FMResultSet *)rs;
- (NSString *)createTableQueryForModel:(id)model;
- (BOOL)dropIfInvalidSchema;

@end

@protocol DBModelProtocol <NSObject>

@required
+ (NSString *)dbModelDataType;
+ (EFDataModel *)dbModel;

@end
