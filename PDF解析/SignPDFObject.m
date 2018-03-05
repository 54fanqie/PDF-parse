//
//  SignPDFObject.m
//  PDF解析
//
//  Created by 番茄 on 2017/11/25.
//  Copyright © 2017年 番茄. All rights reserved.
//

#import "SignPDFObject.h"
#import <UIKit/UIKit.h>

@implementation SignPDFObject
+(void)setP7InPD{
    
    CGPDFDocumentRef myDocument;
    CFStringRef path = CFStringCreateWithCString(NULL, [@"/Users/fanqie/Desktop/PDF文件/haha.pdf" UTF8String], kCFStringEncodingUTF8);
    CFURLRef url = CFURLCreateWithFileSystemPath (NULL, path, kCFURLPOSIXPathStyle, 0);
    CFRelease (path);
    
    myDocument = CGPDFDocumentCreateWithURL(url);
    CGPDFDictionaryRef dic = CGPDFDocumentGetCatalog(myDocument);
    CGPDFDictionaryApplyFunction(dic, haha, nil);//读取PDF源目录
    CGPDFDictionaryRef catalogDic = CGPDFDocumentGetCatalog(myDocument);
    
    NSString * path2 = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSLog(@"%@", path2);
    //[SignPDFObject creatPDF];
    //[SignPDFObject drawPDF];
     [SignPDFObject addSignaturePDFData:[NSData dataWithContentsOfFile:@"/Users/fanqie/Desktop/testPDF.pdf"]];
}

void haha(const char *key, CGPDFObjectRef object, void *info)
{
    NSString *k = [[NSString alloc] initWithCString:key encoding:NSUTF8StringEncoding];
    CGPDFStringRef contents = NULL;
    if (CGPDFObjectGetValue(object,kCGPDFObjectTypeString, &contents)) {
        NSString * tempStr = (NSString*)CFBridgingRelease(CGPDFStringCopyTextString(contents));
        NSLog(@" %@ 签名值:%@",k,tempStr);
    }
    
    CGPDFStreamRef objectStream = NULL; //如果 contents是个数流
    if (CGPDFObjectGetValue(object, kCGPDFObjectTypeStream, &objectStream)) {
        CGPDFDataFormat   format;
        CFDataRef dataRef = CGPDFStreamCopyData(objectStream,&format);
        NSData * data = (__bridge NSData*)dataRef;
        NSString * str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"🍎KEY:%@----->%@🍎",k,str);
        
    }
    
    CGPDFDictionaryRef dictionaryRef  = NULL; //如果 Dictionary是个数流
    if (CGPDFObjectGetValue(object, kCGPDFObjectTypeDictionary, &dictionaryRef)) {
        CGPDFDictionaryApplyFunction(dictionaryRef, haha, nil);
    }
}


