//
//  MovieViewController.h
//  Flixter
//
//  Created by Daniel Flores Garcia on 6/15/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MovieViewController : UIViewController <UISearchBarDelegate>
@property (weak, nonatomic) IBOutlet UISearchBar *navBar;

@end

NS_ASSUME_NONNULL_END
