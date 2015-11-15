//
//  ToDoOADetailController.m
//  MonitorPlatform
//
//  Created by 张 仁松 on 12-2-10.
//  Copyright (c) 2012年 博安达. All rights reserved.
//

#import "ToDoOADetailController.h"
#import "MPAppDelegate.h"
#import "WebServiceHelper.h"
#import "AttachViewController.h"
#import "ZrsUtils.h"

extern MPAppDelegate *g_appDelegate;

@implementation ToDoOADetailController
@synthesize aItem,isDone;
@synthesize attachFileAry,formcontentNodeAry,formcontentValueAry;
@synthesize currentParsedData,canWriteAry,formalAry;
@synthesize formcontentPinyinNameAry,cellHeightAry;
@synthesize actionController,handleActionPopoverController;
@synthesize filesPopoverController,filesController,webHelper;


#pragma mark -
#pragma mark View lifecycle

-(void)handleAction:(id)sender
{
    if (handleActionPopoverController)
        [handleActionPopoverController dismissPopoverAnimated:YES];
   
    if (filesPopoverController)
        [filesPopoverController dismissPopoverAnimated:YES];
    
	NSMutableString *submitXML = [[NSMutableString alloc] initWithCapacity:2000];
	[submitXML appendFormat:@"<![CDATA[<?xml version=\"1.0\" encoding=\"GB2312\"?><root><公文><基本信息>"
	 "<公文标识>%@</公文标识><发送时间>%@</发送时间></基本信息><表单>",aItem.guid,aItem.generateDate];
	
	int arySize = [canWriteAry count]; 	
	int i;
	for(i=0;i < arySize;i++){
		NSString *str = [canWriteAry objectAtIndex:i];
		if ( str && ([str isEqualToString:@"true"] || [str isEqualToString:@"TRUE"])) {
			NSString *name = [formcontentPinyinNameAry objectAtIndex:i];
			NSString *tagValue = [formcontentValueAry objectAtIndex:i];
            NSMutableString *stripValue = [NSMutableString stringWithString:tagValue];
            if([stripValue length] > 0){//去掉空格
                [stripValue replaceOccurrencesOfString:@" " withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, stripValue.length)];
            }
            if([stripValue length] <=0){
                NSString *tagTitle = @"签批意见";
                if(i < [formcontentNodeAry count])
                    tagTitle = [formcontentNodeAry objectAtIndex:i];
                NSString *msg = [NSString stringWithFormat:@"%@不能为空。",tagTitle];
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:@"提示"
                                      message:msg
                                      delegate:self
                                      cancelButtonTitle:@"确定"
                                      otherButtonTitles:nil];
                [alert show];
                [alert release];
                    return;
                    
            }
			//将特殊字符< > " ' 替换为 《 》 “ ’
			tagValue = [tagValue stringByReplacingOccurrencesOfString:@"<" withString:@"《"];
			tagValue = [tagValue stringByReplacingOccurrencesOfString:@">" withString:@"》"];
			tagValue = [tagValue stringByReplacingOccurrencesOfString:@"\"" withString:@"”"];
			tagValue = [tagValue stringByReplacingOccurrencesOfString:@"'" withString:@"‘"];
			
			[submitXML appendFormat:@"<%@>%@</%@>",name,tagValue,name];
		}
	}
	[submitXML appendString:@"</表单><流程相关>"];
	
	
    if (!handleActionPopoverController)
    {
        ActionItemsController *tmpController3 = [[ActionItemsController alloc] init];
        tmpController3.contentSizeForViewInPopover = CGSizeMake(320, 400);
        tmpController3.delegate = self;
        self.actionController = tmpController3;
        actionController.baseInfoXML = submitXML;
        actionController.gwGUID = aItem.guid;
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:actionController];
        UIPopoverController *tmppopover3 = [[UIPopoverController alloc] initWithContentViewController:nav];
        
        self.handleActionPopoverController = tmppopover3;
        [nav release];
        [tmpController3 release];
        [tmppopover3 release];
    }
    [submitXML release];
//    [filesPopoverController dismissPopoverAnimated:YES];
	[self.handleActionPopoverController presentPopoverFromBarButtonItem:sender
											   permittedArrowDirections:UIPopoverArrowDirectionAny
                                                               animated:YES];
    
}