+(void)addSignaturePDFData:(NSData*)pdfData{
    
    NSMutableData * outputPDFData = [[NSMutableData alloc]init];
    CGDataConsumerRef dataConsumer =CGDataConsumerCreateWithCFData((CFMutableDataRef)outputPDFData);
    
    CFMutableDictionaryRef attrDictionary=NULL;
    attrDictionary=CFDictionaryCreateMutable(NULL,0,&kCFTypeDictionaryKeyCallBacks,&kCFTypeDictionaryValueCallBacks);
    NSDictionary * perms = [NSDictionary dictionaryWithObjectsAndKeys:@"222",@"12", nil];
    NSDictionary * tree = [NSDictionary dictionaryWithObjectsAndKeys:@"nihao ",@"嘻嘻", nil];
    CFDictionaryAddValue(attrDictionary,@"Perms", (__bridge const void *)(perms));
    CFDictionaryAddValue(attrDictionary,@"tree", (__bridge const void *)(tree));
    NSDictionary * num = [NSDictionary dictionaryWithObjectsAndKeys:@"121221212 ",@"2121212121", nil];
    NSString * string = [SignPDFObject DataTOjsonString:num];
    
    
    
    CFDictionarySetValue(attrDictionary,kCGPDFContextSubject,(CFStringRef)string);
    CGContextRef pdfContext = CGPDFContextCreate(dataConsumer,NULL,attrDictionary);
    CFRelease(dataConsumer);
    CFRelease(attrDictionary);
    
    
    // Draw the old "pdfData" on pdfContext
    CGRect pageRect;
    CFDataRef myPDFData = (__bridge CFDataRef)pdfData;
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(myPDFData);
    CGPDFDocumentRef pdf = CGPDFDocumentCreateWithProvider(provider);
    CGDataProviderRelease(provider);
    
    CGPDFPageRef page = CGPDFDocumentGetPage(pdf,1);
    pageRect = CGPDFPageGetBoxRect(page,kCGPDFMediaBox);
    CGContextBeginPage(pdfContext,&pageRect);
    CGContextDrawPDFPage(pdfContext,page);
    
    
    CGPDFContextEndPage(pdfContext);
    CGPDFContextClose(pdfContext);
    CGContextRelease(pdfContext);
    
//     write new PDFData in "outPutPDF.pdf" file in document directory
    
    NSString * pdfFilePath = @"/Users/fanqie/Desktop/outPutPDF.pdf";
    [outputPDFData writeToFile:pdfFilePath atomically:YES];

}





+(NSString*)DataTOjsonString:(id)object
{
    NSString *jsonString = nil;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return jsonString;
}





+(void)drawPDF{
    
    //绘图上下文
    CGContextRef pdfContext;
    CFStringRef path;
    CFURLRef url;
    CFDataRef boxData = NULL;
    CFMutableDictionaryRef myDictionary = NULL;
    CFMutableDictionaryRef pageDictionary = NULL;
    //文件存放的路径
    NSString * filePath = @"/Users/fanqie/Desktop";
    
    const char * filename = [[NSString stringWithFormat:@"%@/newText.pdf",filePath] cStringUsingEncoding:kCFStringEncodingUTF8];
    path = CFStringCreateWithCString (NULL, filename,kCFStringEncodingUTF8);
    url = CFURLCreateWithFileSystemPath (NULL, path,kCFURLPOSIXPathStyle, 0);
    CFRelease (path);
    //文档信息字典
    myDictionary = CFDictionaryCreateMutable(NULL, 0,
                                             &kCFTypeDictionaryKeyCallBacks,
                                             &kCFTypeDictionaryValueCallBacks);
    //    CGPDFDocumentRef myDocument;
    //    CFStringRef path2 = CFStringCreateWithCString(NULL, [@"/Users/fanqie/Desktop/PDF文件/haha.pdf" UTF8String], kCFStringEncodingUTF8);
    //    CFURLRef url2 = CFURLCreateWithFileSystemPath (NULL, path2, kCFURLPOSIXPathStyle, 0);
    //    CFRelease (path2);
    //
    //    myDocument = CGPDFDocumentCreateWithURL(url2);
    
    
    //设置文档名称
    CFDictionarySetValue(myDictionary, @"Root",@"haha");
    //设置文档尺寸
    CGRect pageRect = CGRectMake(0, 0, 200, 200);
    //创建文档
    pdfContext = CGPDFContextCreateWithURL (url, &pageRect, myDictionary);
    CFRelease(myDictionary);
    CFRelease(url);
    //设置内容信息字典
    pageDictionary = CFDictionaryCreateMutable(NULL, 0,
                                               &kCFTypeDictionaryKeyCallBacks,
                                               &kCFTypeDictionaryValueCallBacks);
    boxData = CFDataCreate(NULL,(const UInt8 *)&pageRect, sizeof (CGRect));
    CFDictionarySetValue(pageDictionary, kCGPDFContextMediaBox, boxData);
    //开始渲染一页
    CGPDFContextBeginPage (pdfContext, pageDictionary);
    CGFloat  colors[4] = {1,0,0,1};
    CGContextSetFillColorSpace(pdfContext, CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB));
    CGContextSetFillColor(pdfContext, colors);
    CGContextFillRect(pdfContext, CGRectMake(0, 0, 100, 100));
    //结束此页的渲染
    CGPDFContextEndPage (pdfContext);
    //开始新一页内容的渲染
    CGPDFContextBeginPage (pdfContext, pageDictionary);
    CGContextSetFillColorSpace(pdfContext, CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB));
    CGContextSetFillColor(pdfContext, colors);
    CGContextFillRect(pdfContext, CGRectMake(0, 0, 100, 100));
    CGPDFContextEndPage (pdfContext);
    
    
    CGContextRelease (pdfContext);
    CFRelease(pageDictionary);
    CFRelease(boxData);
    
}






