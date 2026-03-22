#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Executes a block and catches any Obj-C NSException that is thrown.
/// Returns the exception's reason string, or nil if no exception occurred.
FOUNDATION_EXPORT NSString * _Nullable LLBTryObjC(void (NS_NOESCAPE ^block)(void));

NS_ASSUME_NONNULL_END
