//
//  patos.m
//  patos

#import "patos.h"
#import "NSString+Hex.h"
#import "NSTask+EasyExecute.h"

@interface NSString (Safe)
- (const char*) safeUTF8String;
@end

@interface NSTask (Extended)
+ (NSString*) executeXcodeTool:(NSString*)toolName arguments:(NSArray*)arguments printLogs:(BOOL)printLogs;
@end

@interface patos ()
{
}

@property (nonatomic, assign, readwrite) unsigned int mainFunctionSymbolAddress;
@property (nonatomic, assign, readwrite) unsigned int slide;
@property (nonatomic, assign, readwrite) unsigned int targetSymbolAddress;

- (BOOL) extractAndPrintSymbol;
- (BOOL) deriveDSYMPath;
- (BOOL) extractSlide;
- (BOOL) extractMainFunctionSymbolAddress;
- (BOOL) calculateLoadAddress;
- (BOOL) calculateTargetSymbolAddress;
- (BOOL) calculateTargetSymbol;  // also prints

@end

@implementation patos

- (NSString*) dSYMPath
{
    if (!_dSYMPath && _XCArchivePath)
    {
        [self deriveDSYMPath];
    }
    return _dSYMPath;
}

- (id) initWithArgc:(int)argc argv:(const char**)argv
{
    if (self = [super init])
    {
        for (int argi = 1; argi < argc - 1; argi++)
        {
            NSString* arg = [NSString stringWithUTF8String:argv[argi]];
            NSString* val = [NSString stringWithUTF8String:argv[argi+1]];
            if (!_XCArchivePath && [arg hasPrefix:@"-x"])
            {
                _XCArchivePath = val;
            }
            else if (!_dSYMPath && [arg hasPrefix:@"-d"])
            {
                _dSYMPath = val;
            }
            else if (!_mainFunctionStackAddress && [arg hasPrefix:@"-m"])
            {
                _mainFunctionStackAddress = val.hexValue;
            }
            else if (!_targetStackAddress && [arg hasPrefix:@"-a"])
            {
                _targetStackAddress = val.hexValue;
            }
            else if (!_CPUArchitecture && [arg hasPrefix:@"-c"])
            {
                _CPUArchitecture = val;
            }
            else if (!_loadAddress && [arg hasPrefix:@"-l"])
            {
                _loadAddress = val.hexValue;
            }
            else if (!_slide && [arg hasPrefix:@"-s"])
            {
                _slide = val.hexValue;
            }
            else if ([arg hasPrefix:@"-p"] && [[val lowercaseString] hasPrefix:@"y"])
            {
                _printAllDebugLogs = YES;
            }
        }
        
        _executionPath = [NSString stringWithUTF8String:argv[0]];
    }
    return self;
}

- (void) printUsage
{
    printf("%s [-c <CPU_ARCH>] [-m <MAIN_FUNCTION_STACK_ADDRESS> OR -l <LOAD_ADDRESS>] -a <TARGET_STACK_ADDRESS> [-x <PATH_TO_XCARCHIVE> OR -d <PATH_TO_DSYM>] [-s <SLIDE (optional)>] [-p <TO OUTPUT ALL DEBUG LOGS pass Y. Pass N otherwise. Default is N>]\n", _executionPath.safeUTF8String);
}

- (int) run
{
    if ((!_mainFunctionStackAddress && !_loadAddress) ||
        !_targetStackAddress ||
        !_CPUArchitecture ||
        (!_dSYMPath && !_XCArchivePath))
    {
        [self printUsage];
        return -1;
    }
    
    if (!self.dSYMPath)
    {
        fprintf(stderr, "%s is not a viable xarchive!\n", _XCArchivePath.safeUTF8String);
        return -1;
    }
    
    if (![self extractAndPrintSymbol])
    {
        fprintf(stderr, "Could not load symbol address!\n");
        return -1;
    }
    
    return 0;
}

