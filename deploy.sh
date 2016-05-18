#!/bin/bash

set -e

git checkout -B deploy

filename=$(date +'%s')
mv public/_assets/main.js public/_assets/main$filename.js
mv public/_assets/main.css public/_assets/main$filename.css


content=$(<"config/platform.yml")
from="_assets/main."
to="_assets/main$filename."
formated=${content//$from/$to}
echo "$formated" > "config/platform.yml"


git add config/platform.yml
git add public
git commit -m 'add assets'
git push dokku deploy:master -f
git checkout master
