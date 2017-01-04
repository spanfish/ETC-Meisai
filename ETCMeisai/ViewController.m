//
//  ViewController.m
//  ETCMeisai
//
//  Created by Xiangwei Wang on 11/2/16.
//  Copyright © 2016 Xiangwei Wang. All rights reserved.
//

#import "ViewController.h"
#import <AFNetworking/AFNetworking.h>
#import "HTMLNode.h"
#import "HTMLParser.h"
#import "ETCDetail.h"
#import "ETCDetailTableViewCell.h"
#import "MBProgressHUD.h"
#import "SearchViewController.h"
#import "HtmlUtil.h"

@interface ViewController () {
    
}
@property(nonatomic, strong) NSString *filePath;
@property(nonatomic, weak) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property(nonatomic, strong) NSMutableArray *detailArray;
@property(nonatomic, strong) NSString *meisaiTitle;
@property(nonatomic, assign) BOOL editing;
@property(nonatomic, strong) NSString* totalPaid;
@property(nonatomic, strong) NSMutableDictionary *checkDictionary;


@property(nonatomic, strong) NSMutableArray *targetMonthArray;
@property(nonatomic, strong) UIBarButtonItem *preMonthButton;//前个月
@property(nonatomic, strong) UIBarButtonItem *nextMonthButton;//下个月
@property(nonatomic, strong) UIBarButtonItem *searchButton;
@property(nonatomic, strong) UIBarButtonItem *searchCancelButton;
@property(nonatomic, strong) UIBarButtonItem *searchClearButton;
//@property(nonatomic, strong) UIBarButtonItem *selectAllButton;
//@property(nonatomic, strong) UIBarButtonItem *deselectAllButton;
@property(nonatomic, strong) UIBarButtonItem *fixedSpaceButton;
@property(nonatomic, strong) UIBarButtonItem *flexibleSpaceButton;
@property(nonatomic, strong) UIBarButtonItem *selectButton;
@property(nonatomic, strong) UIBarButtonItem *selectCancelButton;
@property(nonatomic, strong) UIBarButtonItem *certifyPdfButton;//证明书
@property(nonatomic, strong) UIBarButtonItem *detailPdfButton;//利用明细
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _editing = NO;
    
    self.preMonthButton = [[UIBarButtonItem alloc] initWithTitle:@"前月"
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(loadPrevPage:)];
    
    self.nextMonthButton = [[UIBarButtonItem alloc] initWithTitle:@"次月"
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(loadNextPage:)];
    
//    self.selectAllButton = [[UIBarButtonItem alloc] initWithTitle:@"全選択"
//                                                            style:UIBarButtonItemStylePlain
//                                                           target:self
//                                                           action:@selector(selectAll:)];
    
//    self.deselectAllButton = [[UIBarButtonItem alloc] initWithTitle:@"全解除"
//                                                            style:UIBarButtonItemStylePlain
//                                                           target:self
//                                                           action:@selector(deselectAll:)];
    
    self.searchButton = [[UIBarButtonItem alloc] initWithTitle:@"検索"
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(searchTouched:)];
    
    self.selectButton = [[UIBarButtonItem alloc] initWithTitle:@"選択"
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(selectTouched:)];

    self.selectCancelButton = [[UIBarButtonItem alloc] initWithTitle:@"キャンセル"
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(selectCancelTouched:)];
    
    self.searchClearButton = [[UIBarButtonItem alloc] initWithTitle:@"利用明細へ"
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(showDefaultPage:)];
    
    self.certifyPdfButton = [[UIBarButtonItem alloc] initWithTitle:@"証明書"
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(certifyPdf:)];
    
    self.detailPdfButton = [[UIBarButtonItem alloc] initWithTitle:@"明細書"
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(detailPdf:)];
    
    self.fixedSpaceButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                          target:nil
                                                                                action:nil];
    self.fixedSpaceButton.width = 20;
    

    self.flexibleSpaceButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                           target:nil
                                                                           action:nil];

    [self.toolbar setItems:@[]];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    self.navigationItem.rightBarButtonItem = self.searchClearButton;
    
    [self showDetailPage];
}

