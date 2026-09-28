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

# Lab Activity 6: discussion

**How the data is structured in Firestore when a chat starts.** Chatting uses two top-level collections:

- **`Users/{uid}`**: one document per Firebase account, written at sign up. The document ID is the Firebase Auth `uid`, and it holds `uid`, `email`, `username`, `firstName`, `lastName`, `age`, `phone` and `createdAt`. The chat list streams this whole collection, leaves out the signed-in user, and filters it by the search text. Accounts made before this lab get their document the next time they sign in.
- **`chat_rooms/{chatRoomID}`**: one document per pair of users. The room ID is the two uids **sorted and joined with `_`** (for example `3CRE…_8aK0…`). Sorting means that whether A messages B or B messages A, both land in the same room. The room document stores `participants` (both uids), `lastMessage`, `lastSenderId` and `lastTimestamp`, which the chat list uses for its preview and ordering.
  - **`chat_rooms/{chatRoomID}/messages/{autoId}`**: each message holds `senderId`, `senderEmail`, `receiverId`, `message`, `timestamp` and `seen`. The chat screen streams this subcollection ordered by `timestamp`.

When A sends the first message to B, nothing needs to be set up first. `sendMessage` builds the room ID and, in one batch, writes both the room document and the first message. From then on, both users' apps are listening to the same `messages` subcollection, so each new message appears on both screens in real time. "Sending…" is Firestore's pending local write (`metadata.hasPendingWrites`). ✓ means the server accepted it. ✓✓ means the receiver's app has set `seen: true` while their chat was open.

The handout's `sendMessage` only adds the message. Without the batch, the `chat_rooms/{id}` document itself would never exist, only its `messages` subcollection. Firestore allows that, but the room can't be queried, so the list couldn't show last messages. Writing the room document fixes this.

**What happens if you chat with yourself.** The room ID is `[myUid, myUid]` sorted and joined, so `myUid_myUid`. Firestore accepts it, and the messages get saved in a room whose only participant is you. Every message has `senderId == receiverId == myUid`, so they all show up as your own bubbles on the right, and there's never a reply. They'd also never get ✓✓, since the seen logic only marks messages sent by the *other* person. It works technically, but it's meaningless as a conversation, so the chat list hides the signed-in user (Enhancement 1). That way you can't open a chat with yourself from the app.

**Security rules.** The handout sets `allow read, write: if true`, which lets anyone on the internet read or delete every user and message without logging in. This project deploys `reillo_mobile/firestore.rules` instead, which requires a signed-in Firebase user (`request.auth != null`). The app behaves the same, but anonymous access is blocked. The next step would be rules that only let a user edit their own `Users` document and only let participants read a room.
