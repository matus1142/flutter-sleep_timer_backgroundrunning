import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:perfect_volume_control/perfect_volume_control.dart';
import 'package:sleep_timer/volumn.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

//background service knowledge
//https://medium.com/@mustafatahirhussein/using-background-services-in-flutter-77c201f0c1b2

//Use shared_preferences for shared variable between function

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); //initial background service
  await initializeService(); //initial background service
  runApp(const MyApp());
}

// Future<void> readyForShared() async {
//   var sharedPreferences = await SharedPreferences.getInstance();
// }

Future<void> saveDataTimeLeft(String value) async {
  var sharedPreferences = await SharedPreferences.getInstance();
  sharedPreferences.setString("timeLeftString", value);
}

Future<void> saveDataTimeSet(String value) async {
  var sharedPreferences = await SharedPreferences.getInstance();
  sharedPreferences.setString("timeSetString", value);
}

Future<void> saveDataCancelStatus(String value) async {
  var sharedPreferences = await SharedPreferences.getInstance();
  sharedPreferences.setString("CancelStatusString", value);
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: false,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
        // // auto start service
        // autoStart: true,

        // // this will be executed when app is in foreground in separated isolate
        // onForeground: onStart,

        // // you have to enable background fetch capability on xcode project
        // onBackground: onIosBackground,
        ),
  );
  //service.startService();
}

// bool onIosBackground(ServiceInstance service) {
//   WidgetsFlutterBinding.ensureInitialized();
//   print('FLUTTER BACKGROUND FETCH');

//   return true;
// }

int timeLeft = 10 * 60;

final service = FlutterBackgroundService();

void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // bring to foreground
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    var sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.reload(); // Its important
    var TimeoutCheck =
        int.parse(sharedPreferences.getString("timeLeftString").toString());
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Sleep Timer",
        content:
            "${(TimeoutCheck/ 60).ceil()} 分 = ${TimeoutCheck}秒", //if null then display no data
      );
    }

    
    var cancel_status =
        int.parse(sharedPreferences.getString("CancelStatusString").toString());
    if (cancel_status == 1) {
      await saveDataCancelStatus('0');
      service.stopSelf();
    } else if (TimeoutCheck <= 0) {
      await _startCountDown();
      Timer(Duration(seconds: 5), () {
        timeLeft =
            int.parse(sharedPreferences.getString("timeSetString").toString());
        saveDataTimeLeft(timeLeft.toString());
        service.stopSelf(); //stop background service
      });
    } else {
      await _startCountDown(); //execute function _startCountDown
    }

    /// you can see this log in logcat
    print(sharedPreferences.getString("timeLeftString"));
    //print(sharedPreferences.getString("timeSetString"));
    //print('FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');
  });
}

Future _startCountDown() async {
  var sharedPreferences = await SharedPreferences.getInstance();
  timeLeft =
      int.parse(sharedPreferences.getString("timeLeftString").toString());
  if (timeLeft > 0) {
    timeLeft--; //counter timer
    await saveDataTimeLeft(timeLeft.toString());
  } else {
    final session = await AudioSession.instance;
    await session.setActive(true); //for pause music app
    Timer(Duration(seconds: 3), () {
      PerfectVolumeControl.setVolume(0);
    }); //mute volume when timeout

  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SleepTimer(),
    );
  }
}

class SleepTimer extends StatefulWidget {
  @override
  State<SleepTimer> createState() => _SleepTimerState();
}

class _SleepTimerState extends State<SleepTimer> {
  int t_timeLeft = 0;
  int timeset = 0;
  int cancel_status = 0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // readyForShared();
    DisplayCounter(); //Continue counter after clear app
  }

  Future<void> DisplayCounter() async {
    var sharedPreferences = await SharedPreferences.getInstance();
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      await sharedPreferences.reload();
      //reload value of variable in sharedPreferences
      t_timeLeft =
          int.parse(sharedPreferences.getString("timeLeftString").toString());
      //get value from timeLeftString variable
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    void openDialog() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return const Dialog(
              child: Volumn(), //run widget from volumn.dart
            );
          });
    }

    return Scaffold(
      body: Center(
          child: Column(
        children: [
          SizedBox(height: 100),
          Text(
            t_timeLeft <= 0
                ? 'DONE'
                : '${(t_timeLeft / 60).ceil().toString()} min',
            style: TextStyle(fontSize: 50),
          ),
          SizedBox(height: 15),
          Text(
            t_timeLeft <= 0 ? '' : '${t_timeLeft.toString()} s',
            style: TextStyle(fontSize: 50),
          ),
          SizedBox(height: 50),
          MaterialButton(
              child: Text("S T A R T"),
              color: Colors.green,
              onPressed: () async {
                var sharedPreferences = await SharedPreferences.getInstance();
                timeLeft = int.parse(
                    sharedPreferences.getString("timeSetString").toString());
                await saveDataTimeLeft(
                    timeLeft.toString()); //save data to variable timeSetString
                cancel_status = 0;
                await saveDataCancelStatus(cancel_status.toString());
                await service.startService(); //start background service
                FlutterBackgroundService()
                    .invoke("setAsForeground"); //set forground on notification
              }),
          SizedBox(height: 30),
          MaterialButton(
              child: Text("C A N C E L"),
              color: Colors.red.shade200,
              onPressed: () async {
                var sharedPreferences = await SharedPreferences.getInstance();
                timeLeft = int.parse(
                    sharedPreferences.getString("timeLeftString").toString());
                cancel_status = 1;
                await saveDataCancelStatus(cancel_status.toString());
                //service.invoke("stopService"); //stop background service
              }),
          Padding(
            padding: const EdgeInsets.all(70),
            child: TextField(
                onChanged: (value) async {
                  if (value != "") {
                    timeset = int.parse(value) * 60; //sec -> min
                  } else {
                    timeset = 10 * 60; //sec -> min
                  }
                  await saveDataTimeSet(timeset.toString());
                },
                textAlign: TextAlign.center,
                obscureText: false,
                keyboardType: TextInputType.numberWithOptions(
                    signed: false, decimal: false),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Time Minute (default is 10)',
                )),
          ),
        ],
      )),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.volume_up_sharp),
          onPressed: () async {
            openDialog();
          }),
    );
  }
}
