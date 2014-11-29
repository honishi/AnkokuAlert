AnkokuAlert 2.x
=========
- Niconama alert alternative for OS X.
- Binary available at [Mac App Store](https://itunes.apple.com/jp/app/ankoku-alert/id447599289?l=en&mt=12).

screenshot
-
![screenshot](./document/screenshot.png)

setup repository
-
````
brew insatll uncrustify
cd .git/hooks
ln -s ../../scripts/git-hooks/pre-commit
````

project dependencies
-
* `xcproj` command is required to keep xcode.pbxproj file clean
* see detail at http://qiita.com/masaki925/items/878ab05824b772d72da9

````
brew install xcproj
````

````
pod install
open AnkokuAlert.xcworkspace
````

setup coredata
-
````
brew install mogenerator
mogenerator -m AnkokuAlert.xcdatamodeld/AnkokuAlert.xcdatamodel -O Models/ --template-var arc=true
````

license
-
copyright &copy; 2013- honishi, hiroyuki onishi.

distributed under the [MIT license][mit].
[mit]: http://www.opensource.org/licenses/mit-license.php
