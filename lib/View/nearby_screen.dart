import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:indoor_location/models/app_state_model.dart';
import 'package:indoor_location/models/beacon_info.dart';
import 'package:indoor_location/models/ranged_beacon_data.dart';
import 'package:indoor_location/UmbrellaBeaconTools/localization_algorithms.dart';
import 'package:indoor_location/UmbrellaBeaconTools/umbrella_beacon.dart';
import 'package:indoor_location/widgets.dart';
import 'package:wakelock/wakelock.dart';
import '../styles.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({Key? key}) : super(key: key);

  @override
  NearbyScreenState createState() {
    return NearbyScreenState();
  }
}

class NearbyScreenState extends State<NearbyScreen> {
  String? beaconStatusMessage;
  AppStateModel appStateModel = AppStateModel.instance;

  Localization localization = Localization();

  Map<String, double>? wtCoordinates;
  Map<String, double>? minMaxCoordinates;

  Map<String, RangedBeaconData> rangedAnchorBeacons = {};

  RangedBeaconData? rbd;
  UmbrellaBeacon? umbrellaBeacon = UmbrellaBeacon.instance;

  FlutterBlue flutterBlue = FlutterBlue.instance;

  // Scanning
  StreamSubscription? beaconSubscription;
  Map<int, Beacon> beacons = {};

  // ignore: cancel_subscriptions
  StreamSubscription? networkChanges;
  ConnectivityResult connectivityResult = ConnectivityResult.none;

  // State
  StreamSubscription? bluetoothChanges;
  BluetoothState blState = BluetoothState.unknown;

