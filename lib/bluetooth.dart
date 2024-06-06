import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'ble_controller.dart';

class bluetooth extends StatefulWidget {
  const bluetooth({Key? key}) : super(key: key);


  @override
  State<bluetooth> createState() => _bluetoothState();
}

class _bluetoothState extends State<bluetooth> {
  late BleController controller;
  bool isConnected = false;
  bool isScan = false;
  int val = 0;

  @override
  void initState() {
    super.initState();
    controller = BleController();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "BMS Configurator",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF0058DB),
        leading: Container(
          padding: EdgeInsets.all(10),
          child: Image.asset('assets/images/logo.jpg'),
        ),
      ),
      body: GetBuilder<BleController>(
        init: controller,
        builder: (controller) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 15,
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      child: StreamBuilder<List<ScanResult>>(
                        stream: controller.scanResults,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Column(
                              children: snapshot.data!.map((data) {
                                return ListTile(
                                  title: Text(data.device.name),
                                  subtitle: Text(data.device.id.id),
                                  trailing: Text(data.rssi.toString()),
                                  leading: Radio(
                                    value: data.device,
                                    groupValue: controller.selectedDevice,
                                    onChanged: (BluetoothDevice? value) {
                                      controller.setSelectedDevice(value!);
                                    },
                                  ),
                                );
                              }).toList(),
                            );
                          } else {
                            return Center(child: Text("No Device Found"));
                          }
                        },
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            controller.scanDevices();
                            setState(() {
                              isScan = true;
                            });
                          },
                          child: Text("Scan"),
                        ),
                        SizedBox(width: 15),
                        ElevatedButton(
                          onPressed: () {
                            if (isScan) {
                              if (controller.selectedDevice != null) {
                                controller.connectToDevice(controller.selectedDevice!);
                                Fluttertoast.showToast(
                                  msg: 'Connected to ${controller.selectedDevice!.name}',
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.white,
                                  textColor: Colors.black,
                                  fontSize: 16.0,
                                );
                                setState(() {
                                  isConnected = true;
                                });
                              } else {
                                Fluttertoast.showToast(
                                  msg: 'No device selected',
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.white,
                                  textColor: Colors.black,
                                  fontSize: 16.0,
                                );
                              }
                            } else {
                              Fluttertoast.showToast(
                                msg: 'First click on scan button to discover devices',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.white,
                                textColor: Colors.black,
                                fontSize: 16.0,
                              );
                            }
                          },
                          child: Text("CONNECT"),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (isScan) {
                              if (isConnected) {
                                controller.disconnectToDevice(controller.selectedDevice!);
                                Fluttertoast.showToast(
                                  msg: 'Disconnected from ${controller.selectedDevice!.name}',
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.white,
                                  textColor: Colors.black,
                                  fontSize: 16.0,
                                );
                                setState(() {
                                  isConnected = false;
                                  controller.setSelectedDevice(null);
                                });
                              } else {
                                Fluttertoast.showToast(
                                  msg: 'First connect to the device',
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.white,
                                  textColor: Colors.black,
                                  fontSize: 16.0,
                                );
                              }
                            } else {
                              Fluttertoast.showToast(
                                msg: 'Click Scan Button First and then connect to the device to enable it',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.white,
                                textColor: Colors.black,
                                fontSize: 16.0,
                              );
                            }
                          },
                          child: Text("DISCONNECT"),
                        ),
                        SizedBox(width: 15),
                        ElevatedButton(
                          onPressed: () async{
                            if (isScan) {
                              if (isConnected) {
                                  for(val = 0; val<=20; val++){
                                    if(val == 20) {
                                      await controller
                                          .saveSelectedDeviceToPrefs();
                                      Navigator.pushNamed(
                                          context, './dashboard');
                                    }
                                  }
                              } else {
                                Fluttertoast.showToast(
                                  msg: 'First connect to the device',
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.white,
                                  textColor: Colors.black,
                                  fontSize: 16.0,
                                );
                              }
                            } else {
                              Fluttertoast.showToast(
                                msg: 'Click Scan Button First and then connect to the device to enable it',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.white,
                                textColor: Colors.black,
                                fontSize: 16.0,
                              );
                            }
                          },
                          child: Text("NEXT"),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
