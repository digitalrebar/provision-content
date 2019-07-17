#!/usr/bin/env bash

repo=$1

if [ "${TRAVIS_BRANCH}" = "tip" ] || [ "${TRAVIS_BRANCH}" = "stable" ]
then
    curl -H "Content-Type: application/json" -H "Accept: application/json" -H "Travis-API-Version: 3" -H "Authorization: token ${TRAVIS_API_TOKEN}" "https://api.travis-ci.com/repo/rackn%2Frackn-saas/requests" -X POST -d "{ \"request\": { \"message\": \"Trigger build by ${repo}\", \"branch\": \"${TRAVIS_BRANCH}\" } }"
fi