  @override
  void initState() {
    super.initState();

    // Subscribe to state changes
    bluetoothChanges = flutterBlue.state.listen((s) {
      setState(() {
        blState = s;
        debugPrint("Bluetooth State changed");
        if (blState == BluetoothState.on) {
          appStateModel.bluetoothEnabled = true;
          debugPrint("Bluetooth is on");
        } else {
          appStateModel.bluetoothEnabled = false;
        }
      });
    });

    networkChanges = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      setState(() {
        connectivityResult = result;
        if (connectivityResult == ConnectivityResult.wifi ||
            connectivityResult == ConnectivityResult.mobile) {
          appStateModel.wifiEnabled = true;
          debugPrint("Network connected");
        } else {
          appStateModel.isScanning = false;
          appStateModel.wifiEnabled = false;
          stopScan();
        }
      });
    });

    Wakelock.enable();

    appStateModel.checkGPS();
  }

  @override
  void dispose() {
    debugPrint("dispose() called");
    beacons.clear();
    bluetoothChanges?.cancel();
    bluetoothChanges = null;
    beaconSubscription?.cancel();
    beaconSubscription = null;
    super.dispose();
  }

  startScan() {
    if (kDebugMode) {
      print("Scanning now");
    }

    if (umbrellaBeacon == null) {
      if (kDebugMode) {
        print('BleManager is null!');
      }
    } else {
      appStateModel.isScanning = true;
    }

    umbrellaBeacon?.scan(FlutterBlue.instance).then((beacon) {
      setState(() {
        beacons[beacon.hash] = beacon;
      });
    });
  }

  stopScan() {
    if (kDebugMode) {
      print("Scan stopped");
    }
    beaconSubscription?.cancel();
    beaconSubscription = null;
    setState(() {
      appStateModel.isScanning = false;
    });
  }

  buildRangedBeaconTiles() {
    List<BeaconInfo> anchorBeacons = AppStateModel.instance.getAnchorBeacons();

    return beacons.values.map<Widget>((b) {
      if (b is EddystoneUID) {
        for (var pBeacon in anchorBeacons) {
          if (pBeacon.beaconUUID == b.namespaceId) {
            //beaconDebugInfo(pBeacon, b);

            // If beacon has already been added, update lists and upload to database
            // else, create a new RangedBeaconInfo obj and add that

            if (!rangedAnchorBeacons.containsKey(pBeacon.beaconUUID)) {
              rbd =
                  RangedBeaconData(pBeacon.phoneMake, pBeacon.beaconUUID, b.tx);
              rbd?.addRawRssi(b.rawRssi);
              rbd?.addRawRssiDistance(b.rawRssiLogDistance);
              rbd?.addkfRssi(b.kfRssi);
              rbd?.addkfRssiDistance(b.kfRssiLogDistance);

              rbd?.x = pBeacon.x;
              rbd?.y = pBeacon.y;

              rangedAnchorBeacons[pBeacon.beaconUUID] = rbd!;
            } else {
              rbd = rangedAnchorBeacons[pBeacon.beaconUUID];
              rbd?.addRawRssi(b.rawRssi);
              rbd?.addRawRssiDistance(b.rawRssiLogDistance);
              rbd?.addkfRssi(b.kfRssi);
              rbd?.addkfRssiDistance(b.kfRssiLogDistance);

              rangedAnchorBeacons[pBeacon.beaconUUID] = rbd!;
            }

            Map<RangedBeaconData, double> rbdDistance = {
              rbd!: b.kfRssiLogDistance
            };

            localization.addAnchorNode(rbd!.beaconUUID, rbdDistance);
            if (localization.conditionsMet) {
              // print("Enough beacons for trilateration");

              wtCoordinates = localization.WeightedTrilaterationPosition();
              appStateModel.addWTXY(wtCoordinates);

              minMaxCoordinates = localization.MinMaxPosition();
              appStateModel.addMinMaxXY(minMaxCoordinates);
            }

            Timer(
                const Duration(seconds: 1),
                () => appStateModel.uploadRangedBeaconData(
                    rbd!, "${pBeacon.phoneMake}+${pBeacon.beaconUUID}"));

            return RangedBeaconCard(beacon: rbd!);
          }
        }
      }
      return const Card();
    }).toList();
  }

  buildScanButton() {
    if (appStateModel.isScanning) {
      return FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: () {
          stopScan();
          setState(() {
            appStateModel.isScanning = false;
          });
        },
        child: const Icon(Icons.stop),
      );
    } else {
      return FloatingActionButton(
          backgroundColor: Colors.greenAccent,
          onPressed: () {
            appStateModel.checkGPS();
            appStateModel.checkLocationPermission();
            if (appStateModel.wifiEnabled &
                appStateModel.bluetoothEnabled &
                appStateModel.gpsEnabled &
                appStateModel.gpsAllowed) {
              startScan();
              setState(() {
                appStateModel.isScanning = true;
              });
            } else if (!appStateModel.gpsAllowed) {
              showGenericDialog(context, "Location Permission Required",
                  "Location is needed to scan a beacon");
            } else {
              showGenericDialog(
                  context,
                  "Wi-Fi, Bluetooth and GPS need to be on",
                  'Please check each of these in order to scan');
            }
          },
          child: const Icon(Icons.search));
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> tiles = [];

    tiles.addAll(buildRangedBeaconTiles());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: createMaterialColor(const Color(0xFFE8E6D9)),
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Text(
              'Umbrella',
              style: TextStyle(color: Colors.black),
            ),
            Image(image: AssetImage('assets/icons8-umbrella-24.png'))
          ],
        ),
      ),
      floatingActionButton: buildScanButton(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          (rangedAnchorBeacons.length < 3)
              ? buildInfoTitle(context,
                  "You need ${3 - rangedAnchorBeacons.length} more anchor nodes for position estimate")
              : buildInfoTitle(context,
                  "Estimated Trilateration position: ${wtCoordinates!['x']!.toStringAsFixed(4)} , ${wtCoordinates!['y']!.toStringAsFixed(4)}\n\nEstimated in Ma position: ${minMaxCoordinates!['x']!.toStringAsFixed(4)} , ${minMaxCoordinates!['y']!.toStringAsFixed(4)}"),
          (connectivityResult == ConnectivityResult.none)
              ? buildAlertTile(context, "Wifi equird to send beacon data")
              : Container(),
          (appStateModel.isScanning) ? buildProgressBarTile() : Container(),
          (blState != BluetoothState.on)
              ? buildAlertTile(context, "Please check that Bluetooth is on")
              : Container(),
          Expanded(
            child: ListView(
              children: tiles,
            ),
          )
        ],
      ),
    );
  }
}
