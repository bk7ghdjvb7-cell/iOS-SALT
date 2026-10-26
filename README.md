# iOS SALT

iOS app for Savannah Area Local Tours.

Open `SALT.xcodeproj` in Xcode. The SALT target runs in mock mode until `GoogleService-Info.plist` is added, and Xcode will ask for a signing team.

Demo sign-in: `demo@salt.savannah` / `SavannahTour1`

Any email containing `@` and any password of at least 12 characters signs in while mock mode is on. Five failures for the same email lock that email on the device for 15 minutes.
