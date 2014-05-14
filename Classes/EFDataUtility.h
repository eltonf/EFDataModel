//
//  EFDataUtility.h
//  Pods
//
//  Created by Elton Faggett on 5/14/14.
//
//

#import <Foundation/Foundation.h>

@interface EFDataUtility : NSObject

+ (NSString *)stringFromArray:(NSArray *)array separator:(NSString *)separator;
+ (NSString *)stringFromArray:(NSArray *)array separator:(NSString *)separator includeQuotes:(BOOL)includeQuotes;
+ (NSString *)createEditableCopyOfFileIfNeeded:(NSString *)fileName addSkipBackupAttribute:(BOOL)addSkipBackupAttribute;
+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL;

@end
