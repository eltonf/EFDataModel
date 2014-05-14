//
//  DBModel.m
//  MobilePRISM
//
//  Created by Elton Faggett on 3/19/14.
//  Copyright (c) 2014 Dallas Cowboys FC. All rights reserved.
//

#import "EFDataModel.h"
#import "FMResultSet.h"
#import <objc/runtime.h>
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

@interface EFDataModel ()

@property (strong, nonatomic) NSDictionary *columnMap;

@end

@implementation EFDataModel

- (id)initWithDataType:(NSString *)dataType
{
    self = [super init];
    if (self)
    {
        _dataType = dataType;
        self.table = [EFDataManager tableForDataType:dataType];
        self.columnMap = [EFDataManager columnMapForDataType:dataType];
    }
    return self;
}

+ (EFDataModel *)modelForDataType:(NSString *)dataType
{
    return [[EFDataModel alloc] initWithDataType:dataType];
}

- (Class)classForDBModelObject
{
    NSString *className = [EFDataManager classNameForDataType:self.dataType];
    if(!className) {
        className = self.dataType;
    }
    return NSClassFromString(className);
}

- (NSString *)columnForKey:(NSString *)key
{
    id object = [self.columnMap objectForKey:key];
    if (object == nil) {
        DDLogError(@"%@ | %@ is nil", self.dataType, key);
        return nil;
    } else if ([object isKindOfClass:[NSString class]]) {
        return (NSString *)object;
    } else if ([object isKindOfClass:[NSDictionary class]]) {
        return [object objectForKey:@"columnName"];
    } else {
        return nil;
    }
}

- (BOOL)isColumnKeyPrimary:(NSString *)columnKey
{
    id object = [self.columnMap objectForKey:columnKey];
    if (object && [object isKindOfClass:[NSDictionary class]]) {
        return [[object objectForKey:@"isPrimaryKey"] boolValue];
    } else {
        return NO;
    }
}

- (NSSet *)primaryKeys
{
    NSMutableSet *primaryKeys = [NSMutableSet new];
    for (NSString *columnKey in [self columnKeys]) {
        if ([self isColumnKeyPrimary:columnKey]) {
            [primaryKeys addObject:[self columnForKey:columnKey]];
        }
    }
    return primaryKeys;
}

- (NSSet *)columns
{
    NSMutableSet *columns = [NSMutableSet new];
    NSArray *keys = [self.columnMap allKeys];
    for (NSString *key in keys) {
        [columns addObject:[self columnForKey:key]];
    }
    return columns;
}

- (NSArray *)columnKeys
{
    return [self.columnMap allKeys];
}

- (BOOL)dropIfInvalidSchema
{
    return [EFDataManager dropIfInvalidForDataType:self.dataType];
}

- (NSDictionary *)fieldDictionariesByKeyForObject:(id)object
{
    NSMutableDictionary *fieldDictionariesByKey = [NSMutableDictionary dictionary];
    for (NSDictionary *dict in DBModelProperties(object)) {
        fieldDictionariesByKey[dict[DBModelKey]] = dict;
    }
    
    return fieldDictionariesByKey;
}

- (void)setValuesOnTarget:(id)target fromResultSet:(FMResultSet *)rs
{
    NSDictionary *fieldDictionariesByKey = [self fieldDictionariesByKeyForObject:target];
    NSArray *dbKeys = [self.columnMap allKeys];
    for (NSString *dbKey in dbKeys) {
        NSDictionary *propertyDict = [fieldDictionariesByKey objectForKey:dbKey];
        if (propertyDict) {
            DBModelValueType valueType = [[propertyDict objectForKey:DBModelType] integerValue];
            [self setValueType:valueType onTarget:target forKey:dbKey fromResultSet:rs];
        }
    }
}

