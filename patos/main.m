//
//  main.m
//  patos

#import <Foundation/Foundation.h>
#import "patos.h"

int main(int argc, const char * argv[])
{
    int retVal = 0;
    @autoreleasepool {
        
        patos* p = [[patos alloc] initWithArgc:argc argv:argv];
        
        retVal = [p run];
        
    }
    return retVal;
}

