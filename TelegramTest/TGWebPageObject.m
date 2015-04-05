//
//  TGWebPageObject.m
//  Telegram
//
//  Created by keepcoder on 01.04.15.
//  Copyright (c) 2015 keepcoder. All rights reserved.
//

#import "TGWebpageObject.h"
#import "TGDateUtils.h"
#import "TGWebpageIGObject.h"
#import "TGWebpageYTObject.h"
#import "TGWebpageTWObject.h"
#import "TGWebpageStandartObject.h"
#import "TGWebpageArticle.h"
#import "NSAttributedString+Hyperlink.h"
@implementation TGWebpageObject

-(id)initWithWebPage:(TLWebPage *)webpage {
    if(self = [super init]) {
        
        _webpage = webpage;
        
        
        NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
        style.lineBreakMode = NSLineBreakByTruncatingTail;
        style.alignment = NSLeftTextAlignment;
        
        if(webpage.author) {
            
            NSMutableAttributedString *author = [[NSMutableAttributedString alloc] init];
            
            
            [author appendString:webpage.author withColor:DARK_BLACK];
            
            [author setFont:[NSFont fontWithName:@"HelveticaNeue-Medium" size:12.5] forRange:author.range];
            
            [author addAttribute:NSParagraphStyleAttributeName value:style range:author.range];
            
            _author = author;
            
        }
        
        
        _date = webpage.date == 0 ? nil : [TGDateUtils stringForMessageListDate:webpage.date];
        
        if(webpage.title) {
            NSMutableAttributedString *title = [[NSMutableAttributedString alloc] init];
            
            
            
            [title appendString:webpage.title withColor:[NSColor blackColor]];
            [title setFont:[NSFont fontWithName:@"HelveticaNeue" size:12.5] forRange:title.range];
            
            _title = title;
        }
        
        if(!_author) {
            
            NSMutableAttributedString *copy = [_title mutableCopy];
            
            [copy setFont:[NSFont fontWithName:@"HelveticaNeue-Medium" size:12.5] forRange:copy.range];
            [copy addAttribute:NSParagraphStyleAttributeName value:style range:copy.range];
            _author = copy;
            
        }
        
        NSMutableAttributedString *siteName = [[NSMutableAttributedString alloc] init];
        
        [siteName appendString:webpage.site_name withColor:LINK_COLOR];
        
        [siteName setFont:[NSFont fontWithName:@"HelveticaNeue-Medium" size:12.5] forRange:siteName.range];
        [siteName addAttribute:NSParagraphStyleAttributeName value:style range:siteName.range];
        
        _siteName = siteName;
        
        if(webpage.n_description) {
            NSMutableAttributedString *desc = [[NSMutableAttributedString alloc] init];
            
            [desc appendString:webpage.n_description withColor:[NSColor blackColor]];
            [desc setFont:[NSFont fontWithName:@"HelveticaNeue" size:12.5] forRange:desc.range];
            
            NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
            style.lineBreakMode = NSLineBreakByWordWrapping;
            style.alignment = NSLeftTextAlignment;
            
            [desc addAttribute:NSParagraphStyleAttributeName value:style range:desc.range];
            _desc = desc;
            
            [desc detectExternalLinks];
        }
        
       
        if(webpage.n_description.length > 0) {
            _toolTip = [NSString stringWithFormat:@"%@",webpage.n_description];
        }
        
        
        
        if(![webpage.photo isKindOfClass:[TL_photoEmpty class]] && webpage.photo.sizes.count > 0) {
            NSArray *photo = [webpage.photo sizes];
            
            TLPhotoSize *photoSize = [photo lastObject];
            
            __block NSImage *thumb;
            
            [photo enumerateObjectsUsingBlock:^(TLPhotoSize *obj, NSUInteger idx, BOOL *stop) {
                
                if([obj isKindOfClass:[TL_photoCachedSize class]]) {
                    thumb = [[NSImage alloc] initWithData:obj.bytes];
                    *stop = YES;
                }
                
            }];
            
            
            _imageObject = [[TGImageObject alloc] initWithLocation:photoSize.location placeHolder:thumb sourceId:0 size:photoSize.size];
            
            
            NSSize imageSize = strongsize(NSMakeSize(photoSize.w, photoSize.h), 320);
            
            
            _imageObject.imageSize = imageSize;
        }
        
        
    }
    
    return self;
}



-(void)makeSize:(int)width {
    
    if(![self.webpage.type isEqualToString:@"profile"]) {
        _imageSize = strongsize(_imageObject.imageSize, width - 67);
        
        _titleSize = [self.title coreTextSizeForTextFieldForWidth:_imageSize.width ? : width-67];
        _descSize = [self.desc coreTextSizeForTextFieldForWidth:_imageSize.width ? : width-67];
        
        _size = _imageSize;
        
        _size.height+=self.titleSize.height + self.descSize.height + (!self.author ?:17) + (((_title || _desc) && _imageObject) ? 8 : 0) + 12;
    } else {
        _imageSize = strongsize(_imageObject.imageSize, 60);
        
        _titleSize = [self.title coreTextSizeForTextFieldForWidth: width-132];
        _descSize = [self.desc coreTextSizeForTextFieldForWidth: width-132];
        
        _size = _imageSize;
    }
    
    
    
    
    
    _size.width = width - 60;
    
}

-(Class)webpageContainer {
    return NSClassFromString(@"TGWebpageContainer");
}

+(id)objectForWebpage:(TLWebPage *)webpage {
    
    
    if(!ACCEPT_FEATURE)
        return nil;
    
    static NSArray *supportTypes;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        supportTypes = @[@"video",@"article",@"photo",@"profile"];
    });
    
    if([supportTypes indexOfObject:webpage.type] == NSNotFound)
        return nil;
    
    if([webpage.site_name isEqualToString:@"YouTube"])
    {
        return [[TGWebpageYTObject alloc] initWithWebPage:webpage];
    }
    
    if([webpage.site_name isEqualToString:@"Instagram"])
    {
        return [[TGWebpageIGObject alloc] initWithWebPage:webpage];
    }
    
    if([webpage.site_name isEqualToString:@"Twitter"])
    {
        return [[TGWebpageTWObject alloc] initWithWebPage:webpage];
    }
    
    
    if([webpage.type isEqualToString:@"article"])
    {
        return [[TGWebpageArticle alloc] initWithWebPage:webpage];
    }
    
    if([webpage.type isEqualToString:@"photo"] || ([webpage.type isEqualToString:@"video"] && [webpage.embed_type isEqualToString:@"video/mp4"]))
    {
        return [[TGWebpageStandartObject alloc] initWithWebPage:webpage];
    }
    
    return nil;
}

-(NSImage *)siteIcon  {
    return nil;
}


@end
