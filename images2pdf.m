#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

int main (int argc, const char * argv[]) {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	if (argc == 2) {
		NSString *folderPath = [[NSString stringWithFormat:@"%s",argv[1]] stringByExpandingTildeInPath];
		BOOL isFolder;
		if ([[NSFileManager defaultManager] fileExistsAtPath:folderPath isDirectory:&isFolder]) {
			if (isFolder) {
				NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
				contents = [contents sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
					return [obj1 compare:obj2 options:NSNumericSearch];
				}];
				NSMutableData* outputData = [[NSMutableData alloc] init];
				CGDataConsumerRef dataConsumer = CGDataConsumerCreateWithCFData((CFMutableDataRef)outputData);
				CGContextRef pdfContext = CGPDFContextCreate(dataConsumer, NULL, NULL); 
				CFRelease(dataConsumer);
				
				for (NSString *path in contents) {
					NSString *itemPath = [folderPath stringByAppendingPathComponent:path];
					BOOL isFile;
					if ([[NSFileManager defaultManager] fileExistsAtPath:itemPath isDirectory:&isFile]) {
						if (!isFile) {
							if (UTTypeConformsTo((CFStringRef)[[NSWorkspace sharedWorkspace] typeOfFile:itemPath error:nil],kUTTypeImage)) {
								CGImageSourceRef pageSource = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:itemPath], NULL);
								if (pageSource != NULL) {
									CGImageRef pageImage = CGImageSourceCreateImageAtIndex(pageSource, 0, NULL);
									CGRect pageSize = CGRectMake(0, 0, CGImageGetWidth(pageImage), CGImageGetHeight(pageImage));
									CGContextBeginPage(pdfContext, &pageSize);
									CGContextDrawImage(pdfContext, pageSize, pageImage);
									CGImageRelease(pageImage);
									CFRelease(pageSource);
									CGContextEndPage(pdfContext);
								}
							}
						}
					}
				}
				CGPDFContextClose(pdfContext);
				CGContextRelease(pdfContext);
				
				NSString *writePath = [folderPath stringByDeletingLastPathComponent];
				NSString *documentPath = [writePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ - generated.pdf",[folderPath lastPathComponent]]];
				[outputData writeToFile:documentPath atomically:YES];
				[outputData release];
			}
		}
	} else {
		NSLog(@"Please supply only the path to the folder:");
		NSLog(@"./images2pdf /path/to/folder/of/images/");
	}
    [pool drain];
    return 0;
}