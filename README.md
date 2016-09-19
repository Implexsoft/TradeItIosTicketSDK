# TradeItIosTicketSDK
Framework to launch TradeIt trading ticket/portfolio.

# Installation
## Cocoapods

Follow the [Cocoapods: Getting started guide](https://guides.cocoapods.org/using/getting-started.html) and [Cocoapods: Using Cocoapods guide](https://guides.cocoapods.org/using/using-cocoapods.html) if you've never used Cocoapods before.

Inside your `Podfile` you need to add the TradeIt spec repo as a source:

```ruby
source 'https://github.com/tradingticket/SpecRepo'
```

Under your project target add our Ticket SDK pod as a dependency:

```ruby
pod 'TradeItIosTicketSDK', '0.1.13'
```

This is a base example of what it should look like:

```ruby
source 'https://github.com/tradingticket/SpecRepo'

target 'YourProjectTargetName' do
  use_frameworks!
  pod 'TradeItIosTicketSDK', '0.1.13'
end
```

Then run:

```
pod install
```

The Ticket SDK and Ad SDK should be installed for you.

## Deprecated framework build notes
NOTE: To build select the framework target, and iOS Device and build (it will build for both iOS and Simulators)

Also, the frameworks are copied to this location:  ${HOME}/Code/TradeIt/TradeItIosTicketSDKLib/  if that's not where your code is, your missing out on life :) you can go into the Framework Build Phases and modify the last couple lines in the MultiPlatform Build Script

XCode7 - As of XCode7/iOS9 the submission process has changed, until we get a build script you'll need to manually edit the Info.plist file inside the generated .bundle  Open the file and remove the CFSupportedPlatforms and ExecutableFile lines.

# Usage
## Specifying parameters for the TradeIt ticket
When setting order parameters in the ticket, follow the conventions listed in our API documentation:

Order Quantity: only positive integers

Order Action: buy, sell, buyToCover, sellShort

Order Type: market, limit, stopMarket, stopLimit

For more information, visit https://www.trade.it/documentation/api#PreviewTrade

## Launching the Trade screen
<img src="https://www.trade.it/images/guide/trading-flow.png">

~~~~
#import <TradeItIosTicketSDK/TradeItIosTicketSDK.h>

- (IBAction)launchTicket:(id)sender {
    [TradeItTicketController showTicketWithApiKey: @"tradeit-test-api-key" symbol: @"GE" viewController: self];
}

// restrict the ticket to only show Trade.Use this method if yur app does not want to show the TradeIT portfolio from the trading ticket
- (IBAction)launchTicketOnly:(id)sender {
    [TradeItTicketController showRestrictedTicketWithApiKey: @"tradeit-test-api-key" symbol: @"GE" viewController:self];
}
~~~~

## Launching the Portfolio screen
<img src="https://www.trade.it/images/guide/portfolio-flow.png">

~~~~
#import <TradeItIosTicketSDK/TradeItIosTicketSDK.h>

- (IBAction)launchPortfolio:(id)sender {
    [TradeItTicketController showPortfolioWithApiKey: @"tradeit-test-api-key" viewController: self];
}

// restrict the ticket to only show Portfolio. Use this method if yur app does not want to show the TradeIT trading ticket for the portfolio
- (IBAction)launchPortfolioOnly:(id)sender {
    [TradeItTicketController showRestrictedPortfolioWithApiKey: @"tradeit-test-api-key" viewController: self];
}
~~~~

#### Launching the Portfolio screen, with specific account selected: This is useful if you app displays a list of all the accounts that user can click on

~~~~
#import <TradeItIosTicketSDK/TradeItIosTicketSDK.h>
    
- (void)viewDidLoad {
    NSArray * linkedAccounts = [TradeItTicketController getLinkedAccounts];
    NSDictionary * firstAccount = [linkedAccounts objectAtIndex: 0];
    self.selectedAccountNumber = [firstAccount valueForKey: @"accountNumber"];
}

- (IBAction)launchPortfolio:(id)sender {
    [TradeItTicketController showPortfolioWithApiKey: @"tradeit-test-api-key" viewController: self accountNumber: self.selectedAccountNumber];
}
~~~~

#### If you would like to pull in a users holdings/portfolio data to screens outside of the SDK, then use the code below.
Note: that this code will launch the authentication flow and handle any security questions if the user is not already authenticated.

~~~~
- [TradeItTicketController getSessions: self withApiKey:@"tradeit-test-api-key"
    onCompletion:^(NSArray *sessions) {
    NSDictionary * firstSession = [sessions objectAtIndex: 0];
    NSString * sessionToken = [firstSession valueForKey:@"token"];
    NSString * accountNumber = [firstSession valueForKey:@"accountNumber"];
    
    //use sessionToken with anything here:  https://www.trade.it/documentation/api
    //or to use with the existing services in the library
    
    TradeItConnector * myConnector = [[TradeItConnector alloc] initWithApiKey: @"tradeit-test-api-key"];
    
    TradeItSession * mySession = [[TradeItSession alloc] initWithConnector: myConnector];
    mySession.token = sessionToken;
    
    TradeItGetPositionsRequest * positionRequest = [[TradeItGetPositionsRequest alloc] initWithAccountNumber:accountNumber];
    
    TradeItPositionService * positionRequester = [[TradeItPositionService alloc] initWithSession: mySession];
    
    [positionRequester getAccountPositions: positionRequest withCompletionBlock:^(TradeItResult * result) {
         //update UI with position data
    }]; 
}];
~~~~

## Launching the Account Setup screen
<img src="https://www.trade.it/images/guide/login flow.png">
~~~~
#import <TradeItIosTicketSDK/TradeItIosTicketSDK.h>
    
- (IBAction)launchAccountSelection:(id)sender {
    [TradeItTicketController showAccountsWithApiKey: @"tradeit-test-api-key" viewController: self onCompletion: nil];
}
~~~~

## Launching the Promotional Broker Center.
Any account opening revenues from the Broker Center will be shared with the app developper. Please contact TradeIt for more details

<img src="https://www.trade.it/images/guide/broker_center.jpg" width="200">

Before launching the Broker Center, TradeIt needs to retrieve configuration data. For best performance, call the following method sometime before launching the screen:

~~~~
#import <TradeItIosTicketSDK/TradeItIosTicketSDK.h>
    
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [TradeItTicketController initializePublisherData: @"tradeit-test-api-key" onLoad: ^(BOOL brokerCenterActive){
        // use boolean*
    }];
    return YES;
}
~~~~