-(void)handleAttachFiles:(id)sender
{
    if (handleActionPopoverController)
        [handleActionPopoverController dismissPopoverAnimated:YES];
      
    if (filesPopoverController)
        [filesPopoverController dismissPopoverAnimated:YES];
    
	NSMutableArray *tmpAry = [[NSMutableArray alloc] initWithArray:attachFileAry];
	//if (bHaveMainText) {
	//	[tmpAry addObject:@"正文.doc"];
	//}
    
	filesController.fileAry = tmpAry;
	filesController.delegate = self;
	[tmpAry release];
	[self.filesPopoverController presentPopoverFromBarButtonItem:sender
                                        permittedArrowDirections:UIPopoverArrowDirectionAny
                                                        animated:YES];
}

- (void)openAttachFile:(AttachFileItem*)aFileItem{
 	[self.filesPopoverController dismissPopoverAnimated:YES];

    
    AttachViewController* attachViewController = [[AttachViewController alloc] 
                                                  initWithTitle:aFileItem.fileName
                                                  andGUID:aFileItem.fileID
                                                  isTif:aFileItem.isTif ];
    attachViewController.isJPG = aFileItem.isJPG;
    [self.navigationController pushViewController:attachViewController animated:YES];
    [attachViewController release];	
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = @"公文详细信息";

	if (isDone)
    {
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"附件" style:UIBarButtonItemStyleBordered target:self action:@selector(handleAttachFiles:)] autorelease];
    }
    else
    {
        
        UIToolbar* tools = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 150, 44)];
        [tools setTintColor:[self.navigationController.navigationBar tintColor]];
        [tools setAlpha:[self.navigationController.navigationBar alpha]];
        NSMutableArray* buttons = [[NSMutableArray alloc] initWithCapacity:8];
        UIBarButtonItem *anotherButton0 = [[UIBarButtonItem alloc] initWithTitle:@"附件" style:UIBarButtonItemStyleBordered
                                                                          target:self action:@selector(handleAttachFiles:)];
        
        UIBarButtonItem *fixedButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                     target:self action:nil];
        fixedButton.width = 20.0f;
        UIBarButtonItem *anotherButton1 = [[UIBarButtonItem alloc] initWithTitle:@"流转" style:UIBarButtonItemStyleBordered
                                                                          target:self action:@selector(handleAction:)];
        [buttons addObject:anotherButton0];
        [anotherButton0 release];
        [buttons addObject:fixedButton];
        [fixedButton release];
        
        [buttons addObject:anotherButton1];
        [anotherButton1 release];
        
        [tools setItems:buttons animated:NO];
        [buttons release];
        UIBarButtonItem *myBtn = [[UIBarButtonItem alloc] initWithCustomView:tools];
        self.navigationItem.rightBarButtonItem = myBtn;
        
        [myBtn release];
        [tools release];
        /*
        UIBarButtonItem *attachButton = [[UIBarButtonItem alloc] initWithTitle:@"附件" style:UIBarButtonItemStyleBordered
                                                                          target:self action:@selector(handleAttachFiles:)];
        
        UIBarButtonItem *fixedButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                     target:self action:nil];
        fixedButton.width = 20.0f;
        
        UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithTitle:@"流转" style:UIBarButtonItemStyleBordered
                                                                          target:self action:@selector(handleAction:)];
        NSArray *rightButtons = [NSArray arrayWithObjects:actionButton,fixedButton,attachButton, nil];
        self.navigationItem.rightBarButtonItems = rightButtons;
        [attachButton release];
        [fixedButton release];
        [actionButton release];*/
	}
	
	attachFileAry  = [[NSMutableArray alloc] initWithCapacity:5];
	formcontentNodeAry = [[NSMutableArray alloc] initWithCapacity:25];
	formcontentValueAry = [[NSMutableArray alloc] initWithCapacity:25];
	canWriteAry = [[NSMutableArray alloc] initWithCapacity:25];
	formcontentPinyinNameAry =  [[NSMutableArray alloc] initWithCapacity:25];
	self.cellHeightAry = [NSMutableArray array];
	self.currentParsedData = [NSMutableString string];
	
	AttachmentFilesController *tmpController4 = [[AttachmentFilesController alloc] init];
	tmpController4.contentSizeForViewInPopover = CGSizeMake(320, 400);
	self.filesController = tmpController4;
	UINavigationController *nav2 = [[UINavigationController alloc] initWithRootViewController:filesController];
	UIPopoverController *tmppopover4 = [[UIPopoverController alloc] initWithContentViewController:nav2];	
	self.filesPopoverController = tmppopover4;
	[nav2 release];
	[tmpController4 release];
	[tmppopover4 release];
    self.formalAry = [NSArray arrayWithObjects:@"紧急程度",@"办文编号",@"来文单位",@"来文字号",
                               @"来文日期",@"办结日期",@"页数",@"标题",@"拟办意见",@"领导批示",@"办理结果",
                               @"备注",@"打印人",@"打印日期",nil];
    [self getDetail:aItem.guid];
}

