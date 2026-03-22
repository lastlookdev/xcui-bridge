#import "ObjCExceptionCatcher.h"

NSString * _Nullable LLBTryObjC(void (NS_NOESCAPE ^block)(void)) {
    @try {
        block();
        return nil;
    } @catch (NSException *exception) {
        return [NSString stringWithFormat:@"%@: %@", exception.name, exception.reason ?: @"(no reason)"];
    }
}
