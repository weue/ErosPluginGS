# ErosPluginGS

[![CI Status](https://img.shields.io/travis/sharesin/ErosPluginGS.svg?style=flat)](https://travis-ci.org/sharesin/ErosPluginGS)
[![Version](https://img.shields.io/cocoapods/v/ErosPluginGS.svg?style=flat)](https://cocoapods.org/pods/ErosPluginGS)
[![License](https://img.shields.io/cocoapods/l/ErosPluginGS.svg?style=flat)](https://cocoapods.org/pods/ErosPluginGS)
[![Platform](https://img.shields.io/cocoapods/p/ErosPluginGS.svg?style=flat)](https://cocoapods.org/pods/ErosPluginGS)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

ErosPluginGS is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ErosPluginGS', :git => 'https://github.com/sharesin/ErosPluginGS.git'
```

## Configuration

### 1. info.plist


```
<key>NSBluetoothPeripheralUsageDescription</key>
<string>是否允许此App使用您的蓝牙？</string>
<key>UIBackgroundModes</key>
<array>
<string>bluetooth-central</string>
<string>remote-notification</string>
</array>
```

### 2. Add GSDK.a Library

download GSDK.a from git(https://github.com/sharesin/ErosPluginGS.git)

```
Open Xcode Project->Click Project->TARGETS->Build Phases->Link Binary With Libraries

Click plus sign -> Add Other...->Select GSDK.a
```

### 3. pod update

### 4. Run


## Author

sharesin, zhujigao@caas.com

## License

ErosPluginGS is available under the MIT license. See the LICENSE file for more info.