- (void)setValueOnTarget:(id)target forKey:(NSString *)key fromResultSet:(FMResultSet *)rs
{
    //process fields
    NSMutableDictionary *fieldDictionariesByKey = [NSMutableDictionary dictionary];
    for (NSDictionary *dict in DBModelProperties(target)) {
        fieldDictionariesByKey[dict[DBModelKey]] = dict;
    }
    
    DBModelValueType valueType = [[[fieldDictionariesByKey objectForKey:key] objectForKey:DBModelType] integerValue];
    [self setValueType:valueType onTarget:target forKey:key fromResultSet:rs];
}

- (void)setValueType:(DBModelValueType)valueType onTarget:(id)target forKey:(NSString *)key fromResultSet:(FMResultSet *)rs
{
    NSString *dbColumn = [self columnForKey:key];
    [self setValueType:valueType onTarget:target forKey:key dbColumn:dbColumn fromResultSet:rs];
}

- (void)setValueType:(DBModelValueType)valueType onTarget:(id)target forKey:(NSString *)key dbColumn:(NSString *)dbColumn fromResultSet:(FMResultSet *)rs
{
    id value = nil;
    switch (valueType) {
        case DBModelValueTypeBoolean:
        {
            BOOL primitiveValue = [rs boolForColumn:dbColumn];
            value = [NSNumber numberWithBool:primitiveValue];
            
            break;
        }
            
        case DBModelValueTypeDate:
        {
            value = [rs dateForColumn:dbColumn];
            
            break;
        }
            
        case DBModelValueTypeDouble:
        {
            double primitiveValue = [rs doubleForColumn:dbColumn];
            value = [NSNumber numberWithDouble:primitiveValue];
            
            break;
        }
            
        case DBModelValueTypeInteger:
        {
            NSInteger primitiveValue = [rs intForColumn:dbColumn];
            value = [NSNumber numberWithInteger:primitiveValue];
            
            break;
        }
            
        case DBModelValueTypeString:
        {
            value = [rs stringForColumn:dbColumn];
            
            break;
        }
            
        default:
        {
            DDLogWarn(@"DBModel value type not found for key [%@]", key);
            
            break;
        }
    }
    
    [target setValue:value forKeyPath:key];
}

static inline NSArray *DBModelProperties(id model)
{
    if (!model) return nil;
    
    static void *DBModelPropertiesKey = &DBModelPropertiesKey;
    NSMutableArray *properties = objc_getAssociatedObject(model, DBModelPropertiesKey);
    if (!properties)
    {
        properties = [NSMutableArray array];
        Class subclass = [model class];
        while (subclass != [NSObject class])
        {
            unsigned int propertyCount;
            objc_property_t *propertyList = class_copyPropertyList(subclass, &propertyCount);
            for (unsigned int i = 0; i < propertyCount; i++)
            {
                //get property name
                objc_property_t property = propertyList[i];
                const char *propertyName = property_getName(property);
                NSString *key = @(propertyName);
                
                //get property type
                Class valueClass = nil;
                DBModelValueType valueType = DBModelValueTypeUnknown;
                char *typeEncoding = property_copyAttributeValue(property, "T");
                switch (typeEncoding[0])
                {
                    case '@':
                    {
                        if (strlen(typeEncoding) >= 3)
                        {
                            char *className = strndup(typeEncoding + 2, strlen(typeEncoding) - 3);
                            __autoreleasing NSString *name = @(className);
                            NSRange range = [name rangeOfString:@"<"];
                            if (range.location != NSNotFound)
                            {
                                name = [name substringToIndex:range.location];
                            }
                            valueClass = NSClassFromString(name) ?: [NSObject class];
                            free(className);
                            
                            if ([valueClass isSubclassOfClass:[NSString class]])
                            {
                                valueType = DBModelValueTypeString;
                            }
                            else if ([valueClass isSubclassOfClass:[NSNumber class]])
                            {
                                valueType = DBModelValueTypeDouble;
                            }
                            else if ([valueClass isSubclassOfClass:[NSDate class]])
                            {
                                valueType = DBModelValueTypeDate;
                            }
                            else if ([valueClass isSubclassOfClass:[UIImage class]])
                            {
                                valueType = DBModelValueTypeImage;
                            }
                            else
                            {
                                valueType = DBModelValueTypeDefault;
                            }
                        }
                        break;
                    }
                    case 'c':
                    case 'B':
                    {
                        valueClass = [NSNumber class];
                        valueType = DBModelValueTypeBoolean;
                        break;
                    }
                    case 'i':
                    case 's':
                    case 'l':
                    case 'q':
                    case 'C':
                    case 'I':
                    case 'S':
                    case 'L':
                    case 'Q':
                    {
                        valueClass = [NSNumber class];
                        valueType = DBModelValueTypeInteger;
                        break;
                    }
                    case 'f':
                    case 'd':
                    {
                        valueClass = [NSNumber class];
                        valueType = DBModelValueTypeDouble;
                        break;
                    }
                    case '{': //struct
                    case '(': //union
//                    {
//                        valueClass = [NSValue class];
//                        valueType = FXFormFieldTypeLabel;
//                        break;
//                    }
                    case ':': //selector
                    case '#': //class
                    default:
                    {
                        valueClass = nil;
                        valueType = DBModelValueTypeUnknown;
                    }
                }
                free(typeEncoding);
                
                //add to properties
                if (valueClass && valueType)
                {
                    [properties addObject:@{DBModelKey: key, DBModelClass: valueClass, DBModelType: @(valueType)}];
                }
            }
            free(propertyList);
            subclass = [subclass superclass];
        }
        objc_setAssociatedObject(model, DBModelPropertiesKey, properties, OBJC_ASSOCIATION_RETAIN);
    }
    return properties;
}