-(void) showDefaultPage:(id) sender
{
    self.editing = NO;
    self.checkDictionary = nil;
    [self.tableView reloadData];

    NSError *error = nil;
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:appDelegate.htmlString error:&error];
    if(error)
    {
#if DEBUG
        NSLog(@"error:%@", error);
#endif
        [self handleError];
        return;
    }
    
    if(appDelegate.demo)
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"201610" ofType:@"html"];
        appDelegate.htmlString = [NSString stringWithContentsOfFile:path
                                                           encoding:NSUTF8StringEncoding
                                                              error:nil];
        [self showDetailPage];
        return;
    }
    
    [MBProgressHUD showHUDAddedTo:appDelegate.window animated:YES];
    
    HTMLNode *body = [parser body];
    for(HTMLNode * node in [body findChildTags:@"a"])
    {
        NSString *onclick = [node getAttributeNamed:@"onclick"];
        NSRange r2 = [onclick rangeOfString:@"funccode=1013000000&nextfunc=1013000000"];
        if(r2.location != NSNotFound)
        {
            NSRange r1 = [onclick rangeOfString:@"/etc/R;jsessionid="];
            if(r1.location != NSNotFound)
            {
                NSString *url = [onclick substringWithRange:NSMakeRange(r1.location, r2.location + [@"funccode=1013000000&nextfunc=1013000000" length] - r1.location)];
                
                [[HtmlUtil sharedInstance] submit:url
                                             page:appDelegate.htmlString
                                       parameters:nil
                                          success:^(NSString *html) {
                                              [MBProgressHUD hideHUDForView:appDelegate.window animated:YES];
                                              appDelegate.htmlString = html;
                                              if([self sessionTimeout])
                                              {
                                                  [self performSegueWithIdentifier:@"Login" sender:self];
                                                  return;
                                              }
                                              [self showDetailPage];
                                          } failure:^(NSError *error) {
                                              [MBProgressHUD hideHUDForView:appDelegate.window animated:YES];
                                              [self handleError];
                                          }];
                return;
            }
        }
    }
    [MBProgressHUD hideHUDForView:appDelegate.window animated:YES];
    [self handleError];
}
//前月
-(void)loadPrevPage:(id)sender
{
    if([self.targetMonthArray count] > 0)
    {
        for(int i = 0; i < [self.targetMonthArray count]; i++)
        {
            NSString *url = [self.targetMonthArray objectAtIndex:i];
            if([url length] == 0 && i > 0)
            {
                [self loadDetailPage:[self.targetMonthArray objectAtIndex:i - 1]];
                break;
            }
        }
    }
}
//下月
-(void)loadNextPage:(id)sender
{
    if([self.targetMonthArray count] > 0)
    {
        for(int i = 0; i < [self.targetMonthArray count]; i++)
        {
            NSString *url = [self.targetMonthArray objectAtIndex:i];
            if([url length] == 0 && i < [self.targetMonthArray count] - 1)
            {
                [self loadDetailPage:[self.targetMonthArray objectAtIndex:i + 1]];
                break;
            }
        }
    }
}
//本月数据解析
-(void) loadDetailPage:(NSString *) pageURL
{
    self.editing = NO;
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;

    if(appDelegate.demo)
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:[pageURL substringWithRange:NSMakeRange([pageURL length] - 6, 6)] ofType:@"html"];
        if(![[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            self.detailArray = nil;
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 60)];
            label.text = @"明細がありません　";
            label.font = [UIFont systemFontOfSize:15];
            label.textAlignment = NSTextAlignmentCenter;
            self.tableView.tableHeaderView = label;
            [self.tableView reloadData];

            return;
        }
        self.tableView.tableHeaderView = nil;
        
        appDelegate.htmlString = [[NSString alloc] initWithContentsOfFile:path
                                                                 encoding:NSUTF8StringEncoding
                                                                    error:nil];
        [self showDetailPage];
        return;
    }
    
    [MBProgressHUD showHUDAddedTo:appDelegate.window animated:YES];
    [[HtmlUtil sharedInstance] submit:pageURL
                                 page:appDelegate.htmlString
                           parameters:nil
                              success:^(NSString *html) {
                                  [MBProgressHUD hideHUDForView:appDelegate.window animated:YES];
                                  
                                  appDelegate.htmlString = html;
                                  [self showDetailPage];
                                  
                              } failure:^(NSError *error) {
                                  [MBProgressHUD hideHUDForView:appDelegate.window animated:YES];
                                  
                                  [self handleError];
                              }];

}

-(void) handleError
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    NSError *error = nil;
    NSString *msg = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:appDelegate.htmlString error:&error];
    if(error)
    {
        msg = @"エラーが発生しました。最初からやり直してください";
    }
    else
    {
        HTMLNode *bodyNode = [parser body];
        for(HTMLNode *errorTable in [bodyNode findChildrenWithAttribute:@"class"
                                                           matchingName:@"error"
                                                           allowPartial:NO])
        {
            if([[errorTable.tagName lowercaseString] isEqualToString:@"table"])
            {
                msg = @"エラーが発生しました。最初からやり直してください";
                break;
            }
        }
    }
    
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"エラー"
                                                                   message:msg == nil ? @"エラーが発生しました。最初からやり直してください" : msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performSegueWithIdentifier:@"Login" sender:self];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

