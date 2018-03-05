//
//  ParsePDFObject.h
//  PDF解析
//
//  Created by 番茄 on 2017/11/20.
//  Copyright © 2017年 番茄. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ParsePDFObject : NSObject

-(void)parsePDFAction:(NSString*)filePath complete:(void(^)(NSData *))block;

@end
