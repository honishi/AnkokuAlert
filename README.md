AnkokuAlert 2.x
=========
Niconama alert altenative for OS X

sample
-
![screenshot](https://dl.dropboxusercontent.com/u/444711/github.com/honishi/AnkokuAlert/screenshot.png)

setup repository
-
````
$ brew insatll uncrustify
$ cd .git/hooks
$ ln -s ../../scripts/git-hooks/pre-commit
````
setup coredata
-
````
$ brew install mogenerator
$ mogenerator -m AnkokuAlert.xcdatamodeld/AnkokuAlert.xcdatamodel -O Models/ --template-var arc=true
````

license
-
copyright &copy; 2013- honishi, hiroyuki onishi.

distributed under the [MIT license][mit].
[mit]: http://www.opensource.org/licenses/mit-license.php
