import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'ble_controller.dart';

class voltageDivider extends StatefulWidget {
  const voltageDivider({super.key});

  @override
  State<voltageDivider> createState() => _voltageDividerState();
}

class _voltageDividerState extends State<voltageDivider> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("BMS Configurator",
            style: TextStyle(color: Colors.white)
        ),
        backgroundColor: Color(0xFF0058DB),
        leading: Container(
          padding: EdgeInsets.all(10),
          child: Image.asset('assets/images/logo.jpg'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: MyForm(),
      ),
    );
  }
}


class MyForm extends StatefulWidget {
  @override
  _MyFormState createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final TextEditingController selectedValue1 = TextEditingController();
  // final TextEditingController selectedValue2 = TextEditingController();
  // final TextEditingController selectedValue = TextEditingController();
  final TextEditingController minValue1 = TextEditingController();
  // final TextEditingController minValue2 = TextEditingController();
  final TextEditingController ADCValue1 = TextEditingController();
  // final TextEditingController ADCValue2 = TextEditingController();

  late BleController bleController;
  late Future<DeviceInfo> deviceInfoFuture;
  @override
  void initState() {
    super.initState();

    bleController = BleController();
    deviceInfoFuture = loadDeviceInfo() ;

  }

  Future<DeviceInfo> loadDeviceInfo() async {
    BluetoothDevice? selectedDevice = await bleController.loadSelectedDeviceFromPrefs();
    return DeviceInfo(selectedDevice!);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DeviceInfo>(
      future: deviceInfoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          DeviceInfo deviceInfo = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              children: [
                // Heading
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'RTD Calibration',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // buildTextFieldWithButtons('RTD Select', selectedValue,'@RTDSEL',bleController,deviceInfo.device),
                buildTextFieldWithButtons('Scale Factor 1', selectedValue1,'@VDRTD1',bleController,deviceInfo.device),
                // buildTextFieldWithButtons('Scale Factor 2', selectedValue2,'@VDRTD2',bleController,deviceInfo.device),
                buildTextFieldWithButtons('MIN TEMP 1', minValue1,'@TEMP1MIN',bleController,deviceInfo.device),
                // buildTextFieldWithButtons('MIN TEMP 2', minValue2,'@TEMP2MIN',bleController,deviceInfo.device),
                buildTextFieldWithButtons('ADC Value 1', ADCValue1,'@TEMP1LVAL',bleController,deviceInfo.device),
                // buildTextFieldWithButtons('ADC Value 2', ADCValue2,'@TEMP2LVAL',bleController,deviceInfo.device),
              ],
            ),
          );
        }
      },
    );
  }
  Widget buildTextFieldWithButtons(String labelText, TextEditingController controller, String data, BleController bleController, BluetoothDevice name) {
    late String dataToSend;
    String value = ' ';
    return GetBuilder<BleController>(
      init: bleController,
      builder: (bleController) {
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(labelText: labelText),
              ),
            ),
            SizedBox(width: 8.0),
            ElevatedButton(
              onPressed: () async{
                dataToSend = data + '?' + '\n\r';
                bleController.sendMessage(name, dataToSend);
                value = await bleController.subscribeToNotifications(name);
                const Duration timeoutDuration = Duration(seconds: 15);
                const Duration delayBetweenRetries = Duration(seconds: 1);
                DateTime startTime = DateTime.now();

                while (DateTime.now().difference(startTime) < timeoutDuration) {
                  value = await bleController.subscribeToNotifications(name);

                  if (!value.isEmpty) {
                    setState(() {
                      controller.text = value;
                      value = ' ';
                    });
                    break; // Exit the loop if a response is received
                  }

                  await Future.delayed(delayBetweenRetries);
                }

                if (value.isEmpty) {
                  // Handle the case where no response is received within the timeout
                  setState(() {
                    Fluttertoast.showToast(
                      msg: 'Timeout: No response received within 15 seconds.',
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.white,
                      textColor: Colors.black,
                      fontSize: 16.0,
                    );
                  });
                }

                print('Receive $labelText: ${controller.text}');
              },
              child: Text('Receive'),
            ),
            SizedBox(width: 8.0),
            ElevatedButton(
              onPressed: () async{
                if (!controller.text.isEmpty) {
                  dataToSend = data + ' ' + controller.text + '\n\r';
                  bleController.sendMessage(name, dataToSend);
                  value = await bleController.subscribeToNotifications(name);
                  const Duration timeoutDuration = Duration(seconds: 15);
                  const Duration delayBetweenRetries = Duration(seconds: 1);
                  DateTime startTime = DateTime.now();

                  while (DateTime.now().difference(startTime) < timeoutDuration) {
                    value = await bleController.subscribeToNotifications(name);

                    if (!value.isEmpty) {
                      setState(() {
                        Fluttertoast.showToast(
                          msg: value,
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.white,
                          textColor: Colors.black,
                          fontSize: 16.0,
                        );
                        controller.text = '';
                        value = ' ';
                      });
                      break; // Exit the loop if a response is received
                    }

                    await Future.delayed(delayBetweenRetries);
                  }

                  if (value.isEmpty) {
                    // Handle the case where no response is received within the timeout
                    setState(() {
                      Fluttertoast.showToast(
                        msg: 'Timeout: No response received within 15 seconds.',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.white,
                        textColor: Colors.black,
                        fontSize: 16.0,
                      );
                    });
                  }

                  print('Send $labelText: $dataToSend');
                }

                else{
                  Fluttertoast.showToast(
                    msg: 'Enter the value to send msg',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.white,
                    textColor: Colors.black,
                    fontSize: 16.0,
                  );
                }
              },
              child: Text('Send'),
            ),
          ],
        );
      },
    );
  }
}

class DeviceInfo {
  final BluetoothDevice device;

  DeviceInfo(this.device);
}