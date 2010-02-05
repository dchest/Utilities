//
//  NSString+Wrap.h
//

#import <Cocoa/Cocoa.h>


@interface NSString (Wrap) 
- (NSString *)stringByWrappingWithLineLength:(NSUInteger)lineLength;
@end
