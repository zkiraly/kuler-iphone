//
//  ThemeFeedReader.m
//  Kuler Experiment
//
//<kuler:themeItem>
//  <kuler:themeID>230218</kuler:themeID>
//  <kuler:themeTitle>cyr</kuler:themeTitle>
//  <kuler:themeImage>http://kuler.adobe.com/kuler/themeImages/theme_230218.png</kuler:themeImage>
//  <kuler:themeAuthor>
//    <kuler:authorID>124541</kuler:authorID>
//    <kuler:authorLabel>sidart2</kuler:authorLabel>
//  </kuler:themeAuthor>
//  <kuler:themeTags/>
//  <kuler:themeRating>0</kuler:themeRating>
//  <kuler:themeDownloadCount>1</kuler:themeDownloadCount>
//  <kuler:themeCreatedAt>20080802</kuler:themeCreatedAt>
//  <kuler:themeEditedAt>20080802</kuler:themeEditedAt>
//  <kuler:themeSwatches>
//    <kuler:swatch>
//      <kuler:swatchHexColor>353131</kuler:swatchHexColor>
//      <kuler:swatchColorMode>rgb</kuler:swatchColorMode>
//      <kuler:swatchChannel1>0.207843</kuler:swatchChannel1>
//      <kuler:swatchChannel2>0.192157</kuler:swatchChannel2>
//      <kuler:swatchChannel3>0.192157</kuler:swatchChannel3>
//      <kuler:swatchChannel4>0.0</kuler:swatchChannel4>
//      <kuler:swatchIndex>0</kuler:swatchIndex>
//    </kuler:swatch>
//    <kuler:swatch>... 4 more
//  </kuler:themeSwatches>
//</kuler:themeItem>

#import "ThemeFeedReader.h"


@implementation ThemeFeedReader

static NSUInteger parsedItemsCounter;

@synthesize currentObject = _currentObject;
@synthesize currentSwatch = _currentSwatch;
@synthesize contentOfCurrentProperty = _contentOfCurrentProperty;
@synthesize kulerElementNames = _kulerElementNames;

// Limit the number of parsed Themes to 50. Otherwise the application runs very slowly on the device.
#define MAX_THEMES 50

- (id)init
{
    [super init];

    self.kulerElementNames = [NSArray arrayWithObjects:
		@"link", 
		@"kuler:themeID", 
		@"kuler:themeTitle",
        @"kuler:authorID",
        @"kuler:authorLabel",
        @"kuler:themeDownloadCount",
        @"kuler:themeCreatedAt",
        @"kuler:themeEditedAt", nil];
	
    return self;
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    parsedItemsCounter = 0;
}

- (void)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error
{
    NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:URL];
    // Set self as the delegate of the parser so that it will receive the parser delegate methods callbacks.
    [parser setDelegate:self];
    // Depending on the XML document you're parsing, you may want to enable these features of NSXMLParser.
    [parser setShouldProcessNamespaces:YES];
    [parser setShouldReportNamespacePrefixes:NO];
    [parser setShouldResolveExternalEntities:NO];

    [parser parse];

    NSError *parseError = [parser parserError];
    if (parseError && error) {
        *error = parseError;
    }

    [parser release];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if (qName) {
        elementName = qName;
    }

    // If the number of parsed themes is greater than MAX_ELEMENTS, abort the parse.
    // Otherwise the application runs very slowly on the device.
    if (parsedItemsCounter >= MAX_THEMES) {
		NSLog(@"max themes reached.");
        [parser abortParsing];
    }
	
	NSLog(@"we found the element %@", elementName );
	
    if ([elementName isEqualToString:@"item"]) {

        parsedItemsCounter++;

        // An entry in the RSS feed represents an theme, so create an instance of it.
        self.currentObject = [[Theme alloc] init];
        // Add the new Theme object to the application's array of themes.
        [(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(addToThemeList:) withObject:self.currentObject waitUntilDone:YES];
		
    } else if ([elementName isEqualToString:@"kuler:swatch"]) {
        self.currentSwatch = [[Swatch alloc] init];
        // Add the new Swatch object to the Theme's array of swatches.
		[self.currentObject.swatches addObject: self.currentSwatch];

	} else if ( [self.kulerElementNames containsObject:elementName] ) {
        // The contents are collected in parser:foundCharacters:.
        self.contentOfCurrentProperty = [NSMutableString string];
    } else {
        // The element isn't one that we care about, so set the property that holds the
        // character content of the current element to nil. That way, in the parser:foundCharacters:
        // callback, the string that the parser reports will be ignored.
        self.contentOfCurrentProperty = nil;
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if (qName) {
        elementName = qName;
    }

	// TODO: Process swatches. Convert the string values to NSColors.
	
    if ([elementName isEqualToString:@"kuler:themeTitle"]) {
        self.currentObject.title = self.contentOfCurrentProperty;
		NSLog(@"we found the title element");

    } else if ([elementName isEqualToString:@"kuler:themeID"]) {
        self.currentObject.themeID = self.contentOfCurrentProperty;

    } else if ([elementName isEqualToString:@"kuler:authorID"]) {
        self.currentObject.authorId = self.contentOfCurrentProperty;

    } else if ([elementName isEqualToString:@"kuler:authorLabel"]) {
        self.currentObject.authorLabel = self.contentOfCurrentProperty;

    } else if ([elementName isEqualToString:@"kuler:themeDownloadCount"]) {
        self.currentObject.downloadCount = [self.contentOfCurrentProperty integerValue];

    } else if ([elementName isEqualToString:@"kuler:authorLabel"]) {
        self.currentObject.authorLabel = self.contentOfCurrentProperty;

    } else if ([elementName isEqualToString:@"kuler:themeEditedAt"]) {
        self.currentObject.edited = self.contentOfCurrentProperty;

    } else if ([elementName isEqualToString:@"kuler:swatchHexColor"]) {
        self.currentSwatch.hexColor = [self.contentOfCurrentProperty integerValue];
		
    } else if ([elementName isEqualToString:@"kuler:swatchColorMode"]) {
        self.currentSwatch.colorMode = self.contentOfCurrentProperty;

    } else if ([elementName isEqualToString:@"kuler:swatchChannel1"]) {
        self.currentSwatch.channel1 = [self.contentOfCurrentProperty floatValue];
		
    } else if ([elementName isEqualToString:@"kuler:swatchChannel2"]) {
        self.currentSwatch.channel2 = [self.contentOfCurrentProperty floatValue];
		
    } else if ([elementName isEqualToString:@"kuler:swatchChannel3"]) {
        self.currentSwatch.channel3 = [self.contentOfCurrentProperty floatValue];
		
    } else if ([elementName isEqualToString:@"kuler:swatchChannel4"]) {
        self.currentSwatch.channel4 = [self.contentOfCurrentProperty floatValue];
		
    } else if ([elementName isEqualToString:@"kuler:swatchIndex"]) {
        self.currentSwatch.displaySequence = [self.contentOfCurrentProperty integerValue];
		
    } else if ([elementName isEqualToString:@"link"]) {
        self.currentObject.link = [NSURL URLWithString: self.contentOfCurrentProperty];
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (self.contentOfCurrentProperty) {
        // If the current element is one whose content we care about, append 'string'
        // to the property that holds the content of the current element.
        [self.contentOfCurrentProperty appendString:string];
    }
}

@end
