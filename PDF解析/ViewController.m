//
//  ViewController.m
//  PDF解析
//
//  Created by 番茄 on 2017/11/17.
//  Copyright © 2017年 番茄. All rights reserved.
//

#import "ViewController.h"
#import "ParsePDFObject.h"
id selfClass;

@interface ViewController ()
@property(nonatomic,strong) NSMutableDictionary * auxInfo;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    ParsePDFObject * pf = [[ParsePDFObject alloc]init];
    [pf parsePDFAction:@"/Users/fanqie/Desktop/加密文档.pdf" complete:^(NSData * byte) {
        NSLog(@"---------------------------------%@,%ld",[ViewController hexStringWithData:byte],byte.length);
        
    }];
    
}

+ (NSString *)hexStringWithData:(NSData *)data {
    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
    if (!dataBuffer) {
        return [NSString string];
    }
    
    NSUInteger          dataLength  = [data length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i) {
        [hexString appendFormat:@"%02x", (unsigned char)dataBuffer[i]];
    }
    return [NSString stringWithString:hexString];
}

-(void)jiexiPDF{
    //获取PDF摘要：每页获取  pages->dic->kids->content->stream
    
    CGPDFDocumentRef myDocument;
    CFStringRef path = CFStringCreateWithCString(NULL, [@"/Users/fanqie/Desktop/PDF文件/haha.pdf" UTF8String], kCFStringEncodingUTF8);
    NSLog(@"path:%@", path);
    CFURLRef url = CFURLCreateWithFileSystemPath (NULL, path, kCFURLPOSIXPathStyle, 0);
    NSLog(@"url:%@", url);
    CFRelease (path);
    
    myDocument = CGPDFDocumentCreateWithURL(url);
    CGPDFDictionaryRef dic = CGPDFDocumentGetCatalog(myDocument);
    CGPDFDictionaryRef ermsDic=NULL;
    if (CGPDFDictionaryGetDictionary(dic,"Perms", &ermsDic)) {
        CGPDFDictionaryRef DocMDP=NULL;
        if (CGPDFDictionaryGetDictionary(ermsDic,"DocMDP", &DocMDP)) {
            CGPDFDictionaryApplyFunction(DocMDP, myFunction, nil);
        }
       
    }
//    CGPDFDictionaryApplyFunction(dic, myFunction, nil);
    

    CFMutableDictionaryRef muDicREf = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, NULL, NULL);
    CFDictionaryAddValue(muDicREf, "Perms", CFSTR("xixi"));
    CFDictionaryRef perms = CFDictionaryCreateCopy(kCFAllocatorDefault, muDicREf);
//    CGContextRef  gf = cg
    
    typedef struct CGPDFArray *CGPDFArrayRef;
    
    CGPDFOperatorTableRef myTable;
    
    myTable = CGPDFOperatorTableCreate();
    
    CGPDFOperatorTableSetCallback(myTable,"MP",&op_MP);
    CGPDFOperatorTableSetCallback(myTable,"DP",&op_DP);
    CGPDFOperatorTableSetCallback(myTable,"BMC",&op_BMC);
    CGPDFOperatorTableSetCallback(myTable,"BDC",&op_BDC);
    CGPDFOperatorTableSetCallback(myTable,"EMC",&op_EMC);
    
    CGPDFDictionaryRef  redDIC = CGPDFDocumentGetInfo(myDocument);
    
   
    
    int k;
    CGPDFPageRef myPage;
    CGPDFScannerRef myScanner;
    CGPDFContentStreamRef myContentStream;
    
    
    size_t  numOfPages=CGPDFDocumentGetNumberOfPages(myDocument); // 1
    for(k=0;k<numOfPages;k++){
        myPage =CGPDFDocumentGetPage(myDocument,k + 1); // 2
        CGPDFDictionaryRef pageDic = CGPDFPageGetDictionary(myPage);
        CGPDFDictionaryApplyFunction(pageDic, myFunction, nil);
        
        
        myContentStream = CGPDFContentStreamCreateWithPage(myPage); // 3
        //        CGPDFStreamCopyData(myContentStream, <#CGPDFDataFormat * _Nullable format#>)
        myScanner = CGPDFScannerCreate(myContentStream,myTable,NULL); // 4
        CGPDFScannerScan(myScanner); // 5
        CGPDFPageRelease(myPage); // 6
        CGPDFScannerRelease(myScanner); // 7
        CGPDFContentStreamRelease(myContentStream); // 8
    }
    CGPDFOperatorTableRelease(myTable);
}

/// 删除沙盒里的文件



