//
//  FrameDetailsViewController.m
//  UnfoldingWord
//
//  Created by Acts Media Inc. on 02/12/14.
//  Copyright (c) 2014 Distant Shores Media All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>

#import "FrameDetailsViewController.h"
#import "FrameCell.h"
#import "DWImageGetter.h"
#import "UWCoreDataClasses.h"
#import "FPPopoverController.h"
#import "ACTLabelButton.h"
#import "UFWSelectionTracker.h"
#import "LanguageInfoController.h"
#import "UFWNextChapterCell.h"
#import "UFWVersionPickerVC.h"
#import "ChapterListTableViewController.h"
#import "EmptyCell.h"
#import "UFWStatusInfoViewController.h"
#import "UFWInfoView.h"
#import "ACTLabelButton.h"
#import "Constants.h"
#import "NSString+Trim.h"
#import "UIViewController+FileTransfer.h"
#import "UnfoldingWord-Swift.h"

@interface FrameDetailsViewController () <UIGestureRecognizerDelegate, ACTLabelButtonDelegate, FrameCellDelegate>

@property (nonatomic, strong) OpenChapter *chapterMain;
@property (nonatomic, strong) OpenChapter *chapterSide;

@property (nonatomic, strong) FPPopoverController *customPopoverController;
@property (nonatomic, strong) ACTLabelButton *buttonNavItem;

@property (nonatomic, assign) UIInterfaceOrientation lastOrientation;

@property (nonatomic, strong) NSArray *arrayOfFramesMain;
@property (nonatomic, strong) NSArray *arrayOfFramesSide;

/// Used to track which collection view cells to show.
@property (nonatomic, strong) NSString *cellIDFrame;
@property (nonatomic, strong) NSString *cellIDNextChapter;
@property (nonatomic, strong) NSString *cellIdEmpty;

@property (nonatomic, assign) BOOL didShowPicker;
@property (nonatomic, assign) BOOL isShowingSide;

@property (nonatomic, assign) BOOL isHidingChrome;


@end

@implementation FrameDetailsViewController

- (UWTOC *)tocFromIsSide:(BOOL)isSide {
    if (isSide == true) {
        return self.chapterSide.container.toc;
    }
    else {
        return self.chapterMain.container.toc;
    }

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self addTapGestureRecognizer];
    
    [self loadNibsForCollectionView];
    
    self.collectionView.pagingEnabled = YES;
    
    UWTOC *tocMain = [UFWSelectionTracker TOCforJSON];
    UWTOC *tocSide = [UFWSelectionTracker TOCforJSONSide];
    
    self.isShowingSide = [UFWSelectionTracker isShowingSideOBS];

    OpenChapter *chapterMain = [tocMain chapterForNumber:[UFWSelectionTracker chapterNumberJSON]];
    OpenChapter *chapterSide = [tocSide chapterForNumber:[UFWSelectionTracker chapterNumberJSON]];
    [self resetMainChapter:chapterMain sideChapter:chapterSide];
}

- (void)loadNibsForCollectionView
{
    self.cellIDFrame = NSStringFromClass([FrameCell class]);
    UINib *frameNib = [UINib nibWithNibName:self.cellIDFrame bundle:nil];
    [self.collectionView registerNib:frameNib forCellWithReuseIdentifier:self.cellIDFrame];
    
    self.cellIDNextChapter = NSStringFromClass([UFWNextChapterCell class]);
    UINib *nextNib = [UINib nibWithNibName:self.cellIDNextChapter bundle:nil];
    [self.collectionView registerNib:nextNib forCellWithReuseIdentifier:self.cellIDNextChapter];
    
    self.cellIdEmpty = NSStringFromClass([EmptyCell class]);
    UINib *emptyNib = [UINib nibWithNibName:self.cellIdEmpty bundle:nil];
    [self.collectionView registerNib:emptyNib forCellWithReuseIdentifier:self.cellIdEmpty];
}


