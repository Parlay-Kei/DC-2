# Quick Test Guide - DC-2 Flutter App

## Running the App

### Prerequisites
1. Enable Developer Mode in Windows:
   ```powershell
   start ms-settings:developers
   ```
   Enable "Developer Mode" to allow symlink support.

2. Ensure Flutter is set up:
   ```bash
   flutter doctor
   ```

### Running on Windows
```bash
cd C:\Dev\DC-2
flutter run -d windows
```

### Running on Android Emulator
```bash
cd C:\Dev\DC-2
flutter run -d emulator-5554
```

### Running on Chrome (Web)
```bash
cd C:\Dev\DC-2
flutter run -d chrome
```

---

## Test Scenarios

### 1. Test Home Screen Loading

**Login Credentials**:
- Email: `steve.hubbard@stratanoble.com`
- User ID: `243e2de1-d5ec-4f31-aca2-f1fb56ba1b40`

**Expected Behavior**:
- ✅ Stats card shows numbers (bookings, favorites, spent) without infinite spinner
- ✅ "Upcoming" section shows appointments or "No upcoming appointments"
- ✅ "Trending Barbers" section shows barber cards or "No barbers found"

**Debug Output to Check**:
```
DEBUG: Fetching trending barbers...
DEBUG: Trending barbers response type: List<dynamic>
DEBUG: Parsed X barbers
DEBUG: Returning X trending barbers

DEBUG: Fetching user stats for 243e2de1-d5ec-4f31-aca2-f1fb56ba1b40...
DEBUG: User stats: {bookings: X, favorites: Y, spent: Z}

DEBUG: Fetching upcoming appointments for user 243e2de1-d5ec-4f31-aca2-f1fb56ba1b40...
DEBUG: Found X upcoming appointments
```

---

### 2. Test Nearby Map

**Steps**:
1. Navigate to "Nearby" tab (second icon in bottom nav)
2. Verify map view is selected (default)

**Expected Behavior**:
- ✅ OpenStreetMap tiles load and display Las Vegas area
- ✅ Map controls (+ / - zoom buttons) appear on left side
- ✅ If barbers exist: Red circle markers appear on map
- ✅ If barbers exist: Bottom carousel shows barber cards
- ✅ Badge shows "X barbers found" or "Searching..."

**Debug Output to Check**:
```
NearbyBarbersProvider: Searching near (36.1699, -115.1398)
BarberService.getNearbyBarbers: Searching near (36.1699, -115.1398)
BarberService: Bounding box: lat(34.2299 to 38.1099), lng(-116.5798 to -113.6998)
BarberService: Found X barbers in bounding box
BarberService: Returning X barbers within 100.0 miles
NearbyBarbersProvider: Found X barbers
```

---

### 3. Test List View Toggle

**Steps**:
1. From Nearby tab (Map view), tap "List" button
2. Verify list appears with barbers
3. Tap "Map" button to switch back

**Expected Behavior**:
- ✅ View switches between map and list smoothly
- ✅ Selected button has red background
- ✅ Unselected button has gray border

---

### 4. Test Error Cases

**No Network**:
- Disconnect from internet
- Navigate to Home or Nearby tab
- Should show empty states, not crash or freeze

**No Barbers in Database**:
- Should show "No barbers found nearby"
- Map should still render with tiles

---

## Common Issues

### Issue: "Building with plugins requires symlink support"
**Solution**: Enable Developer Mode in Windows Settings
```powershell
start ms-settings:developers
```

### Issue: Map tiles not loading
**Possible Causes**:
1. Network firewall blocking `tile.openstreetmap.org`
2. No internet connection
3. CORS issues (web only)

**Debug**: Check console for network errors

### Issue: Infinite spinners still appear
**Possible Causes**:
1. Supabase RLS policies blocking user
2. Invalid user session
3. Network timeout

**Debug**: Check console for:
```
DEBUG: Error fetching trending barbers: <error>
DEBUG: Stack trace: <stack>
```

---

## Checking Logs

### Flutter Console
When running with `flutter run`, all `print()` and `debugPrint()` statements appear in console.

Look for lines starting with:
- `DEBUG:` - Application debug logs
- `BarberService:` - Barber data fetching logs
- `NearbyBarbersProvider:` - Map data logs

### Filtering Logs
```bash
# Run and filter for DEBUG logs only
flutter run -d windows 2>&1 | grep "DEBUG"

# Run and filter for errors
flutter run -d windows 2>&1 | grep -i "error"
```

---

## Verifying Database

### Check Barbers Table
If you have access to Supabase dashboard:

1. Go to: https://dskpfnjbgocieoqyiznf.supabase.co
2. Navigate to Table Editor > barbers
3. Verify:
   - Records exist
   - `is_active = true`
   - `latitude` and `longitude` are not null

### Example Query (SQL Editor)
```sql
-- Count active barbers
SELECT COUNT(*) FROM barbers WHERE is_active = true;

-- Count barbers with coordinates
SELECT COUNT(*) FROM barbers
WHERE is_active = true
  AND latitude IS NOT NULL
  AND longitude IS NOT NULL;

-- View sample barbers
SELECT id, shop_name, latitude, longitude, is_active
FROM barbers
WHERE is_active = true
LIMIT 10;
```

---

## Hot Reload

While the app is running, you can make code changes and reload:

- Press `r` in terminal for hot reload
- Press `R` in terminal for hot restart
- Press `q` to quit

---

## Clean Build

If experiencing persistent issues:

```bash
cd C:\Dev\DC-2
flutter clean
flutter pub get
flutter run -d windows
```

This clears all cached builds and dependencies.

---

## Contact

For issues or questions, check:
- Main documentation: `C:\Dev\DC-2\docs\FLUTTER_APP_FIXES.md`
- Setup guide: `C:\Dev\DC-2\SETUP.md`
- Testing checklist: `C:\Dev\DC-2\TESTING_CHECKLIST.md`
