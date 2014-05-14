//
//  DBHelper.m
//  MobilePRISM
//
//  Created by Elton Faggett on 2/5/14.
//  Copyright (c) 2014 Dallas Cowboys FC. All rights reserved.
//

#import "EFDataDBHelper.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "FMDatabaseAdditions.h"
#import "EFDataModel.h"
#import "DDLog.h"
#import <objc/runtime.h>

static const int ddLogLevel = LOG_LEVEL_INFO;

static NSDictionary *_databaseMap;

@implementation EFDataDBHelper

+ (void)initialize
{
    [super initialize];
    
    NSString *dbMapFilePath = [[NSBundle mainBundle] pathForResource:@"EFDataModelDatabaseMap" ofType:@"plist"];
    _databaseMap = [NSDictionary dictionaryWithContentsOfFile:dbMapFilePath];
}

+ (NSString *)tableForDataType:(NSString *)dataType
{
    NSDictionary *itemMap = [_databaseMap objectForKey:dataType];
    return [itemMap objectForKey:@"table"];
}

+ (NSDictionary *)columnMapForDataType:(NSString *)dataType
{
    NSDictionary *itemMap = [_databaseMap objectForKey:dataType];
    return [itemMap objectForKey:@"columnMap"];
}

+ (NSString *)classNameForDataType:(NSString *)dataType
{
    NSDictionary *itemMap = [_databaseMap objectForKey:dataType];
    return [itemMap objectForKey:@"className"];
}

+ (BOOL)dropIfInvalidForDataType:(NSString *)dataType
{
    NSDictionary *itemMap = [_databaseMap objectForKey:dataType];
    return [[itemMap objectForKey:@"dropIfInvalidSchema"] boolValue];
}

+ (BOOL)validateTableForDBModel:(EFDataModel *)dbModel database:(FMDatabase *)database
{
    if (![database tableExists:dbModel.table]) {
        DDLogWarn(@"Table [%@] does NOT exist for dataType [%@]", dbModel.table, dbModel.dataType);
        return NO;
    } else {
        NSMutableSet *dbColumns = [NSMutableSet new];
        NSMutableSet *primaryKeys = [NSMutableSet new];
        NSString *query = [NSString stringWithFormat:@"PRAGMA table_info('%@')", dbModel.table];
        FMResultSet *rs = [database executeQuery:query];
        while ([rs next]) {
            NSString *column = [rs stringForColumn:@"name"];
            [dbColumns addObject:column];
            NSInteger primaryKeyIndex = [rs intForColumn:@"pk"];
            if (primaryKeyIndex > 0) {
                [primaryKeys addObject:column];
            }
        }
        
        NSSet *modelColumns = [dbModel columns];
        NSSet *modelPrimaryKeys = [dbModel primaryKeys];
        return [modelColumns isSubsetOfSet:dbColumns] && [modelPrimaryKeys isEqualToSet:primaryKeys];
    }
}

+ (BOOL)createTableForDBModel:(EFDataModel *)dbModel object:(id)object database:(FMDatabase *)database
{
    DDLogInfo(@"CREATE_TABLE [%@] for dataType [%@]", dbModel.table, dbModel.dataType);
    NSString *query = [dbModel createTableQueryForModel:object];
    DDLogDebug(@"CREATE_TABLE_QUERY [%@]", query);
    return [database executeUpdate:query];
}

+ (BOOL)dropTableForDBModel:(EFDataModel *)dbModel database:(FMDatabase *)database
{
    DDLogInfo(@"DROP_TABLE [%@] for dataType [%@]", dbModel.table, dbModel.dataType);
    NSString *query = [NSString stringWithFormat:@"DROP TABLE %@", dbModel.table];
    return [database executeUpdate:query];
}

+ (BOOL)saveUsingDatabaseQueue:(FMDatabaseQueue *)databaseQueue items:(NSArray *)items dataType:(NSString *)dataType
{
    if ([items count] == 0) {
        return YES;
    }
    
    __block BOOL schemaAcceptable = NO;
    EFDataModel *dbModel = [[EFDataModel alloc] initWithDataType:dataType];
    if (!dbModel.table) {
        DDLogError(@"ERROR No table defined for dataType [%@]", dataType);
        return NO;
    }
    [databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        schemaAcceptable = [self validateTableForDBModel:dbModel database:db];
        if (!schemaAcceptable) {
            if ([dbModel dropIfInvalidSchema]) {
                [self dropTableForDBModel:dbModel database:db];
            }
            schemaAcceptable = [self createTableForDBModel:dbModel object:[items firstObject] database:db];
        }
    }];
    
    if (schemaAcceptable) {
        return [self saveUsingDatabaseQueue:databaseQueue items:items dbModel:dbModel];
    } else {
        DDLogError(@"Table schema invalid for dataType [%@]", dataType);
        return NO;
    }
}

