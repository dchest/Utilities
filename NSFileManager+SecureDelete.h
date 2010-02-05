//
//  NSFileManager+SecureDelete.h
//  
//  Securely deletes file by running /usr/bin/srm on it
//

#import <Cocoa/Cocoa.h>


@interface NSFileManager (SecureDelete)
- (void)securelyRemoveFileAtPath:(NSString *)path;
@end
