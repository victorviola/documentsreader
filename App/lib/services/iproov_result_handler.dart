import 'package:flutter/material.dart';
import 'package:iproov_flutter/events.dart';

Future<void> handleIProovResult({
  required BuildContext context,
  required IProovEvent event,
}) async {
  if (event is IProovEventSuccess) return;

  String title = "Try again";
  String text = "Something went wrong during the scan.";
  String image = "assets/images/F1 Unknown Code.png";

  if (event is IProovEventFailure) {

    switch (event.feedbackCode) {
      case "eyes_closed":
        title = "Keep your eyes open";
        text = "Please ensure your eyes are open during the scan.";
        image = "assets/images/F5 Eyes Closed.png";
        break;
      case "face_too_far":
        title = "Come closer";
        text = "Move your face closer to the screen.";
        image = "assets/images/F6 Face Too Far.png";
        break;
      case "face_too_close":
        title = "Move back a bit";
        text = "Hold your device slightly further away.";
        image = "assets/images/F7 Face Too Close.png";
        break;
      case "misaligned_face":
        title = "Centre your face";
        text = "Align your face within the oval frame.";
        image = "assets/images/F4 Face Isn't In The Hoval.png";
        break;
      case "mutiple_faces":
        title = "Only one person";
        text = "Make sure you're the only person visible.";
        image = "assets/images/F10 Multiple Faces.png";
        break;
      case "obscured_face":
        title = "Uncover your face";
        text = "Remove any obstructions from your face.";
        image = "assets/images/F9 Obscured Face.png";
        break;
      case "sunglasses":
        title = "Remove sunglasses";
        text = "Take off any sunglasses or dark glasses.";
        image = "assets/images/F8 Remove Sunglasses.png";
        break;
      case "too_bright":
        title = "Reduce lighting";
        text = "Find a spot with less bright light.";
        image = "assets/images/F3 Avoid Direct_Bright Lighting.png";
        break;
      case "too_dark":
        title = "More light needed";
        text = "Ensure your face is well lit.";
        image = "assets/images/G8 Should Be In A Well Lit Area.png";
        break;
      case "too_much_movement":
        title = "Hold still";
        text = "Try to keep your head and phone steady.";
        image = "assets/images/F2 Too Much Movement.png";
        break;
    }
  } else if (event is IProovEventError) {
    switch (event.error.title) {
      case "networkError":
        title = "Network issue";
        text = "Check your internet connection and try again.";
        image = "assets/images/E3 Network Error.png";
        break;
      case "cameraPermissionDenied":
        title = "Camera access needed";
        text = "Enable camera permissions in your settings.";
        image = "assets/images/E4 Camera Permission Denied.png";
        break;
      case "notSupported":
        title = "Device not supported";
        text = "This device is not compatible with iProov.";
        image = "assets/images/E2A Computer Not Supported.png";
        break;
      case "cancelled":
        title = "Scan cancelled";
        text = "You cancelled the scan. Try again when ready.";
        image = "assets/images/E12A User Cancelled.png";
        break;
      default:
        text = event.error.message ?? text;
        break;
    }
  }

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (image.isNotEmpty) Image.asset(image, fit: BoxFit.cover),
          const SizedBox(height: 16),
          Text(text),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}