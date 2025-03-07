Face Liveliness Detection in Flutter

📌 Overview

This Flutter project implements real-time face liveliness detection using Google ML Kit and Camera Plugin. It ensures the user is present and alive by verifying a sequence of facial actions:

✅ Blink 👀✅ Smile 😊✅ Look Left ⬅️✅ Look Right ➡️

If all actions are completed within 10 seconds, the user is verified!

🛠️ Features

Uses Google ML Kit for face detection

Detects blink, smile, and head movements

Uses front camera with mirrored preview

Includes a 10-second verification timer

Requests camera permissions dynamically

📲 Installation & Setup

1️⃣ Clone this repository

git clone https://github.com/your-username/flutter-face-liveliness.git
cd flutter-face-liveliness

2️⃣ Install dependencies

flutter pub get

3️⃣ Add camera permissions

Modify AndroidManifest.xml (for Android):

<uses-permission android:name="android.permission.CAMERA" />

Modify Info.plist (for iOS):

<key>NSCameraUsageDescription</key>
<string>We need camera access for face detection</string>

4️⃣ Run the project

flutter run

🔧 Dependencies Used

camera → Captures real-time camera feed

google_mlkit_face_detection → Detects facial features

permission_handler → Manages camera permissions

🖥️ Usage

Once the app starts:

Grant camera access when prompted.

Follow the on-screen instructions to complete the liveliness check.

If successful, you will see a ✅ "Liveliness Verified" message.

📌 Troubleshooting

❌ Camera permission denied?

Manually enable it in phone settings.

❌ Face detection not working?

Ensure good lighting conditions.

Keep your face fully visible.

❌ Detection is slow?

Try using a lower ResolutionPreset in CameraController.

📜 License

This project is open-source. Feel free to modify and enhance it!

🚀 Happy Coding!
