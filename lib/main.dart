import 'dart:async';

import 'package:fire_dec/fireObservation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


/// Create a [AndroidNotificationChannel] for heads up notifications
late AndroidNotificationChannel channel;
/// Initialize the [FlutterLocalNotificationsPlugin] package.
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;


/// Define a top-level named handler which background/terminated messages will
/// call.
///
/// To verify things are working, check out the native platform logs.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print('Handling a background message ${message.messageId}');
  if(message.data['mobile']=='true'){
    channel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: "This channel is used for important notifications.", // description
      importance: Importance.high,
    );

    var flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    flutterLocalNotificationsPlugin.show(
        message.notification.hashCode,
        message.data['title'],
        message.data['body'],
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            // TODO add a proper drawable resource to android, for now using
            //      one that already exists in example app.
            icon: '@mipmap/ic_launcher',
          ),
        ));
    return;
  }


}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (!kIsWeb) {
    channel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: "This channel is used for important notifications.", // description
      importance: Importance.high,
    );

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    /// Create an Android Notification Channel.
    ///
    /// We use this channel in the `AndroidManifest.xml` file to override the
    /// default FCM channel to enable heads up notifications.
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    /// Update the iOS foreground notification presentation options to allow
    /// heads up notifications.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fire detector',
      theme: ThemeData(


        primaryColorDark: Colors.blueGrey,
        primarySwatch: Colors.deepPurple,
      ),
      home: MyHomePage(title: 'Fire Detectors Notifier'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);


  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final fb = FirebaseDatabase.instance;
  final myController = TextEditingController();
  final name = "Name";
  var retrievedName;
  var notifi=true;
  late StreamSubscription streamSubscription;

  List<ListTile> lists = [];
  late String token ;

  @override
  void initState() {
    

    // TODO: implement initState
    super.initState();

    getdata();
    getFCMToken();

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        print(message.data);

        // Navigator.pushNamed(context, '/message',
        //     arguments: MessageArguments(message, true));
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('we have message');
      if(message.data['mobile']=='true'){
        flutterLocalNotificationsPlugin.show(
            message.notification.hashCode,
            message.data['title'],
            message.data['body'],
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                // TODO add a proper drawable resource to android, for now using
                //      one that already exists in example app.
                icon: '@mipmap/ic_launcher',
              ),
            ));
        return;
      }
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                // TODO add a proper drawable resource to android, for now using
                //      one that already exists in example app.
                icon: android.smallIcon,
              ),
            ));
      }

    });

    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    //   print('A new onMessageOpenedApp event was published!');
    //   Navigator.pushNamed(context, '/message',
    //       arguments: MessageArguments(message, true));
    // });
  }

  void getFCMToken ()  {
    FirebaseMessaging.instance.getToken(vapidKey: 'BGpdLRs......').then((tk) {
      if (tk!=null){
        token=tk;
        print(token);
        FirebaseDatabase.instance.reference().child("token/tumzied").set(token);
      }
      print(tk);
    });
  }

   void getdata() {

    //  FirebaseDatabase.instance.reference().child("fire").once().then((DataSnapshot snapshot){
    //   print(snapshot.value);
    // });

      FirebaseDatabase.instance.reference().child("fire").limitToLast(5).orderByChild('timestamp').onChildAdded.forEach((event){

        var fo=FireObservation.json(event.snapshot.value);
        // print(fo.toString());
        //   print(event.snapshot.value);

        setState(() {


          lists=[...lists,
              ListTile( title: Text(fo.observation),
                leading: Icon(
                  Icons.fire_hydrant,
                  color: Colors.redAccent,
                  size: 40.0,
                  textDirection: TextDirection.ltr,
                  semanticLabel: 'Icon', // Announced in accessibility modes (e.g TalkBack/VoiceOver). This label does not show in the UI.
                ),
                subtitle: Text('call your local fire service '),
                trailing: Text(fo.date,style: TextStyle(fontWeight: FontWeight.bold),),
              )

            ];

        });

      });


  }

  @override
  Widget build(BuildContext context) {
    final ref = fb.reference();
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Text("Notification switcher"),
                SizedBox(width: 20),
                // Expanded(child: TextField(controller: myController)),
                Switch(value: notifi, onChanged: (e){
                  ref.child('Notification').set(!notifi);
                      setState(() {
                        notifi=!notifi;
                      });


                })
              ],
            ),
            // ElevatedButton(
            //   onPressed: () {
            //     ref.child(name).set(myController.text);
            //   },
            //   child: Text("Submit"),
            // ),
            SizedBox(height: 50),
            Expanded(
              child: ListView(children: lists.reversed.toList()),
            ),


            // ElevatedButton(
            //   onPressed: () {
            //     ref.child("fire").once().then((DataSnapshot data) {
            //       Map<dynamic, dynamic> values = data.value;
            //       values.forEach((key, value) {
            //         print(value);
            //
            //
            //       });
            //     });
            //     // ref.child('fire').
            //   },
            //   child: Text("retrieve data"),
            // ),
            // Container(
            //   height: 500,
            //   margin: EdgeInsets.fromLTRB(10 , 0 , 10, 0),
            //
            //   child: StreamBuilder(
            //       stream: ref.child('fire').orderByChild('timestamp').limitToLast(5).onChildAdded,
            //       builder: (context, snapshot) {
            //
            //         print((snapshot.data as Event).snapshot.value);
            //
            //         if (snapshot.hasData) {
            //            List<Card> observationValues=[];
                      // final listOfAllTheValues=Map<dynamic,dynamic>.from((snapshot.data as Event).snapshot.value);
                      //  listOfAllTheValues.map((key, value){
                      //   var data = FireObservation.json(value);
                      //   observationValues.add( Card(
                      //     elevation: 5.0,
                      //     margin: EdgeInsets.symmetric(horizontal: 10,vertical: 5),
                      //
                      //     child: Column(
                      //
                      //       crossAxisAlignment: CrossAxisAlignment.start,
                      //       mainAxisAlignment: MainAxisAlignment.spaceAround,
                      //
                      //       children: <Widget>[
                      //         Text("DATETIME: " + data.date),
                      //         Text("observation: ".toUpperCase() + data.observation),
                      //
                      //       ],
                      //     ),
                      //   ));
                      //
                      // var temp=null;
                      // return temp;
                      // });



                  //     return Expanded(
                  //       child: ListView(
                  //         children: [
                  //           ListTile(
                  //             title: Text("this is title"),
                  //           )
                  //         ] ,
                  //       ),
                  //     );
                  //   }
                  //   return SizedBox(height: 50, child: CircularProgressIndicator());
                  // }),
            // ),


          ],
        )));
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }
}
