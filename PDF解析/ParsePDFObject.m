//
//  ParsePDFObject.m
//  PDF解析
//
//  Created by 番茄 on 2017/11/20.
//  Copyright © 2017年 番茄. All rights reserved.
//

#import "ParsePDFObject.h"
#import <UIKit/UIKit.h>

id selfMyParse;

@interface ParsePDFObject()
@property (nonatomic,strong) NSMutableData * contentData;
@property (nonatomic,assign) int page;
@end

@implementation ParsePDFObject

-(void)parsePDFAction:(NSString*)filePath complete:(void(^)(NSData *))block{
    //获取PDF摘要：每页获取  pages->dic->kids->content->stream
    CGPDFDocumentRef myDocument;
    CFStringRef path = CFStringCreateWithCString(NULL, [filePath UTF8String], kCFStringEncodingUTF8);
    CFURLRef url = CFURLCreateWithFileSystemPath (NULL, path, kCFURLPOSIXPathStyle, 0);
    NSLog(@"url:%@", url);
    CFRelease (path);
    
    myDocument = CGPDFDocumentCreateWithURL(url);
    CGPDFDictionaryRef dic = CGPDFDocumentGetCatalog(myDocument);
    CGPDFDictionaryRef ermsDic;
    if (CGPDFDictionaryGetDictionary(dic,"Perms", &ermsDic)) {
        
    }
    typedef struct CGPDFArray *CGPDFArrayRef;
    
    selfMyParse = self;
    CGPDFOperatorTableRef myTable;
    myTable = CGPDFOperatorTableCreate();
    // 标记的内容操作符代表一些可以解析的PDF操作符
    CGPDFOperatorTableSetCallback(myTable,"MP",&op_MP);
    CGPDFOperatorTableSetCallback(myTable,"DP",&op_DP);
    CGPDFOperatorTableSetCallback(myTable,"BMC",&op_BMC);
    CGPDFOperatorTableSetCallback(myTable,"BDC",&op_BDC);
    CGPDFOperatorTableSetCallback(myTable,"EMC",&op_EMC);
    
    int k;
    CGPDFPageRef myPage;
    CGPDFScannerRef myScanner;
    CGPDFContentStreamRef myContentStream;
    
    size_t  numOfPages=CGPDFDocumentGetNumberOfPages(myDocument);
    self.page = (int)numOfPages;
    //获取pages内，每页的content内容
    self.contentData = [NSMutableData data];
    dispatch_group_t group = dispatch_group_create();
    for(k=0;k<numOfPages;k++){
        dispatch_group_enter(group);
        myPage =CGPDFDocumentGetPage(myDocument,k + 1);
        
        CGPDFDictionaryRef pageDic = CGPDFPageGetDictionary(myPage);
        
        CGPDFDictionaryApplyFunction(pageDic, parseFunction, nil);
        
        myContentStream = CGPDFContentStreamCreateWithPage(myPage);
        
        myScanner = CGPDFScannerCreate(myContentStream,myTable,NULL);
        CGPDFScannerScan(myScanner);
        
        
        CGPDFPageRelease(myPage);
        CGPDFScannerRelease(myScanner);
        CGPDFContentStreamRelease(myContentStream);
        dispatch_group_leave(group);
    }
    CGPDFOperatorTableRelease(myTable);
    
    
    __weak typeof(self) weakself=self;
    dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if (block) {
            block(weakself.contentData);
        }
    });
    
}
-(Byte*)changeStringToByte:(NSArray*)muString{
    NSString * appendString = [[NSString alloc]init];
    for (NSString * string in muString) {
        appendString = [appendString stringByAppendingString:string];
    }
    NSData * strData = [appendString dataUsingEncoding: NSUTF8StringEncoding];
    Byte * strByte = (Byte *)[strData bytes];
    return strByte;
}


void parseFunction(const char *key, CGPDFObjectRef object, void *info)
{
    NSString *k = [[NSString alloc] initWithCString:key encoding:NSUTF8StringEncoding];
    NSLog(@"结构目录“%@",k);
    if([k isEqualToString:@"Contents"]){
        NSData  * content = [ParsePDFObject getType:object];
//      NSLog(@"PDF内容key:%@/n%s",k,[content bytes]);
        [[selfMyParse contentData] appendData:content];
    }
}



