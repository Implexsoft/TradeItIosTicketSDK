//
//  EditScreenViewController.m
//  TradeItIosTicketSDK
//
//  Created by Antonio Reyes on 7/27/15.
//  Copyright (c) 2015 Antonio Reyes. All rights reserved.
//

#import "EditScreenViewController.h"

@interface EditScreenViewController () {
    
    __weak IBOutlet UIButton *orderActionButton;
    __weak IBOutlet UIButton *orderTypeButton;
    __weak IBOutlet UIButton *orderExpirationButton;
    
    __weak IBOutlet UIButton *brokerButton;
    
    NSArray * linkedBrokers;
    NSArray * brokers;
}

@end

@implementation EditScreenViewController

- (NSArray *) getOrderActionTitles {
    NSArray * actions = @[@"Buy",@"Sell",@"Buy to Cover",@"Sell Short"];
    return actions;
}
- (NSArray *) getOrderTypeTitles {
    NSArray * types = @[@"Market",@"Limit",@"Stop Market",@"Stop Limit"];
    return types;
}
- (NSArray *) getOrderActionValues {
    NSArray * actions = @[@"buy",@"sell",@"buyToCover",@"sellShort"];
    return actions;
}
- (NSArray *) getOrderTypeValues {
    NSArray * types = @[@"market",@"limit",@"stopMarket",@"stopLimit"];
    return types;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    orderActionButton.layer.borderColor = [[UIColor colorWithRed:201.0f/255.0f green:201.0f/255.0f blue:201.0f/255.0f alpha:1.0f] CGColor];
    orderTypeButton.layer.borderColor = [[UIColor colorWithRed:201.0f/255.0f green:201.0f/255.0f blue:201.0f/255.0f alpha:1.0f] CGColor];
    orderExpirationButton.layer.borderColor = [[UIColor colorWithRed:201.0f/255.0f green:201.0f/255.0f blue:201.0f/255.0f alpha:1.0f] CGColor];
    brokerButton.layer.borderColor = [[UIColor colorWithRed:201.0f/255.0f green:201.0f/255.0f blue:201.0f/255.0f alpha:1.0f] CGColor];

    orderActionButton.layer.borderWidth = 1;
    orderTypeButton.layer.borderWidth = 1;
    orderExpirationButton.layer.borderWidth = 1;
    brokerButton.layer.borderWidth = 1;
    
    [self setCurrentOrderAction];
    [self setCurrentOrderType];
    [self setCurrentOrderExpiration];
    
    linkedBrokers = [TradeItTicket getLinkedBrokersList];
    //get last broker used??
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI Changes

-(void) setCurrentOrderAction {
    NSArray * actions = [self getOrderActionValues];
    NSArray * actionTitles = [self getOrderActionTitles];
    int i;
    for(i = (int) actions.count - 1; i > 0; i--) {
        if([actions[i] isEqualToString: [[[self tradeSession] orderInfo] action]]) {
            break;
        }
    }
    [orderActionButton setTitle:actionTitles[i] forState:UIControlStateNormal];
}

-(void) setCurrentOrderType {
    NSArray * types = [self getOrderTypeValues];
    NSArray * typeLabels = [self getOrderTypeTitles];
    int i;
    for(i = (int) types.count - 1; i > 0; i--) {
        if([types[i] isEqualToString:[[[[self tradeSession] orderInfo] price] type]]) {
            break;
        }
    }
    
    [orderTypeButton setTitle:typeLabels[i] forState:UIControlStateNormal];
}

-(void) setCurrentOrderExpiration {
    if([self.tradeSession.orderInfo.expiration isEqualToString:@"gtc"]) {
        [orderExpirationButton setTitle:@"Good Until Canceled" forState:UIControlStateNormal];
    } else {
        [orderExpirationButton setTitle:@"Good For The Day" forState:UIControlStateNormal];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.

    [[segue destinationViewController] setTradeSession: self.tradeSession];
    [[segue destinationViewController] setEditMode:YES];
}

//placeholder action used in storyboard segue to unwind
- (IBAction)unwindToEdit:(UIStoryboardSegue *)unwindSegue {
    
}

#pragma mark - Events

- (IBAction)orderActionPressed:(id)sender {
    CustomIOSAlertView * alert = [[CustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView: @"Select Order Action" andTag:601]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"Select",nil]];
    
    [alert setOnButtonTouchUpInside:^(CustomIOSAlertView *alertView, int buttonIndex) {
        int actionIndex = [(UIPickerView *)[alertView.containerView viewWithTag:601] selectedRowInComponent:0];
        self.tradeSession.orderInfo.action = [self getOrderActionValues][actionIndex];
        [self setCurrentOrderAction];
    }];
    
    [alert show:YES];
}

- (IBAction)orderTypePressed:(id)sender {
    CustomIOSAlertView * alert = [[CustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView: @"Select Order Type" andTag:602]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"Select",nil]];
    
    [alert setOnButtonTouchUpInside:^(CustomIOSAlertView *alertView, int buttonIndex) {
        int actionIndex = [(UIPickerView *)[alertView.containerView viewWithTag:602] selectedRowInComponent:0];
        
        //have two places storing order type is a bad idea
        //TODO refactor
        self.tradeSession.orderInfo.price.type = [self getOrderTypeValues][actionIndex];
        self.tradeSession.orderType = [self getOrderTypeValues][actionIndex];
        
        [self setCurrentOrderType];
    }];
    
    [alert show:YES];
}

