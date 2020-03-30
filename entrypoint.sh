#!/bin/bash -l

set -e

: ${WPENGINE_ENVIRONMENT_NAME?Required environment name variable not set.}
: ${WPENGINE_SSH_KEY_PRIVATE?Required secret not set.}
: ${WPENGINE_SSH_KEY_PUBLIC?Required secret not set.}

SSH_PATH="$HOME/.ssh"
WPENGINE_HOST="git.wpengine.com"
KNOWN_HOSTS_PATH="$SSH_PATH/known_hosts"
WPENGINE_SSH_KEY_PRIVATE_PATH="$SSH_PATH/wpengine_key"
WPENGINE_SSH_KEY_PUBLIC_PATH="$SSH_PATH/wpengine_key.pub"
WPENGINE_ENVIRONMENT_DEFAULT="production"
WPENGINE_ENV=${WPENGINE_ENVIRONMENT:-$WPENGINE_ENVIRONMENT_DEFAULT}
LOCAL_BRANCH_DEFAULT="master"
BRANCH=${LOCAL_BRANCH:-$LOCAL_BRANCH_DEFAULT}

mkdir "$SSH_PATH"

ssh-keyscan -t rsa "$WPENGINE_HOST" >> "$KNOWN_HOSTS_PATH"

echo "$WPENGINE_SSH_KEY_PRIVATE" > "$WPENGINE_SSH_KEY_PRIVATE_PATH"
echo "$WPENGINE_SSH_KEY_PUBLIC" > "$WPENGINE_SSH_KEY_PUBLIC_PATH"

chmod 700 "$SSH_PATH"
chmod 644 "$KNOWN_HOSTS_PATH"
chmod 600 "$WPENGINE_SSH_KEY_PRIVATE_PATH"
chmod 644 "$WPENGINE_SSH_KEY_PUBLIC_PATH"

echo $BASH_VERSION

echo "Adding built files that are normally .gitignored..."
array=()
mapfile -t array < _build/.deploy_include.txt
for e in "${array[@]}"
do
    printf "$e\n"
    git add "$e" -f
done

echo "Removing files we don't want on the server..."
array=()
mapfile -t array < _build/.deploy_exclude.txt
for e in "${array[@]}"
do
    git rm -r --ignore-unmatch "$e"
done

echo "Committing build changes..."
git commit -m "Committing build changes"

git config core.sshCommand "ssh -i $WPENGINE_SSH_KEY_PRIVATE_PATH -o UserKnownHostsFile=$KNOWN_HOSTS_PATH"
git remote add $WPENGINE_ENV git@$WPENGINE_HOST:$WPENGINE_ENV/$WPENGINE_ENVIRONMENT_NAME.git
git push -fu $WPENGINE_ENV $BRANCH:master
