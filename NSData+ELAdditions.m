//
//  NSData+ELAdditions.m
//  EllipticLicense
//
//  Created by Dmitry Chestnykh on 28.03.09.
//
//  Copyright (c) 2009 Dmitry Chestnykh, Coding Robots
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//
//  Base32 encoding/decoding methods taken from public domain code at
//  http://www.cocoadev.com/index.pl?NSDataCategory


#import "NSData+ELAdditions.h"
#import "openssl/sha.h"

@implementation NSData (ELAdditions)

+ (NSData *)el_dataWithBase32String:(NSString *)encoded;
{
	/* First valid character that can be indexed in decode lookup table */
	static int charDigitsBase = '2';
	
	/* Lookup table used to decode() characters in encoded strings */
	static int charDigits[] =
	{	26,27,28,29,30,31,-1,-1,-1,-1,-1,-1,-1,-1 //   23456789:;<=>?
		,-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14 // @ABCDEFGHIJKLMNO
		,15,16,17,18,19,20,21,22,23,24,25,-1,-1,-1,-1,-1 // PQRSTUVWXYZ[\]^_
		,-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14 // `abcdefghijklmno
		,15,16,17,18,19,20,21,22,23,24,25                // pqrstuvwxyz
	};
	
	if (! [encoded canBeConvertedToEncoding:NSASCIIStringEncoding]) return nil;
	const char *chars = [encoded UTF8String]; // avoids using characterAtIndex.
	int charsLen = strlen(chars);
	
	// Note that the code below could detect non canonical Base32 length within the loop. However canonical Base32 length can be tested before entering the loop.
	// A canonical Base32 length modulo 8 cannot be:
	// 1 (aborts discarding 5 bits at STEP n=0 which produces no byte),
	// 3 (aborts discarding 7 bits at STEP n=2 which produces no byte),
	// 6 (aborts discarding 6 bits at STEP n=1 which produces no byte).
	switch (charsLen & 7) { // test the length of last subblock
		case 1: //  5 bits in subblock:  0 useful bits but 5 discarded
		case 3: // 15 bits in subblock:  8 useful bits but 7 discarded
		case 6: // 30 bits in subblock: 24 useful bits but 6 discarded
			return nil; // non-canonical length
	}
	int charDigitsLen = sizeof(charDigits);
	int bytesLen = (charsLen * 5) >> 3;
	Byte bytes[bytesLen];
	int bytesOffset = 0, charsOffset = 0;
	// Also the code below does test that other discarded bits
	// (1 to 4 bits at end) are effectively 0.
	while (charsLen > 0)
	{
		int digit, lastDigit;
		// STEP n = 0: Read the 1st Char in a 8-Chars subblock
		// Leave 5 bits, asserting there's another encoding Char
		if ((digit = (int)chars[charsOffset] - charDigitsBase) < 0 || digit >= charDigitsLen || (digit = charDigits[digit]) == -1)
			return nil; // invalid character
		lastDigit = digit << 3;
		// STEP n = 5: Read the 2nd Char in a 8-Chars subblock
		// Insert 3 bits, leave 2 bits, possibly trailing if no more Char
		if ((digit = (int)chars[charsOffset + 1] - charDigitsBase) < 0 || digit >= charDigitsLen || (digit = charDigits[digit]) == -1)
			return nil; // invalid character
		bytes[bytesOffset] = (Byte)((digit >> 2) | lastDigit);
		lastDigit = (digit & 3) << 6;
		if (charsLen == 2) {
			if (lastDigit != 0) return nil; // non-canonical end
			break; // discard the 2 trailing null bits
		}
		// STEP n = 2: Read the 3rd Char in a 8-Chars subblock
		// Leave 7 bits, asserting there's another encoding Char
		if ((digit = (int)chars[charsOffset + 2] - charDigitsBase) < 0 || digit >= charDigitsLen || (digit = charDigits[digit]) == -1)
			return nil; // invalid character
		lastDigit |= (Byte)(digit << 1);
		// STEP n = 7: Read the 4th Char in a 8-chars Subblock
		// Insert 1 bit, leave 4 bits, possibly trailing if no more Char
		if ((digit = (int)chars[charsOffset + 3] - charDigitsBase) < 0 || digit >= charDigitsLen || (digit = charDigits[digit]) == -1)
			return nil; // invalid character
		bytes[bytesOffset + 1] = (Byte)((digit >> 4) | lastDigit);
		lastDigit = (Byte)((digit & 15) << 4);
		if (charsLen == 4) {
			if (lastDigit != 0) return nil; // non-canonical end
			break; // discard the 4 trailing null bits
		}
		// STEP n = 4: Read the 5th Char in a 8-Chars subblock
		// Insert 4 bits, leave 1 bit, possibly trailing if no more Char
		if ((digit = (int)chars[charsOffset + 4] - charDigitsBase) < 0 || digit >= charDigitsLen || (digit = charDigits[digit]) == -1)
			return nil; // invalid character
		bytes[bytesOffset + 2] = (Byte)((digit >> 1) | lastDigit);
		lastDigit = (Byte)((digit & 1) << 7);
		if (charsLen == 5) {
			if (lastDigit != 0) return nil; // non-canonical end
			break; // discard the 1 trailing null bit
		}
		// STEP n = 1: Read the 6th Char in a 8-Chars subblock
		// Leave 6 bits, asserting there's another encoding Char
		if ((digit = (int)chars[charsOffset + 5] - charDigitsBase) < 0 || digit >= charDigitsLen || (digit = charDigits[digit]) == -1)
			return nil; // invalid character
		lastDigit |= (Byte)(digit << 2);
		// STEP n = 6: Read the 7th Char in a 8-Chars subblock
		// Insert 2 bits, leave 3 bits, possibly trailing if no more Char
		if ((digit = (int)chars[charsOffset + 6] - charDigitsBase) < 0 || digit >= charDigitsLen || (digit = charDigits[digit]) == -1)
			return nil; // invalid character
		bytes[bytesOffset + 3] = (Byte)((digit >> 3) | lastDigit);
		lastDigit = (Byte)((digit & 7) << 5);
		if (charsLen == 7) {
			if (lastDigit != 0) return nil; // non-canonical end
			break; // discard the 3 trailing null bits
		}
		// STEP n = 3: Read the 8th Char in a 8-Chars subblock
		// Insert 5 bits, leave 0 bit, next encoding Char may not exist
		if ((digit = (int)chars[charsOffset + 7] - charDigitsBase) < 0 || digit >= charDigitsLen || (digit = charDigits[digit]) == -1)
			return nil; // invalid character
		bytes[bytesOffset + 4] = (Byte)(digit | lastDigit);
		//// This point is always reached for chars.length multiple of 8
		charsOffset += 8;
		bytesOffset += 5;
		charsLen -= 8;
	}
	// On loop exit, discard the n trailing null bits
	return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

- (NSString *)el_base32String;
{
	/* Lookup table used to canonically encode() groups of data bits */
	static char canonicalChars[] =
	{	'A','B','C','D','E','F','G','H','I','J','K','L','M' // 00..12
		,'N','O','P','Q','R','S','T','U','V','W','X','Y','Z' // 13..25
		,'2','3','4','5','6','7'                             // 26..31
	};
	const Byte *bytes = [self bytes];
	int bytesOffset = 0, bytesLen = [self length];
	int charsOffset = 0, charsLen = ((bytesLen << 3) + 4) / 5;
	char chars[charsLen+1]; // +1 for terminating null
	while (bytesLen != 0) {
		int digit, lastDigit;
		// INVARIANTS FOR EACH STEP n in [0..5[; digit in [0..31[;
		// The remaining n bits are already aligned on top positions
		// of the 5 least bits of digit, the other bits are 0.
		////// STEP n = 0: insert new 5 bits, leave 3 bits
		digit = bytes[bytesOffset] & 255;
		chars[charsOffset] = canonicalChars[digit >> 3];
		lastDigit = (digit & 7) << 2;
		if (bytesLen == 1) { // put the last 3 bits
			chars[charsOffset + 1] = canonicalChars[lastDigit];
			break;
		}
		////// STEP n = 3: insert 2 new bits, then 5 bits, leave 1 bit
		digit = bytes[bytesOffset + 1] & 255;
		chars[charsOffset + 1] = canonicalChars[(digit >> 6) | lastDigit];
		chars[charsOffset + 2] = canonicalChars[(digit >> 1) & 31];
		lastDigit = (digit & 1) << 4;
		if (bytesLen == 2) { // put the last 1 bit
			chars[charsOffset + 3] = canonicalChars[lastDigit];
			break;
		}
		////// STEP n = 1: insert 4 new bits, leave 4 bit
		digit = bytes[bytesOffset + 2] & 255;
		chars[charsOffset + 3] = canonicalChars[(digit >> 4) | lastDigit];
		lastDigit = (digit & 15) << 1;
		if (bytesLen == 3) { // put the last 1 bits
			chars[charsOffset + 4] = canonicalChars[lastDigit];
			break;
		}
		////// STEP n = 4: insert 1 new bit, then 5 bits, leave 2 bits
		digit = bytes[bytesOffset + 3] & 255;
		chars[charsOffset + 4] = canonicalChars[(digit >> 7) | lastDigit];
		chars[charsOffset + 5] = canonicalChars[(digit >> 2) & 31];
		lastDigit = (digit & 3) << 3;
		if (bytesLen == 4) { // put the last 2 bits
			chars[charsOffset + 6] = canonicalChars[lastDigit];
			break;
		}
		////// STEP n = 2: insert 3 new bits, then 5 bits, leave 0 bit
		digit = bytes[bytesOffset + 4] & 255;
		chars[charsOffset + 6] = canonicalChars[(digit >> 5) | lastDigit];
		chars[charsOffset + 7] = canonicalChars[digit & 31];
		//// This point is always reached for bytes.length multiple of 5
		bytesOffset += 5;
		charsOffset += 8;
		bytesLen -= 5;
	}
	//return [NSString stringWithCString:chars length:sizeof(chars)]; // deprecated
	chars[charsLen] = '\0';
	return [NSString stringWithCString:chars encoding:NSASCIIStringEncoding];
}

- (NSData *)el_sha1Digest;
{
	unsigned char digest[SHA_DIGEST_LENGTH];
	SHA1([self bytes], [self length], digest);
	return [NSData dataWithBytes:digest length:SHA_DIGEST_LENGTH];
}

-  (NSString *)el_sha1DigestString;
{
	return [[self el_sha1Digest] el_hexString];
}

- (NSString *)el_hexString;
{
	const unsigned char *bytes = [self bytes];
	NSMutableString *hexString = [[[NSMutableString alloc] initWithCapacity:[self length] * 2] autorelease];
	for (int i = 0; i < [self length]; i++)
		[hexString appendFormat:@"%02x", (unsigned char)(bytes[i])];
	return [hexString uppercaseString];
}

+ (NSData *)el_dataWithHexString:(NSString *)hexString;
{
	NSMutableData *data = [NSMutableData dataWithCapacity:[hexString length]/2];
	char *chars = (char *)[hexString UTF8String];
	unsigned char value;
	while (*chars != '\0') {
		if (*chars >= '0' && *chars <= '9')
			value = (*chars - '0') << 4;
		else if (*chars >= 'a' && *chars <= 'f')
			value = (*chars - 'a' + 10) << 4;
		else if (*chars >= 'A' && *chars <= 'F')
			value = (*chars - 'A' + 10) << 4;
		else
			return nil;
		
		chars++;
		if (*chars >= '0' && *chars <= '9')
			value |= *chars - '0';
		else if (*chars >= 'a' && *chars <= 'f')
			value |= *chars - 'a' + 10;
		else if (*chars >= 'A' && *chars <= 'F')
			value |= *chars - 'A' + 10;
		else
			return nil;
		[data appendBytes:&value length:sizeof(value)];
		chars++;
	}
	return data;
}

+ (NSData *)el_dataWithString:(NSString *)string;
{
	const char *bytes = [string UTF8String];
	return [NSData dataWithBytes:bytes length:strlen(bytes)];
}

+ (NSData *)el_dataWithStringNoNull:(NSString *)string;
{
	const char *bytes = [string UTF8String];
	size_t lengthWithoutNull = strlen(bytes)-1;
	if (lengthWithoutNull <= 0)
		return nil;
	return [NSData dataWithBytes:bytes length:lengthWithoutNull];
}


@end