- (IBAction)orderExpirationPressed:(id)sender {
    CustomIOSAlertView * alert = [[CustomIOSAlertView alloc]init];
    [alert setContainerView:[self createPickerView: @"Select Order Expiration" andTag:603]];
    [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"Select",nil]];
    
    [alert setOnButtonTouchUpInside:^(CustomIOSAlertView *alertView, int buttonIndex) {
        int actionIndex = [(UIPickerView *)[alertView.containerView viewWithTag:603] selectedRowInComponent:0];
        NSString * exp = actionIndex == 0 ? @"day" : @"gtc";
        self.tradeSession.orderInfo.expiration = exp;
        [self setCurrentOrderExpiration];
    }];
    
    [alert show:YES];
}

- (IBAction)brokerSelectPressed:(id)sender {
    if([linkedBrokers count] > 2) {
        CustomIOSAlertView * alert = [[CustomIOSAlertView alloc]init];
        [alert setContainerView:[self createPickerView: @"Select Brokerage" andTag:604]];
        [alert setButtonTitles:[NSMutableArray arrayWithObjects:@"Select",nil]];
        
        [alert setOnButtonTouchUpInside:^(CustomIOSAlertView *alertView, int buttonIndex) {
            int actionIndex = [(UIPickerView *)[alertView.containerView viewWithTag:604] selectedRowInComponent:0];
            self.tradeSession.broker = linkedBrokers[actionIndex];
        }];
    } else {
        [self performSegueWithIdentifier:@"editToBrokerSelectView" sender:self];
    }
}


#pragma mark - Picker Views

- (UIView *)createPickerView: (NSString *) popupTitle andTag:(int) tag {
    UIView * contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 290, 200)];
    
    UILabel * title = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 270, 50)];
    [title setTextColor:[UIColor blackColor]];
    [title setTextAlignment:NSTextAlignmentCenter];
    [title setFont: [UIFont boldSystemFontOfSize:16.0f]];
    [title setNumberOfLines:0];
    [title setText: popupTitle];
    [contentView addSubview:title];
    
    UIPickerView * picker = [[UIPickerView alloc] initWithFrame:CGRectMake(10, 50, 270, 130)];
    [picker setDataSource: self];
    [picker setDelegate: self];
    picker.showsSelectionIndicator = YES;
    [picker setTag: tag];
    [contentView addSubview:picker];
    
    [contentView setNeedsDisplay];
    return contentView;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if(pickerView.tag == 603) {
        return 2;
    } else if(pickerView.tag == 604) {
        return linkedBrokers.count;
    } else {
        return 4;
    }
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if([pickerView tag] == 601) {
        return [self getOrderActionTitles][row];
    } else if([pickerView tag] == 602){
        return [self getOrderTypeTitles][row];
    } else if([pickerView tag] == 603) {
        if(row == 0) {
            return @"Good For The Day";
        } else {
            return @"Good Until Canceled";
        }
    } else {
        return [TradeItTicket getBrokerDisplayString:linkedBrokers[row]];
    }
}

@end
































