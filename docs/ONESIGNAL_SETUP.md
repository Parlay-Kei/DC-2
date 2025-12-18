# Direct Cuts - OneSignal Push Notification Setup

## Step 1: Create OneSignal Account

1. Go to https://onesignal.com and sign up
2. Click "New App/Website"
3. Enter app name: **Direct Cuts**
4. Select platforms: **Google Android** and **Apple iOS**

---

## Step 2: Android Setup (FCM)

### Get Firebase Server Key:
1. Go to https://console.firebase.google.com
2. Create new project or use existing: **Direct Cuts**
3. Add Android app with package name: `com.directcuts.app`
4. Download `google-services.json`
5. Place it in `C:\Dev\DC-2\android\app\google-services.json`

### Get FCM Credentials:
1. In Firebase Console → Project Settings → Cloud Messaging
2. Enable Cloud Messaging API (V1)
3. Copy the **Server Key** (legacy) or set up Service Account JSON

### Configure in OneSignal:
1. In OneSignal dashboard → Settings → Platforms → Google Android
2. Paste your Firebase Server Key
3. Save

---

## Step 3: iOS Setup (APNs)

### Generate APNs Key:
1. Go to https://developer.apple.com
2. Certificates, Identifiers & Profiles → Keys
3. Create new key with **Apple Push Notifications service (APNs)**
4. Download the `.p8` file
5. Note your **Key ID** and **Team ID**

### Configure in OneSignal:
1. In OneSignal dashboard → Settings → Platforms → Apple iOS
2. Upload your `.p8` file
3. Enter Key ID and Team ID
4. Enter Bundle ID: `com.directcuts.app`
5. Save

---

## Step 4: Get Your OneSignal App ID

1. In OneSignal dashboard → Settings → Keys & IDs
2. Copy your **OneSignal App ID** (looks like: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)

---

## Step 5: Configure in App

Edit `C:\Dev\DC-2\lib\services\notification_service.dart`:

```dart
// Line 12 - Replace with your actual App ID
const String _oneSignalAppId = 'YOUR_ONESIGNAL_APP_ID';
```

---

## Step 6: Test Push Notifications

### From OneSignal Dashboard:
1. Go to Messages → New Push
2. Select "Send to Subscribed Users"
3. Enter title and message
4. Click "Send"

### From App:
1. Run app on device (not emulator for best results)
2. Allow notification permission when prompted
3. Check OneSignal dashboard → Audience for registered device

---

## Troubleshooting

### Android:
- Ensure `google-services.json` is in `android/app/`
- Check that package name matches everywhere
- Run `flutter clean && flutter pub get`

### iOS:
- Ensure APNs key is uploaded correctly
- Check bundle ID matches
- Push notifications only work on physical devices

### General:
- Check OneSignal dashboard for registered devices
- Enable verbose logging in app for debugging
- Ensure internet connectivity

---

## Optional: Segment Users

You can tag users for targeted notifications:

```dart
// In your app after user logs in
NotificationService.instance.setUserTags({
  'user_type': 'customer', // or 'barber'
  'city': 'las_vegas',
});
```

Then target segments in OneSignal dashboard.

---

## Testing Without OneSignal

If you want to test the app without OneSignal configured:

1. The app will still work - notifications just won't be received
2. Local notifications (reminders) will still work
3. You'll see errors in console about OneSignal but app won't crash

---

## Production Checklist

- [ ] Firebase project created
- [ ] google-services.json added to android/app/
- [ ] Apple Developer account active
- [ ] APNs key created and uploaded
- [ ] OneSignal App ID configured in code
- [ ] Test notification sent successfully
- [ ] User segmentation set up (optional)
