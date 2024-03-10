# Tickmate Changelog

## v1.3 and v1.3.1

v1.3 released on the iOS App Store 2024/01/29  
v1.3.1 released on the visionOS App Store 2024/02/02

### Major changes

+ Native Apple Vision Pro support

### Minor improvements

+ Improve future-proofing by only showing known in-app purchases
([#88](https://github.com/skjiisa/Tickmate-iOS/pull/88))
+ Fix iOS 16 and 17 issues related to Introspect for SwiftUI
([#89](https://github.com/skjiisa/Tickmate-iOS/pull/89))
+ Fix tracks rearranging themselves on new installs
([#91](https://github.com/skjiisa/Tickmate-iOS/pull/91))
+ Make swiping between pages less janky (again)
([a40b9a9](https://github.com/skjiisa/Tickmate-iOS/commit/a40b9a9dc6aab239704391e5666402d8f7735a95))

## v1.2.3

Released on the App Store 2021/11/04

+ Fix laggy swiping between track groups
([f7711aa](https://github.com/Isvvc/Tickmate-iOS/commit/f7711aa2aa063f74c441e3e0f0b2abf5dc9fed00))

## v1.2.2

Released on the App Store 2021/10/04

### Minor improvements

+ Sort tracks in the widget by the in-app sort order as opposed to the order they are selected in
([3fda8c7](https://github.com/Isvvc/Tickmate-iOS/pull/74/commits/3fda8c79826095acf8986522dc9612e6eb054362))

#### iOS 15 fixes

+ Fix not being able to open sheets
([319eb0d](https://github.com/Isvvc/Tickmate-iOS/pull/74/commits/319eb0d880b28e81bba60f5c00ea3ac090ea637a))
+ Fix text fields being empty
([9bac4d9](https://github.com/Isvvc/Tickmate-iOS/pull/74/commits/9bac4d9c6bf52af7bcdbca208722c0c37ee1ffdc))

## v1.2.1

Released on the App Store 2021/07/17

+ Fix issue with new tracks not showing in the tracks list
([e381324](https://github.com/Isvvc/Tickmate-iOS/commit/e3813249cd457132fe258c3df918759bcb10bae0))

## v1.2

### Major features

+ Widgets!
([#51](https://github.com/Isvvc/Tickmate-iOS/pull/51))
  + There are now 3 sizes of customizable widgets for your Home Screen or Today View.
+ Fix laggy ticking
([#50](https://github.com/Isvvc/Tickmate-iOS/issues/50))
  + Ticking days should now happen immediately when tapped

### Minor improvements

+ Fix text wrap issue on "Yesterday" text on larger Dynamic Type sizes
([#48](https://github.com/Isvvc/Tickmate-iOS/issues/48))
+ Add a basic launch screen
([#49](https://github.com/Isvvc/Tickmate-iOS/issues/49))
+ Add version and build numbers in settings
([#52](https://github.com/Isvvc/Tickmate-iOS/issues/52))
+ Fix layout of tracks row when large number of tracks exist
([#54](https://github.com/Isvvc/Tickmate-iOS/issues/54))

## v1.1

Released

+ 2021/06/23 on GitHub
+ 2021/07/09 on the App Store

### Major features

+ Track groups
([#29](https://github.com/Isvvc/Tickmate-iOS/pull/29))
  + In-app purchase that allows you to group tracks together and swipe between groups on the main screen

### Minor improvements

+ Fix lag when editing Tracks
([949a361](https://github.com/Isvvc/Tickmate-iOS/commit/949a3619418b0896a61bbb3dc54569f3b834e41d))
+ Fix issue where date would not update when opening the app on a new day
([934c875](https://github.com/Isvvc/Tickmate-iOS/commit/934c8755327b20a1636dac4a28b3c0af1dd3eb58))
+ Add new section of preset tracks
([df74640](https://github.com/Isvvc/Tickmate-iOS/commit/df74640dff3619046ddd1bafa685cd4b597b7b4d), [#46](https://github.com/Isvvc/Tickmate-iOS/pull/46))
+ Fix week separators sometimes not showing correctly or at all
([#47](https://github.com/Isvvc/Tickmate-iOS/pull/47))
+ Minor back-end bug fixes
([15bcc73](https://github.com/Isvvc/Tickmate-iOS/commit/15bcc734103871d9e455a107b4edb0592cc9f99e))
