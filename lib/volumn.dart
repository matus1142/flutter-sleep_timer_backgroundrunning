import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:perfect_volume_control/perfect_volume_control.dart';

class Volumn extends StatefulWidget {
  const Volumn({super.key});

  @override
  State<Volumn> createState() => _VolumnState();
}

class _VolumnState extends State<Volumn> {
  @override
  double currentvol = 0.0;
  void initState() {
    // TODO: implement initState
    super.initState();
    PerfectVolumeControl.hideUI = false; 
    // set if system ui is hided or not no volume up/down
    Future.delayed(Duration.zero,() async{
      currentvol = await PerfectVolumeControl.getVolume();
      print("current volume = ${currentvol}");
      setState(() {
        //refresh UI
      });
    });

    PerfectVolumeControl.stream.listen((Volumn) {
      //refresh UI when use volume up/down button from smartphone
      setState(() {
        currentvol =  Volumn;
      });
     });

  }

  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 100,
      child: Column(
        children: [
          Text("Volume"),
          Slider(
            value: currentvol, 
            onChanged: (Volumn){
              currentvol = Volumn;
              PerfectVolumeControl.setVolume(Volumn);
              setState(() {
                
              });
            },
            min:0,
            max: 1,
            divisions: 100,
            )
        ],),
    );
  }
}