-(BOOL) sessionTimeout
{
    NSError *error = nil;
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:appDelegate.htmlString error:&error];
    if(error)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"エラー"
                                                                       message:@"エラーが発生しました。最初からやり直してください"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self performSegueWithIdentifier:@"Login" sender:self];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
        return YES;
    }
    HTMLNode *bodyNode = [parser body];
    HTMLNode *loginButton = [bodyNode findChildWithAttribute:@"name" matchingName:@"risLoginId" allowPartial:NO];
    if(loginButton)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"エラー"
                                                                       message:@"タイムアウトしました。ログインしてください"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self performSegueWithIdentifier:@"Login" sender:self];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
        return YES;
    }
    return NO;
}

-(BOOL) sessionTimeout:(NSString *) string
{
    NSError *error = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:string error:&error];
    if(error)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"エラー"
                                                                       message:@"エラーが発生しました。最初からやり直してください"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self performSegueWithIdentifier:@"Login" sender:self];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
        return YES;
    }
    HTMLNode *bodyNode = [parser body];
    HTMLNode *loginButton = [bodyNode findChildWithAttribute:@"name" matchingName:@"risLoginId" allowPartial:NO];
    if(loginButton)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"エラー"
                                                                       message:@"タイムアウトしました。ログインしてください"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"確定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self performSegueWithIdentifier:@"Login" sender:self];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
        return YES;
    }
    return NO;
}

-(void) showDetailPage
{
    self.totalPaid = nil;
    if([self sessionTimeout])
    {
        return;
    }
    NSError *error = nil;
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:appDelegate.htmlString error:&error];
    if(error)
    {
        [self handleError];
        return;
    }

    HTMLNode *bodyNode = [parser body];
    
    self.detailArray = [NSMutableArray array];
    self.targetMonthArray = [NSMutableArray array];
    //明細タイトル
    HTMLNode *meisaiinfo = [bodyNode findChildOfClass:@"meisaiinfo"];
    HTMLNode *titleNode =  [meisaiinfo findChildWithAttribute:@"class" matchingName:@"title" allowPartial:NO];
    if(titleNode)
    {
        self.meisaiTitle = titleNode.allContents;
    }
    else
    {
        self.meisaiTitle = @"2016年11月分";
    }

    NSInteger currentYear = [[self.meisaiTitle substringWithRange:NSMakeRange(0, 4)] integerValue];
    NSInteger currentMonth = [[self.meisaiTitle substringWithRange:NSMakeRange(5, 2)] integerValue];
    
    //月
    BOOL found = NO;
    for(HTMLNode *buttonNode in [bodyNode findChildTags:@"button"])
    {
        if([[buttonNode getAttributeNamed:@"class"] isEqualToString:@"mlink_no"])
        {
            NSString *str = [buttonNode getAttributeNamed:@"onclick"];
            NSRange i = [str rangeOfString:@"/etc/R;jsessionid="];
            NSRange j = [str rangeOfString:@"taisyoYM="];
            NSString *buttonUrl = [str substringWithRange:NSMakeRange(i.location, j.location + [@"taisyoYM=201610" length] - i.location)];
            if(![self.targetMonthArray containsObject:buttonUrl])
            {
                NSInteger year = [[buttonUrl substringWithRange:NSMakeRange([buttonUrl length] - 6, 4)] integerValue];
                NSInteger month = [[buttonUrl substringWithRange:NSMakeRange([buttonUrl length] - 2, 2)] integerValue];
                NSAssert(buttonUrl != nil, @"url is nil");
                [self.targetMonthArray addObject:buttonUrl];
                if((year == currentYear && month + 1 == currentMonth) || (month == 12 && currentMonth==1 && currentYear-1==year))
                {
                    [self.targetMonthArray addObject:@""];
                    found = YES;
                }
                
            }
        }
    }
    if(!found)
    {
        [self.targetMonthArray insertObject:@"" atIndex:0];
    }
#if DEBUG
    NSLog(@"targetMonthArray:%@", self.targetMonthArray);
