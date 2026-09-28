# reillo_mobile

INF231

## Getting Started

The app uses UserService to authenticate and save the user data, the User model to organize it, ProfileScreen to display it, and the saved user ID to load the correct cart in CartScreen.
# lab act 4
# Lab Activity 5: discussion

**DummyJSON workflow.** On sign in, the app sends the username and password to `https://dummyjson.com/auth/login`. The API returns the user and an access token, and `UserService.saveUserData()` stores them in SharedPreferences. On launch, the splash screen calls `isLoggedIn()`, which checks for that saved token. Sign up posts the form fields (firstName, lastName, age, phone, username, email, password) to `/users/add`. DummyJSON only simulates the insert, though. It returns the new user with an id, but nothing is saved, so that account can't log in. Updating the username or password (`PUT /users/{id}`) and deleting the account (`DELETE /users/{id}`) are simulated the same way. Logging out just clears the saved session.

**Firebase workflow.** Sign up calls `createAccount()` (`createUserWithEmailAndPassword`) and sets the username as the account's display name with `updateUsername()`. It then saves the session the same way as DummyJSON, with `loginType = firebase`. Sign in calls `signIn()` (`signInWithEmailAndPassword`). The Firebase SDK keeps the session and refreshes the ID token automatically, so on launch `isLoggedIn()` waits for `authStateChanges()` to report whether a user is signed in. Changing the password (`resetPasswordFromCurrentPassword`) and deleting the account (`deleteAccount`) both re-authenticate with the current password first, because Firebase requires a recent login for those actions. Log out calls `signOut()` and clears the saved session. Firebase Auth only stores the email, password and display name, so the other sign-up fields (name, age, contact number) are saved on the device, keyed by the user's uid.

**Main idea of UserService.** The screens never call HTTP or Firebase directly. Every account action goes through `UserService`, and the saved `LoginType` decides whether it goes to DummyJSON or Firebase (`changeUsername`, `changePassword`, `removeAccount`, `logout`). Both backends save the session in the same shape, so the splash screen, profile and cart all read it through `getUserData()` / `getUser()` and don't need to know which backend was used.

**Benefits of Firebase for this app.** Sign up is real: accounts persist, and emails are checked for duplicates. Passwords are hashed by Firebase instead of being handled by our own API. The ID token refreshes automatically, and sessions survive app restarts without us storing a password. Sensitive actions require re-authentication. Accounts can be managed in the Firebase Console, and the same project can later add Firestore with security rules, so the profile fields sync across devices instead of living only on this phone.