- (BOOL) extractAndPrintSymbol
{
    BOOL success = NO;
    
    if (self.mainFunctionStackAddress)
    {
        if (self.printAllDebugLogs)
        printf("Main Stack Address == 0x%x\n", self.mainFunctionStackAddress);
    }
    else if (self.loadAddress)
    {
        if (self.printAllDebugLogs)
        printf("Load Address == 0x%x\n", self.loadAddress);
    }
    if (self.printAllDebugLogs)
    printf("Target Stack Address == 0x%x\n", self.targetStackAddress);

    if (self.slide || [self extractSlide])
    {
        if (self.printAllDebugLogs)
        printf("Slide == 0x%x\n", self.slide);
        if (self.loadAddress || [self extractMainFunctionSymbolAddress])
        {
            if (self.mainFunctionSymbolAddress)
            {
                if (self.printAllDebugLogs)
                printf("Main Symbol Address == 0x%x\n", self.mainFunctionSymbolAddress);
            }

            if (self.loadAddress || [self calculateLoadAddress])
            {
                if (self.mainFunctionSymbolAddress)
                {
                    if (self.printAllDebugLogs)
                    printf("Load Address == 0x%x\n", self.loadAddress);
                }

                /*if*/ ([self calculateTargetSymbolAddress]);
                {
                    if (self.printAllDebugLogs)
                    printf("Target Symbol Address == 0x%x\n", self.targetSymbolAddress);
                    success = [self calculateTargetSymbol];
                    if (!self.printAllDebugLogs)
                        fprintf(stderr, "%s\n", self.targetSymbol.safeUTF8String);
                }
            }
        }
    }
    
    return success;
}

- (BOOL) deriveDSYMPath
{
    NSString* binary = nil;
    NSString* xcarchive = _XCArchivePath;
    
    @autoreleasepool {
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:xcarchive isDirectory:&isDir] && isDir)
        {
            NSString* file = [xcarchive stringByAppendingPathComponent:@"dSYMs"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:xcarchive isDirectory:&isDir] && isDir)
            {
                NSMutableArray* possibleDSYMs = [NSMutableArray array];
                NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:file error:NULL];
                for (NSString* theFile in files)
                {
                    if ([theFile hasSuffix:@".app.dSYM"])
                    {
                        [possibleDSYMs addObject:[file stringByAppendingPathComponent:theFile]];
                    }
                }
                
                file = nil;
                if (possibleDSYMs.count > 1)
                {
                    file = [possibleDSYMs objectAtIndex:0];
                }
                else if (possibleDSYMs.count == 1)
                {
                    file = [possibleDSYMs objectAtIndex:0];
                }
                
                if (file)
                {
                    NSString* name = [file lastPathComponent];
                    name = [name stringByDeletingPathExtension];
                    name = [name stringByDeletingPathExtension];
                    file = [file stringByAppendingPathComponent:@"Contents"];
                    file = [file stringByAppendingPathComponent:@"Resources"];
                    file = [file stringByAppendingPathComponent:@"DWARF"];
                    file = [file stringByAppendingPathComponent:name];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:file isDirectory:&isDir] && !isDir)
                    {
                        binary = file;
                    }
                }
            }
        }
    }
    
    if (binary)
    {
        _dSYMPath = binary;
    }
    
    return !!binary;
}

- (BOOL) extractSlide
{
    unsigned int slide = 0;
    BOOL success = NO;
    
    @autoreleasepool {
        NSString* output = [NSTask executeXcodeTool:@"otool" arguments:@[@"-arch", self.CPUArchitecture, @"-l", self.dSYMPath] printLogs:self.printAllDebugLogs];
        NSArray* lines = [output componentsSeparatedByString:@"\n"];
        NSCharacterSet* whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        for (NSUInteger i = 0; i < lines.count && !success; i++)
        {
            NSString* line = [[lines objectAtIndex:i] stringByTrimmingCharactersInSet:whitespace];
            if ([line isEqualToString:@"cmd LC_SEGMENT"])
            {
                BOOL isText = NO;
                for (NSUInteger j = 1; j+i < lines.count && j < 8 && !success; j++)
                {
                    line = [[lines objectAtIndex:i+j] stringByTrimmingCharactersInSet:whitespace];
                    if (!isText)
                    {
                        isText = [line isEqualToString:@"segname __TEXT"];
                    }
                    else if ([line hasPrefix:@"vmaddr"])
                    {
                        success = YES;
                        slide = [[[line stringByReplacingOccurrencesOfString:@"vmaddr" withString:@""] stringByTrimmingCharactersInSet:whitespace] hexValue];
                    }
                }
            }
        }
    }

    if (success)
        self.slide = slide;
    return success;
}