#endif

    //hakkoMeisai
    NSArray *checkArray = [bodyNode findChildrenWithAttribute:@"name"
                                                 matchingName:@"hakkoMeisai"
                                                 allowPartial:NO];
    for(HTMLNode *checkNode in checkArray)
    {
        HTMLNode *tableRow = [[checkNode parent] parent];
        NSArray *detailArray = [tableRow findChildrenWithAttribute:@"class"
                                                      matchingName:@"meisaivalue"
                                                      allowPartial:TRUE];
        ETCDetail *detail = [[ETCDetail alloc] init];
        detail.checkValue = [checkNode getAttributeNamed:@"value"];
        NSLog(@"detail.checkValue:%@", detail.checkValue);
        for(NSInteger i = 0; i < [detailArray count]; i++)
        {
            HTMLNode *span = [detailArray objectAtIndex:i];
            if(i == 0)
            {
                //利用年月日
                //時分
                //利用ＩＣ(自)
                NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:3];
                for(HTMLNode *children in span.children)
                {
#if DEBUG
                    NSLog(@"contents:%@", children.allContents);
#endif
                    if(children.allContents.length > 0)
                    {
                        [tmp addObject:children.allContents];
                    }
                }
                detail.useFromArray = tmp;
            }
            else if(i == 1)
            {
                //利用年月日
                //時分
                //利用ＩＣ(至)
                NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:3];
                for(HTMLNode *children in span.children)
                {
#if DEBUG
                    NSLog(@"contents:%@", children.allContents);
#endif
                    if(children.allContents.length > 0)
                    {
                        [tmp addObject:children.allContents];
                    }
                }
                detail.useToArray = tmp;
            }
            else if(i == 2)
            {
                //(割引前料金)
                //(ＥＴＣ割引額)
                //通行料金
                NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:3];
                for(HTMLNode *children in span.children)
                {
#if DEBUG
                    NSLog(@"contents:%@", children.allContents);
#endif
                    if(children.allContents.length > 0)
                    {
                        [tmp addObject:children.allContents];
                    }
                }
                detail.tollArray = tmp;
            }
            else if(i == 3)
            {
                //還元額適用料金
                //前払金適用料金
                //後納料金
                NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:3];
                for(HTMLNode *children in span.children)
                {
#if DEBUG
                    NSLog(@"contents:%@", children.allContents);
#endif
                    if(children.allContents.length > 0)
                    {
                        [tmp addObject:children.allContents];
                    }
                }
                detail.payArray = tmp;
            }
            else if(i == 4)
            {
                //車種
                //車両番号
                //ＥＴＣカード番号
                NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:3];
                for(HTMLNode *children in span.children)
                {
#if DEBUG
                    NSLog(@"contents:%@", children.allContents);
#endif
                    if(children.allContents.length > 0)
                    {
                        [tmp addObject:children.allContents];
                    }
                }
                detail.carInfoArray = tmp;
            }
            else if(i == 5)
            {
                //備考
                NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:3];
                for(HTMLNode *children in span.children)
                {
#if DEBUG
                    NSLog(@"contents:%@", children.allContents);
#endif
                    if(children.allContents.length > 0)
                    {
                        [tmp addObject:children.allContents];
                    }
                }
                detail.commentArray = tmp;
            }
        }//end for
        [self.detailArray addObject:detail];
    }//end checkbox for

    [self.tableView reloadData];
    self.title = self.meisaiTitle;

    if(self.detailArray.count == 0)
    {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 60)];
        label.text = @"明細がありません　";
        label.font = [UIFont systemFontOfSize:15];
        label.textAlignment = NSTextAlignmentCenter;
        self.tableView.tableHeaderView = label;
    }
    else
    {
        self.tableView.tableHeaderView = nil;
    }

    NSArray *spanArray = [bodyNode findChildrenWithAttribute:@"class" matchingName:@"meisaicaption" allowPartial:YES];
    HTMLNode *totalPaidNode = nil;
    for(HTMLNode *spanNode in spanArray) {
        if([spanNode.contents isEqualToString:@"支払い総額"])
        {
#if DEBUG
            NSLog(@"%@", spanNode.parent.parent.rawContents);
#endif
            HTMLNode *trNode = spanNode.parent.parent;
            if(trNode && trNode.children.count > 1) {
                totalPaidNode = [trNode findChildWithAttribute:@"class" matchingName:@"meisaivalue" allowPartial:YES];
#if DEBUG
                NSLog(@"tdNode:%@", totalPaidNode.rawContents);
#endif
            }
            break;
        }
    }
    if(totalPaidNode) {
        self.totalPaid = totalPaidNode.contents;
        self.totalPaid = [self.totalPaid stringByReplacingOccurrencesOfString:@"\\" withString:@"¥"];
    }
    
    //検索条件を変更する
    self.searchButton.enabled = NO;
    for(HTMLNode *linkNode in [meisaiinfo findChildTags:@"a"])
    {
        if([linkNode.contents isEqualToString:@"検索条件を変更する"])
        {
            self.searchButton.enabled = YES;
            break;
        }
    }
    
    [self updateBarButtons];
}

