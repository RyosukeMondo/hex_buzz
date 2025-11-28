#!/usr/bin/env -S bash -c '"$(dirname "$0")/venv/bin/python" "$0" "$@"'
# -*- coding: utf-8 -*-
"""
Deploy Android App Bundle to Google Play Store.

Prerequisites:
1. Create a service account in Google Cloud Console
2. Enable Google Play Android Developer API
3. Grant service account access in Play Console
4. Download JSON key file

Usage:
    ./tool/deploy/deploy_play_store.py --aab build/app/outputs/bundle/release/app-release.aab

Environment variables:
    GOOGLE_PLAY_KEY_FILE: Path to service account JSON key file
"""

import argparse
import os
import sys
from pathlib import Path

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

PACKAGE_NAME = "blog.techvisual.hexbuzz"
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]


def get_service(key_file: str):
    """Create authenticated Google Play API service."""
    credentials = service_account.Credentials.from_service_account_file(
        key_file, scopes=SCOPES
    )
    return build("androidpublisher", "v3", credentials=credentials)


def upload_aab(service, aab_path: str, track: str = "internal"):
    """Upload AAB to specified track."""
    print(f"Starting upload to {track} track...")

    # Create an edit
    edit = service.edits().insert(body={}, packageName=PACKAGE_NAME).execute()
    edit_id = edit["id"]
    print(f"Created edit: {edit_id}")

    try:
        # Upload the AAB
        media = MediaFileUpload(aab_path, mimetype="application/octet-stream")
        bundle = (
            service.edits()
            .bundles()
            .upload(packageName=PACKAGE_NAME, editId=edit_id, media_body=media)
            .execute()
        )
        version_code = bundle["versionCode"]
        print(f"Uploaded bundle version: {version_code}")

        # Assign to track
        track_config = {
            "track": track,
            "releases": [
                {
                    "versionCodes": [str(version_code)],
                    "status": "completed" if track == "production" else "draft",
                }
            ],
        }
        service.edits().tracks().update(
            packageName=PACKAGE_NAME,
            editId=edit_id,
            track=track,
            body=track_config,
        ).execute()
        print(f"Assigned to {track} track")

        # Commit the edit
        service.edits().commit(packageName=PACKAGE_NAME, editId=edit_id).execute()
        print("Edit committed successfully!")
        print(f"\n✅ Deployed version {version_code} to {track}")

    except Exception as e:
        # Delete the edit on failure
        service.edits().delete(packageName=PACKAGE_NAME, editId=edit_id).execute()
        raise e


def main():
    parser = argparse.ArgumentParser(description="Deploy to Google Play Store")
    parser.add_argument("--aab", required=True, help="Path to AAB file")
    parser.add_argument(
        "--track",
        default="internal",
        choices=["internal", "alpha", "beta", "production"],
        help="Release track (default: internal)",
    )
    parser.add_argument(
        "--key-file",
        default=os.environ.get("GOOGLE_PLAY_KEY_FILE"),
        help="Service account JSON key file",
    )
    args = parser.parse_args()

    if not args.key_file:
        print("Error: No key file specified.")
        print("Set GOOGLE_PLAY_KEY_FILE env var or use --key-file")
        print("\nTo create a service account key:")
        print("1. Go to Google Cloud Console > IAM > Service Accounts")
        print("2. Create a service account")
        print("3. Download JSON key")
        print("4. In Play Console > Settings > API access, grant access")
        sys.exit(1)

    if not Path(args.key_file).exists():
        print(f"Error: Key file not found: {args.key_file}")
        sys.exit(1)

    if not Path(args.aab).exists():
        print(f"Error: AAB file not found: {args.aab}")
        sys.exit(1)

    service = get_service(args.key_file)
    upload_aab(service, args.aab, args.track)


if __name__ == "__main__":
    main()
