@echo off
echo ============================================
echo  GymForge Setup Script
echo ============================================
echo.

echo Step 1: Clean Flutter...
call flutter clean
echo.

echo Step 2: Get packages...
call flutter pub get
echo.

echo Step 3: Configure Firebase (select gymforge-f9fe3 and Android)...
call flutterfire configure
echo.

echo Step 4: Deploy Firestore rules FIRST before anything else...
call firebase deploy --only firestore:rules --project gymforge-f9fe3
echo.

echo Step 5: Deploy Firestore indexes...
call firebase deploy --only firestore:indexes --project gymforge-f9fe3
echo.

echo ============================================
echo  Setup complete! Now run: flutter run
echo ============================================
pause
