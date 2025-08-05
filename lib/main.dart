import "dart:io";
import "dart:async";
import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:network_info_plus/network_info_plus.dart";
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

String address = "localhost";
List<String> messages = [];
void startServer()async{
  NetworkInfo networkInfo = NetworkInfo();
  final String htmlContent = await rootBundle.loadString('html/index.html');
  final String cssContent = await rootBundle.loadString('html/style.css');
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  address = await networkInfo.getWifiIP() ?? "localhost";
  await for(HttpRequest request in server) {
    if(request.method=="GET"){
        switch(request.uri.path) {
          case '/':
            request.response.headers.contentType = ContentType.html;
            request.response.write(htmlContent);
            request.response.close();
            break;
          case '/style.css':
            request.response.headers.contentType = ContentType("text", "css", charset: "utf-8");
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
        messages.add(message);
        
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
    Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Server App"),
      ),
      body: Column(
        children: [
          Text("Server address: $address"),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(messages[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}