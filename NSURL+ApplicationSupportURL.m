#import "NSURL+ApplicationSupportURL.h"


@implementation NSURL (ApplicationSupportURL)

+ (NSURL *)applicationSupportURL
{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(
                    NSApplicationSupportDirectory, NSUserDomainMask, YES);
  NSString *basePath;
  if ([paths count] > 0) {
    basePath = [paths objectAtIndex:0];
  }
  else {
    NSLog(@"ERROR: Using application support directory not found!");
    return nil;
  }
  NSString *appName = [[[NSBundle mainBundle] infoDictionary]
                       objectForKey:@"CFBundleExecutable"];
  NSURL *url = [[NSURL fileURLWithPath:basePath]
                URLByAppendingPathComponent:appName];
  [[NSFileManager defaultManager] createDirectoryAtPath:[url path]
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:NULL];
  return url;
}


@end
