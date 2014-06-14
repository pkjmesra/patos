//
//  NSString+Hex.m
//  patos

#import "NSString+Hex.h"

@implementation NSString (Hex)
- (unsigned int) hexValue
{
    unsigned int value   = 0;
    NSScanner*   scanner = [NSScanner scannerWithString:self];
    [scanner scanHexInt:&value];
    return value;
}
@end
