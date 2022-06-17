//
//  MovieViewController.m
//  Flixter
//
//  Created by Daniel Flores Garcia on 6/15/22.
//

#import "MovieViewController.h"
#import "TableViewCell.h"
#import "UIImageView+AFNetworking.h"
#import "DetailsViewController.h"
#import <UIKit/UIKit.h>

@interface MovieViewController () <UITableViewDataSource, UISearchBarDelegate>{
    NSMutableArray *filteredMovies;
    BOOL isFiltered;
}


@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *movies;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

@end

@implementation MovieViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // search bar stuff
    isFiltered = false;
    self.navBar.delegate = self;
    [self.loadingIndicator startAnimating]; // start loading indicator
    
    self.tableView.dataSource = self;
    
    // create instance of refresh control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(beginRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:refreshControl atIndex:0];
    
    // api request (boilerplate)
    NSURL *url = [NSURL URLWithString:@"https://api.themoviedb.org/3/movie/now_playing?api_key=bfc0a5530e166a5f2fc8843954b151fd"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:nil
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
           if (error != nil) {
               if (error.code == -1009){ // Network error
                   UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Network error"
                                              message:@"Check your internet connection"
                                              preferredStyle:UIAlertControllerStyleAlert];

                   UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction * action) {}];

                   [alert addAction:defaultAction];
                   [self presentViewController:alert animated:YES completion:nil];
                       NSLog(@"%@", [error localizedDescription]);
                   
               }
           }
           else { // Successful API request
               NSDictionary *dataDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
               // Get the array of movies
               self.movies = dataDictionary[@"results"];
               [self.tableView reloadData];
           }
       }];
    [task resume];
    // api request done. stop loading indicator
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (isFiltered){
        return filteredMovies.count;
    }
    return self.movies.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSMutableArray *updMovies;
    if (isFiltered){
        updMovies = filteredMovies;
    }
    else{
        updMovies = self.movies;
    }
  
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TableViewCell" forIndexPath:indexPath];
    NSDictionary *movie = updMovies[indexPath.row];
    
    // set title label
    cell.titleLabel.text = movie[@"title"];
    // set synopsis lable
    cell.synopsisLabel.text = movie[@"overview"];
    // set image view
    NSString *baseURLString = @"https://image.tmdb.org/t/p/w500";
    NSString *posterURLString = movie[@"poster_path"];
    NSString *fullPosterURLString = [baseURLString stringByAppendingString:posterURLString];
    NSURL *posterURL = [NSURL URLWithString:fullPosterURLString];
    cell.posterView.image = nil;
    [cell.posterView setImageWithURL:posterURL];

    return cell;
}

- (void)beginRefresh:(UIRefreshControl *)refreshControl {
       
        // api request (boilerplate)
        NSURL *url = [NSURL URLWithString:@"https://api.themoviedb.org/3/movie/now_playing?api_key=bfc0a5530e166a5f2fc8843954b151fd"];
        NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                              delegate:nil
                                                         delegateQueue:[NSOperationQueue mainQueue]];
        session.configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
           
            if (error != nil) {
                NSLog(@"%@", [error localizedDescription]);
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"My Alert"
                                           message:@"This is an alert."
                                           preferredStyle:UIAlertControllerStyleAlert];

                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action) {}];

                [alert addAction:defaultAction];
                [self presentViewController:alert animated:YES completion:nil];
            }
            else {
                NSDictionary *dataDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                self.movies = dataDictionary[@"results"];
                [self.tableView reloadData];
            }
           // Reload the tableView now that there is new data
            [self.tableView reloadData];
           // Tell the refreshControl to stop spinning
            [refreshControl endRefreshing];
        }];
    
        [task resume];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    if (searchText.length == 0) {
        isFiltered = false;
        [self.navBar endEditing:YES];
    }
    else {
        isFiltered = true;
        filteredMovies = [[NSMutableArray alloc]init];

     for (NSDictionary *movie in self.movies) {
         NSString *title = movie[@"title"];
            NSRange range = [title rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if (range.location != NSNotFound) {
                [filteredMovies addObject:movie];
            }
        }
    }
    [self.tableView reloadData];

}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Pass the selected object to the new view controller.
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
    NSDictionary *dataToPass = self.movies[indexPath.row];
    DetailsViewController *detailVC = [segue destinationViewController];
    detailVC.detailDict = dataToPass;
}


@end
