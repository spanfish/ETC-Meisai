//
//  SearchViewController.m
//  ETCMeisai
//
//  Created by Xiangwei Wang on 11/5/16.
//  Copyright © 2016 Xiangwei Wang. All rights reserved.
//

#import "SearchViewController.h"
#import <AFNetworking/AFNetworking.h>
#import "HTMLNode.h"
#import "HTMLParser.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"
#import "HtmlUtil.h"

#define kDatePickerTag              99     // view tag identifiying the date picker view

@interface SearchViewController ()

@property(nonatomic, weak) IBOutlet UITableView *tableView;
@property(nonatomic, strong) NSIndexPath *datePickerIndexPath;
@property(nonatomic, strong) NSMutableArray *tableViewRowIdentifierArray;
@property(nonatomic, strong) NSDate *fromDate;
@property(nonatomic, strong) NSDate *toDate;
@property(nonatomic, strong) NSString *sokoKbn;
@property(nonatomic, strong) NSString *carNumber;
@property(nonatomic, strong) NSDateFormatter *dateFormatter;
@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"ETC利用履歴検索";
    self.tableViewRowIdentifierArray = [NSMutableArray array];
    [self.tableViewRowIdentifierArray addObject:@"DateFrom"];//利用年月日
    [self.tableViewRowIdentifierArray addObject:@"DateTo"];//利用年月日
    [self.tableViewRowIdentifierArray addObject:@"Basic"];//走行区分
    [self.tableViewRowIdentifierArray addObject:@"Input"];//車両番号
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateStyle:NSDateFormatterShortStyle];    // show short-style date format
    [self.dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *arbitraryDate = [NSDate date];
    NSDateComponents *comp = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:arbitraryDate];
    [comp setDay:1];
    self.fromDate = [gregorian dateFromComponents:comp];
    self.toDate = arbitraryDate;
    self.sokoKbn = @"0";
    
    [self loadPage];
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

-(IBAction)cancelTouched:(id)sender {
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
        [self performSegueWithIdentifier:@"List" sender:self];
        return;
    }

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
                                              appDelegate.htmlString = html;
                                              if([self sessionTimeout])
                                              {
                                                  [self performSegueWithIdentifier:@"Login" sender:self];
                                                  return;
                                              }
                                              [self performSegueWithIdentifier:@"List" sender:self];
                                          } failure:^(NSError *error) {
                                              [self handleError];
                                          }];
                return;
            }
        }
    }
    
    [self handleError];
}

-(void) loadPage
{

}

