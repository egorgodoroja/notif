import "dart:io";
import "dart:async";
import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";

void main() {
  runApp(const MyApp());
  if(Platform.isIOS){
    initNotifications();
  }
  startServer();
}

FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

  const InitializationSettings initializationSettings =
      InitializationSettings(iOS: initializationSettingsIOS);

  await notifications.initialize(initializationSettings);

  // Запрос разрешений
  final bool? granted = await notifications
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
}

List<Rx> rxs = [];

class Rx<T> {
  T _value;
  Rx(this._value){
    rxs.add(this);
  }
  StreamController _controller = StreamController();
  set value(T newValue) {
    _value = newValue;
    _controller.add(1);
  }
  T get value => _value;
  Stream get stream => _controller.stream;
}


extension MyObject on Object{
  Rx get obs => Rx(this);
}

final address = Rx("");

final messages = <String>[].obs;

void startServer()async{
  final String htmlContent = await rootBundle.loadString('assets/index.html');
  final String cssContent = await rootBundle.loadString('assets/style.css');
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  address.value = server.address.address;
  await for(HttpRequest request in server) {
    if(request.method=="GET"){
        switch(request.uri.path) {
          case '/':
            request.response.headers.contentType = ContentType.html;
            request.response.write(htmlContent);
            request.response.close();
            break;
          case '/style.css':
            request.response.headers.contentType = ContentType("text", "css");
            request.response.write(cssContent);
            request.response.close();
            break;
          default:
            request.response.statusCode = HttpStatus.notFound;
            request.response.write('404 Not Found');
            request.response.close();
        } 
      }else if(request.method=="POST"){
        final content = await utf8.decoder.bind(request).join();
        await request.response.close();

        // Преобразуем строку в Map
        final formData = Uri.splitQueryString(content);
        final message = formData['message'] ?? 'неизвестно';
        
        await notifications.show(
        0,
        'Форма получена',
        message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'form_channel',
            'Form Channel',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Server App',
      home: const Home()
    );
  }
}

class Home extends StatefulWidget{
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home>{
  @override
  void initState() {
    super.initState();
    for (var rx in rxs) {
      rx.stream.listen((_) {
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Server App"),
      ),
      body: Column(
        children: [
          Text("Server address: ${address.value}"),
          Expanded(
            child: ListView.builder(
              itemCount: messages.value.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(messages.value[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}