import 'dart:async';

import 'package:flutter/material.dart';
import 'package:perfect_volume_control/perfect_volume_control.dart';
import 'package:sleep_timer/volumn.dart';
import 'package:audio_session/audio_session.dart';

//background service knowledge
//https://medium.com/@mustafatahirhussein/using-background-services-in-flutter-77c201f0c1b2

void main() {
  runApp(const MyApp());
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
  int timeLeft = 10 * 60;
  int timeset = 10 * 60;
  int cancel_status = 0;

  Future _startCountDow() async {
    Timer.periodic(Duration(seconds: 1), (timer) async {
      if (timeLeft > 0 && cancel_status == 0) {
        setState(() {
          timeLeft--;
          print(timeLeft);
        });
      } else {
        if (cancel_status != 1) {
          final session = await AudioSession.instance;
          await session.setActive(true); //for pause music app

        } else {
          setState(() {
            timeLeft = timeset;
            cancel_status = 0;
          });
        }

        timer.cancel();
        if (cancel_status != 1) {
          int counter = 5; //delay 5 second after pause then mute
          Timer.periodic(Duration(seconds: 1), (timer) async {
            if (counter > 0) {
              counter--;
            } else {
              PerfectVolumeControl.setVolume(0);
              timer.cancel();
            }
          });
        }
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            timeLeft <= 0 ? 'DONE' : ((timeLeft / 60).ceil()).toString(),
            style: TextStyle(fontSize: 100),
          ),
          MaterialButton(
              child: Text("S T A R T"),
              color: Colors.green,
              onPressed: () {
                timeLeft = timeset;
                setState(() {
                  _startCountDow();
                });
              }),
          MaterialButton(
              child: Text("C A N C E L"),
              color: Colors.red.shade200,
              onPressed: () {
                timeLeft = timeset;
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
          )
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
