git co -B deploy
git add public
git commit -m 'add assets'
git push deis deploy:master -f
git checkout master
