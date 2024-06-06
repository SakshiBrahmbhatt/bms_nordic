import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';

class getStarted extends StatefulWidget {
  const getStarted({super.key});

  @override
  State<getStarted> createState() => _getStartedState();
}

class _getStartedState extends State<getStarted> {

  bool onBluetooth = false;

  @override
  void initState() {
    super.initState();
    checkBluetooth();
  }

  Future<void> checkBluetooth() async {
    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      return;
    }
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) async {
      print("Bluetooth Adapter State: $state");
      if (state == BluetoothAdapterState.on) {
        print("Bluetooth is ON");
        setState(() {
          onBluetooth = true;
        });
      } else {
        print("Bluetooth is OFF");
        setState(() {
          onBluetooth = false;
        });
      }
    });

    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }
  }
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top:270,
            left:80,
            child: Text("         BMS\nCONFIGURATOR",
              style: TextStyle(
                fontSize: 30,
                color: Color(0xFF2871E6),
              ),),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                if(onBluetooth) {
                  Navigator.pushNamed(context, "./bluetooth");
                }
                else{
                  Fluttertoast.showToast(
                    msg: 'Please enable Bluetooth on your device',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.white,
                    textColor: Colors.black,
                    fontSize: 16.0,
                  );
                }
              },
              child:Text("Get Started",
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                ),),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2871E6),
              ),
            ),
          ),
          Positioned(
            bottom: 90,
            left:190,
            child: Center(
              child: Text("Made by"),
            ),
          ),
          Positioned(
            bottom: 2,
            child:Container(
              width: size.width,
              height: size.height * 0.15,
              child: Image.asset("assets/images/samudra.png"),
            ),
          ),
        ],
      ),
    );
  }
}





