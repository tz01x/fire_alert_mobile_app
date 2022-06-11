import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class FireObservation{
  final String observation;
  final String date;


  FireObservation({required this.observation, required this.date});

  factory FireObservation.json(Map<dynamic,dynamic>data ){
    int millis= int.parse(data['timestamp'].toString() )*1000 ;
    var dt=DateTime.fromMillisecondsSinceEpoch(millis);
    var d12 = DateFormat('hh:mm a, MM/dd/yyyy').format(dt);
    return FireObservation(observation: data['observation']?? 'False call *', date: d12);

  }

  @override
  String toString() {
    // TODO: implement toString
    return observation+" "+date;
  }


}