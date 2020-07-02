
# set appropriate branch if you need to check out changes not on the
# main v4 branch
BRANCH=${BRANCH:-"v4"}

git init
git remote add origin https://github.com/digitalrebar/provision-content.git
git fetch origin
git checkout origin/$BRANCH -- vmware-lib 