*The onLoad callback passes a boolean that determines whether the Open Account feature is available.

To launch the Broker Center screen itself:

~~~~
#import <TradeItIosTicketSDK/TradeItIosTicketSDK.h>
    
[TradeItTicketController showBrokerCenterWithApiKey:@"tradeit-test-api-key" viewController:self];
~~~~

## Launching via instantiation

Alternatively, if you instantiate the ticket, you can manually set the flow using presentationMode:

~~~~
#import <TradeItIosTicketSDK/TradeItIosTicketSDK.h>

// trading
- (IBAction)launchTicket:(id)sender {
    TradeItTicketController * ticket = [[TradeItTicketController alloc] initWithApiKey: @"tradeit-test-api-key" symbol: @"GE" viewController: self];
    // choose one of the following:
    ticket.presentationMode = TradeItPresentationModeAuth;
    ticket.presentationMode = TradeItPresentationModeTradeOnly;
    ticket.presentationMode = TradeItPresentationModePortfolioOnly;
    [ticket showTicket];
}
~~~~

## Debugging/Setup
Should you want to test the full flow of the app, you can use our dummy broker as documented in TradeItIosEmsApi. To enable the dummy broker on the ticket, use the full method call and set the 'withDebug' property. Keep in mind that you must use your QA api key when in debug mode. Also, you will need to reset your NSUserDefaults between debug and production sessions, as your saved authentication data is particular to the server environment:

~~~~
#import <TradeItIosTicketSDK/TradeItIosTicketSDK.h>

// debug trading ticket
- (IBAction)launchTicket:(id)sender {
    [TradeItTicketController showTicketWithApiKey: @"tradeit-test-api-key" symbol: @"GE" orderAction: @"buy" orderQuantity: @1 viewController: self withDebug: YES onCompletion: nil];
}

// debug portfolio ticket
- (IBAction)launchPortfolio:(id)sender {
    [TradeItTicketController showPortfolioWithApiKey: @"tradeit-test-api-key" viewController: self withDebug: YES onCompletion: nil];
}
~~~~