- (void)updateFakeNavBar
{
    self.fakeNavBar.labelButtonBookPlusChapter.text = self.chapterMain.title;
    NSString *mainVersionText = self.chapterMain.container.toc.version.slug.uppercaseString;
    mainVersionText = [mainVersionText stringByReplacingOccurrencesOfString:@"OBS" withString:@""];
    mainVersionText = [mainVersionText stringByReplacingOccurrencesOfString:@"-" withString:@""];
    NSString *sideVersionText = self.chapterSide.container.toc.version.slug.uppercaseString;
    sideVersionText = [sideVersionText stringByReplacingOccurrencesOfString:@"OBS" withString:@""];
    sideVersionText = [sideVersionText stringByReplacingOccurrencesOfString:@"-" withString:@""];
    self.fakeNavBar.labelButtonSSVersionMain.text = mainVersionText;
    self.fakeNavBar.labelButtonVersionMainAlone.text = mainVersionText;
    self.fakeNavBar.labelButtonSSVersionSide.text = sideVersionText;
}

- (void)resetMainChapter:(OpenChapter *)mainChapter sideChapter:(OpenChapter *)sideChapter
{
    self.chapterMain = mainChapter;
    self.chapterSide = sideChapter;
    
    [self updateFakeNavBar];
    [self.collectionView reloadData];
}

- (void)setChapterMain:(OpenChapter *)chapterMain
{
    _chapterMain = chapterMain;
    self.arrayOfFramesMain = [chapterMain sortedFrames];
}

- (void)setChapterSide:(OpenChapter *)chapterSide
{
    _chapterSide = chapterSide;
    self.arrayOfFramesSide = [chapterSide sortedFrames];
}

- (void)addMasterContainerBlocksToContainer:(ContainerVC *)masterContainer {
    
    //   typealias AudioActionBlock = (barButton : UIBarButtonItem, isOn: Bool) -> (toc : UWTOC?, chapterIndex : Int?, setToOn: Bool)
    
//    masterContainer.actionSpeaker = { [weak self] (barButton : UIBarButtonItem, isOn: Bool) in
//        if isOn == false, let strongself = self {
//            if let toc = strongself.tocMain {
//                return (toc, strongself.currentChapterNumber, true)
//            }
//            else if let toc = strongself.tocSide {
//                return (toc, strongself.currentChapterNumber, true)
//            }
//        }
//        return (nil, nil, false)
//    }
    
    //    typealias DiglotActionBlock =  (barButton : UIBarButtonItem, isOn: Bool) -> Void
    __weak typeof(self) weakself = self;
    masterContainer.actionDiglot = ^ void (UIBarButtonItem *bbi, BOOL isOn) {
        weakself.isShowingSide = isOn;
        [UFWSelectionTracker setIsShowingSideOBS:isOn];
        FrameCell *visibleFrameCell = [weakself visibleFrameCell];
        [visibleFrameCell setIsShowingSide:isOn animated:YES];
    };
    
    // typealias ShareActionBlock = (barButton : UIBarButtonItem) -> (UWTOC?)
    masterContainer.actionShare = ^ UWTOC* (UIBarButtonItem *bbi) {
        UWTOC *toc = weakself.chapterMain.container.toc;
        if (toc != nil) {
            return toc;
        }
        
        UWTOC *tocSide = weakself.chapterSide.container.toc;
        if (tocSide != nil) {
            return tocSide;
        }
        
        return nil;
    };
    
    //typealias FontActionBlock = (size : FontSize, font : UIFont, brightness: Float) -> Void
    masterContainer.actionFont = ^ void (CGFloat size, UIFont *font, float brightness) {
        FrameCell *cell = [weakself visibleFrameCell];
        if (cell == nil) {
            return;
        }
        cell.label_contentMain.font = [cell.label_contentMain.font fontWithSize:size];
        cell.label_contentSide.font = [cell.label_contentSide.font fontWithSize:size];
    };

    
//    masterContainer.blockTopBottomHidden = { [weak self] (percentHidden : CGFloat) in
//        guard let strongself = self else { return }
//        strongself.currentChapterVC()?.percentHidden = percentHidden
//    }
    
}


