@echo off
echo Google Sign-In Debug Information
echo ================================
echo.

echo 1. Package Name: Curren.See
echo 2. Firebase Project ID: currensee-f1718
echo.

echo 3. Current SHA-1 in google-services.json:
echo    c9977410d0e4cb5e354ed0d618bdd1f0d66c2ed9
echo.

echo 4. Getting actual SHA-1 from debug keystore...
cd /d "%USERPROFILE%\.android"
if exist debug.keystore (
    keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android | findstr SHA1
) else (
    echo Debug keystore not found at %USERPROFILE%\.android\debug.keystore
)

echo.
echo 5. OAuth Client IDs from google-services.json:
echo    Android: 455542611420-k6cigrm66fpd73m7f048ioov5atc33o5.apps.googleusercontent.com
echo    Web: 455542611420-oor09omint210uorsentkh6mvv8te3sg.apps.googleusercontent.com
echo.

echo 6. To fix Google Sign-In:
echo    a) Copy the actual SHA-1 from above
echo    b) Go to Firebase Console > Project Settings > Your apps
echo    c) Add the SHA-1 fingerprint
echo    d) Download new google-services.json
echo    e) Replace the existing file
echo    f) Clean and rebuild the app
echo.

echo 7. Common Google Sign-In Errors:
echo    - PlatformException(sign_in_failed): Wrong SHA-1 certificate
echo    - DEVELOPER_ERROR: OAuth client not configured
echo    - Network error: Check internet connection
echo.

pause