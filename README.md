# Warsow Version Manager

Simple way to install any version of Warsow FPS on your Linux machine. Use it
to play any version of the game at any time or to run multiple isolated servers
with different configs!

## Usage

```
Warsow Version Manager

Usage:
    wvm help          Show this help message
    wvm init          Initialize this folder to use with wvm
    wvm list          List installed versions
    wvm current       Show current version of Warsow
    wvm use           Set current version of Warsow
    wvm profile       Show profiles or switch a profile

Example:
    wvm use v1.6
    wvm profile sm
    ./warsow
```

## Notes

Currently script doesn't support installing remote versions, so right now
you need to download a version yourself and unpack it into `versions` directory
with a name corresponding to its version (e.g. `v1.6`). Then you can switch
to it with `wvm use v1.6`.

## Planned features

* Automatic generation of a Warsow launcher (`./warsow` and a desktop launcher)
* Remote download of any of the Warsow versions;
* Easy Warsow and WarsowTV server deployment and management;
* Remote RCON console to running servers;
* Profile copying and migration.

## Contacts

Email: stylemistake@gmail.com

Web: [stylemistake.com](http://stylemistake.com)