+(NSData * )getType:(CGPDFObjectRef)object{
    NSMutableData * contentData = [[NSMutableData alloc]init];;
    CGPDFObjectType type = CGPDFObjectGetType(object);
    switch(type){
        case kCGPDFObjectTypeString: {
            break;
        }
        case kCGPDFObjectTypeInteger: {
            break;
        }
        case kCGPDFObjectTypeBoolean: {
            break;
        }
        case kCGPDFObjectTypeArray : {
            
            CGPDFArrayRef objectArray = NULL;  //如果 contents是个数组
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeArray, &objectArray)) {
                NSData * content = [ParsePDFObject parsePDFArray:objectArray];
                [contentData appendData:content];
            }
            
            break;
        }
        case kCGPDFObjectTypeNull: {
            break;
        }
        case kCGPDFObjectTypeReal: {
            
            break;
        }
        case kCGPDFObjectTypeName: {
            
            break;
        }
        case kCGPDFObjectTypeDictionary: {
            
            break;
        }
        case kCGPDFObjectTypeStream: {
            CGPDFStreamRef objectStream = NULL; //如果 contents是个数流
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeStream, &objectStream)) {
                CGPDFDataFormat format;
                CFDataRef dataRef = CGPDFStreamCopyData(objectStream,&format);
                NSData * data = (__bridge NSData*)dataRef;
                [contentData appendData:data];
            }
            
            break;
        }
            break;
    }
    return contentData;
    
}

+(NSData *)parsePDFArray:(CGPDFArrayRef)arr{
    NSMutableData  * tempData = [[NSMutableData alloc] init];
    int count = (int)CGPDFArrayGetCount(arr);
    for(int i=0; i<count; i++){
        CGPDFObjectRef object;
        CGPDFArrayGetObject(arr, i, &object);
        CGPDFObjectType type = CGPDFObjectGetType(object);
        switch(type){
            case kCGPDFObjectTypeString: {
                CGPDFStringRef objectString;
                if (CGPDFObjectGetValue(object, kCGPDFObjectTypeString, &objectString)) {
                    NSString *tempStr = (NSString *)CFBridgingRelease(CGPDFStringCopyTextString(objectString));
                    [tempData appendBytes:[tempStr UTF8String] length:tempStr.length];
                    
                }
                break;
            }
            case kCGPDFObjectTypeInteger: {
                CGPDFInteger objectInteger;
                if (CGPDFObjectGetValue(object, kCGPDFObjectTypeInteger, &objectInteger)) {
                    //                    [temp addObject:[NSNumber numberWithInt:(int)objectInteger]];
                }
                break;
            }
            case kCGPDFObjectTypeBoolean: {
                CGPDFBoolean objectBool;
                if (CGPDFObjectGetValue(object, kCGPDFObjectTypeBoolean, &objectBool)) {
                    //                    [temp addObject:[NSNumber numberWithBool:objectBool]];
                }
                break;
            }
            case kCGPDFObjectTypeArray : {
                CGPDFArrayRef objectArray;
                if (CGPDFObjectGetValue(object, kCGPDFObjectTypeArray, &objectArray)) {
                    NSData * data = [ParsePDFObject parsePDFArray:objectArray];
                    [tempData appendData:data];
                }
                break;
            }
            case kCGPDFObjectTypeNull: {
                
                break;
            }
            case kCGPDFObjectTypeReal: {
                
                break;
            }
            case kCGPDFObjectTypeName: {
                
                break;
            }
            case kCGPDFObjectTypeDictionary: {
                
                break;
            }
            case kCGPDFObjectTypeStream: {
                CGPDFStreamRef objectStream = NULL; //如果 contents是个数流
                if (CGPDFObjectGetValue(object, kCGPDFObjectTypeStream, &objectStream)) {
                    CGPDFDataFormat format;
                    CFDataRef dataRef = CGPDFStreamCopyData(objectStream,&format);
                    NSData * data = (__bridge NSData*)dataRef;
        
                    [tempData appendData:data];
                    if (i < count - 1) {
                        NSData * space = [NSData dataWithBytes:"\n" length:1];
                        [tempData appendData:space];
                    }
                }
                break;
            }
            default:
                break;
        }
        
    }
    return tempData;
}




static void
op_MP (CGPDFScannerRef s, void *info)
{
    const char *name;
    
    if (!CGPDFScannerPopName(s, &name))
        return;
    
    printf("MP /%s\n", name);
}

static void
op_DP (CGPDFScannerRef s, void *info)
{
    const char *name;
    
    if (!CGPDFScannerPopName(s, &name))
        return;
    
    printf("MP /%s\n", name);
}

static void
op_BMC (CGPDFScannerRef s, void *info)
{
    const char *name;
    
    if (!CGPDFScannerPopName(s, &name))
        return;
    
    printf("MP /%s\n", name);
}

static void
op_BDC (CGPDFScannerRef s, void *info)
{
    const char *name;
    
    if (!CGPDFScannerPopName(s, &name))
        return;
    
    printf("MP /%s\n", name);
}

static void
op_EMC (CGPDFScannerRef s, void *info)
{
    const char *name;
    
    if (!CGPDFScannerPopName(s, &name))
        return;
    
    printf("MP /%s\n", name);
}

@end