-(IBAction) search:(id)sender
{
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
        [self performSegueWithIdentifier:@"List" sender:self];
        return;
    }
    
    HTMLNode *bodyNode = [parser body];
    HTMLNode *submit = [bodyNode findChildWithAttribute:@"onclick"
                                           matchingName:@"submitKensaku"
                                           allowPartial:YES];
    if(submit)
    {
        NSString *tmp = [submit getAttributeNamed:@"onclick"];
        NSRange i = [tmp rangeOfString:@"/etc/R;jsessionid="];
        NSRange j = [tmp rangeOfString:@"nextfunc=1013000000"];
        NSString *searchUrl = [tmp substringWithRange:NSMakeRange(i.location, j.location + [@"nextfunc=1013000000" length] - i.location)];
        
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        
        NSDateComponents *comp = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:self.fromDate];
        
        [params setObject:[NSString stringWithFormat:@"%ld", (long)comp.year] forKey:@"fromYYYY"];//2016
        [params setObject:[NSString stringWithFormat:@"%02ld", (long)comp.month] forKey:@"fromMM"];//01
        [params setObject:[NSString stringWithFormat:@"%02ld", (long)comp.day] forKey:@"fromDD"];//01
        
        comp = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:self.toDate];
        [params setObject:[NSString stringWithFormat:@"%ld", (long)comp.year] forKey:@"toYYYY"];
        [params setObject:[NSString stringWithFormat:@"%02ld", (long)comp.month] forKey:@"toMM"];//01
        [params setObject:[NSString stringWithFormat:@"%02ld", (long)comp.day] forKey:@"toDD"];//01
        
        [params setObject:self.sokoKbn == nil ? @"" : self.sokoKbn forKey:@"sokoKbn"];
        if([self.sokoKbn isEqualToString:@"1"])
        {
            [params setObject:self.carNumber == nil ? @"" : self.carNumber forKey:@"sharyoNo"];//sharyoNo
        }
        [params setObject:@"100" forKey:@"hyojiCnt"];//hyojiCnt
        [params setObject:@"0" forKey:@"kuguriDay"];
        
        [[HtmlUtil sharedInstance] submit:searchUrl
                                     page:appDelegate.htmlString
                               parameters:params
                                  success:^(NSString *html) {
                                      appDelegate.htmlString = html;
                                      if([self sessionTimeout])
                                      {
                                          [self performSegueWithIdentifier:@"Login" sender:self];
                                          return;
                                      }
                                      [self performSegueWithIdentifier:@"List" sender:self];
                                  } failure:^(NSError *error) {
                                      [self handleError];
                                  }];
    }
    else
    {
        [self handleError];
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = self.tableViewRowIdentifierArray.count;
    if ([self hasInlineDatePicker])
    {
        // we have a date picker, so allow for it in the number of rows in this section
        NSInteger numRows = self.tableViewRowIdentifierArray.count;
        
        rows = numRows + 1;
    }
    
    if(![self.sokoKbn isEqualToString:@"1"])
    {
        rows--;
    }
    
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellID = nil;
    if([self hasInlineDatePicker])
    {
        if([self indexPathHasPicker:indexPath])
        {
            cellID = @"DateCell";
        }
        else
        {
            NSInteger row = indexPath.row;
            if(indexPath.row >= self.datePickerIndexPath.row)
            {
                row--;
            }
            cellID = [self.tableViewRowIdentifierArray objectAtIndex:row];
        }
    }
    else
    {
        cellID = [self.tableViewRowIdentifierArray objectAtIndex:indexPath.row];
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if(![self hasPickerForIndexPath:indexPath])
    {
        if([cellID isEqualToString:@"DateFrom"])
        {
            cell.textLabel.text = @"利用年月日・開始";
            cell.detailTextLabel.text = [self.dateFormatter stringFromDate: self.fromDate];
        }
        else if([cellID isEqualToString:@"DateTo"])
        {
            cell.textLabel.text = @"利用年月日・終了";
            cell.detailTextLabel.text = [self.dateFormatter stringFromDate: self.toDate];
        }
        else if([cellID isEqualToString:@"Basic"])
        {
            cell.textLabel.text = @"走行区分";
            if([self.sokoKbn isEqualToString:@"0"])
            {
                cell.detailTextLabel.text = @"全て";
            }
            else if([self.sokoKbn isEqualToString:@"1"])
            {
                cell.detailTextLabel.text = @"ＥＴＣ無線走行のみ";
            }
            else
            {
                cell.detailTextLabel.text = @"ＥＴＣカード手渡しのみ";
            }
        }
        else if([cellID isEqualToString:@"Input"])
        {
            cell.textLabel.text = @"車両番号・(ナンバーの下4桁)";
            cell.detailTextLabel.text = self.carNumber == nil ? @"ナンバーの下4桁" : self.carNumber;
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ([self indexPathHasPicker:indexPath] ? 216 : self.tableView.rowHeight);
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell.reuseIdentifier isEqualToString:@"DateFrom"] || [cell.reuseIdentifier isEqualToString:@"DateTo"])
    {
        [self displayInlineDatePickerForRowAtIndexPath:indexPath];
    }
    else if ([cell.reuseIdentifier isEqualToString:@"Basic"])
    {
        //走行区分
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"全て" style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                    self.sokoKbn = @"0";
                                                    cell.detailTextLabel.text = @"全て";
                                                    [self.tableView reloadData];
                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"ＥＴＣ無線走行のみ" style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                    self.sokoKbn = @"1";
                                                    cell.detailTextLabel.text = @"ＥＴＣ無線走行のみ";
                                                    [self.tableView reloadData];
                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"ＥＴＣカード手渡しのみ" style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                    self.sokoKbn = @"2";
                                                    cell.detailTextLabel.text = @"ＥＴＣカード手渡しのみ";
                                                    [self.tableView reloadData];
                                                }]];
        alert.popoverPresentationController.sourceView = cell.contentView;
        alert.popoverPresentationController.sourceRect = cell.contentView.bounds;
        [alert setModalPresentationStyle:UIModalPresentationPopover];
        [self presentViewController:alert
                           animated:YES
                         completion:^{
                             
                         }];
    }
    else if ([cell.reuseIdentifier isEqualToString:@"Input"])
    {
        //車両番号
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"車両番号"
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField)
         {
             textField.placeholder = @"ナンバーの下4桁";
         }];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                    UITextField *textfield = alert.textFields.firstObject;
                                                    self.carNumber = textfield.text;
#if DEBUG
                                                    NSLog(@"self.carNumber:%@",self.carNumber);
#endif
                                                    cell.detailTextLabel.text = self.carNumber == nil ? @"ナンバーの下4桁" :self.carNumber;
#if DEBUG
                                                    NSLog(@"detailTextLabel.text:%@",cell.detailTextLabel.text);
