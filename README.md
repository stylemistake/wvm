# Warsow Version Manager

Simple way to install any version of Warsow FPS on your Linux machine. Use it
to play any version of the game at any time or to run multiple isolated servers
with different configs!


## Installation

Using `wget`:

```
mkdir warsow
cd warsow
wget -O wvm.sh https://raw.githubusercontent.com/stylemistake/warsow-vm/master/wvm.sh
bash wvm.sh init
```

Using `curl`:

```
mkdir warsow
cd warsow
curl -o wvm.sh https://raw.githubusercontent.com/stylemistake/warsow-vm/master/wvm.sh
bash wvm.sh init
```

Then you run commands like this:

```
bash wvm.sh list remote
```

You can load it up into your session and use it from anywhere:

```
source wvm.sh
wvm list remote
```


## Usage

```
Warsow Version Manager

Usage:
    wvm help          Show this help message
    wvm init          Initialize this folder to use with wvm
    wvm list          List installed versions
    wvm list remote   List remote versions available to install
    wvm install       Download and install a version of Warsow
    wvm current       Show current version of Warsow
    wvm use           Set current version of Warsow
    wvm run           Run a version of Warsow
    wvm profile       Show profiles or switch a profile
    wvm server        Start/stop a Warsow server

Example:
    wvm init
    wvm install v1.5.1
    wvm use v1.5.1
    wvm profile sm
    ./warsow

Server example:
    wvm init
    wvm install v1.5.1
    wvm use v1.5.1
    wvm server init server-duel1
    wvm server init server-duel2
    (edit server configs for each profile)
    wvm server start server-duel1
    wvm server start server-duel2
    wvm server list
    wvm server stop server-duel1
    wvm server stop server-duel2
```


## Notes

Currently, `wvm` doesn't create aliases or symlinks to major versions, so if
you do `wvm install latest`, it resolves to `latest -> v1.5 -> v1.5.1` and
installs correspondingly into `v1.5.1` folder. It does not symlink
`latest -> v1.5.1` for your convenience. If you want this symlink, create one
yourself, then `wvm use latest`. This feature will be implemented soon!


## Planned features

* Automatic generation of a Warsow launcher (`./warsow` and a desktop launcher)
* Automatic version aliasing for convenient version switching (e.g.
`latest -> v1.5.1`)
* Remote RCON console to running servers;
* Profile copying and migration.


## Contacts

Style Mistake <[stylemistake@gmail.com]>

[stylemistake.com]: http://stylemistake.com
[stylemistake@gmail.com]: mailto:stylemistake@gmail.com