/// ACTLabelButton Delegate Method
- (void)labelButtonPressed:(ACTLabelButton *)labelButton;
{
    [self userRequestedBookPicker:labelButton];
}

//- (void)userPressedDiglotBBI:(UIBarButtonItem *)diglotBBI
//{
//    self.isShowingSide = ! self.isShowingSide;
//    FrameCell *visibleFrameCell = [self visibleFrameCell];
//    [visibleFrameCell setIsShowingSide:self.isShowingSide animated:YES];
//}

#pragma mark - Chapter Picker
- (void)userRequestedBookPicker:(id)sender
{
//    __weak typeof(self) weakself = self;
//    UIViewController *navVC = [ChapterListTableViewController navigationChapterPickerWithTopContainer:self.chapterMain.container.toc.version.language.topContainer completion:^(BOOL isCanceled, OpenChapter *selectedChapter) {
//        if (isCanceled == NO && selectedChapter != nil) {
//            OpenChapter *sideChapter = [weakself.chapterSide.container matchingChapter:selectedChapter];
//            [weakself resetMainChapter:selectedChapter sideChapter:sideChapter];
//        }
//        [weakself dismissViewControllerAnimated:YES completion:^{}];
//    }];
//    [self presentViewController:navVC animated:YES completion:^{}];
}

#pragma mark - FrameCellDelegate Methods -
//
//#pragma mark Status Info Popover
//
//- (void)showPopOverStatusInfo:(FrameCell *)cell view:(UIView *)view isSide:(BOOL)isSide
//{
//    UFWStatusInfoViewController *statusVC = [[UFWStatusInfoViewController alloc] init];
//    if (isSide == YES) {
//        statusVC.status = self.chapterSide.container.toc.version.status;
//    }
//    else {
//        statusVC.status = self.chapterMain.container.toc.version.status;
//    }
//    CGFloat width = fmin((self.view.frame.size.width - 40), 530);
//    CGSize size = [UFWInfoView sizeForStatus:statusVC.status forWidth:width withDeleteButton:NO];
//    self.customPopoverController = [[FPPopoverController alloc] initWithViewController:statusVC delegate:nil maxSize:size];
//    self.customPopoverController.border = NO;
//    [self.customPopoverController setShadowsHidden:YES];
//    
//    if ([view isKindOfClass:[UIView class]]) {
//        self.customPopoverController.arrowDirection = FPPopoverArrowDirectionAny;
//        [self.customPopoverController presentPopoverFromView:view];
//    }
//    else {
//        self.customPopoverController.arrowDirection = FPPopoverNoArrow;
//        [self.customPopoverController presentPopoverFromView:self.view];
//    }
//}
//
//#pragma mark Sharing
//
//- (void)showSharing:(FrameCell *)cell view:(UIView *)view isSide:(BOOL)isSide
//{
//    OpenChapter *chapterSelected = (isSide == YES) ? self.chapterSide : self.chapterMain;
//    UWVersion *versionSelected = chapterSelected.container.toc.version;
//    if (versionSelected == nil) {
//        return;
//    }    
//    [self sendFileForVersion:versionSelected fromBarButtonOrView:view];
// }

#pragma mark Version Picker

