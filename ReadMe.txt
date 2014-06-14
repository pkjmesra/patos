Use this tool to extract the symbol of a known stack address if you know the load address.

cd <directory where the patos tool is kept>

./patos [-c <CPU_ARCH>] [-m <MAIN_FUNCTION_STACK_ADDRESS> OR -l <LOAD_ADDRESS>] -a <TARGET_STACK_ADDRESS> [-x <PATH_TO_XCARCHIVE> OR -d <PATH_TO_DSYM>] [-s <SLIDE (optional)>] [-p <TO OUTPUT ALL DEBUG LOGS pass Y. Pass N otherwise. Default is N>]

One of MAIN_FUNCTION_STACK_ADDRESS or LOAD_ADDRESS is mandatory
TARGET_STACK_ADDRESS is mandatory, of course
One of PATH_TO_XCARCHIVE or PATH_TO_DSYM is mandatory
SLIDE is optional

Pass -p Y if you want to see all debug logs. Not passing -p or passing -p N will just output the final symbolicated symbol name.


For example if thread 0 stack frames are:

Thread 0:
0   libsystem_kernel.dylib        	0x3952457c __semwait_signal_nocancel + 24
1   libsystem_c.dylib             	0x3949f8ad nanosleep$NOCANCEL + 161
2   libsystem_c.dylib             	0x394baf95 usleep$NOCANCEL + 49
3   libsystem_c.dylib             	0x394d4ffd abort + 81
4   YourAppName                  	0x0064137f 0x4000 + 6542207
5   CoreFoundation                	0x2e7dd20b __handleUncaughtException + 579
6   libobjc.A.dylib               	0x38f6ff69 _objc_terminate() + 173
7   libc++abi.dylib               	0x3893a1b1 std::__terminate(void
8   libc++abi.dylib               	0x38939d13 __cxa_rethrow + 99
9   libobjc.A.dylib               	0x38f6fe2b objc_exception_rethrow + 39
10  CoreFoundation                	0x2e7107db CFRunLoopRunSpecific + 639
11  CoreFoundation                	0x2e710547 CFRunLoopRunInMode + 103
12  GraphicsServices              	0x3366d6cf GSEventRunModal + 135
13  UIKit                         	0x3106f88d UIApplicationMain + 1133
14  YourAppName                  	0x0018e615 0x4000 + 1615381
15  YourAppName                  	0x000094c4 0x4000 + 21700

the crashed thread stack frames are:

Thread 2 Crashed:
0   libsystem_kernel.dylib        	0x39523f9c __psynch_mutexwait + 24
1   libsystem_pthread.dylib       	0x3958d299 _pthread_mutex_lock_contended + 49
2   libsystem_pthread.dylib       	0x39589d37 _pthread_mutex_lock + 259
3   YourAppName                  	0x006864eb 0x4000 + 6825195
4   YourAppName                  	0x005e8189 0x4000 + 6177161
5   YourAppName                  	0x005ead33 0x4000 + 6188339
6   YourAppName                  	0x006368b9 0x4000 + 6498489
7   libdispatch.dylib             	0x39458d51 _dispatch_call_block_and_release + 9
8   libdispatch.dylib             	0x3945dcb9 _dispatch_queue_drain + 485
9   libdispatch.dylib             	0x3945ac6b _dispatch_queue_invoke + 39
10  libdispatch.dylib             	0x3945e5ef _dispatch_root_queue_drain + 75
11  libdispatch.dylib             	0x3945e8d9 _dispatch_worker_thread2 + 53
12  libsystem_pthread.dylib       	0x39589c15 _pthread_wqthread + 297
13  libsystem_pthread.dylib       	0x39589ad8 start_wqthread + 4


Under thread 0, 
frame 15 is your load address,
frame 14 is your main function address

Under thread 2,
frame 3,4,5,6 is what you’d like to symbolicate

So you could say:

./patos -c armv7 -l 0x000094c4 -x /Users/<your username>/Desktop/YourAppName.xcarchive -a 0x006864eb
or
./patos -c armv7 -l 0x000094c4 -x /Users/<your username>/Desktop/YourAppName.xcarchive -a 0x005e8189
or
./patos -c armv7 -l 0x000094c4 -x /Users/<your username>/Desktop/YourAppName.xcarchive -a 0x005ead33
or
./patos -c armv7 -l 0x000094c4 -x /Users/<your username>/Desktop/YourAppName.xcarchive -a 0x006368b9


Licensing:
==========
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