-(void) updateBarButtons
{
    int current = -1;
    for(int i = 0; i < [self.targetMonthArray count]; i++)
    {
        NSString *url = [self.targetMonthArray objectAtIndex:i];
        if([url length] == 0)
        {
            current = i;
        }
    }
    if(current == [self.targetMonthArray count] - 1)
    {
        self.nextMonthButton.enabled = NO;
    }
    else
    {
        self.nextMonthButton.enabled = YES;
    }
    if(current == 0)
    {
        self.preMonthButton.enabled = NO;
    }
    else
    {
        self.preMonthButton.enabled = YES;
    }
//    self.selectAllButton.enabled = [self.detailArray count] > 0;
    
    if([self.detailArray count] > 0)
    {
        [self.toolbar setItems:@[self.selectButton,
                                 //self.fixedSpaceButton,
                                 //self.searchClearButton,
                                 //self.fixedSpaceButton,
                                 //self.selectAllButton,
                                 self.flexibleSpaceButton,
                                 self.preMonthButton,
                                 self.fixedSpaceButton,
                                 self.nextMonthButton]];
    }
    else
    {
        [self.toolbar setItems:@[//self.selectButton,
                                 //self.fixedSpaceButton,
                                 //self.searchClearButton,
                                 //self.fixedSpaceButton,
                                 //self.selectAllButton,
                                 self.flexibleSpaceButton,
                                 self.preMonthButton,
                                 self.fixedSpaceButton,
                                 self.nextMonthButton]];
    }
    
    if(self.searchButton.enabled)
    {
        self.navigationItem.leftBarButtonItem = self.searchButton;
    }
    else
    {
        self.navigationItem.leftBarButtonItem = nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableView
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.detailArray count] > 0 ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section== 0) {
        return [self.detailArray count];
    } else {
        return [self.detailArray count] > 0 ? 1 : 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 1) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Summary"];
        cell.textLabel.text = @"支払い総額";
        cell.detailTextLabel.text = self.totalPaid;
        return cell;
    }
    
    ETCDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Detail"];
    if(self.editing)
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        if([self.checkDictionary objectForKey:[NSNumber numberWithInteger:indexPath.row]])
        {
            imageView.image = [UIImage imageNamed:@"check"];
        }
        else
        {
            imageView.image = [UIImage imageNamed:@"check-gray"];
        }
        cell.accessoryView = imageView;
    }
    else
    {
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    ETCDetail *detail = [self.detailArray objectAtIndex:indexPath.row];
    cell.fromDateTimeLabel.text = [NSString stringWithFormat:@"%@ %@",
                                   [detail.useFromArray count] > 0 ? [detail.useFromArray firstObject] : @"",
                                   [detail.useFromArray count] > 1 ? [detail.useFromArray objectAtIndex:1] : @""];
    cell.fromICLabel.text = [detail.useFromArray count] > 2 ? [detail.useFromArray lastObject] : @"";
    
    cell.toDateTimeLabel.text = [NSString stringWithFormat:@"%@ %@",
                                   [detail.useToArray count] > 0 ? [detail.useToArray firstObject] : @"",
                                   [detail.useToArray count] > 1 ? [detail.useToArray objectAtIndex:1] : @""];
    cell.toICLabel.text = [detail.useToArray count] > 2 ? [detail.useToArray lastObject] : @"";
    
    cell.tollLabel.text = [detail.tollArray count] > 0 ? [NSString stringWithFormat:@"¥%@", [detail.tollArray lastObject]] : @"N/A";
    NSMutableString *comments = [NSMutableString string];
    for(NSString *comment in detail.commentArray)
    {
        if([comments length] > 0)
        {
            [comments appendString:@"\n"];
        }
        [comments appendString:comment];
    }
    cell.commentLabel.text = comments;
    
    if([detail.carInfoArray count] == 3)
    {
        NSString *cardNo = [detail.carInfoArray objectAtIndex:2];
        if([cardNo length] > 8)
        {
            cardNo = [cardNo substringFromIndex: [cardNo length] - 8];
        }
        cell.cardNumberLabel.text = [NSString stringWithFormat:@"カ)%@", cardNo];
    }
    else
    {
        cell.cardNumberLabel.text = @"カ) N/A";
    }
    if([detail.tollArray count] == 3)
    {
        cell.discountLabel.text = [NSString stringWithFormat:@"割)%@", [detail.tollArray objectAtIndex:1]];
    }
    else
    {
        cell.discountLabel.text = @"割) 0";
    }
    return cell;
}

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 1) {
        return;
    }
    if(indexPath.row % 2 == 1)
    {
        cell.backgroundColor = [UIColor groupTableViewBackgroundColor];
    }
    else
    {
        cell.backgroundColor = [UIColor whiteColor];
    }
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if(indexPath.section == 1) {
        return;
    }
    if(!self.editing)
    {
        return;
    }
    if([self.checkDictionary objectForKey:[NSNumber numberWithInteger:indexPath.row]])
    {
        [self.checkDictionary removeObjectForKey: [NSNumber numberWithInteger:indexPath.row]];
    }
    else
    {
        [self.checkDictionary setObject:[NSNumber numberWithInteger:indexPath.row] forKey:[NSNumber numberWithInteger:indexPath.row]];
    }
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    if([self.checkDictionary count] > 0)
    {
        [self.toolbar setItems:@[self.selectCancelButton,
                                 //self.fixedSpaceButton,
                                 //self.selectAllButton,
                                 //self.fixedSpaceButton,
                                 //self.deselectAllButton,
                                 self.flexibleSpaceButton,
                                 self.certifyPdfButton,
                                 self.fixedSpaceButton,
                                 self.detailPdfButton
                                 ]];
    }
    else
    {
        [self.toolbar setItems:@[self.selectCancelButton,
                                 //self.fixedSpaceButton,
                                 //self.selectAllButton,
                                 //self.fixedSpaceButton,
                                 //self.deselectAllButton,
                                 self.flexibleSpaceButton,
                                 //self.certifyPdfButton,
                                 //self.fixedSpaceButton,
                                 //self.detailPdfButton
                                 ]];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

-(NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if([self.detailArray count] == 0) {
        return nil;
    }
    if(section == 1) {
        return @"合計金額";
    } else {
        return @"明細";
    }
}
#pragma mark - IBAction
-(IBAction)selectTouched:(id)sender
{
    self.editing = YES;
    self.checkDictionary = [NSMutableDictionary dictionary];
    [self.toolbar setItems:@[self.selectCancelButton,
                             //self.fixedSpaceButton,
                             //self.selectAllButton,
                             //self.fixedSpaceButton,
                             //self.deselectAllButton,
                             self.flexibleSpaceButton,
                             //self.preMonthButton,
                             //self.fixedSpaceButton,
                             //self.nextMonthButton
                             ]];
    
    
    [self.tableView reloadData];
}

//利用証明書発行
-(IBAction) certifyPdf:(id)sender
{
    self.filePath = nil;
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;

    if(appDelegate.demo)
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"201611051649" ofType:@"pdf"];
        NSData *pdfData = [NSData dataWithContentsOfFile:path];
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *fileName = [NSString stringWithFormat:@"利用証明_%@.pdf", self.meisaiTitle];
        if([pdfData writeToFile:[documentsDirectory stringByAppendingPathComponent:fileName] atomically:YES])
        {
            self.filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
            QLPreviewController* preview = [[QLPreviewController alloc] init];
            preview.dataSource = self;
            [self presentViewController:preview
                               animated:YES
                             completion:^{
                             }];
        }
        return;
    }

    NSError *error = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:appDelegate.htmlString error:&error];
    if(error)
    {
        [self handleError];
        return;
    }
    
    NSString *url = nil;
    for(HTMLNode *node in [[parser body] findChildTags:@"a"])
    {
        NSString *tmp = [node getAttributeNamed:@"onclick"];
        NSRange i = [tmp rangeOfString:@"/etc/R;jsessionid="];
        NSRange j = [tmp rangeOfString:@"funccode=1013000000&nextfunc=1013600000"];
        if(i.location != NSNotFound && j.location != NSNotFound)
        {
            url = [tmp substringWithRange:NSMakeRange(i.location, j.location + [@"funccode=1013000000&nextfunc=1013600000" length] - i.location)];
            break;
        }
        
    }
    
    if(!url)
    {
        [self handleError];
        return;
    }
    
    [MBProgressHUD showHUDAddedTo:appDelegate.window animated:YES];


    NSMutableSet *hakkoMeisaiSet = [NSMutableSet set];
    for(NSNumber *key in [self.checkDictionary allKeys])
    {
        ETCDetail *dtl = [self.detailArray objectAtIndex:[key integerValue]];
        [hakkoMeisaiSet addObject:dtl.checkValue];
    }

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:hakkoMeisaiSet forKey:@"hakkoMeisai"];
    
    [[HtmlUtil sharedInstance] submit:url
                                 page:appDelegate.htmlString
                           parameters:params
                      successWithData:^(NSData *data) {
                          NSString *str = [[NSString alloc] initWithData:data encoding:NSJapaneseEUCStringEncoding];
                          if(str)
                          {
                              if([self sessionTimeout:str])
                              {
                                  [MBProgressHUD hideHUDForView:appDelegate.window animated:YES];
                                  return;
                              }
                          }
                          
                          NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                          
                          NSString *fileName = [NSString stringWithFormat:@"利用証明_%@.pdf", self.meisaiTitle];
                          if([data writeToFile:[documentsDirectory stringByAppendingPathComponent:fileName] atomically:YES])
                          {
                              [MBProgressHUD hideHUDForView:appDelegate.window animated:YES];
                              self.filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
                              
                              QLPreviewController* preview = [[QLPreviewController alloc] init];
                              preview.dataSource = self;
                              [self presentViewController:preview
                                                 animated:YES
                                               completion:^{
                                                   
                                               }];
                          }
                          else
                          {
                              [MBProgressHUD hideHUDForView:appDelegate.window animated:YES];
                              [self handleError];
                          }

                      }
                              failure:^(NSError *error) {
                                  [MBProgressHUD hideHUDForView:appDelegate.window animated:YES];
                                  [self handleError];
                              }];
}