- (void)processTOCPicked:(UWTOC *)selectedTOC isSide:(BOOL)isSide;
{
    // Select the chapter
    if (selectedTOC.openContainer.chapters.count == 0) { // handle unexpected error.
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:@"No chapters for your selection." delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles: nil] show];
        return;
    }
    
    OpenChapter *selectedChapter = [selectedTOC.openContainer sortedChapters][0];
    // Override the selected chapter if we have open that matches an existing chapter
    for (OpenChapter *aChapter in selectedTOC.openContainer.chapters.allObjects) {
        if (aChapter.number.integerValue == [UFWSelectionTracker chapterNumberJSON]) {
            selectedChapter = aChapter;
            break;
        }
    }
    // End select chapter
    
    // Select the frame
    if (selectedChapter.frames.count == 0) { // handle unexpected error.
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:@"No frames for your selection." delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles: nil] show];
        return;
    }
    
    NSInteger frameIndex = [UFWSelectionTracker frameNumberJSON];
    NSArray *frames = [selectedChapter sortedFrames];
    if (frameIndex >= frames.count) {
        frameIndex = 0;
    }
    // End select frame
    
    [UFWSelectionTracker setChapterJSON:selectedChapter.number.integerValue];
    [UFWSelectionTracker setFrameJSON:frameIndex];
    
    // Save the selections
    if (isSide) {
        [UFWSelectionTracker setJSONTOCSide:selectedTOC];
        [self resetMainChapter:self.chapterMain sideChapter:selectedChapter];
    }
    else {
        [UFWSelectionTracker setJSONTOC:selectedTOC];
        [self resetMainChapter:selectedChapter sideChapter:self.chapterSide];
    }
    
    [self jumpToCurrentFrameAnimated:NO];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ( [self checkForRotationChange] == YES) {
        [self.collectionView reloadData];
    }
    [self jumpToCurrentFrameAnimated:YES];
    
}

#pragma mark - Tap Gesture Hide Nav Bar

- (void)addTapGestureRecognizer
{
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognized:)];
    tapRecognizer.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tapRecognizer];
}

- (void)tapRecognized:(UITapGestureRecognizer *)tapRecognizer
{
    [self.containerVC alternateTopBottomShowing];
    [self.collectionViewLayout invalidateLayout];
}

- (void)showOrHideNavigationBarAnimated:(BOOL)animated
{
    BOOL hide = (self.navigationController.navigationBarHidden) ? NO : YES;
    FrameCell *frameCell = [self visibleFrameCell];
    [frameCell setIsShowingFullScreen:hide animated:animated];
    [self.navigationController setNavigationBarHidden:hide animated:animated];
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    // Always have a cell that
    if (self.chapterMain.frames.count == 0) {
        return 1;
    }
    
    // Calculate whether to add the "Next Chapter" cell at the end -- do this unless we're on the last chapter.
    NSArray *chaptersArray = [self.chapterMain.container sortedChapters];

    OpenChapter *lastChapter = nil;
    
    if (chaptersArray.count > 0) {
        lastChapter = [chaptersArray lastObject];
    }
    
    //If last chapter, there is no next chapter cell; otherwise need to add one.
    if ([self.chapterMain isEqual:lastChapter]) {
        return self.arrayOfFramesMain.count;
    }
    else {
        return self.arrayOfFramesMain.count + 1;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.collectionView.frame.size;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.arrayOfFramesMain.count == 0) { // nothing loaded
        EmptyCell *emptyCell = [collectionView dequeueReusableCellWithReuseIdentifier:self.cellIdEmpty forIndexPath:indexPath];
        return emptyCell;
    }
    else if ([self.arrayOfFramesMain count] == indexPath.row) // We passed the last frame
    {
        UFWNextChapterCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:self.cellIDNextChapter forIndexPath:indexPath];
        [cell.buttonNextChapter setTitle:NSLocalizedString(@"nextChapter", nil) forState:UIControlStateNormal];
        if (cell.buttonNextChapter.allTargets.count == 0) {
            [cell.buttonNextChapter addTarget:self action:@selector(onNextChapterTouched:) forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    }
    else // we're on a regular frame
    {
        FrameCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:self.cellIDFrame forIndexPath:indexPath];
        cell.delegate = self;
        
        NSInteger row = indexPath.row;
        OpenFrame *frameMain = nil;
        if (row < self.arrayOfFramesMain.count) {
            frameMain = self.arrayOfFramesMain[row];
        }
        OpenFrame *frameSide = nil;
        if (row < self.arrayOfFramesSide.count) {
            frameSide = self.arrayOfFramesSide[row];
        }
        
        cell.label_contentMain.text = frameMain.text;
        cell.label_contentSide.textAlignment = [LanguageInfoController textAlignmentForLanguageCode:self.chapterMain.container.toc.version.language.lc];
        [cell setVersionName:self.chapterMain.container.toc.version.name isSide:NO];
        [cell setStatusImage:[UFWInfoView imageReverseForStatus:self.chapterMain.container.toc.version.status] isSide:NO];
        
        
        cell.label_contentSide.text = frameSide.text;
        cell.label_contentSide.textAlignment = [LanguageInfoController textAlignmentForLanguageCode:self.chapterSide.container.toc.version.language.lc];
        [cell setVersionName:self.chapterSide.container.toc.version.name isSide:YES];
        [cell setStatusImage:[UFWInfoView imageReverseForStatus:self.chapterSide.container.toc.version.status] isSide:YES];
        
        [cell setIsShowingSide:self.isShowingSide animated:NO];
        [cell setIsShowingFullScreen:self.navigationController.navigationBarHidden animated:NO];
        
        [cell setFrameImage:nil];
    
        
        __weak typeof(self) weakself = self;
        [[DWImageGetter sharedInstance] retrieveImageWithURLString:frameMain.imageUrl completionBlock:^(NSString *originalUrl, UIImage *image) {
            // Must double check that the image hasn't been recycled for a different chapter
            NSIndexPath *currentIP = [weakself.collectionView indexPathForCell:cell];
            OpenFrame *currentFrame = [weakself.arrayOfFramesMain objectAtIndex:currentIP.row];
            if ([currentFrame.imageUrl isEqualToString:originalUrl]) {
                [cell setFrameImage:image];
            }
        }];
        return cell;
    }
}

