//
//  patos.m
//  patos

#import <Foundation/Foundation.h>

@interface patos : NSObject
- (id) initWithArgc:(int)argc argv:(const char**)argv;

@property (nonatomic, copy, readwrite) NSString* executionPath; // argv[0]
@property (nonatomic, copy, readwrite) NSString* XCArchivePath;
@property (nonatomic, copy, readwrite) NSString* dSYMPath;      // if not present, derived from XCArchivePath
@property (nonatomic, copy, readwrite) NSString* CPUArchitecture;
@property (nonatomic, assign, readwrite) unsigned int mainFunctionStackAddress;
@property (nonatomic, assign, readwrite) unsigned int loadAddress;
@property (nonatomic, assign, readwrite) unsigned int targetStackAddress;
@property (nonatomic, assign, readwrite) BOOL printAllDebugLogs;
- (void) printUsage;

- (int) run; // 0 indicates target symbol was extracted
@property (nonatomic, readonly) NSString* targetSymbol;

@end