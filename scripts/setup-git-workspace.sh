#!/bin/sh
gh auth login -w -p ssh
mkdir $HOME/gravitational
git clone git@github.com:gravitational/teleport.git ~t
git clone git@github.com:Joerger/teleport-config.git ~c