#pragma mark - Rotation

- (BOOL)checkForRotationChange
{
    UIInterfaceOrientation currentOrient = [[UIApplication sharedApplication] statusBarOrientation];
    if (self.lastOrientation == 0) {
        self.lastOrientation = currentOrient;
        return NO;
    }
    else if ( UIInterfaceOrientationIsLandscape(self.lastOrientation) && UIInterfaceOrientationIsLandscape(currentOrient)) {
        return NO;
    }
    else if ( UIInterfaceOrientationIsPortrait(self.lastOrientation) && UIInterfaceOrientationIsPortrait(currentOrient)) {
        return NO;
    }
    else {
        self.lastOrientation = currentOrient;
        return YES;
    }
}

-(void) willRotateToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.customPopoverController dismissPopoverAnimated:YES];
    
    //    // Always show the navigation bar in portrait mode.
    //    if (UIDeviceOrientationIsPortrait(toInterfaceOrientation) && self.navigationController.navigationBarHidden) {
    //        [self showOrHideNavigationBarAnimated:YES];
    //    }
    
    if (self.lastOrientation != 0) {
        if ( UIInterfaceOrientationIsLandscape(self.lastOrientation) && UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
            return;
        }
        if ( UIInterfaceOrientationIsPortrait(self.lastOrientation) && UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
            return;
        }
    }
    
    CGRect windowFrame = [[UIScreen mainScreen] bounds];
    CGFloat height = 0;
    if (self.view.bounds.size.width > self.view.bounds.size.height) {
        height = fmin(windowFrame.size.height, windowFrame.size.width);
    }
    else {
        height = fmax(windowFrame.size.height, windowFrame.size.width);
    }
    
    CGPoint currentOffset = self.collectionView.contentOffset;
    CGFloat offsetIndex = (int)currentOffset.x / (self.view.bounds.size.width);
    CGFloat newOffsetX = offsetIndex * (height);
    CGPoint newOffset = CGPointMake(newOffsetX, 0);
    
    self.collectionView.layer.opacity = 0.0;
    
    [UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        
    } completion:^(BOOL finished) {
        [self.collectionView setContentOffset:newOffset];
        [UIView animateWithDuration:.35 delay:.15 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.collectionView.layer.opacity = 1.0;
        } completion:^(BOOL finished) {}];
    }];
    [self.collectionView reloadData];
    
    self.lastOrientation = toInterfaceOrientation;
}

