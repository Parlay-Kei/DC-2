# Direct Cuts - End-to-End Testing Checklist

## Pre-Testing Setup
- [ ] Ensure Supabase is running and accessible
- [ ] Verify environment variables are set in `.env`
- [ ] Have test user accounts ready (customer + barber)

---

## 1. Authentication Flow

### 1.1 Registration
- [ ] Open app - shows splash screen with DC logo
- [ ] Navigate to Register screen
- [ ] Enter valid email, password, full name
- [ ] Select role (Customer/Barber)
- [ ] Submit registration
- [ ] Verify account created in Supabase
- [ ] Auto-login after registration

### 1.2 Login
- [ ] Logout if logged in
- [ ] Navigate to Login screen
- [ ] Enter valid credentials
- [ ] Successful login redirects to home
- [ ] Invalid credentials show error message

### 1.3 Password Reset
- [ ] Click "Forgot Password"
- [ ] Enter email
- [ ] Verify reset email sent (check Supabase logs)

---

## 2. Customer Flow

### 2.1 Home Screen
- [ ] Displays personalized greeting with time context
- [ ] Shows user avatar (or initials)
- [ ] Stats card shows: Bookings, Favorites, Spent
- [ ] "Upcoming" section displays or shows empty state
- [ ] "Trending Barbers" section loads barbers
- [ ] Bottom nav has: Home, Nearby, FAB (book), Favorites, Profile

### 2.2 Barber Discovery (Nearby Tab)
- [ ] Location permission requested
- [ ] Barbers load based on location
- [ ] Search/filter functionality works
- [ ] Barber cards show: name, rating, distance, services
- [ ] Tap barber opens profile

### 2.3 Barber Profile
- [ ] Shows barber details: name, bio, rating, reviews
- [ ] Services list with prices
- [ ] "Book Now" button visible
- [ ] Reviews section loads
- [ ] Can add to favorites (star icon)

### 2.4 Booking Flow
- [ ] Select service from barber profile
- [ ] Select date from calendar
- [ ] Select available time slot
- [ ] Confirm booking details
- [ ] Payment method selection
- [ ] Submit booking
- [ ] Success screen with booking confirmation
- [ ] Booking appears in "Upcoming"

### 2.5 Booking Management
- [ ] View booking details
- [ ] Cancel booking (within allowed window)
- [ ] Reschedule booking
- [ ] View past bookings

### 2.6 Reviews
- [ ] Can write review for completed booking
- [ ] Star rating selector works
- [ ] Submit review
- [ ] Review appears on barber profile

### 2.7 Messaging
- [ ] Open conversation with barber
- [ ] Send text message
- [ ] Receive message (real-time)
- [ ] Send image
- [ ] Typing indicator shows

### 2.8 Favorites
- [ ] Add barber to favorites
- [ ] Favorites tab shows saved barbers
- [ ] Remove from favorites

### 2.9 Profile & Settings
- [ ] Edit profile (name, phone, avatar)
- [ ] Change password
- [ ] Notification settings toggle
- [ ] Payment methods (add/remove)
- [ ] Sign out
- [ ] Delete account flow

---

## 3. Barber Flow

### 3.1 Dashboard
- [ ] Stats: Today's appointments, Earnings, Rating
- [ ] Today's schedule list
- [ ] Quick actions

### 3.2 Schedule Management
- [ ] View weekly calendar
- [ ] See appointments by day
- [ ] Accept/decline pending bookings
- [ ] Mark appointments complete

### 3.3 Services Management
- [ ] View services list
- [ ] Add new service (name, price, duration)
- [ ] Edit existing service
- [ ] Delete service
- [ ] Toggle service active/inactive

### 3.4 Availability
- [ ] Set weekly availability hours
- [ ] Toggle days on/off
- [ ] Set start/end times per day
- [ ] Block specific dates

### 3.5 Earnings
- [ ] View earnings summary
- [ ] Daily/weekly/monthly breakdown
- [ ] Payout history

### 3.6 Client Management
- [ ] View client list
- [ ] Client booking history
- [ ] Notes on clients

---

## 4. Real-time Features

### 4.1 Messaging
- [ ] Messages arrive in real-time
- [ ] Typing indicators work both ways
- [ ] Read receipts update

### 4.2 Notifications
- [ ] Push notification received (if OneSignal configured)
- [ ] In-app notification badge updates
- [ ] Notification center shows history
- [ ] Mark notifications read

### 4.3 Booking Updates
- [ ] Customer notified when barber confirms
- [ ] Barber notified of new booking
- [ ] Both notified of cancellation

---

## 5. Error Handling

### 5.1 Network Errors
- [ ] App handles offline gracefully
- [ ] Shows retry option
- [ ] Cached data displayed when available

### 5.2 Validation Errors
- [ ] Form validation messages clear
- [ ] Required fields marked
- [ ] Invalid input highlighted

### 5.3 API Errors
- [ ] Error messages user-friendly
- [ ] No raw error dumps to user

---

## 6. Performance

### 6.1 Load Times
- [ ] App launches < 3 seconds
- [ ] Screen transitions smooth
- [ ] Lists scroll smoothly
- [ ] Images load with placeholders

### 6.2 Memory
- [ ] No memory leaks after extended use
- [ ] Images properly cached/disposed

---

## 7. Platform Specific

### 7.1 Android
- [ ] Back button works correctly
- [ ] Deep links open correct screens
- [ ] Notifications work
- [ ] Camera/gallery permissions

### 7.2 iOS
- [ ] Swipe back gesture works
- [ ] Deep links work
- [ ] Notifications work
- [ ] Camera/photo permissions

---

## Test Accounts

### Customer Test Account
- Email: `testcustomer@directcuts.com`
- Password: `TestCustomer123!`

### Barber Test Account
- Email: `testbarber@directcuts.com`
- Password: `TestBarber123!`

---

## Sign-Off

| Tester | Date | Result | Notes |
|--------|------|--------|-------|
| | | | |
| | | | |
