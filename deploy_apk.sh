#!/usr/bin/env bash
set -euo pipefail

# Build or fetch the latest Expeditious Reader Android APK and deploy it to the Catalogue Server.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RELEASE_DIR="$REPO_DIR/releases"
APK_DEST="$RELEASE_DIR/expeditiousreader.apk"
REMOTE_HOST="${CATALOGUE_SSH_HOST:-dl380g9}"
REMOTE_DIR="${CATALOGUE_REMOTE_DIR:-~/projects/expeditiousreader}"

mkdir -p "$RELEASE_DIR"

if [ -n "${ANDROID_HOME:-}" ] || [ -d "$HOME/Android/Sdk" ]; then
    echo "Building Android APK locally via Flutter..."
    flutter build apk --release
    cp "$REPO_DIR/build/app/outputs/flutter-apk/app-release.apk" "$APK_DEST"
else
    echo "Fetching latest built Android APK from GitHub Actions (Build Android APK)..."
    TMP_DL="$(mktemp -d)"
    trap 'rm -rf "$TMP_DL"' EXIT

    RUN_ID="$(gh run list --repo Paul-PADataAnalytics/expeditiousreader --workflow build-android.yml --branch main --status success --limit 1 --json databaseId --jq '.[0].databaseId')"
    if [ -z "$RUN_ID" ] || [ "$RUN_ID" = "null" ]; then
        echo "Error: No successful Build Android APK workflow run found." >&2
        exit 1
    fi
    echo "Downloading artifact 'android-apk' from workflow run #$RUN_ID..."
    gh run download "$RUN_ID" --repo Paul-PADataAnalytics/expeditiousreader --name android-apk --dir "$TMP_DL"
    cp "$TMP_DL/app-release.apk" "$APK_DEST"
fi

ls -lh "$APK_DEST"

if ssh -o BatchMode=yes -o ConnectTimeout=5 "$REMOTE_HOST" "mkdir -p $REMOTE_DIR/releases $REMOTE_DIR/build/web" 2>/dev/null; then
    echo "Deploying APK to $REMOTE_HOST:$REMOTE_DIR/releases/expeditiousreader.apk..."
    rsync -av "$APK_DEST" "$REMOTE_HOST:$REMOTE_DIR/releases/expeditiousreader.apk"
    ssh "$REMOTE_HOST" "cp $REMOTE_DIR/releases/expeditiousreader.apk $REMOTE_DIR/build/web/expeditiousreader.apk"
    echo "APK deployed and live at /download/expeditiousreader.apk"
else
    echo "Note: Remote host '$REMOTE_HOST' not reachable over SSH; APK saved locally at $APK_DEST"
fi
