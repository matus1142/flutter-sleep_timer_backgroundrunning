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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(const MyApp());
}

Future<void> readyForShared() async {
  var sharedPreferences = await SharedPreferences.getInstance();
  //counterValue = sharedPreferences.getString("timeLeftString") ?? "0";
}

Future<void> saveData(String value) async {
  var sharedPreferences = await SharedPreferences.getInstance();
  sharedPreferences.setString("timeLeftString", value);
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
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

bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  print('FLUTTER BACKGROUND FETCH');

  return true;
}

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
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Sleep Timer",
        content:
            "${sharedPreferences.getString("timeLeftString") ?? 'no data'}",
      );
    }
    // var timeLeftInt =
    //     int.parse(sharedPreferences.getString("timeLeftString").toString());
    // if (timeLeftInt <= 0) {
    //   final session = await AudioSession.instance;
    //   await session.setActive(true); //for pause music app
    // }

    /// you can see this log in logcat
    // print(timeLeftInt);
    print('FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');
  });
}

int timeLeft = 10 * 60;

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
  // int timeLeft = 10 * 60;
  int timeset = 10 * 60;
  int cancel_status = 0;

  final service = FlutterBackgroundService();
  late final ServiceInstance serviceNotify;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readyForShared();
  }

  Future _startCountDow() async {
    Timer.periodic(Duration(seconds: 1), (timer) async {
      if (timeLeft > 0 && cancel_status == 0) {
        timeLeft--;
        await saveData(timeLeft.toString());

        
        setState(() {});
      } else {
        if (cancel_status != 1) {
          final session = await AudioSession.instance;
          await session.setActive(true); //for pause music app
          Timer(Duration(seconds: 7), () {
            PerfectVolumeControl.setVolume(0);
          });
        } else {
          setState(() {
            timeLeft = timeset;
            cancel_status = 0;
          });
        }
        service.invoke("stopService");
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    void openDialog() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return const Dialog(
              child: Volumn(),
            );
          });
    }

    return Scaffold(
      body: Center(
          child: Column(
        // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(height: 100),
          Text(
            timeLeft <= 0 ? 'DONE' : ((timeLeft / 60).ceil()).toString(),
            style: TextStyle(fontSize: 100),
          ),
          SizedBox(height: 50),
          MaterialButton(
              child: Text("S T A R T"),
              color: Colors.green,
              onPressed: () async {
                timeLeft = timeset;
                await service.startService();
                FlutterBackgroundService().invoke("setAsForeground");
                setState(() {
                  _startCountDow();
                });
              }),
          SizedBox(height: 30),
          MaterialButton(
              child: Text("C A N C E L"),
              color: Colors.red.shade200,
              onPressed: () async {
                timeLeft = timeset;
                var isRunning = await service.isRunning();
                if (isRunning) {
                  service.invoke("stopService");
                }
                setState(() {
                  cancel_status = 1;
                });
              }),
          Padding(
            padding: const EdgeInsets.all(70),
            child: TextField(
                onChanged: (value) {
                  if (value != "") {
                    timeset = int.parse(value) * 60; //sec -> min
                  } else {
                    timeset = 10 * 60; //sec -> min
                  }
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
