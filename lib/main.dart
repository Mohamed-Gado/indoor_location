import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:indoor_location/app.dart';
import 'package:indoor_location/firebase_options.dart';
import 'package:provider/provider.dart';
import 'models/app_state_model.dart';
import 'package:flutter/cupertino.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  return runApp(
    ChangeNotifierProvider<AppStateModel>(
      create: (context) => AppStateModel.instance,
      child: const UmbrellaMain(),
    ),
  );
}