#endif
                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                    
                                                }]];
        [self presentViewController:alert
                           animated:YES
                         completion:^{
                             
                         }];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)displayInlineDatePickerForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // display the date picker inline with the table content
    [self.tableView beginUpdates];
    
    BOOL before = NO;   // indicates if the date picker is below "indexPath", help us determine which row to reveal
    if ([self hasInlineDatePicker])
    {
        before = self.datePickerIndexPath.row < indexPath.row;
    }
    
    BOOL sameCellClicked = (self.datePickerIndexPath.row - 1 == indexPath.row);
    
    // remove any date picker cell if it exists
    if ([self hasInlineDatePicker])
    {
        //[self.tableViewRowIdentifierArray removeObjectAtIndex:self.datePickerIndexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.datePickerIndexPath.row inSection:0]]
                              withRowAnimation:UITableViewRowAnimationFade];
        self.datePickerIndexPath = nil;
    }
    
    if (!sameCellClicked)
    {
        // hide the old date picker and display the new one
        NSInteger rowToReveal = (before ? indexPath.row - 1 : indexPath.row);
        NSIndexPath *indexPathToReveal = [NSIndexPath indexPathForRow:rowToReveal inSection:0];
        
        [self toggleDatePickerForSelectedIndexPath:indexPathToReveal];
        self.datePickerIndexPath = [NSIndexPath indexPathForRow:indexPathToReveal.row + 1 inSection:0];
    }
    
    // always deselect the row containing the start or end date
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.tableView endUpdates];
    
    // inform our date picker of the current date to match the current cell
    [self updateDatePicker];
}

/*! Determines if the UITableViewController has a UIDatePicker in any of its cells.
 */
- (BOOL)hasInlineDatePicker
{
    return (self.datePickerIndexPath != nil);
}


/*! Adds or removes a UIDatePicker cell below the given indexPath.
 
 @param indexPath The indexPath to reveal the UIDatePicker.
 */
- (void)toggleDatePickerForSelectedIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView beginUpdates];
    
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:0]];
    
    // check if 'indexPath' has an attached date picker below it
    if ([self hasPickerForIndexPath:indexPath])
    {
        // found a picker below it, so remove it
        [self.tableView deleteRowsAtIndexPaths:indexPaths
                              withRowAnimation:UITableViewRowAnimationFade];
    }
    else
    {
        // didn't find a picker below it, so we should insert it
        [self.tableView insertRowsAtIndexPaths:indexPaths
                              withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [self.tableView endUpdates];
}

/*! Updates the UIDatePicker's value to match with the date of the cell above it.
 */
- (void)updateDatePicker
{
    if (self.datePickerIndexPath != nil)
    {
        UITableViewCell *associatedDatePickerCell = [self.tableView cellForRowAtIndexPath:self.datePickerIndexPath];
        
        UIDatePicker *targetedDatePicker = (UIDatePicker *)[associatedDatePickerCell viewWithTag:kDatePickerTag];

        if (targetedDatePicker != nil)
        {
            if(self.datePickerIndexPath.row == 1)
            {
                [targetedDatePicker setDate:self.fromDate];
            }
            else
            {
                [targetedDatePicker setDate:self.toDate];
            }
            [targetedDatePicker setMaximumDate:[NSDate date]];
            [targetedDatePicker setMinimumDate:[[NSDate date] dateByAddingTimeInterval:-15*30*24*60*60]];
            // we found a UIDatePicker in this cell, so update it's date value
            //
            //NSDictionary *itemData = self.dataArray[self.datePickerIndexPath.row - 1];
            //[targetedDatePicker setDate:[itemData valueForKey:kDateKey] animated:NO];
        }
    }
}

/*! Determines if the given indexPath has a cell below it with a UIDatePicker.
 
 @param indexPath The indexPath to check if its cell has a UIDatePicker below it.
 */
- (BOOL)hasPickerForIndexPath:(NSIndexPath *)indexPath
{
    BOOL hasDatePicker = NO;
    
    NSInteger targetedRow = indexPath.row;
    targetedRow++;
    
    UITableViewCell *checkDatePickerCell =
    [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:targetedRow inSection:0]];
    UIDatePicker *checkDatePicker = (UIDatePicker *)[checkDatePickerCell viewWithTag:kDatePickerTag];
    
    hasDatePicker = (checkDatePicker != nil);
    return hasDatePicker;
}
/*! Determines if the given indexPath points to a cell that contains the UIDatePicker.
 
 @param indexPath The indexPath to check if it represents a cell with the UIDatePicker.
 */
- (BOOL)indexPathHasPicker:(NSIndexPath *)indexPath
{
    return ([self hasInlineDatePicker] && self.datePickerIndexPath.row == indexPath.row);
}

- (IBAction)dateAction:(id)sender
{
    UIDatePicker *picker = sender;
    if(self.datePickerIndexPath.row == 1)
    {
        self.fromDate = picker.date;
    }
    else
    {
        self.toDate = picker.date;
    }
    NSIndexPath *targetedCellIndexPath = [NSIndexPath indexPathForRow:self.datePickerIndexPath.row - 1 inSection:0];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:targetedCellIndexPath];

    cell.detailTextLabel.text = [self.dateFormatter stringFromDate:picker.date];

}
@end
