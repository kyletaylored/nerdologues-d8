#!/bin/bash

set -x

git config user.email "stevepersch+circleci@gmail.com"
git config user.name "Circle CI Automation"

composer config --global github-oauth.github.com $GITHUB_TOKEN
composer global require -n "consolidation/cgr"
composer global require -n "hirak/prestissimo:^0.3"
cgr "drush/drush:~8"

/usr/bin/env COMPOSER_BIN_DIR=$HOME/bin composer -n --working-dir=$HOME require pantheon-systems/terminus "^1"


terminus --version
mkdir -p ~/.terminus/plugins
# todo, do I really want the dev-reusue-multidev branch?
composer create-project -n -d ~/.terminus/plugins pantheon-systems/terminus-build-tools-plugin
composer create-project -n -d ~/.terminus/plugins pantheon-systems/terminus-secrets-plugin:~1

{
 terminus auth:login -n --machine-token="$TERMINUS_TOKEN"
} &> /dev/null

terminus whoami

echo "Installing gulp globally"
npm install -g gulp
