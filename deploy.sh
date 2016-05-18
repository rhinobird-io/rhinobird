#!/bin/bash

set -e

git checkout -B deploy

filename=$(date +'%s')
mv public/_assets/main.js public/_assets/main$filename.js
mv public/_assets/main.css public/_assets/main$filename.css

echo "development:
  hostname: localhost:8000
  script_url: 'http://localhost:2992/_assets/main$filename.js'
  css_url: ''
  email: 'rhinobird.worksap.test@gmail.com'


production:
  hostname: rhinobird.workslan
  script_url: '/platform/_assets/main$filename.js'
  css_url: '/platform/_assets/main$filename.css'
  email: 'rhinobird.worksap@gmail.com'" > "config/platform.yml"


git add config/platform.yml
git add public
git commit -m 'add assets'
git push dokku deploy:master -f
git checkout master