+ (BOOL)saveUsingDatabaseQueue:(FMDatabaseQueue *)databaseQueue items:(NSArray *)items dbModel:(EFDataModel *)dbModel
{
#ifdef DEBUG
	NSDate *time1 = [NSDate date];
#endif
    
    __block BOOL success = NO;
    [databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSArray *keys = [dbModel columnKeys];
        for (NSObject *item in items)
        {
            NSParameterAssert([item conformsToProtocol:@protocol(DBModelProtocol)]);
            NSMutableString *query = [NSMutableString stringWithFormat:@"INSERT OR REPLACE INTO %@", dbModel.table];
            NSMutableString *columnMutableString;
            NSMutableString *valueMutableString;
            
            for (NSString *key in keys)
            {
                NSString *column = [dbModel columnForKey:key];
                if (columnMutableString == nil)
                    columnMutableString = [NSMutableString stringWithFormat:@"`%@`", column];
                else
                    [columnMutableString appendFormat:@", `%@`", column];
                
                NSValue *value = [item valueForKey:key];
                NSMutableString *eachValueString;
                if (value != nil && (NSNull *)value != [NSNull null])
                {
                    if ([value isKindOfClass:[NSDate class]])
                    {
                        if (db.hasDateFormatter)
                            eachValueString = [NSMutableString stringWithString:[db stringFromDate:(NSDate *)value]];
                        else
                            eachValueString = [NSMutableString stringWithFormat:@"%f", [(NSDate *)value timeIntervalSince1970]];
                    }
                    else
                        eachValueString = [NSMutableString stringWithFormat:@"%@", value];
                    
                    // Escape single quotes
                    NSRange range = NSMakeRange(0, [eachValueString length]);
                    [eachValueString replaceOccurrencesOfString:@"'" withString:@"''" options:NSCaseInsensitiveSearch range:range];
                }
                else
                {
                    eachValueString = [NSMutableString stringWithString:@""];
                }
                
                if (valueMutableString == nil)
                    valueMutableString = [NSMutableString stringWithFormat:@"'%@'", eachValueString];
                else
                    [valueMutableString appendFormat:@", '%@'", eachValueString];
            }
            
            [query appendFormat:@" (%@) VALUES (%@)", columnMutableString, valueMutableString];
            DDLogVerbose(@"QUERY: %@", query);
            success = [db executeUpdate:query];
            if (!success)
            {
                DDLogError(@"ERROR: SAVE_DATA (%@) failed", dbModel.dataType);
                DDLogError(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                *rollback = YES;
                return;
            }
        }
    }];
	
#ifdef DEBUG
	NSDate *time2 = [NSDate date];
	NSTimeInterval elapsedTime1 = [time2 timeIntervalSinceDate:time1];
	DDLogInfo(@"SAVE_DATA (%@): %f seconds | itemCount: %lu", dbModel.dataType, elapsedTime1, (unsigned long)[items count]);
#endif
    
    return YES;
}

#pragma mark - Generic Helpers

+ (NSString *)stringFromArray:(NSArray *)array separator:(NSString *)separator
{
    return [self stringFromArray:array separator:separator includeQuotes:NO];
}

+ (NSString *)stringFromArray:(NSArray *)array separator:(NSString *)separator includeQuotes:(BOOL)includeQuotes
{
    NSMutableString *mutableString = [NSMutableString string];
    NSString *quote = includeQuotes ? @"'" : @"";
    for (id obj in array)
    {
        if ([mutableString length] == 0)
            [mutableString appendFormat:@"%@%@%@", quote, [obj description], quote];
        else
            [mutableString appendFormat:@"%@%@%@%@", separator, quote, [obj description], quote];
    }
    
    return mutableString;
}

+ (NSString *)createEditableCopyOfFileIfNeeded:(NSString *)fileName addSkipBackupAttribute:(BOOL)addSkipBackupAttribute
{
    if (fileName == nil)
    {
        DDLogError(@"createEditableCopyOfFileIfNeeded called with nil file name");
        return nil;
    }
    
    // First, test for existence.
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError * error;
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [paths objectAtIndex:0];
    NSString * filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    
	DDLogVerbose(@"File path (%@): %@", fileName, filePath);
    
	success = [fileManager fileExistsAtPath:filePath];
    if (success) return filePath;
    
    // The writable database does not exist, so copy the default to the appropriate location.
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:fileName];
    //    success = [fileManager copyItemAtPath:defaultDBPath toPath:filePath error:&error];
    
    NSURL *fromURL = [NSURL fileURLWithPath:defaultDBPath];
    NSURL *toURL = [NSURL fileURLWithPath:filePath];
    success = [fileManager copyItemAtURL:fromURL toURL:toURL error:&error];
    if (success)
    {
        if (addSkipBackupAttribute)
        {
            if ([self addSkipBackupAttributeToItemAtURL:toURL])
            {
                DDLogInfo(@"SKIP_BACKUP_ATTRIBUTE_ADDED - %@\n%@", fileName, filePath);
            }
            else
            {
                DDLogInfo(@"ERROR_SKIP_BACKUP_ATTRIBUTE_NOT_ADDED - %@\n%@", fileName, filePath);
            }
        }
    }
    else
    {
        NSAssert1(0, @"Failed to create writable file with message '%@'.", [error localizedDescription]);
        return nil;
    }
    
    return filePath;
}

+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    
    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if(!success){
        NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    return success;
}

@end