- (BOOL) extractMainFunctionSymbolAddress
{
    unsigned int main_symbol = 0;
    BOOL success = NO;
    
    @autoreleasepool {
        NSString* dwarfdump = [NSTask executeAndReturnStdOut:@"/usr/bin/xcrun" arguments:@[@"-find", @"-sdk", @"iphoneos", @"dwarfdump"]];
        NSString* output = [NSTask executeAndReturnStdOut:dwarfdump
                                                arguments:@[@"--all", @"--arch", self.CPUArchitecture, self.dSYMPath]
                                      withMaxStringLength:1024*100];
        NSArray* lines = [output componentsSeparatedByString:@"\n"];
        for (NSString* line in lines)
        {
            if ([line hasSuffix:@") main"])
            {
                NSMutableArray* subvalues = [[line componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":)-["]] mutableCopy];
                for (NSUInteger i = 0; i < subvalues.count; i++)
                {
                    NSString* subvalue = [[subvalues objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if (subvalue.length == 0)
                    {
                        [subvalues removeObjectAtIndex:i];
                        i--;
                    }
                }
                
                if (subvalues.count > 1)
                {
                    main_symbol = [[subvalues objectAtIndex:1] hexValue];
                    success = main_symbol > 0;
                }
                
                break;
            }
        }
    }
    
    if (success)
        self.mainFunctionSymbolAddress = main_symbol;
    return success;
}

- (BOOL) calculateLoadAddress
{
    BOOL success = NO;
    unsigned int ld_address = self.mainFunctionStackAddress - self.mainFunctionSymbolAddress;
    if (ld_address > self.mainFunctionStackAddress)
    {
        if (self.printAllDebugLogs)
        fprintf(stderr, "main() stack address MUST be larger than the main() symbol address\n");
    }
    else
    {
        ld_address += self.slide;
        if (ld_address < self.slide)
        {
            if (self.printAllDebugLogs)
            fprintf(stderr, "value of vm_addr (slide) is too large!\n");
        }
        else
        {
            success = YES;
            self.loadAddress = ld_address;
        }
    }
    return success;
}

- (BOOL) calculateTargetSymbolAddress
{
    BOOL success = NO;
    unsigned int func_symbol_address = self.targetStackAddress - self.loadAddress;
    if (func_symbol_address > self.targetStackAddress)
    {
        if (self.printAllDebugLogs)
        fprintf(stderr, "target stack address is too small for the calculated load address (0x%x)\n", self.loadAddress);
    }
    else
    {
        func_symbol_address += self.slide;
        if (func_symbol_address < self.slide)
        {
            if (self.printAllDebugLogs)
            fprintf(stderr, "value of vm_addr (slide) is too large!\n");
        }
        else
        {
            success = YES;
            self.targetSymbolAddress = func_symbol_address;
        }
    }
    return success;
}

- (BOOL) calculateTargetSymbol
{
    NSString* addy = [NSString stringWithFormat:@"0x%x", self.targetStackAddress];
    NSString* addy2 = [NSString stringWithFormat:@"0x%x", (self.loadAddress ? self.loadAddress : self.slide)];
    NSString* output = [NSTask executeXcodeTool:@"atos" arguments:@[@"-arch", self.CPUArchitecture, @"-o", self.dSYMPath, (self.loadAddress ? @"-l" : @"-s"), addy2, addy] printLogs:self.printAllDebugLogs];
    NSArray* comp = [output componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    output = comp.count > 0 ? [comp lastObject] : nil;
    output = [output stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    _targetSymbol = [output copy];
    return !!_targetSymbol;
}

@end

@implementation NSTask (Extended)

+ (NSString*) executeXcodeTool:(NSString*)toolName arguments:(NSArray*)arguments printLogs:(BOOL)printLogs
{
    NSString* toolPath = [NSTask executeAndReturnStdOut:@"/usr/bin/xcrun" arguments:@[@"-find", @"-sdk", @"iphoneos", toolName]];
    NSString* output = nil;
    if (toolPath)
    {
        if (printLogs)
        {
            printf("\n\n");
            printf("%s ", toolPath.safeUTF8String);
        }
        for (NSString* arg in arguments)
        {
            if (printLogs)
            printf("%s ", arg.safeUTF8String);
        }
        if (printLogs)
        printf("\n");
        output = [NSTask executeAndReturnStdOut:toolPath arguments:arguments];
        if (printLogs)
            printf("%s\n", output.safeUTF8String); // This will print outputs of the tool like all binary segments and headers/load addresses
        /*
         Load command 0
         cmd LC_UUID
         cmdsize 24
         uuid C4E01E61-640B-367F-BD10-17AED1619084
         Load command 1
         cmd LC_SYMTAB
         cmdsize 24
         symoff 4096
         nsyms 40995
         stroff 496036
         strsize 1619152
         */
    }
    else
    {
        if (printLogs)
        printf("\n\nMissing Tool! %s\n", toolName.safeUTF8String);
    }
    return output;
}

@end

@implementation NSString (Safe)

- (const char*) safeUTF8String
{
    return [self cStringUsingEncoding:NSUTF8StringEncoding];
}

@end