//利用明細ＰＤＦ出力
-(IBAction) detailPdf:(id)sender
{
    self.filePath = nil;
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    if(appDelegate.demo)
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"201611051701" ofType:@"pdf"];
        NSData *pdfData = [NSData dataWithContentsOfFile:path];
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *fileName = [NSString stringWithFormat:@"利用明細_%@.pdf", self.meisaiTitle];
        if([pdfData writeToFile:[documentsDirectory stringByAppendingPathComponent:fileName] atomically:YES])
        {
            self.filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
            QLPreviewController* preview = [[QLPreviewController alloc] init];
            preview.dataSource = self;
            [self presentViewController:preview
                               animated:YES
                             completion:^{
                             }];
        }
        return;
    }
    
    
    NSError *error = nil;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:appDelegate.htmlString error:&error];
    if(error)
    {
        [self handleError];
        return;
    }
    
    NSString *url = nil;
    for(HTMLNode *node in [[parser body] findChildTags:@"a"])
    {
        NSString *tmp = [node getAttributeNamed:@"onclick"];
        NSRange i = [tmp rangeOfString:@"/etc/R;jsessionid="];
        NSRange j = [tmp rangeOfString:@"funccode=1013000000&nextfunc=1013400000"];
        if(i.location != NSNotFound && j.location != NSNotFound)
        {
            url = [tmp substringWithRange:NSMakeRange(i.location, j.location + [@"funccode=1013000000&nextfunc=1013400000" length] - i.location)];
            break;
        }
    }
    
    if(!url)
    {
        [self handleError];
        return;
    }
    
    [MBProgressHUD showHUDAddedTo:appDelegate.window animated:YES];
    
    NSMutableSet *hakkoMeisaiSet = [NSMutableSet set];
    for(NSNumber *key in [self.checkDictionary allKeys])
    {
        ETCDetail *dtl = [self.detailArray objectAtIndex:[key integerValue]];
        [hakkoMeisaiSet addObject:dtl.checkValue];
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:hakkoMeisaiSet forKey:@"hakkoMeisai"];
    [[HtmlUtil sharedInstance] submit:url
                                 page:appDelegate.htmlString
                           parameters:params
                      successWithData:^(NSData *data) {
                          NSString *str = [[NSString alloc] initWithData:data encoding:NSJapaneseEUCStringEncoding];
                          if(str)
                          {
                              if([self sessionTimeout:str])
                              {
                                  [MBProgressHUD hideHUDForView:appDelegate.window animated:YES];
                                  return;
                              }
                          }
                          
                          NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                          
                          NSString *fileName = [NSString stringWithFormat:@"利用証明_%@.pdf", self.meisaiTitle];
                          if([data writeToFile:[documentsDirectory stringByAppendingPathComponent:fileName] atomically:YES])
                          {
                              [MBProgressHUD hideHUDForView:appDelegate.window animated:YES];
                              self.filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
                              
                              QLPreviewController* preview = [[QLPreviewController alloc] init];
                              preview.dataSource = self;
                              [self presentViewController:preview
                                                 animated:YES
                                               completion:^{
                                                   
                                               }];
                          }
                          else
                          {
                              [MBProgressHUD hideHUDForView:appDelegate.window animated:YES];
                              [self handleError];
                          }
                          
                      }
                              failure:^(NSError *error) {
                                  [MBProgressHUD hideHUDForView:appDelegate.window animated:YES];
                                  [self handleError];
                              }];
}

