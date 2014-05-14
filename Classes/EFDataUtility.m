//
//  EFDataUtility.m
//  Pods
//
//  Created by Elton Faggett on 5/14/14.
//
//

#import "EFDataUtility.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

@implementation EFDataUtility

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
