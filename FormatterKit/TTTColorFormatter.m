// TTTColorFormatter.m
// 
// Copyright (c) 2013 Mattt Thompson (http://mattt.me)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "TTTColorFormatter.h"

static void TTTGetRGBAComponentsFromColor(UIColor *color, CGFloat *red, CGFloat *green, CGFloat *blue, CGFloat *alpha) {
    [color getRed:red green:green blue:blue alpha:alpha];
}

static void TTTGetCMYKComponentsFromColor(UIColor *color, CGFloat *cyan, CGFloat *magenta, CGFloat *yellow, CGFloat *black) {
    CGFloat r = 0.0f, g = 0.0f, b = 0.0f;
    TTTGetRGBAComponentsFromColor(color, &r, &g, &b, NULL);

    CGFloat k = 1.0f - fmaxf(fmaxf(r, g), b);
    CGFloat dK = 1.0f - k;

    CGFloat c = (1.0f - (r + k)) / dK;
    CGFloat m = (1.0f - (g + k)) / dK;
    CGFloat y = (1.0f - (b + k)) / dK;

    if (cyan) *cyan = c;
    if (magenta) *magenta = m;
    if (yellow) *yellow = y;
    if (black) *black = k;
}

static void TTTGetHSLComponentsFromColor(UIColor *color, CGFloat *hue, CGFloat *saturation, CGFloat *lightness) {
    CGFloat r = 0.0f, g = 0.0f, b = 0.0f;
    TTTGetRGBAComponentsFromColor(color, &r, &g, &b, NULL);

    CGFloat h = 0.0f, s = 0.0f, l = 0.0f;

    CGFloat v = fmaxf(fmaxf(r, g), b);
    CGFloat m = fminf(fminf(r, g), b);
    l = (m + v) / 2.0f;

    CGFloat vm = v - m;

    if (l > 0.0f && vm > 0.0f) {
        s = vm / ((l <= 0.5f) ? (v + m) : (2.0f - v - m));

        CGFloat r2 = (v - r) / vm;
        CGFloat g2 = (v - g) / vm;
        CGFloat b2 = (v - b) / vm;

        if (r == v) {
            h = (g == m ? 5.0f + b2 : 1.0f - g2);
        } else if (g == v) {
            h = (b == m ? 1.0f + r2 : 3.0f - b2);
        } else {
            h = (r == m ? 3.0f + g2 : 5.0f - r2);
        }

        h /= 6.0f;
    }

    if (hue) *hue = h;
    if (saturation) *saturation = s;
    if (lightness) *lightness = l;
}

#pragma mark -

@implementation TTTColorFormatter

- (NSString *)hexadecimalStringFromColor:(UIColor *)color {
    CGFloat r = 0.0f, g = 0.0f, b = 0.0f;
    TTTGetRGBAComponentsFromColor(color, &r, &g, &b, NULL);

    return [NSString stringWithFormat:@"#%02X%02X%02X", (NSUInteger)roundf(r * 0xFF), (NSUInteger)roundf(g * 0xFF), (NSUInteger)roundf(b * 0xFF)];
}

- (UIColor *)colorFromHexadecimalString:(NSString *)string {
    NSScanner *scanner = [NSScanner scannerWithString:string];
    scanner.charactersToBeSkipped = [[NSCharacterSet alphanumericCharacterSet] invertedSet];

    NSUInteger value;
    [scanner scanHexInt:&value];

    CGFloat r = ((value & 0xFF0000) >> 16) / 255.0f;
    CGFloat g = ((value & 0xFF00) >> 8) / 255.0f;
    CGFloat b = ((value & 0xFF)) / 255.0f;

    return [UIColor colorWithRed:r green:g blue:b alpha:1.0];
}

#pragma mark -

- (NSString *)RGBStringFromColor:(UIColor *)color {
    CGFloat r = 0.0f, g = 0.0f, b = 0.0f;
    TTTGetRGBAComponentsFromColor(color, &r, &g, &b, NULL);

    return [NSString stringWithFormat:@"rgb(%d, %d, %d)", (NSUInteger)roundf(r * 0xFF), (NSUInteger)roundf(g * 0xFF), (NSUInteger)roundf(b * 0xFF)];
}

- (UIColor *)colorFromRGBString:(NSString *)string {
    return [self colorFromRGBAString:string];
}

#pragma mark -

- (NSString *)RGBAStringFromColor:(UIColor *)color {
    CGFloat r = 0.0f, g = 0.0f, b = 0.0f, a = 0.0f;
    TTTGetRGBAComponentsFromColor(color, &r, &g, &b, &a);

    return [NSString stringWithFormat:@"rgb(%d, %d, %d, %g)", (NSUInteger)roundf(r * 0xFF), (NSUInteger)roundf(g * 0xFF), (NSUInteger)roundf(b * 0xFF), a];

}

- (UIColor *)colorFromRGBAString:(NSString *)string {
    NSScanner *scanner = [NSScanner scannerWithString:string];
    scanner.charactersToBeSkipped = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];

    NSInteger r, g, b; CGFloat a;
    [scanner scanInteger:&r];
    [scanner scanInteger:&g];
    [scanner scanInteger:&b];

    if ([scanner scanFloat:&a]) {
        return [UIColor colorWithRed:(r / 255.0f) green:(g / 255.0f) blue:(b / 255.0f) alpha:a];
    } else {
        return [UIColor colorWithRed:(r / 255.0f) green:(g / 255.0f) blue:(b / 255.0f) alpha:1.0];
    }

}

#pragma mark -

- (NSString *)CMYKStringFromColor:(UIColor *)color {
    CGFloat c = 0.0f, m = 0.0f, y = 0.0f, k = 0.0f;
    TTTGetCMYKComponentsFromColor(color, &c, &m, &y, &k);

    return [NSString stringWithFormat:@"cmyk(%g%%, %g%%, %g%%, %g%%)", c * 100.0f, m * 100.0f, y * 100.0f, k * 100.0f];
}

- (UIColor *)colorFromCMYKString:(NSString *)string {
    return nil;
}

#pragma mark -

- (NSString *)HSLStringFromColor:(UIColor *)color {
    CGFloat h = 0.0f, s = 0.0f, l = 0.0f;
    TTTGetHSLComponentsFromColor(color, &h, &s, &l);

    return [NSString stringWithFormat:@"hsl(%d, %g%%, %g%%)", (NSUInteger)roundf(h * 0xFF), s * 100.0f, l * 100.0f];
}

- (UIColor *)colorFromHSLString:(NSString *)string {
    NSScanner *scanner = [NSScanner scannerWithString:string];
    scanner.charactersToBeSkipped = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];

    NSInteger h, s, l;
    [scanner scanInteger:&h];
    [scanner scanInteger:&s];
    [scanner scanInteger:&l];

    return [UIColor colorWithHue:(h / 359.0f) saturation:(s / 100.0f) brightness:(l / 100.0f) alpha:1.0f];
}

#pragma mark -

- (NSString *)UIColorDeclarationFromColor:(UIColor *)color {
    CGFloat r = 0.0f, g = 0.0f, b = 0.0f, a = 0.0f;
    [color getRed:&r green:&g blue:&b alpha:&a];

    return [NSString stringWithFormat:@"[UIColor colorWithRed:%g green:%g blue:%g alpha:%g]", r, g, b, a];
}

@end