-(void)viewWillDisappear:(BOOL)animated{
    if (handleActionPopoverController)
        [handleActionPopoverController dismissPopoverAnimated:YES];
    
    if (filesPopoverController)
        [filesPopoverController dismissPopoverAnimated:YES];
    
    if (webHelper) {
        [webHelper cancel];
    }
    [super viewWillDisappear:animated];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Override to allow orientations other than the default portrait orientation.
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	NSInteger row = [indexPath row];
    NSNumber *height = [cellHeightAry objectAtIndex:row];
    
    return [height floatValue];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [formcontentNodeAry count];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if(indexPath.row%2 == 0)
        cell.backgroundColor = LIGHT_BLUE_UICOLOR;
}


-(void)makeSubCell:(UITableViewCell *)aCell withTitle:(NSString *)title
          andValue:(NSString *)aValue 
          canWrite:(BOOL)bCanModified 
            height:(float)height
{
	UILabel* lblTitle = nil;
	UILabel* lblValue = nil;
	
	if (aCell.contentView != nil)
	{
		lblTitle = (UILabel *)[aCell.contentView viewWithTag:1];
		lblValue = (UILabel *)[aCell.contentView viewWithTag:2];
	}
	
    CGRect tRect1;
    CGRect tRect2;
    
    tRect1 = CGRectMake(20, 0, 150, height);
    tRect2 = CGRectMake(200, 0, 550, height);
    
	if (lblTitle == nil) {
        
		lblTitle = [[UILabel alloc] initWithFrame:tRect1]; //此处使用id定义任何控件对象
        lblValue = [[UILabel alloc] initWithFrame:tRect2];
        lblValue.backgroundColor = lblTitle.backgroundColor = [UIColor clearColor];
        
		lblValue.font = lblTitle.font = [UIFont fontWithName:@"Helvetica" size:19.0];
		lblTitle.textAlignment = UITextAlignmentRight;
		lblTitle.tag = 1;
		[aCell.contentView addSubview:lblTitle];
		[lblTitle release];
		[lblValue setTextColor:[UIColor grayColor]];
        lblValue.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        lblValue.numberOfLines = 0;
		lblValue.tag = 2;
		[aCell.contentView addSubview:lblValue];
		[lblValue release];
	}
	if (bCanModified) {
        if (isDone)
            [lblTitle setTextColor:[UIColor blackColor]];
        else
            [lblTitle setTextColor:[UIColor redColor]];
    }
    else {
        [lblTitle setTextColor:[UIColor blackColor]];
    }
	if (lblTitle != nil)	[lblTitle setText:[NSString stringWithFormat:@"%@:", title]];
	if (lblValue != nil)	[lblValue setText:aValue];
    
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	UITableViewCell* cell = nil;
    
    NSNumber *cellHeight = [cellHeightAry objectAtIndex:indexPath.row];
	

    
    NSString *cellIdentifier = nil;
    
    cellIdentifier = [NSString stringWithFormat:@"cellcustom_portrait_%.1f",[cellHeight floatValue]];
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
	
	NSString *str = [canWriteAry objectAtIndex:indexPath.row];
	BOOL bCanModified = NO;
	if ( str && ([str isEqualToString:@"true"] || [str isEqualToString:@"TRUE"])) {
		bCanModified =  YES;
	}
	else {
		bCanModified = NO;
	}
	
    NSString *cellTitle = [formcontentNodeAry objectAtIndex:indexPath.row];
    NSString *cellValue = [formcontentValueAry objectAtIndex:indexPath.row];

    [self makeSubCell:cell withTitle:cellTitle andValue:cellValue canWrite:bCanModified  height:[cellHeight floatValue]];
    	
	if ( bCanModified) {
        if (isDone)
        {
            cell.imageView.image =  [UIImage imageNamed:@"cannotwrite.png"];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else
        {
            cell.imageView.image =  [UIImage imageNamed:@"canwrite.png"];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        }
	}
	else {
		cell.imageView.image =  [UIImage imageNamed:@"cannotwrite.png"];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
    
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    if (isDone)
        return;
    
	NSString *str = [canWriteAry objectAtIndex:indexPath.row];
    NSString *name = [formcontentPinyinNameAry objectAtIndex:indexPath.row];
    
    if ([name isEqualToString:@"附件列表"]) {
        
        if (handleActionPopoverController)
            [handleActionPopoverController dismissPopoverAnimated:YES];
        
        if (filesPopoverController)
            [filesPopoverController dismissPopoverAnimated:YES];
        
        NSMutableArray *tmpAry = [[NSMutableArray alloc] initWithArray:attachFileAry];
        //if (bHaveMainText) {
        //	[tmpAry addObject:@"正文.doc"];
        //}
        filesController.fileAry = tmpAry;
        filesController.delegate = self;
        [tmpAry release];
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [self.filesPopoverController presentPopoverFromRect:cell.frame inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        return;

    }
    
	if ( str && ([str isEqualToString:@"true"] || [str isEqualToString:@"TRUE"])) {
		currentPopRow = indexPath.row;
        OpinionViewController *controller  = [[OpinionViewController alloc] 
                                              initWithNibName:@"OpinionViewController"
                                              bundle:nil];
        [controller setDelegate:self];
        controller.origOpinion = [formcontentValueAry objectAtIndex:indexPath.row];
        
        [self.navigationController pushViewController:controller animated:YES];
        [controller release];
			
	}	
    
}

//代理方法


- (void)returnModifiedWords:(NSString *)words{
	
	[formcontentValueAry replaceObjectAtIndex:currentPopRow withObject:words];
    
    CGFloat width = 550;
    
    CGFloat height = [ZrsUtils calculateTextHeight:words byFontSize:19 andWidth:width];
    [cellHeightAry replaceObjectAtIndex:currentPopRow withObject:[NSNumber numberWithFloat:height]];
    
	[(UITableView*) self.view reloadData];
}

//办理发送后调用
-(void)doneAndBack
{
	if (handleActionPopoverController != nil) {
        [handleActionPopoverController dismissPopoverAnimated:YES];
    }
	[self.navigationController popViewControllerAnimated:YES];
    
    //本步骤主要是发送消息叫返回列表之后刷新列表内容
    [[NSNotificationCenter defaultCenter] postNotificationName:@"doneBack" object:nil];
}

#pragma mark -
#pragma mark Memory management
- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
	[formalAry release];
	
	[attachFileAry release];
	[formcontentValueAry release];
	[formcontentNodeAry release];
	
	[canWriteAry release];

	[formcontentPinyinNameAry release];
	[filesPopoverController release];
	[filesController release];
	
    [super dealloc];
}

#pragma mark - View lifecycle
//GetIpadGWInfo 接口说明
//gwSign 对应guid
//isText 空 tag = 1表示详细信息
//isText = 1 tag=1 表示正文
//isText = 2 tag=1 表示附件

- (void)getDetail:(NSString*)guid
{	
    NSString *param = [WebServiceHelper createParametersWithKey:@"gwSign" 
                                                          value:guid,nil];
    NSString *URL = [NSString stringWithFormat:OA_URL,g_appDelegate.oaServiceIp];
    
    self.webHelper = [[[WebServiceHelper alloc] initWithUrl:URL
                                                                   method:@"GetBasicGWInfo" 
                                                                nameSpace:@"http://tempuri.org/"
                                                               parameters:param 
                                                                 delegate:self] autorelease];
	[webHelper runAndShowWaitingView:self.view];

    
		
}

-(void)processWebData:(NSData*)webData{
    //NSLog(@"date 2 %@",[NSDate date]);
	//NSLog(@"3 DONE. Received Bytes: %d", [webData length]);
	NSMutableString *theXML = [[NSMutableString alloc] initWithBytes: [webData bytes] length:[webData length] encoding:NSUTF8StringEncoding];
	[theXML replaceOccurrencesOfString:@"&lt;" withString:@"<" 
							   options:NSCaseInsensitiveSearch range:NSMakeRange(0, [theXML length])];
	[theXML replaceOccurrencesOfString:@"&gt;" withString:@">" 
							   options:NSCaseInsensitiveSearch range:NSMakeRange(0, [theXML length])];
	

	NSData *replacedWebData = [[[NSData alloc] initWithData:[theXML dataUsingEncoding:NSUTF8StringEncoding]] autorelease];
	//NSLog(@"%@",theXML);
	[theXML release];
	
    //清除Array
	[attachFileAry removeAllObjects];
	[formcontentNodeAry removeAllObjects];
	[formcontentValueAry removeAllObjects];
    
	nParserStatus = -1;
	nParserStatusFather = -1;

	NSXMLParser *xmlParser = [[[NSXMLParser alloc] initWithData: replacedWebData] autorelease];
	[xmlParser setDelegate: self];
	[xmlParser setShouldResolveExternalEntities: YES];
	[xmlParser parse];

}

-(void)processError:(NSError *)error{
    NSString *msg = @"请求数据失败。";
    
    UIAlertView *alert = [[UIAlertView alloc] 
                          initWithTitle:@"提示" 
                          message:msg 
                          delegate:self 
                          cancelButtonTitle:@"确定" 
                          otherButtonTitles:nil];
    [alert show];
    [alert release];
    return;
}


#define PARSER_Formcontent 1
#define PARSER_Text        3
#define PARSER_Attachments    4

#define PARSER_Attachments_Title    41
#define PARSER_Attachments_File     42



-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *) namespaceURI qualifiedName:(NSString *)qName
   attributes: (NSDictionary *)attributeDict
{
    
    
	if (nParserStatusFather == -1) {
		if( [elementName isEqualToString:@"表单"])
		{
			nParserStatusFather = PARSER_Formcontent;
		}
		else if( [elementName isEqualToString:@"Text"])
		{
			nParserStatusFather = PARSER_Text;
		}
		else if( [elementName isEqualToString:@"Attachments"])
		{			
			nParserStatusFather = PARSER_Attachments;
		}

		
	}
	else if (nParserStatusFather == PARSER_Formcontent) {
		NSString *valueWrite = [attributeDict objectForKey:@"canwrite"];
		if (valueWrite) {
			[canWriteAry addObject:valueWrite];
		}
		else {
			NSLog(@"no value %@,",elementName);
		}
		NSString *valueName = [attributeDict objectForKey:@"name"];
		if (valueName) {
			[formcontentPinyinNameAry addObject:valueName];
		}
		else {
			NSLog(@"no value %@,",elementName);
		}
		
	}
    else  if (nParserStatusFather == PARSER_Attachments) {
        if ([elementName isEqualToString:@"Attachment"]) {
            tmpFileItem = [[AttachFileItem alloc] init];
            tmpFileItem.isTif = YES;
            
        }
    }
	
    
}



-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if(nParserStatusFather >=0)
		[currentParsedData appendString:string];
    
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	
	if (nParserStatusFather == PARSER_Formcontent) {
		if( [elementName isEqualToString:@"表单"])
		{
			nParserStatusFather = -1;
		} 
		else{
			[formcontentNodeAry addObject:elementName];
            [currentParsedData replaceOccurrencesOfString:@"\n" withString:@"" 
                                       options:NSCaseInsensitiveSearch range:NSMakeRange(0, [currentParsedData length])];
			[formcontentValueAry addObject:[NSString stringWithString: currentParsedData]];
		}
        
	}
	else if(nParserStatusFather == PARSER_Attachments)
	{
		if( [elementName isEqualToString:@"Attachments"])
		{
			nParserStatusFather = -1;
		} 
		else{
            if ([elementName isEqualToString:@"Attachment"]) {
                [attachFileAry addObject:tmpFileItem]; 
                [tmpFileItem release];
                tmpFileItem = nil;
            }
            else if( tmpFileItem && [elementName isEqualToString:@"Title"]) {
                tmpFileItem.fileName =[NSString stringWithString: currentParsedData];
                NSRange range = [tmpFileItem.fileName rangeOfString:@"."];
                if (range.length>0) {
                    NSString *hzm = [tmpFileItem.fileName substringFromIndex:range.location];
                    if (![hzm isEqualToString:@".tif"])
                        tmpFileItem.isTif = NO;
                    if ([hzm isEqualToString:@".jpg"])
                        tmpFileItem.isJPG = YES;
                }
                else{
                    tmpFileItem.isTif = NO;
                }
               
            }
            else if( tmpFileItem && [elementName isEqualToString:@"ID"]) {
                tmpFileItem.fileID = [NSString stringWithString: currentParsedData];
            }
        }
			
	}
    else if(nParserStatusFather == PARSER_Text){
        
        if( [elementName isEqualToString:@"Text"])
		{
			nParserStatusFather = -1;
		} 
        if (![currentParsedData isEqualToString:@"0"]){
            AttachFileItem *tmpItem = [[AttachFileItem alloc] init];
            tmpItem.fileID = [NSString stringWithString: currentParsedData];
            tmpItem.isTif = NO;
            tmpItem.fileName = @"正文.doc";
            [attachFileAry addObject:tmpItem]; 
            [tmpItem release];
        }
        
    }
	
	[currentParsedData setString:@""];
    
}


