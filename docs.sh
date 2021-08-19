git stash
git checkout master
git pull upstream master
git push origin -d docs-update
git branch -D docs-update
git checkout -b docs-update
sed -i 's/2.11.0/2.12.0/g' k8s/upgrades/README.md
git status
git diff
read -p "Press enter to continue"
git add k8s/upgrades/README.md
git commit -s -m "chore(upgrade): update upgrade README with 2.12.0 steps"
git push origin docs-update

