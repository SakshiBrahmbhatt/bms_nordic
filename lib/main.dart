// import 'package:bmc_nordic/basicDetails.dart';
import 'package:bmc_nordic/calibration.dart';
import 'package:bmc_nordic/dashboard.dart';
import 'package:bmc_nordic/sensorDetails.dart';
import 'package:bmc_nordic/table.dart';
import 'package:bmc_nordic/voltageDivider.dart';
import 'package:flutter/material.dart';
import 'bluetooth.dart';
import 'getStarted.dart';

void main () {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: getStarted(),
      routes:{
        "./bluetooth": (context) => bluetooth(),
        "./dashboard": (context) => dashboard(),
        // "./basic": (context) => basicDetails(),
        "./calibration": (context) => calibration(),
        "./voltage": (context) => voltageDivider(),
        "./sensor": (context) => sensorDetails(),
        "./table": (context) => table(),
      },
    );
  }
}