#!/bin/bash
#
# Deploy the current Circle CI build to multidev.
#
git remote add pantheon $(terminus site connection-info --field=git_url)
# @todo, Consider naming based on PR number instead of build number.
git checkout -b $TERMINUS_ENV

mkdir -p ~/terminus/plugins
git clone https://github.com/greg-1-anderson/terminus-secrets-plugin  ~/terminus/plugins/terminus-secrets-plugin

# @todo, make a terminus plugin to encapsulate these five lines.
# Something like terminus site set-migration-source-secrets --from-site=nerdololgues --from-env=migrateprep
terminus site wake --site=nerdologues --env=migrateprep
terminus secrets set migrate_source_db__database $(terminus site  connection-info  --site=nerdologues  --env=migrateprep  --field=mysql_database)
terminus secrets set migrate_source_db__username $(terminus site  connection-info  --site=nerdologues  --env=migrateprep  --field=mysql_username)
terminus secrets set migrate_source_db__password $(terminus site  connection-info  --site=nerdologues  --env=migrateprep  --field=mysql_password)
terminus secrets set migrate_source_db__host     $(terminus site  connection-info  --site=nerdologues  --env=migrateprep  --field=mysql_host)
terminus secrets set migrate_source_db__port     $(terminus site  connection-info  --site=nerdologues  --env=migrateprep  --field=mysql_port)

git push pantheon $TERMINUS_ENV -f
# @todo Don't switch to sftp after
# https://www.drupal.org/node/2156401 lands
terminus site set-connection-mode --mode=sftp
# Send to dev null so that the generated admin password does not show.
# Hiding all output might be overkill for accomplishing that goal.
terminus drush "si -y config_installer" > /dev/null 2>&1
terminus drush "ms"
terminus drush "mi --all --feedback='50 items'"
terminus drush "ms"



# Create a drush alias file so that Behat tests can be executed against Pantheon.
terminus sites aliases
# Drush Behat driver fails without this option.
echo "\$options['strict'] = 0;" >> ~/.drush/pantheon.aliases.drushrc.php
# Update Behat Params so that migration tests can be run against Pantheon.
export BEHAT_PARAMS='{"extensions" : {"Behat\\MinkExtension" : {"base_url" : "http://'$TERMINUS_ENV'-'$TERMINUS_SITE'.pantheonsite.io/"}, "Drupal\\DrupalExtension" : {"drush" :   {  "alias":  "@pantheon.nerdologues-d8.'$CIRCLE_BUILD_NUM'" }}}}'
# Make sure the site is accessible over the web before making requests to it with Behat.
curl http://$TERMINUS_ENV-$TERMINUS_SITE.pantheonsite.io/

cd tests  && ./../vendor/bin/behat --config=behat/behat-pantheon.yml behat/features/migration/ --strict