#pragma mark - ScrollView Delegate - Resets Top Info

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self resetChapterFrame];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ( ! decelerate) {
        [self resetChapterFrame];
    }
}

- (void)resetChapterFrame
{
    CGPoint currentOffset = self.collectionView.contentOffset;
    NSInteger index = (int)currentOffset.x / (self.view.bounds.size.width);
    [UFWSelectionTracker setFrameJSON:index];
    [self updateFakeNavBar];
}

#pragma mark - Methods to prevent the back gesture

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Disable iOS 7 back gesture
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Enable iOS 7 back gesture
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return NO;
}


#pragma mark - Helpers

- (void)jumpToCurrentFrameAnimated:(BOOL)animated
{
    NSInteger chapterNumber = self.chapterMain.number.integerValue;
    NSInteger selectedChapter = [UFWSelectionTracker chapterNumberJSON];
    
    if ( chapterNumber != selectedChapter) {
        return;
    }
    
    NSInteger currentFrame = [UFWSelectionTracker frameNumberJSON];
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:currentFrame inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:animated];
}


/// Returns the current frame cell if available. Will be nil if no cells or if the current cell is of the wrong type.
- (FrameCell *)visibleFrameCell
{
    CGPoint offset = self.collectionView.contentOffset;
    for (FrameCell *frameCell in self.collectionView.visibleCells) {
        if ([frameCell isKindOfClass:[FrameCell class]]) {
            if (frameCell.frame.origin.x == offset.x) {
                return frameCell;
            }
        }
    }
    return nil;
}

#pragma mark - NextChapter Methods

-(void)onNextChapterTouched:(id)sender
{
    NSArray *chapterMainArray = [self.chapterMain.container sortedChapters];
    
    OpenChapter *nextChapterMain = nil;
    NSInteger chapterNumber = 0;
    for (int i = 0; i < chapterMainArray.count ; i++) {
        OpenChapter *chapter = chapterMainArray[i];
        if ([chapter isEqual:self.chapterMain] && (i+1) < chapterMainArray.count) {
            NSInteger nextChapterIndex = i+1;
            nextChapterMain = chapterMainArray[nextChapterIndex];
            chapterNumber = nextChapterIndex+1;
            break;
        }
    }
    
    if ( ! nextChapterMain) {
        NSAssert3(nextChapterMain, @"%s: Could not find next chapter in array %@ with chapter %@", __PRETTY_FUNCTION__, chapterMainArray, self.chapterMain);
        return;
    }
    
    [UFWSelectionTracker setChapterJSON:chapterNumber];
    [UFWSelectionTracker setFrameJSON:0];
    
    OpenChapter *nextChapterSide = [self.chapterSide.container matchingChapter:nextChapterMain];
    
    self.chapterMain = nextChapterMain;
    self.chapterSide = nextChapterSide;
    
    NSIndexPath *nextIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    
    [self.collectionView scrollToItemAtIndexPath:nextIndexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
    
    CGRect cFrame = self.collectionView.frame;
    [self.collectionView setFrame:CGRectMake(cFrame.size.width,cFrame.origin.y,cFrame.size.width, cFrame.size.height)];
    
    [UIView animateWithDuration:0.5f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction animations:^{
        [self.collectionView setFrame:cFrame];
    } completion:^(BOOL finished){
        [self.collectionView reloadData];
        [self updateFakeNavBar];
        // do whatever post processing you want (such as resetting what is "current" and what is "next")
    }];
}

@end
