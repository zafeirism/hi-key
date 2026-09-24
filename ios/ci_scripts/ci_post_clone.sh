#!/bin/sh
set -e

# Xcode Cloud runs this after cloning the repo, before building.
# It sets CURRENT_PROJECT_VERSION across all targets to CI_BUILD_NUMBER
# (Xcode Cloud's monotonically increasing per-workflow counter) so every
# upload to App Store Connect has a unique build number.

# The Xcode project lives in ios/ within the hi-key monorepo.
cd "$CI_PRIMARY_REPOSITORY_PATH/ios"

echo "Setting CURRENT_PROJECT_VERSION to $CI_BUILD_NUMBER across all targets"

sed -i '' -E "s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = $CI_BUILD_NUMBER;/g" hi.xcodeproj/project.pbxproj

echo "Result:"
grep "CURRENT_PROJECT_VERSION" hi.xcodeproj/project.pbxproj | sort -u
