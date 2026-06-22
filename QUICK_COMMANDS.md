# 🚀 Quick Commands Reference

## Build Commands

### Full Release Build (What we just did)
```bash
cd /Users/rahul/Documents/Nitins_Project/heyd2c-ai-attendance-flutter

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build App Bundle for Play Store
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### After App is Live - Minor Updates
```bash
# For patches/fixes (just increment build number)
flutter build appbundle --release
# AAB ready to upload to Play Store
```

### For Next Major Version
```bash
# Edit pubspec.yaml version
# Change: version: 1.0.0+1 to version: 1.1.0+2 (example)

# Then build
flutter clean
flutter pub get
flutter build appbundle --release
```

### APK Build (Alternative - for direct installation/testing)
```bash
# Build standalone APKs (one per architecture)
flutter build apk --release

# Output: build/app/outputs/apk/release/app-release.apk
# Note: Play Store prefers AAB (App Bundle), but APK can be used for:
# - Direct device testing
# - Side-loading
# - Alternative distribution
```

---

## File Locations (Important)

### Signing Configuration
```
android/pulsara_release.jks          ← KEYSTORE (Keep backed up!)
android/key.properties               ← Signing credentials
```

### Build Outputs
```
build/app/outputs/bundle/release/app-release.aab    ← AAB for Play Store
build/app/outputs/apk/release/app-release.apk       ← APK for testing
```

### Documentation
```
PLAYSTORE_DEPLOYMENT.md              ← Full deployment guide
SUBMISSION_CHECKLIST.md              ← Checklist before launch
PRIVACY_POLICY.md                    ← Privacy policy
```

---

## Common Tasks

### Task: Update app version
```bash
# 1. Edit pubspec.yaml
nano pubspec.yaml

# Change version line:
# OLD: version: 1.0.0+1
# NEW: version: 1.0.1+2  (patch update)
# OR:  version: 1.1.0+3  (minor update)

# 2. Build
flutter clean
flutter pub get
flutter build appbundle --release

# 3. Upload to Play Store Console
```

### Task: Test release build locally
```bash
# Build debug APK for testing
flutter build apk --debug

# Install on connected device
flutter install build/app/outputs/apk/debug/app-debug.apk

# Or if you have the release APK:
adb install build/app/outputs/apk/release/app-release.apk
```

### Task: Get app info
```bash
# View current package info
grep "^name:" pubspec.yaml
grep "^version:" pubspec.yaml

# View Android package name
grep "applicationId" android/app/build.gradle.kts

# View signing configuration
cat android/key.properties
```

### Task: List all build outputs
```bash
# Show all generated APKs/AABs
find build -name "*.apk" -o -name "*.aab" | sort
```

---

## Play Store Upload Sequence

### For First Launch (Internal → Beta → Production)
```
1. Create app in Play Console
   ↓
2. Upload AAB to INTERNAL TESTING track
   ↓
3. Test with team (1-2 weeks)
   ↓
4. Move to CLOSED TESTING (Beta) track
   ↓
5. Test with wider group (1-2 weeks)
   ↓
6. Prepare store listing (images, descriptions)
   ↓
7. Upload AAB to PRODUCTION track
   ↓
8. Submit for review
   ↓
9. Google reviews (typically 1-2 hours)
   ↓
10. ✅ App goes live!
```

### For Updates (After app is live)
```
1. Make code changes
2. Update version in pubspec.yaml
3. Build new AAB
4. Upload to Play Console
5. Create release notes
6. Submit for review
7. App updates automatically for users
```

---

## Troubleshooting

### Issue: "Android Studio SDK not found"
```bash
flutter doctor -v
# Then install missing components
```

### Issue: "Gradle build failed"
```bash
flutter clean
rm -rf ~/.gradle/
flutter pub get
flutter build appbundle --release
```

### Issue: "Keystore password incorrect"
```bash
# Verify key.properties exists and has correct values:
cat android/key.properties

# Make sure passwords match what you entered when creating keystore
```

### Issue: "App Bundle size too large"
```bash
# Already optimized in this build, but if needed:
flutter build appbundle --release --split-per-abi
```

### Issue: "Need to sign APK without key.properties"
```bash
# Create key.properties if missing:
cat > android/key.properties << 'EOF'
storePassword=YOUR_PASSWORD_HERE
keyPassword=YOUR_PASSWORD_HERE
keyAlias=pulsara
storeFile=../pulsara_release.jks
EOF
```

---

## Monitoring After Launch

### Check app performance (Daily)
```bash
# Visit Play Console → Analytics
# Monitor:
# - Install numbers
# - Crash rates
# - User ratings
# - Device OS distribution
```

### View crash reports
```bash
# Play Console → Crashes & ANRs
# Fix issues and update app
```

### Check user reviews
```bash
# Play Console → Ratings & Reviews
# Respond to user feedback
```

---

## Version Numbers Explained

Version format in pubspec.yaml: `version: X.Y.Z+B`

- **X**: Major version (1.0.0 = first release)
- **Y**: Minor version (new features)
- **Z**: Patch version (bug fixes)
- **B**: Build number (Android internal build number)

Examples:
```
1.0.0+1      ← Initial release
1.0.1+2      ← Bug fix patch
1.1.0+3      ← New features
2.0.0+4      ← Major rewrite
```

---

## Important: Keystore Backup

**BACKUP YOUR KEYSTORE IMMEDIATELY!**

```bash
# Create multiple backups
cp android/pulsara_release.jks ~/pulsara_release.jks.backup
cp android/pulsara_release.jks /path/to/external/drive/pulsara_release.jks.backup
cp android/pulsara_release.jks ~/Dropbox/backups/pulsara_release.jks.backup

# Store key.properties securely too (without passwords)
# You'll need to re-enter passwords from your records
```

**Why?** If you lose the keystore, you CANNOT update your app on Play Store. The keystore is forever tied to your app's package ID.

---

## Getting Help

- **Flutter Issues**: `flutter doctor -v`
- **Gradle Issues**: `cd android && ./gradlew clean`
- **Build Details**: Add `--verbose` flag: `flutter build appbundle --release --verbose`
- **Play Store Support**: https://support.google.com/googleplay/android-developer

---

Last Updated: June 17, 2024
App: Pulsara Kiosk v1.0.0
