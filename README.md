# TradeItIosTicketSDK

## Cocoapods
To use the Ticket SDK with Cocoapods, you need to add the Trading Ticket Inc SpecRepo source and add the TicketSDK to your pod dependencies.

```ruby
source 'https://github.com/tradingticket/SpecRepo'

target 'YourProjectTargetName' do
  use_frameworks!
  pod 'TradeItIosTicketSDK', '0.1.1'
end
```

## Deprecated framework build notes
NOTE: To build select the framework target, and iOS Device and build (it will build for both iOS and Simulators)

Also, the frameworks are copied to this location:  ${HOME}/Code/TradeIt/TradeItIosTicketSDKLib/  if that's not where your code is, your missing out on life :) you can go into the Framework Build Phases and modify the last couple lines in the MultiPlatform Build Script

XCode7 - As of XCode7/iOS9 the submission process has changed, until we get a build script you'll need to manually edit the Info.plist file inside the generated .bundle  Open the file and remove the CFSupportedPlatforms and ExecutableFile lines.
