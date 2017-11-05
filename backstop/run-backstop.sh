#!/bin/bash

if [   "$CIRCLE_BRANCH" != "master"  ]  &&   [[  $CIRCLE_BRANCH != *"screenshot"* ]]; then
    echo -e "Screenshots only run on master branch or branches containing 'screenshot' Quitting script."
    exit 0;
fi

npm install -g backstopjs@2.7.3



backstop reference --config=backstop-config.js
VISUAL_REGRESSION_RESULTS=$(backstop test --config=backstop-config.js || echo 'true')

if [[ ${VISUAL_REGRESSION_RESULTS} == *"Mismatch errors found"* ]]
then
    # Visual Regression Failed. Get Visual Difference Image
    echo -e "\nVisual regression tests failed!"
    comment="### Visual regression report (failed):"
    EXIT=1
else
    echo -e "\nVisual regression tests passed"
   comment="### Visual regression report (passed):"
   EXIT=0
fi

rsync -rlvz backstop_data $CIRCLE_ARTIFACTS

artifact_base_url="https://circleci.com/api/v1.1/project/github/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/$CIRCLE_BUILD_NUM/artifacts/0$CIRCLE_ARTIFACTS"

diff_image=$(find * | grep png | grep diff | head -n 1)
diff_image_url=$artifact_base_url/$diff_image
report_url=$artifact_base_url/backstop_data/html_report/index.html
report_link="[![Visual report]($diff_image_url)]($report_url)"


token="$(composer config --global github-oauth.github.com)"
curl -d '{ "body": "'"$comment\\n\\n$report_link"'" }' -X POST https://api.github.com/repos/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/commits/$CIRCLE_SHA1/comments?access_token=$token

exit $EXIT
