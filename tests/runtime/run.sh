#!/bin/sh
haxelib run munit gen
lime test neko
lime test cpp
haxelib run munit test
