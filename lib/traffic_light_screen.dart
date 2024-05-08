import 'package:ar_flutter_plugin_flutterflow/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_flutterflow/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_flutterflow/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_flutterflow/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_flutterflow/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_flutterflow/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_flutterflow/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_flutterflow/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_flutterflow/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_flutterflow/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_flutterflow/models/ar_node.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v;

class ObjectGesturesWidget extends StatefulWidget {
  const ObjectGesturesWidget({super.key});

  @override
  ObjectGesturesWidgetState createState() => ObjectGesturesWidgetState();
}

class ObjectGesturesWidgetState extends State<ObjectGesturesWidget> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];

  final TextEditingController _controller = TextEditingController(text: "");

  bool isObstacleAhead = false;

  @override
  void dispose() {
    arSessionManager?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Train App'),
      ),
      floatingActionButton: IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () {
          _getDataFromCloud();
        },
      ),
      body: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 32),
              const Text("Next station: "),
              const SizedBox(width: 64),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration.collapsed(
                    hintText: "UnionSquare-1A",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    filled: true,
                  ),
                  textAlign: TextAlign.center,
                  onSubmitted: (text) {
                    _getDataFromCloud();
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                ),
              ),
              const SizedBox(width: 32),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: Stack(children: [
              ARView(
                onARViewCreated: onARViewCreated,
                planeDetectionConfig:
                    PlaneDetectionConfig.horizontalAndVertical,
              ),
              Align(
                alignment: FractionalOffset.bottomCenter,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                          onPressed: onRemoveEverything,
                          child: const Text("Remove Everything")),
                    ]),
              )
            ]),
          ),
        ],
      ),
    );
  }

  Future<void> _getDataFromCloud() async {
    final dio = Dio();
    final inputText = _controller.text;
    if (inputText.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Fill in the station")));
      return;
    }

    final response = await dio.get(
        'https://us-east1-trainapi-422319.cloudfunctions.net/train-service-dev-first/$inputText');
    print(response);

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Something went wrong")));
      return;
    }

    setState(() {
      isObstacleAhead = response.data["hasObstacle"];

      final newNodes = List.of(nodes);
      for (final node in newNodes) {
        node.uri = !isObstacleAhead ? "Models/red.gltf" : "Models/green.gltf";
        arObjectManager?.removeNode(node);
        arObjectManager?.addNode(node,
            planeAnchor: anchors.firstOrNull as ARPlaneAnchor?);
      }
      nodes = newNodes;
    });
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager?.onInitialize(
          showFeaturePoints: false,
          showPlanes: false,
          showWorldOrigin: false,
          handlePans: true,
          handleRotation: true,
        );
    this.arObjectManager?.onInitialize();

    this.arSessionManager?.onPlaneOrPointTap = onPlaneOrPointTapped;
    this.arObjectManager?.onPanStart = onPanStarted;
    this.arObjectManager?.onPanChange = onPanChanged;
    this.arObjectManager?.onPanEnd = onPanEnded;
    this.arObjectManager?.onRotationStart = onRotationStarted;
    this.arObjectManager?.onRotationChange = onRotationChanged;
    this.arObjectManager?.onRotationEnd = onRotationEnded;
  }

  Future<void> onRemoveEverything() async {
    for (final node in nodes) {
      arObjectManager?.removeNode(node);
    }

    for (final anchor in anchors) {
      arAnchorManager?.removeAnchor(anchor);
    }
    anchors = [];
    nodes = [];
  }

  Future<void> onPlaneOrPointTapped(
      List<ARHitTestResult> hitTestResults) async {
    var singleHitTestResult = hitTestResults.firstWhereOrNull(
        (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane);
    if (singleHitTestResult != null) {
      var newAnchor =
          ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
      bool? didAddAnchor = await arAnchorManager?.addAnchor(newAnchor);
      if (didAddAnchor == true) {
        anchors.add(newAnchor);
        // Add note to anchor
        var newNode = ARNode(
            type: NodeType.localGLTF2,
            uri: isObstacleAhead ? "Models/red.gltf" : "Models/green.gltf",
            scale: v.Vector3(0.2, 0.2, 0.2),
            position: v.Vector3(0.0, 0.0, 0.0),
            rotation: v.Vector4(1.0, 0.0, 0.0, 0.0));
        bool? didAddNodeToAnchor =
            await arObjectManager?.addNode(newNode, planeAnchor: newAnchor);
        if (didAddNodeToAnchor == true) {
          nodes.add(newNode);
        } else {
          arSessionManager?.onError?.call("Adding Node to Anchor failed");
        }
      } else {
        arSessionManager?.onError?.call("Adding Anchor failed");
      }
    }
  }

  onPanStarted(String nodeName) {
    print("Started panning node $nodeName");
  }

  onPanChanged(String nodeName) {
    print("Continued panning node $nodeName");
  }

  onPanEnded(String nodeName, Matrix4 newTransform) {
    print("Ended panning node $nodeName");
    final pannedNode =
        this.nodes.firstWhere((element) => element.name == nodeName);

    /*
    * Uncomment the following command if you want to keep the transformations of the Flutter representations of the nodes up to date
    * (e.g. if you intend to share the nodes through the cloud)
    */
    //pannedNode.transform = newTransform;
  }

  onRotationStarted(String nodeName) {
    print("Started rotating node $nodeName");
  }

  onRotationChanged(String nodeName) {
    print("Continued rotating node $nodeName");
  }

  onRotationEnded(String nodeName, Matrix4 newTransform) {
    print("Ended rotating node $nodeName");
    final rotatedNode = nodes.firstWhere((element) => element.name == nodeName);

    /*
    * Uncomment the following command if you want to keep the transformations of the Flutter representations of the nodes up to date
    * (e.g. if you intend to share the nodes through the cloud)
    */
    //rotatedNode.transform = newTransform;
  }
}
