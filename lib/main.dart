import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(FaceRecognitionApp(cameras: cameras));
}

/// Main application widget.
class FaceRecognitionApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const FaceRecognitionApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CameraScreen(cameras: cameras),
    );
  }
}
/// Camera screen that handles live face detection and liveliness verification.
class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      enableContours: true,
    ),
  );

  int step = 0;
  Timer? verificationTimer;
  bool isVerified = false;
  int timeLeft = 10;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }
  /// Requests camera permission from the user.
  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      _initializeCamera();
    } else {
      print("❌ Camera permission denied!");
    }
  }

  /// Initializes the front camera and starts the image stream.
  Future<void> _initializeCamera() async {
    final frontCamera = widget.cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    controller = CameraController(
      frontCamera,
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await controller!.initialize();
    if (!mounted) return;
    setState(() {});

    controller!.startImageStream((CameraImage image) {
      if (!isProcessing) {
        isProcessing = true;
        _processImage(image).then((_) => isProcessing = false);
      }
    });

    _startVerificationTimer();
  }

  /// Starts a timer to reset verification if time runs out.
  void _startVerificationTimer() {
    verificationTimer?.cancel();
    timeLeft = 10;
    verificationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft <= 0) {
        _resetVerification();
      } else {
        setState(() {
          timeLeft--;
        });
      }
    });
  }

  /// Resets the verification process when time runs out.
  void _resetVerification() {
    verificationTimer?.cancel();
    setState(() {
      step = 0;
      isVerified = false;
      timeLeft = 10;
    });
    _startVerificationTimer();
  }


  /// Processes the camera image and detects facial expressions.
  Future<void> _processImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation270deg, // Fix orientation for front cam
        format: InputImageFormat.yuv420,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );

    final faces = await faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      print("⚠️ No face detected!");
      return;
    }

    Face face = faces.first;

    bool blinkDetected = face.leftEyeOpenProbability != null &&
        face.rightEyeOpenProbability != null &&
        face.leftEyeOpenProbability! < 0.2 &&
        face.rightEyeOpenProbability! < 0.2;

    bool smileDetected = face.smilingProbability != null &&
        face.smilingProbability! > 0.5;

    bool movingLeft = face.headEulerAngleY != null && face.headEulerAngleY! > 10; // Reversed
    bool movingRight = face.headEulerAngleY != null && face.headEulerAngleY! < -10; // Reversed

    _checkLivelinessSequence(blinkDetected, smileDetected, movingLeft, movingRight);
  }

  /// Checks the sequence of required liveliness actions.
  void _checkLivelinessSequence(bool blink, bool smile, bool left, bool right) {
    if (step == 0 && blink) {
      setState(() => step = 1);
    } else if (step == 1 && smile) {
      setState(() => step = 2);
    } else if (step == 2 && left) {
      setState(() => step = 3);
    } else if (step == 3 && right) {
      setState(() {
        isVerified = true;
        verificationTimer?.cancel();
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    faceDetector.close();
    verificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scaffold(
        appBar: AppBar(title: Text('Facial Recognition with ML Kit '),),
        body: Stack(
          children: [
            if (controller != null && controller!.value.isInitialized)
              Container(
                width: double.infinity,
                height: double.infinity,
                child: Transform.scale(
                  scaleX: -1, // Mirror the front camera preview
                  child: CameraPreview(controller!),
                ),
              ),
            Positioned(
              bottom: 50,
              left: 50,
              right: 50,
              child: Column(
                children: [
                  Text(
                    isVerified ? "Liveliness Verified ✅" : "Perform Actions in Order",
                    style: TextStyle(fontSize: 22, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    step >= 0 ? "1️⃣ Blink 👀 ${step > 0 ? '✅' : ''}" : "",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  Text(
                    step >= 1 ? "2️⃣ Smile 😊 ${step > 1 ? '✅' : ''}" : "",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  Text(
                    step >= 2 ? "3️⃣ Look Left ⬅️ ${step > 2 ? '✅' : ''}" : "",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  Text(
                    step >= 3 ? "4️⃣ Look Right ➡️ ${isVerified ? '✅' : ''}" : "",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "⏳ Time Left: $timeLeft sec",
                    style: TextStyle(fontSize: 20, color: timeLeft > 3 ? Colors.white : Colors.red),
                  ),
                ],
              ),)
          ],
        ),
      ),
    );
  }
}
