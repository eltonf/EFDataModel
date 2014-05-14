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

@property (copy, nonatomic) Class class;
@property (copy, nonatomic) NSString *table;
@property (copy, nonatomic) NSSet *primaryKeys;
@property (copy, nonatomic) NSDictionary *columnMap;
@property (assign, nonatomic) BOOL dropTableIfInvalidSchema;

+ (EFDataModel *)modelWithTable:(NSString *)table primaryKeys:(NSSet *)primaryKeys columnMap:(NSDictionary *)columnMap class:(Class)class;
- (instancetype)initWithTable:(NSString *)table primaryKeys:(NSSet *)primaryKeys columnMap:(NSDictionary *)columnMap class:(Class)class;
//- (Class)classForDBModelObject;
- (NSString *)columnForKey:(NSString *)key;
- (BOOL)isColumnKeyPrimary:(NSString *)columnKey;
//- (NSSet *)primaryKeys;
- (NSSet *)columns;
- (NSArray *)columnKeys;
- (void)setValuesOnTarget:(id)target fromResultSet:(FMResultSet *)rs;
- (NSString *)createTableQueryForModel:(id)model;
//- (BOOL)dropIfInvalidSchema;

@end
