#import "NSString+Wrap.h"


@implementation NSString (Wrap)

- (NSString *)stringByWrappingWithLineLength:(NSUInteger)lineLength;
{
  NSMutableString *result = [[NSMutableString alloc] init];
  unichar c;
  NSUInteger currentLength = 0;
  NSUInteger totalLength = [self length];
  for (NSUInteger i = 0; i < totalLength; i++) {
    c = [self characterAtIndex:i];
    if (++currentLength > lineLength) {
      [result appendFormat:@"%C\n", c];
      len = 0;
    } else {
      [result appendFormat:@"%C", c];
    }
  }
  return [result autorelease];
}

@end
