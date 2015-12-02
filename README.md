# Warsow Version Manager

Simple way to install any version of Warsow FPS on your Linux machine. Use it
to play any version of the game with different profiles, or to run multiple
isolated servers with different configs!


## Installation

Create a directory, where all your warsow installations will be contained:

```
mkdir warsow
cd warsow
```

Download the script using either `curl` or `wget`:

```
curl -o wvm.sh https://raw.githubusercontent.com/stylemistake/wvm/master/wvm.sh
wget -O wvm.sh https://raw.githubusercontent.com/stylemistake/wvm/master/wvm.sh
```

Source the script and install the latest Warsow version:

```
source wvm.sh
wvm init
wvm install latest
```

And you're done!

You can add the line `source <path_to>/wvm.sh` to your `~/.bashrc`, so
it injects `wvm` into your bash session every time you open the console!


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
    wvm run           Run Warsow
    wvm profile       Show profiles or switch a profile
    wvm server        Start/stop a Warsow server

Example:
    wvm install latest
    wvm profile foo
    wvm run

Server example:
    wvm install latest
    wvm server init foo (then edit server.cfg)
    wvm server start foo
    wvm server list
    wvm server stop foo
```


## Planned features

* Automatic generation of a Warsow launcher (`./warsow` and a desktop launcher)
* Remote RCON console to running servers;
* Profile copying and migration.


## Contacts

Style Mistake <[stylemistake@gmail.com]>

[stylemistake.com]: http://stylemistake.com
[stylemistake@gmail.com]: mailto:stylemistake@gmail.com
