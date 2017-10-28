#reponame can be either provided as arugment or auto-detected from *git config remote.origin.url*
git remote add upstream https://github.com/openebs/$reponame
git remote set-url --push upstream no_push
git remote -v
