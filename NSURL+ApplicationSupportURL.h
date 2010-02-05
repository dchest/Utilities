//
//  NSURL+ApplicationSupportURL.h
//  
//  Returns ~/Library/Application Support/AppName
//

#import <Cocoa/Cocoa.h>


@interface NSURL (ApplicationSupportURL)
+ (NSURL *)applicationSupportURL;
@end