void myFunction(const char *key, CGPDFObjectRef object, void *info)
{
    NSString *k = [[NSString alloc] initWithCString:key encoding:NSUTF8StringEncoding];
    
    NSLog(@"------%@-----",k);
    if([k isEqualToString:@"Contents"]){
        CGPDFArrayRef objectArray;  //如果 contents是个数组
        if (CGPDFObjectGetValue(object, kCGPDFObjectTypeArray, &objectArray)) {
           
            CGPDFStringRef string = NULL;
            CGPDFArrayGetString(objectArray, 0, &string);
            NSString * tempStr = (NSString*)CFBridgingRelease(CGPDFStringCopyTextString(string));
            
            NSLog(@"%@-----%zu",tempStr,CGPDFArrayGetCount(objectArray));
        }
        
        
        CGPDFStreamRef objectStream = NULL; //如果 contents是个数流
        if (CGPDFObjectGetValue(object, kCGPDFObjectTypeStream, &objectStream)) {
            CGPDFDataFormat   format;
            
            CFDataRef dataRef = CGPDFStreamCopyData(objectStream,&format);
            NSData * data = (__bridge NSData*)dataRef;
            NSString * str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"🍎%@🍎",str);
            
//            if (CGPDFArrayGetStream(objectArray,1, &objectStream)){
//
//                // get the data if it exists
//                NSArray * aar= [selfClass copyPDFArray:objectArray];
//                NSLog(@"%@",aar);
//            }
            
        }
        
    }
}

-(void)getType:(CGPDFObjectRef)object{
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
            
            break;
        }
            break;
    }
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





- (void)extractPDFDictionary:(CGPDFDocumentRef)pdf{
    NSLog(@"extractingPDFDictionary");
    CGPDFDictionaryRef oldDict = CGPDFDocumentGetInfo(pdf);
    CGPDFDictionaryApplyFunction(oldDict, copyDictionaryValues, NULL);
}

void copyDictionaryValues (const char *key, CGPDFObjectRef object, void *info) {
    NSLog(@"key: %s", key);
    CGPDFObjectType type = CGPDFObjectGetType(object);
    switch (type) {
        case kCGPDFObjectTypeString: {
            CGPDFStringRef objectString;
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeString, &objectString)) {
                NSString *tempStr = (NSString*)CFBridgingRelease(CGPDFStringCopyTextString(objectString));
                [[selfClass auxInfo] setObject:tempStr forKey:[NSString stringWithCString:key encoding:NSUTF8StringEncoding]];
                NSLog(@"set string value  %@",tempStr);
            }
        }
        case kCGPDFObjectTypeInteger: {
            CGPDFInteger objectInteger;
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeInteger, &objectInteger)) {
                [[selfClass auxInfo] setObject:[NSNumber numberWithInt:(int)objectInteger]
                                        forKey:[NSString stringWithCString:key encoding:NSUTF8StringEncoding]];
                NSLog(@"set int value");
            }
        }
        case kCGPDFObjectTypeBoolean: {
            CGPDFBoolean objectBool;
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeBoolean, &objectBool)) {
                [[selfClass auxInfo] setObject:[NSNumber numberWithBool:objectBool]
                                        forKey:[NSString stringWithCString:key encoding:NSUTF8StringEncoding]];
                NSLog(@"set boolean value");
            }
        }
        case kCGPDFObjectTypeArray : {
            CGPDFArrayRef objectArray;
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeArray, &objectArray)) {
                NSArray *tempArr = [selfClass copyPDFArray:objectArray];
                [[selfClass auxInfo] setObject:tempArr
                                        forKey:[NSString stringWithCString:key encoding:NSUTF8StringEncoding]];
                
                NSLog(@"set array value");
            }
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
            
            break;
        }
    }
    
    NSLog(@"%@",[selfClass auxInfo]);
}

- (NSArray *)copyPDFArray:(CGPDFArrayRef)arr{
    int i = 0;
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    for(i=0; i<CGPDFArrayGetCount(arr); i++){
        CGPDFObjectRef object;
        CGPDFArrayGetObject(arr, i, &object);
        CGPDFObjectType type = CGPDFObjectGetType(object);
        switch(type){
            case kCGPDFObjectTypeString: {
                CGPDFStringRef objectString;
                if (CGPDFObjectGetValue(object, kCGPDFObjectTypeString, &objectString)) {
                    NSString *tempStr = (NSString *)CFBridgingRelease(CGPDFStringCopyTextString(objectString));
                    [temp addObject:tempStr];
                    
                }
            }
            case kCGPDFObjectTypeInteger: {
                CGPDFInteger objectInteger;
                if (CGPDFObjectGetValue(object, kCGPDFObjectTypeInteger, &objectInteger)) {
                    [temp addObject:[NSNumber numberWithInt:objectInteger]];
                }
            }
            case kCGPDFObjectTypeBoolean: {
                CGPDFBoolean objectBool;
                if (CGPDFObjectGetValue(object, kCGPDFObjectTypeBoolean, &objectBool)) {
                    [temp addObject:[NSNumber numberWithBool:objectBool]];
                }
            }
            case kCGPDFObjectTypeArray : {
                CGPDFArrayRef objectArray;
                if (CGPDFObjectGetValue(object, kCGPDFObjectTypeArray, &objectArray)) {
                    NSArray *tempArr = [selfClass copyPDFArray:objectArray];
                    [temp addObject:tempArr];
                    
                }
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
                
                break;
            }
        }
    }
    return temp;
}






- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
