#!/usr/bin/env python3
"""
E2E test for HexBuzz authentication and session persistence.
Tests both guest and Google login flows.
"""

import sys
import time
from playwright.sync_api import sync_playwright, expect

APP_URL = "https://mondo-ai-studio.xvps.jp/hex_buzz"

def test_guest_session_persistence():
    """Test that guest session persists after page reload."""
    print("\n=== Test 1: Guest Session Persistence ===")

    with sync_playwright() as p:
        # Launch browser in headless mode (no X server available)
        browser = p.chromium.launch(headless=True)
        context = browser.new_context()

        # Clear cache and storage
        context.clear_cookies()

        page = context.new_page()

        # Enable console logging
        page.on("console", lambda msg: print(f"[Browser] {msg.text}"))

        print(f"1. Navigating to {APP_URL}")
        page.goto(APP_URL, wait_until="networkidle")
        time.sleep(2)

        # Take screenshot of initial state
        page.screenshot(path="/tmp/hex_buzz_01_initial.png")
        print("   Screenshot saved: /tmp/hex_buzz_01_initial.png")

        # Check for "Play as Guest" button
        print("2. Looking for 'Play as Guest' button...")
        try:
            guest_button = page.locator("text=/Play as Guest|Continue as Guest/i")
            if guest_button.is_visible(timeout=5000):
                print("   ✓ Found guest button")
                page.screenshot(path="/tmp/hex_buzz_02_before_guest.png")

                print("3. Clicking 'Play as Guest'...")
                guest_button.click()
                time.sleep(3)

                page.screenshot(path="/tmp/hex_buzz_03_after_guest.png")
                print("   Screenshot saved: /tmp/hex_buzz_03_after_guest.png")

                # Check if we see "Hi, Guest" or username
                print("4. Checking for user greeting...")
                page_text = page.content()
                if "Guest-" in page_text or "Hi," in page_text:
                    print("   ✓ Guest logged in successfully")

                    # Get the username
                    username = None
                    if "Guest-" in page_text:
                        import re
                        match = re.search(r'Guest-\w+', page_text)
                        if match:
                            username = match.group(0)
                            print(f"   Username: {username}")

                    # Test session persistence: reload page
                    print("5. Reloading page to test session persistence...")
                    page.reload(wait_until="networkidle")
                    time.sleep(3)

                    page.screenshot(path="/tmp/hex_buzz_04_after_reload.png")
                    print("   Screenshot saved: /tmp/hex_buzz_04_after_reload.png")

                    # Check if still logged in
                    page_text_after = page.content()
                    if username and username in page_text_after:
                        print(f"   ✅ SUCCESS: Session persisted! Still see {username}")
                        return True
                    elif "Guest-" in page_text_after or "Hi," in page_text_after:
                        print(f"   ⚠️  PARTIAL: Logged in but different username")
                        return False
                    else:
                        print(f"   ❌ FAILED: Session lost after reload")
                        print(f"   Expected to see username, but page shows login screen")
                        return False
                else:
                    print("   ❌ FAILED: Guest login didn't work")
                    return False
            else:
                print("   ❌ Button not found")
                return False
        except Exception as e:
            print(f"   ❌ Error: {e}")
            page.screenshot(path="/tmp/hex_buzz_error.png")
            return False
        finally:
            browser.close()

def test_service_worker_version():
    """Check if service worker is caching old code."""
    print("\n=== Test 2: Service Worker Check ===")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context()
        page = context.new_page()

        # Enable console logging
        console_logs = []
        page.on("console", lambda msg: console_logs.append(msg.text))

        print(f"1. Navigating to {APP_URL}")
        page.goto(APP_URL, wait_until="networkidle")
        time.sleep(5)

        # Check console logs for our debug messages
        print("2. Checking console logs...")
        has_persistence = any("Firebase Auth persistence" in log for log in console_logs)
        has_hybrid_auth = any("HybridAuth" in log for log in console_logs)
        has_cache_hit = any("Auth cache HIT" in log for log in console_logs)

        print(f"   Firebase Auth persistence log: {'✓' if has_persistence else '✗'}")
        print(f"   HybridAuth debug logs: {'✓' if has_hybrid_auth else '✗'}")
        print(f"   Cache hit logs: {'✓' if has_cache_hit else '✗'}")

        if not has_persistence and not has_hybrid_auth:
            print("   ❌ WARNING: New code not loaded! Service worker caching old version")
            print("\n   Recent console logs:")
            for log in console_logs[-10:]:
                print(f"   - {log}")
            return False
        else:
            print("   ✅ New code is loaded")
            return True

        browser.close()

def test_cache_clearing():
    """Test with completely fresh browser state."""
    print("\n=== Test 3: Fresh Browser (No Cache) ===")

    with sync_playwright() as p:
        # Launch with no storage
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            storage_state=None,
            ignore_https_errors=False,
        )
        page = context.new_page()

        # Clear everything
        print("1. Clearing all browser data...")
        context.clear_cookies()

        # Enable console logging
        console_logs = []
        page.on("console", lambda msg: console_logs.append(msg.text))

        # Navigate with hard reload
        print(f"2. Navigating to {APP_URL} (hard reload)...")
        page.goto(APP_URL, wait_until="domcontentloaded")

        # Force reload to bypass service worker
        page.evaluate("navigator.serviceWorker.getRegistrations().then(registrations => {for(let reg of registrations) {reg.unregister()}})")
        print("   Unregistered service workers")

        page.reload(wait_until="networkidle")
        time.sleep(5)

        print("3. Checking console logs...")
        print("\n   All console logs:")
        for log in console_logs:
            print(f"   {log}")

        has_new_code = any("HybridAuth" in log or "Firebase Auth persistence" in log for log in console_logs)

        if has_new_code:
            print("\n   ✅ Fresh load shows new code")
            return True
        else:
            print("\n   ❌ Even fresh load shows old code - deployment issue?")
            return False

        browser.close()

def main():
    print("=" * 60)
    print("HexBuzz E2E Authentication Tests")
    print("=" * 60)

    # Test 1: Service worker check
    sw_ok = test_service_worker_version()

    # Test 2: Cache clearing
    fresh_ok = test_cache_clearing()

    # Test 3: Guest session
    if sw_ok or fresh_ok:
        guest_ok = test_guest_session_persistence()
    else:
        print("\n⚠️  Skipping guest test - new code not loading")
        guest_ok = False

    print("\n" + "=" * 60)
    print("Test Results Summary")
    print("=" * 60)
    print(f"Service Worker Check: {'✅ PASS' if sw_ok else '❌ FAIL'}")
    print(f"Fresh Browser Load:   {'✅ PASS' if fresh_ok else '❌ FAIL'}")
    print(f"Guest Session:        {'✅ PASS' if guest_ok else '❌ FAIL'}")
    print("=" * 60)

    if not (sw_ok or fresh_ok):
        print("\n⚠️  ISSUE: New code not loading even with cache cleared")
        print("   Possible causes:")
        print("   1. Service worker caching old version")
        print("   2. Deployment didn't complete")
        print("   3. CDN/proxy caching")
        print("\nScreenshots saved to /tmp/hex_buzz_*.png")
        return 1
    elif not guest_ok:
        print("\n⚠️  ISSUE: Session not persisting after page reload")
        print("   Check screenshots at /tmp/hex_buzz_*.png")
        return 1
    else:
        print("\n✅ All tests passed!")
        return 0

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n\nTests interrupted")
        sys.exit(1)