-(IBAction) deselectAll:(id)sender
{
    [self.checkDictionary removeAllObjects];
    [self.toolbar setItems:@[self.selectCancelButton,
                             //self.fixedSpaceButton,
                             //self.selectAllButton,
                             //self.fixedSpaceButton,
                             //self.deselectAllButton,
                             self.flexibleSpaceButton,
                             //self.certifyPdfButton,
                             //self.fixedSpaceButton,
                             //self.detailPdfButton
                             ]];
    [self.tableView reloadData];
}

-(IBAction) selectAll:(id)sender
{
    for(NSInteger i = 0; i < [self.detailArray count]; i++)
    {
        [self.checkDictionary setObject:[NSNumber numberWithInteger:i] forKey:[NSNumber numberWithInteger:i]];
    }
    
    [self.toolbar setItems:@[self.selectCancelButton,
                             //self.fixedSpaceButton,
                             //self.selectAllButton,
                             //self.fixedSpaceButton,
                             //self.deselectAllButton,
                             self.flexibleSpaceButton,
                             self.certifyPdfButton,
                             self.fixedSpaceButton,
                             self.detailPdfButton
                             ]];
    //[self.selectAllButton setTitle:@"全解除"];
    [self.tableView reloadData];
    //self.selectAllButton.tag = self.selectAllButton.tag == 0 ? 1 : 0;
}