- (void)parserDidStartDocument:(NSXMLParser *)parser{
	//NSLog(@"-------------------start--------------");
}

//按照公文格式排序
//紧急程度 办文编号 来文单位 来文字号 来文日期 办结日期
//页数 文件标题 拟办意见 领导批示 办理结果
// 备注 打印人 打印日期:
-(void)sortFormcontent
{
	int arySize = [formcontentNodeAry count];
	NSMutableArray* tmpFormcontentNodeAry = [[NSMutableArray alloc] initWithCapacity:arySize];
	NSMutableArray* tmpFormcontentValueAry = [[NSMutableArray alloc] initWithCapacity:arySize];
	NSMutableArray* tmpCanWriteAry = [[NSMutableArray alloc] initWithCapacity:arySize];
	NSMutableArray* tmpFormcontentPinyinNameAry = [[NSMutableArray alloc] initWithCapacity:arySize];
	
	for(NSString *object in formalAry){
		NSUInteger index = [formcontentNodeAry indexOfObject:object];
		if(index !=NSNotFound){
			[tmpFormcontentNodeAry addObject:object];
			[tmpFormcontentValueAry addObject:[formcontentValueAry objectAtIndex:index]];
			[tmpCanWriteAry addObject:[canWriteAry objectAtIndex:index]];
			[tmpFormcontentPinyinNameAry addObject:[formcontentPinyinNameAry objectAtIndex:index]];
			
			[formcontentValueAry removeObjectAtIndex:index];
			[canWriteAry removeObjectAtIndex:index];
			[formcontentPinyinNameAry removeObjectAtIndex:index];
			[formcontentNodeAry removeObjectAtIndex:index];
			
		}
        
	}
	
	[tmpFormcontentNodeAry addObjectsFromArray:formcontentNodeAry];
	[tmpFormcontentValueAry addObjectsFromArray:formcontentValueAry ];
	[tmpCanWriteAry addObjectsFromArray:canWriteAry ];
	[tmpFormcontentPinyinNameAry addObjectsFromArray:formcontentNodeAry];
		
	[self.formcontentNodeAry removeAllObjects];
	[self.canWriteAry removeAllObjects];
	[self.formcontentPinyinNameAry removeAllObjects];
	[self.formcontentValueAry removeAllObjects];
	[formcontentNodeAry addObjectsFromArray:tmpFormcontentNodeAry];
	[canWriteAry addObjectsFromArray:tmpCanWriteAry ];
	[formcontentPinyinNameAry addObjectsFromArray:tmpFormcontentPinyinNameAry ];
	[formcontentValueAry addObjectsFromArray:tmpFormcontentValueAry];
		
	[tmpFormcontentValueAry release];
	[tmpCanWriteAry release];
	[tmpFormcontentPinyinNameAry release];
	[tmpFormcontentNodeAry release];
    
}

- (void)parserDidEndDocument:(NSXMLParser *)parser{
	//NSLog(@"-------------------end--------------");
	[currentParsedData release];
	[self sortFormcontent];
    
    if ([cellHeightAry count] > 0)
        [cellHeightAry removeAllObjects];
    //计算cell高度
    int number = [formcontentValueAry count];
    
    CGFloat width = 760;           
    
    for (int i = 0 ; i<number ; i++)
    {
        NSString *value = [formcontentValueAry objectAtIndex:i];
        CGFloat height = [ZrsUtils calculateTextHeight:value byFontSize:19 andWidth:width];
        
        [cellHeightAry addObject:[NSNumber numberWithFloat:height]];
    }
    
	[self.tableView reloadData];
}

@end
