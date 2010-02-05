#import "NSFileManager+SecureDelete.h"


@implementation NSFileManager (SecureDelete)

- (void)securelyRemoveFileAtPath:(NSString *)path;
{
  NSTask *eraser = [[[NSTask alloc] init] autorelease];  
    [eraser setLaunchPath:@"/usr/bin/srm"];
  [eraser setArguments:[NSArray arrayWithObjects: @"-fm", path, nil]];
  [eraser launch];
}

@end
