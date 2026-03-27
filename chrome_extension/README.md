# RecSports Chrome Extension

## Load the extension

1. Open Chrome and go to `chrome://extensions`.
2. Turn on `Developer mode`.
3. Click `Load unpacked`.
4. Select the `chrome_extension` folder from this repo.

## Use the extension

1. Sign in to the attendance app as a coach.
2. Open `RecSports Sync` in the app.
3. Set `Access mode` to `Browser assisted` and save.
4. Copy the `Browser Sync Token`.
5. In Chrome, open the authenticated TAMU Sport Clubs `Home Events` page.
6. Open the extension popup.
7. Optionally click `Detect From Open App Tab` if the attendance app's `RecSports Sync` page is already open in another tab.
8. Otherwise enter:
   - your attendance app URL
   - the browser sync token
9. Click `Sync Current Tab`.

The popup will show progress as it scrapes each event page. The extension scrapes the current authenticated Sport Clubs page, follows each `View` link, and posts the roster snapshot to the Rails app.
