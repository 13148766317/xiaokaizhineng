//
//  LoginViewController.m
//  lock
//
//  Created by zhaowz on 2017/5/25.
//  Copyright © 2017年 zhao. All rights reserved.
//

#import "XWCountryCodeController.h"

@interface XWCountryCodeController() <UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate,UISearchDisplayDelegate>
{
    //国际代码主tableview
    UITableView *countryCodeTableView;
    //搜索
    UISearchDisplayController *searchController;
    //    UISearchController *searchController;
    UISearchBar *searchBar;
    //代码字典
    NSDictionary *sortedNameDict; //代码字典
    NSArray *indexArray;
    NSMutableArray *searchResultValuesArray;
}

@end

@interface XWCountryCodeController ()

@end

@implementation XWCountryCodeController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    //背景
    [self.view setBackgroundColor:[UIColor whiteColor]];
    //顶部标题
    [self setCustomNavigationView];
    //创建子视图
    [self creatSubviews];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    countryCodeTableView.frame = self.view.bounds;
}

- (void)setCustomNavigationView{
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    self.navigationController.navigationBar.barTintColor = KDSRGBColor(54, 54, 58);
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeBtn.widthAnchor constraintEqualToConstant:30].active = YES;
    [closeBtn.heightAnchor constraintEqualToConstant:30].active = YES;
    [closeBtn setImage:[UIImage imageNamed:@"loginClose"] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:closeBtn];
    self.title = Localized(@"selectCountryOrRegion");
}
- (void)closeBtnAction:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
//创建子视图
-(void)creatSubviews{
    searchResultValuesArray = [[NSMutableArray alloc] init];
    
    countryCodeTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) style:UITableViewStylePlain];
    [self.view addSubview:countryCodeTableView];
    //自动调整自己的宽度，保证与superView左边和右边的距离不变。
    [countryCodeTableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [countryCodeTableView setDataSource:self];
    [countryCodeTableView setDelegate:self];
    [countryCodeTableView setSectionIndexBackgroundColor:[UIColor clearColor]];
    
    searchBar = [[UISearchBar alloc] init];
    searchBar.placeholder = Localized(@"search");
    [searchBar sizeToFit];
    [searchBar setDelegate:self];
    //关闭系统自动联想和首字母大写功能
    [searchBar setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [countryCodeTableView setTableHeaderView:searchBar];
    searchController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    [searchController setDelegate:self];
    searchController.searchResultsDataSource = self;
    searchController.searchResultsDelegate = self;
    
    NSString *plistPathCH = [[NSBundle mainBundle] pathForResource:@"sortedChnames" ofType:@"plist"];
    NSString *plistPathCHFanti = [[NSBundle mainBundle] pathForResource:@"sortedChFantinames" ofType:@"plist"];
    NSString *plistPathEN = [[NSBundle mainBundle] pathForResource:@"sortedEnames" ofType:@"plist"];
    
    //根据语言 设置不同的数据源
    NSString *valueLangeuage = [[NSUserDefaults standardUserDefaults] objectForKey:AppLanguage];
    if (valueLangeuage) {
        if ([valueLangeuage isEqualToString:JianTiZhongWen]) {
            sortedNameDict = [NSDictionary dictionaryWithContentsOfFile:plistPathCH];
        }else if ([valueLangeuage isEqualToString:FanTiZhongWen]){
            sortedNameDict = [NSDictionary dictionaryWithContentsOfFile:plistPathCHFanti];
        }
        else{
            sortedNameDict = [NSDictionary dictionaryWithContentsOfFile:plistPathEN];
        }
    }else{
        
        // 获取当前系统语言。判断首次应该使用哪个语言文件
        NSArray *languages = [NSLocale preferredLanguages];
        NSString *language = [languages objectAtIndex:0];
        if ([language hasPrefix:JianTiZhongWen]) {//开头匹配简体中文
           sortedNameDict = [NSDictionary dictionaryWithContentsOfFile:plistPathCH];
        }
        else if ([language hasPrefix:FanTiZhongWen]) {//开头匹配繁体中文
            sortedNameDict = [NSDictionary dictionaryWithContentsOfFile:plistPathCHFanti];
        }
        else{//其他一律设置为英文
            sortedNameDict = [NSDictionary dictionaryWithContentsOfFile:plistPathEN];
        }
    }
    
    indexArray = [sortedNameDict allKeys];
    indexArray = [indexArray sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
}

//搜索
-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{

    [searchResultValuesArray removeAllObjects];
    
    for (NSArray *array in [sortedNameDict allValues]) {
        for (NSString *value in array) {
            if ([value containsString:searchText]) {
                [searchResultValuesArray addObject:value];
            }
        }
    }
    [searchController.searchResultsTableView reloadData];
}

#pragma mark - UITableView
//section
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (tableView == countryCodeTableView) {
        return [sortedNameDict allKeys].count;
    }else{
        return 1;
    }
}
//row
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView == countryCodeTableView) {
        
        NSArray *array = [sortedNameDict objectForKey:[indexArray objectAtIndex:section]];
        return array.count;
        
    }else{
        return [searchResultValuesArray count];
    }
}
//height
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}
//初始化cell
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == countryCodeTableView) {
        static NSString *ID1 = @"cellIdentifier1";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID1];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ID1];
        }
        //初始化cell数据!
        NSInteger section = indexPath.section;
        NSInteger row = indexPath.row;
        
        cell.textLabel.text = [[sortedNameDict objectForKey:[indexArray objectAtIndex:section]] objectAtIndex:row];
        [cell.textLabel setFont:[UIFont systemFontOfSize:16]];
        return cell;
    }else{
        static NSString *ID2 = @"cellIdentifier2";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID2];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ID2];
        }
        if ([searchResultValuesArray count] > 0) {
            cell.textLabel.text = [searchResultValuesArray objectAtIndex:indexPath.row];
        }
        return cell;
    }
}
//indexTitle
-(NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView{
    if (tableView == countryCodeTableView) {
        return indexArray;
    }else{
        return nil;
    }
}
//
-(NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index{
    if (tableView == countryCodeTableView) {
        return index;
    }else{
        return 0;
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (tableView == countryCodeTableView) {
        if (section == 0) {
            return 0;
        }
        return 30;
    }else {
        return 0;
    }
    
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [indexArray objectAtIndex:section];
}

#pragma mark - 选择国际获取代码
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    //    //1.代理传值
    //    if (self.deleagete && [self.deleagete respondsToSelector:@selector(returnCountryCode:)]) {
    //        [self.deleagete returnCountryCode:cell.textLabel.text];
    //    }
    //    [self dismissViewControllerAnimated:YES completion:nil];
    
    //2.block传值
    if (self.returnCountryCodeBlock != nil) {
        self.returnCountryCodeBlock(cell.textLabel.text);
    }
    //    [self.navigationController popViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - 代理传值
-(void)toReturnCountryCode:(returnCountryCodeBlock)block{
    self.returnCountryCodeBlock = block;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
