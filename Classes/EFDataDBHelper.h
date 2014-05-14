//
//  DBHelper.h
//  MobilePRISM
//
//  Created by Elton Faggett on 2/5/14.
//  Copyright (c) 2014 Dallas Cowboys FC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabaseQueue;
@interface EFDataDBHelper : NSObject

#pragma mark - Database Helpers
+ (NSString *)tableForDataType:(NSString *)dataType;
+ (NSDictionary *)columnMapForDataType:(NSString *)dataType;
+ (NSString *)classNameForDataType:(NSString *)dataType;
+ (BOOL)dropIfInvalidForDataType:(NSString *)dataType;
+ (BOOL)saveUsingDatabaseQueue:(FMDatabaseQueue *)databaseQueue items:(NSArray *)items dataType:(NSString *)dataType;
//+ (NSArray *)retreiveItemsUsingDatabaseQueue:(FMDatabaseQueue *)databaseQueue dataType:(NSString *)dataType queryCriteria:(NSString *)queryCriteria;

#pragma mark - Generic Helpers
+ (NSString *)stringFromArray:(NSArray *)array separator:(NSString *)separator;
+ (NSString *)stringFromArray:(NSArray *)array separator:(NSString *)separator includeQuotes:(BOOL)includeQuotes;
+ (NSString *)createEditableCopyOfFileIfNeeded:(NSString *)fileName addSkipBackupAttribute:(BOOL)addSkipBackupAttribute;
+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL;

@end
