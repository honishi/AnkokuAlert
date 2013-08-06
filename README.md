AnkokuAlert
=========

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
