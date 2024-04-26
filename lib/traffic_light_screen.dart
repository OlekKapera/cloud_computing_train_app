import 'package:arkit_plugin/arkit_plugin.dart';
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
        body: Container(
          child: ARKitSceneView(
            showFeaturePoints: true,
            planeDetection: ARPlaneDetection.horizontal,
            onARKitViewCreated: onARKitViewCreated,
          ),
        ),
      );

  void onARKitViewCreated(ARKitController arkitController) {
    this.arkitController = arkitController;
    this.arkitController.onAddNodeForAnchor = _handleAddAnchor;
  }

  void _handleAddAnchor(ARKitAnchor anchor) {
    if (!(anchor is ARKitPlaneAnchor)) {
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
}