- (NSString *)createTableQueryForModel:(id)model
{
    NSMutableDictionary *fieldDictionariesByKey = [NSMutableDictionary dictionary];
    for (NSDictionary *dict in DBModelProperties(model)) {
        fieldDictionariesByKey[dict[DBModelKey]] = dict;
    }
    
    NSMutableArray *primaryColumns = [NSMutableArray new];
    NSArray *keys = [self.columnMap allKeys];
    NSMutableArray *columnDefinitions = [NSMutableArray new];
    for (NSString *key in keys) {
        NSString *column = [self columnForKey:key];
        DBModelValueType valueType = [[[fieldDictionariesByKey objectForKey:key] objectForKey:DBModelType] integerValue];
        NSString *dbDataType = [self sqliteTypeForValueType:valueType];
        NSMutableString *columnInfo = [NSMutableString stringWithFormat:@"%@ %@", column, dbDataType];
        
        if ([self isColumnKeyPrimary:key]) {
            [columnInfo appendFormat:@" NOT NULL"];
            [primaryColumns addObject:column];
        }
        [columnDefinitions addObject:columnInfo];
    }
    
    NSString *primaryKeyString;
    if ([primaryColumns count] > 0) {
        primaryKeyString = [NSString stringWithFormat:@", PRIMARY KEY(%@)", [EFDataUtility stringFromArray:primaryColumns separator:@", "]];
    } else {
        primaryKeyString = @"";
    }
    NSString *query = [NSString stringWithFormat:@"CREATE TABLE %@ (%@%@)", self.table, [EFDataUtility stringFromArray:columnDefinitions separator:@", "], primaryKeyString];
    
    return query;
}

- (NSString *)sqliteTypeForValueType:(DBModelValueType)valueType
{
    NSString *sqliteType = nil;
    switch (valueType) {
        case DBModelValueTypeBoolean:
        case DBModelValueTypeInteger: {
            sqliteType = @"INTEGER";
            break;
        }
            
        case DBModelValueTypeDate: {
            sqliteType = @"BLOB";
            break;
        }
            
        case DBModelValueTypeDouble: {
            sqliteType = @"REAL";
            break;
        }
            
        case DBModelValueTypeString:
        default: {
            sqliteType = @"TEXT";
            break;
        }
    }
    return sqliteType;
}

@end
