//
//  NSTask+EasyExecute.h
//  patos

#import <Foundation/Foundation.h>

@interface NSTask (EasyExecute)
+ (NSString*) executeAndReturnStdOut:(NSString*)taskPath arguments:(NSArray*)args;
+ (NSString*) executeAndReturnStdOut:(NSString*)taskPath arguments:(NSArray*)args withMaxStringLength:(NSUInteger)strLen; // not guaranteed
@end
