@echo off
echo Getting SHA-1 certificate for Google Sign-In...
echo.

echo Debug SHA-1:
cd /d "%USERPROFILE%\.android"
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android | findstr SHA1

echo.
echo Release SHA-1 (if exists):
cd /d "d:\Development\Flutter\CurrenSee\android\app"
if exist upload-keystore.jks (
    keytool -list -v -keystore upload-keystore.jks -alias upload -storepass 123456 -keypass 123456 | findstr SHA1
) else (
    echo No release keystore found
)

echo.
echo Copy the SHA-1 hash and add it to Firebase Console:
echo 1. Go to Firebase Console
echo 2. Project Settings
echo 3. Your apps section
echo 4. Add fingerprint
echo 5. Paste the SHA-1 hash

pause