-(IBAction)selectCancelTouched:(id)sender
{
    self.editing = NO;
    self.checkDictionary = nil;
    [self.tableView reloadData];
    
    [self updateBarButtons];
}

-(IBAction)searchTouched:(id)sender
{
    NSError *error = nil;
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    HTMLParser *parser = [[HTMLParser alloc] initWithString:appDelegate.htmlString error:&error];
    if(error)
    {
        [self handleError];
        return;
    }

    if(appDelegate.demo)
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Search" ofType:@"html"];
        appDelegate.htmlString = [NSString stringWithContentsOfFile:path
                                                           encoding:NSUTF8StringEncoding
                                                              error:nil];
        [self performSegueWithIdentifier:@"Search" sender:self];
        return;
    }
    

    [MBProgressHUD showHUDAddedTo:appDelegate.window animated:YES];
    HTMLNode *bodyNode = [parser body];

    //明細タイトル
    HTMLNode *meisaiinfo = [bodyNode findChildOfClass:@"meisaiinfo"];

    for(HTMLNode *linkNode in [meisaiinfo findChildTags:@"a"])
    {
        if([linkNode.contents isEqualToString:@"検索条件を変更する"])
        {
            self.navigationItem.leftBarButtonItem.enabled = YES;
            NSString *tmp = [linkNode getAttributeNamed:@"onclick"];
            NSRange i = [tmp rangeOfString:@"/etc/R;jsessionid="];
            NSRange j = [tmp rangeOfString:@"nextfunc=1014000000"];
            NSString *searchUrl = [tmp substringWithRange:NSMakeRange(i.location, j.location + [@"nextfunc=1014000000" length] - i.location)];
            
            AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            [[HtmlUtil sharedInstance] submit:searchUrl
                                         page:appDelegate.htmlString
                                   parameters:nil
                                      success:^(NSString *html) {
                                          appDelegate.htmlString = html;
                                          [MBProgressHUD hideHUDForView:appDelegate.window animated:YES];
                                          if([self sessionTimeout])
                                          {
                                              return;
                                          }
                                          [self performSegueWithIdentifier:@"Search" sender:self];
                                      }
                                      failure:^(NSError *error) {
                                          [MBProgressHUD hideHUDForView:appDelegate.window animated:YES];
                                          [self handleError];
                                      }];

            return;
        }
    }
    [MBProgressHUD hideHUDForView:appDelegate.window animated:YES];
    [self handleError];
}
-(IBAction)clearTouched:(id)sender
{

}
#pragma mark -
-(NSInteger) numberOfPreviewItemsInPreviewController: (QLPreviewController *) controller
{
    return 1;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    return [NSURL fileURLWithPath: self.filePath]; // here is self.pdfFilePath its a path of you pdf
}


-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"Search"])
    {

    }
}
@end
