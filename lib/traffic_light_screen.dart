import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class TrafficLightScreen extends StatefulWidget {
  const TrafficLightScreen({super.key});

  @override
  TrafficLightScreenState createState() => TrafficLightScreenState();
}

class TrafficLightScreenState extends State<TrafficLightScreen> {
  late ARKitController arkitController;
  ARKitReferenceNode? node;
  bool idle = true;

  @override
  void dispose() {
    arkitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Custom Animation')),
        floatingActionButton: FloatingActionButton(
          child: Icon(idle ? Icons.play_arrow : Icons.stop),
          onPressed: () async {
            if (idle) {
              await arkitController.playAnimation(
                  key: 'transform',
                  sceneName: 'Models.scnassets/traffic_light.usdz',
                  animationIdentifier: 'transform');
            } else {
              await arkitController.stopAnimation(key: 'transform');
            }
            setState(() => idle = !idle);
          },
        ),
        body: ARKitSceneView(
          showFeaturePoints: true,
          enablePanRecognizer: true,
          enablePinchRecognizer: true,
          enableRotationRecognizer: true,
          planeDetection: ARPlaneDetection.horizontal,
          onARKitViewCreated: onARKitViewCreated,
        ),
      );

  void onARKitViewCreated(ARKitController arkitController) {
    this.arkitController = arkitController;
    this.arkitController.onAddNodeForAnchor = _handleAddAnchor;
    this.arkitController.onNodePinch = (pinch) => _onPinchHandler(pinch);
    this.arkitController.onNodePan = (pan) => _onPanHandler(pan);
    // this.arkitController.onNodeRotation =
    //     (rotation) => _onRotationHandler(rotation);
  }

  void _handleAddAnchor(ARKitAnchor anchor) {
    if (anchor is! ARKitPlaneAnchor) {
      return;
    }
    _addPlane(arkitController, anchor);
  }

  void _addPlane(ARKitController? controller, ARKitPlaneAnchor anchor) {
    if (node != null) {
      controller?.remove(node!.name);
    }
    node = ARKitReferenceNode(
      url: 'Models.scnassets/traffic_light.usdz',
      position: vector.Vector3(0, 0, 0),
      scale: vector.Vector3(0.002, 0.002, 0.002),
    );
    controller?.add(node!, parentNodeName: anchor.nodeName);
  }

  void _onPinchHandler(List<ARKitNodePinchResult> pinch) {
    final pinchNode = pinch.firstOrNull;
    if (pinchNode != null) {
      final scale = 1 - ((1 - pinchNode.scale) * 0.01);
      final oldScale = node?.scale ?? vector.Vector3.zero();
      node?.scale = oldScale * scale;
    }
  }

  void _onPanHandler(List<ARKitNodePanResult> pan) {
    final panNode = pan.firstOrNull;
    if (panNode != null) {
      final oldPosition = node?.position;
      final translation = panNode.translation * 0.001;
      node?.position = vector.Vector3((oldPosition?.x ?? 0) + translation.x,
          oldPosition?.y ?? 0, (oldPosition?.z ?? 0) + translation.y);
    }
  }

  void _onRotationHandler(List<ARKitNodeRotationResult> rotation) {
    final rotationNode = rotation.firstOrNull;
    if (rotationNode != null) {
      final oldRotation = node?.eulerAngles ?? vector.Vector3.zero();
      node?.eulerAngles = vector.Vector3(
          oldRotation.x + rotationNode.rotation, oldRotation.y, oldRotation.z);
    }
  }
}