#pragma mark 新建一个PDF
+ (void)creatNewPDF
{
    
    
    // 1.创建media box
    CGFloat myPageWidth = 300;
    CGFloat myPageHeight = 300;
    CGRect mediaBox = CGRectMake (0, 0, myPageWidth, myPageHeight);
    
    
    // 2.设置pdf文档存储的路径
    //    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //    NSString *documentsDirectory = paths[0];
    NSString *filePath = @"/Users/fanqie/Desktop/lalala.pdf";
    // NSLog(@"%@", filePath);
    const char  * cfilePath = [filePath UTF8String];
    CFStringRef pathRef = CFStringCreateWithCString(NULL, cfilePath, kCFStringEncodingUTF8);
    
    
    // 3.设置当前pdf页面的属性
    CFStringRef myKeys[3];
    CFTypeRef myValues[3];
    myKeys[0] = kCGPDFContextMediaBox;
    myValues[0] = (CFTypeRef) CFDataCreate(NULL,(const UInt8 *)&mediaBox, sizeof (CGRect));
    myKeys[1] = kCGPDFContextTitle;
    myValues[1] = CFSTR("我的PDF");
    myKeys[2] = kCGPDFContextCreator;
    myValues[2] = CFSTR("Creator Name");
    CFDictionaryRef pageDictionary = CFDictionaryCreate(NULL, (const void **)myKeys, (const void **)myValues, 3,
                                                        &kCFTypeDictionaryKeyCallBacks, & kCFTypeDictionaryValueCallBacks);
    CFMutableDictionaryRef  myDictionary = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(myDictionary, kCGPDFContextTitle, CFSTR("MyPDF File"));
    CFDictionarySetValue(myDictionary, kCGPDFContextCreator, CFSTR("MyName"));
    //    CFDictionarySetValue(myDictionary, kCGPDFContextOwnerPassword, CFSTR("zhoumin"));
    //    CFDictionarySetValue(myDictionary, kCGPDFContextUserPassword, CFSTR("zhoumin"));
    //    pdfContext = CGPDFContextCreateWithURL (url, &pageRect,myDictionary);
    
    // 4.获取pdf绘图上下文
    CGContextRef myPDFContext = MyPDFContextCreate (&mediaBox, pathRef,myDictionary);
    
    
    // 5.开始描绘第一页页面
    CGPDFContextBeginPage(myPDFContext, pageDictionary);
    CGContextSetRGBFillColor (myPDFContext, 1, 0, 0, 1);
    CGContextFillRect (myPDFContext, CGRectMake (0, 0, 200, 100 ));
    CGContextSetRGBFillColor (myPDFContext, 0, 0, 1, .5);
    CGContextFillRect (myPDFContext, CGRectMake (0, 0, 100, 200 ));
    
    // 为一个矩形设置URL链接www.baidu.com
    CFURLRef baiduURL = CFURLCreateWithString(NULL, CFSTR("http://www.baidu.com"), NULL);
    CGContextSetRGBFillColor (myPDFContext, 0, 0, 0, 1);
    CGContextFillRect (myPDFContext, CGRectMake (200, 200, 100, 200 ));
    CGPDFContextSetURLForRect(myPDFContext, baiduURL, CGRectMake (200, 200, 100, 200 ));
    
    CGPDFContextEndPage(myPDFContext);
    
    
    
    // 6.开始描绘第二页页面
    // 注意要另外创建一个page dictionary
    CFDictionaryRef page2Dictionary = CFDictionaryCreate(NULL, (const void **) myKeys, (const void **) myValues, 3,
                                                         &kCFTypeDictionaryKeyCallBacks, & kCFTypeDictionaryValueCallBacks);
    CGPDFContextBeginPage(myPDFContext, page2Dictionary);
    
    // 在左下角画两个矩形
    CGContextSetRGBFillColor (myPDFContext, 1, 0, 0, 1);
    CGContextFillRect (myPDFContext, CGRectMake (0, 0, 200, 100 ));
    CGContextSetRGBFillColor (myPDFContext, 0, 0, 1, .5);
    CGContextFillRect (myPDFContext, CGRectMake (0, 0, 100, 200 ));
    
    // 在右下角写一段文字:"Hello world"
    CGContextSelectFont(myPDFContext, "Helvetica", 30, kCGEncodingMacRoman);
    CGContextSetTextDrawingMode (myPDFContext, kCGTextFill);
    CGContextSetRGBFillColor (myPDFContext, 0, 0, 0, 1);
    const char  *text = [@"Hello world" UTF8String];
    CGContextShowTextAtPoint (myPDFContext, 120, 120, text, strlen(text));
    
    
    
    
    
    /*
     // 为某一个矩形设置destination，这里destination的作用还不是很明白，保留
     CGPDFContextSetDestinationForRect(myPDFContext, CFSTR("Hello world"), CGRectMake(50.0, 300.0, 100.0, 100.0));
     CGContextSetRGBFillColor(myPDFContext, 1, 0, 1, 0.5);
     CGContextFillEllipseInRect(myPDFContext, CGRectMake(50.0, 300.0, 100.0, 100.0));
     */
    
    // 为右上角的矩形设置一段file URL链接，打开本地文件
    NSURL *furl = [NSURL fileURLWithPath:@"/Users/fanqie/Desktop/lalala.pdf"];
    CFURLRef fileURL = (__bridge CFURLRef)furl;
    CGContextSetRGBFillColor (myPDFContext, 0, 0, 0, 1);
    CGContextFillRect (myPDFContext, CGRectMake (200, 200, 100, 200 ));
    CGPDFContextSetURLForRect(myPDFContext, fileURL, CGRectMake (200, 200, 100, 200 ));
    
    CGPDFContextEndPage(myPDFContext);
    
    
    
    // 7.释放创建的对象
    CFRelease(page2Dictionary);
    CFRelease(pageDictionary);
    CFRelease(myValues[0]);
    CGContextRelease(myPDFContext);
}

/*
 * 获取pdf绘图上下文
 * inMediaBox指定pdf页面大小
 * path指定pdf文件保存的路径
 */
CGContextRef MyPDFContextCreate (const CGRect *inMediaBox, CFStringRef path,CFDictionaryRef dic)
{
    CGContextRef myOutContext = NULL;
    CFURLRef url;
    CGDataConsumerRef dataConsumer;
    
    url = CFURLCreateWithFileSystemPath (NULL, path, kCFURLPOSIXPathStyle, false);
    
    if (url != NULL)
    {
        dataConsumer = CGDataConsumerCreateWithURL(url);
        if (dataConsumer != NULL)
        {
            myOutContext = CGPDFContextCreate (dataConsumer, inMediaBox, dic);
            CGDataConsumerRelease (dataConsumer);
        }
        CFRelease(url);
    }
    return myOutContext;
}





@end
