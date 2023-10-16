import 'dart:convert';
import "package:permission_handler/permission_handler.dart";
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:camera/camera.dart';
import 'package:geocoding/geocoding.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:geolocator_whether_and_time/history.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:latlong2/latlong.dart';
import 'package:weather/weather.dart';
import 'package:flutter_map/flutter_map.dart';
import 'favorites.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class Record {
  late String country;
  late String location;
  late String time;
  late String weather;
  late String temperature;
  late double lat;
  late double long;

  Map toJson() {
    return {
      "country": country,
      "city": location,
      "time": time,
      "weather": weather,
      "temperature": temperature,
      "lat": lat,
      "long": long,
    };
  }

  Record(this.country, this.location, this.time, this.weather, this.temperature,
      this.lat, this.long) {}

  Record.fromJson(json) {
    country = json["country"];
    location = json["city"];
    time = json["time"];
    weather = json["weather"];
    temperature = json["temperature"];
    lat = json["lat"];
    long = json["long"];
  }
}

List<Record> historicRecord = <Record>[];
List<String> favoritesImages = <String>[];

Future<void> saveFavorites() async {
  File f = File(
      "storage/emulated/0/Download/geolocator_whether_and_time/favorites_images");
  if (!await f.exists()) {
    f.create(recursive: true);
  }

  String composed = "";
  for (String line in favoritesImages) {
    composed += line + "\n";
    f.writeAsString(composed);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Space,Time and Weather'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CameraController camcon;

  bool init = true;
  MapController mapcon = MapController();
  String? city = " ";
  String? country = " ";
  final String key = "5a9cc07b7fa2280961aca00060e3e4cd";
  String time = DateTime.now().toString();
  bool same = true;
  String whether = "cold,shadowy";
  Position? _position = null;
  late Weather savedWeather;
  bool initCamerabool = false;
  bool useCamerabool = false;
  bool useBackCamera = true;
  List<Image> takenpictures = <Image>[];
  Image? wheaterStateIcon = null;
  bool isInitialMap = true;
  _MyHomePageState() {
    camcon = CameraController(cameras[0], ResolutionPreset.max);
    mapcon = MapController();
    init = true;
    isInitialMap = true;
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    File f = File(
        "storage/emulated/0/Download/geolocator_whether_and_time/favorites_images");
    if (await f.exists()) {
      favoritesImages = await f.readAsLines();
      setState(() {});
    }
  }

  void saveHistory() async {
    try {
      File? f = null;
      if (await File(
              "storage/emulated/0/Download/geolocator_whether_and_time/history_geolocator.json")
          .exists()) {
        print("file tehnically exists");
        f = File(
            "storage/emulated/0/Download/geolocator_whether_and_time/history_geolocator.json");
        print("was able to do that");
        String json = await f.readAsString();
        print("read file");

        try {
          List<dynamic> jsonEnc = jsonDecode(json);
          List<Record>? savedHistory = List<Record>.from(
              jsonEnc.map((e) => Record.fromJson(e)).toList());

          for (Record r in savedHistory) {
            if (!historicRecord.contains(r)) {
              historicRecord.add(r);
            }
          }
        } catch (e) {
          print(
              "Data can't  be json encoded which means that likely it is empty");
        }
      } else {
        print("create file");
        f = await File(
                "storage/emulated/0/Download/geolocator_whether_and_time/history_geolocator.json")
            .create(recursive: true);
      }

      String jsonEnc = jsonEncode(historicRecord.map((r) {
        return r.toJson();
      }).toList());

      f.open(mode: FileMode.writeOnly);

      f.writeAsString(jsonEnc);
    } catch (e) {
      print("Database error but move on msg $e");
      AwesomeNotifications().createNotification(
          content: NotificationContent(
              channelKey: "File Action",
              id: 3,
              title: "Database error",
              body:
                  "Database doesn not work, which means you can't use history",
              actionType: ActionType.Default));
    }
  }

  void loadImages(String baseName) async {
    setState(() {
      takenpictures.clear();
    });
    int index = 1;
    print("LOAD IMAGES");
    print("image-name:storage/emulated/0/Download/$baseName-$index.jpg");
    while (await File("storage/emulated/0/Download/$baseName-$index.jpg")
        .exists()) {
      print(
          "found-image-name:storage/emulated/0/Download/$baseName-$index.jpg");

      try {
        Image img = Image.memory(
          await File("storage/emulated/0/Download/$baseName-$index.jpg")
              .readAsBytes(),
          semanticLabel: "$baseName-$index.jpg",
        );

        setState(() {
          takenpictures.add(img);
        });
      } catch (e) {
        print("image fond but can't be read");
      }

      index += 1;
    }
    setState(() {});
  }

  Future<void> initCamera() async {
    await camcon.initialize().then((value) {
      if (!mounted) {
        setState() {
          initCamerabool = true;
        }

        return;
      }
    }).catchError((error) {
      if (error is CameraException) {
        switch (error.code) {
          case 'CameraAccessDenied':
            break;
          default:
            print("unknown error to camera init");
        }
      }
    });
  }

  void getCurrentLocation({String? queryP = null}) async {
    Position? position = null;
    if (queryP == null) {
      position = await determinePosition();
      print("Position");
      if (position != null) {
        print(position);
      } else {
        position = Position(
            longitude: 0.0,
            latitude: 0.0,
            timestamp: DateTime.now(),
            accuracy: 0.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0);
      }
    } else {
      List<Location> locations = await locationFromAddress(queryP);

      if (locations.isNotEmpty) {
        Location loc = locations[(new Random()).nextInt(locations.length)];

        position = Position(
            longitude: loc.longitude,
            latitude: loc.latitude,
            timestamp: DateTime.now(),
            accuracy: 0.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0);
      } else {
        position = Position(
            longitude: 0.0,
            latitude: 0.0,
            timestamp: DateTime.now(),
            accuracy: 0.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0);
      }
    }

    setState(() {
      _position = position;
      time = DateTime.now().toString();
    });

    await doMeteo();

    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.length > 0) {
      setState(() {
        if (!isInitialMap)
          mapcon.move(LatLng(position!.latitude, position.longitude), 11);

        isInitialMap = false;
        if (placemarks[0].country != country ||
            placemarks[0].locality != city) {
          if (placemarks[0].locality != null) {
            generateNotification();

            ///gnerate notification
          }
          country = placemarks[0].country!;
          city = placemarks[0].locality!;
          loadImages(placemarks[0].locality!);
          historicRecord.add(Record(
              country!,
              city!,
              time,
              savedWeather.weatherDescription!,
              savedWeather.temperature!.toString(),
              _position!.latitude,
              _position!.longitude));
        }
      });
      try {
        final permission = Permission.manageExternalStorage;

        if (await permission.isDenied) {
          permission.request();
        }

        saveHistory();
      } catch (e) {
        print("error but move on");
      }
    }
  }

  Future<Position?> determinePosition() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied)
      permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied)
      ;
    else
      return await Geolocator.getCurrentPosition();

    return null;
  }

  Future<void> doMeteo() async {
    WeatherFactory wf = WeatherFactory(key);
    Weather w = await wf.currentWeatherByLocation(
        _position!.latitude, _position!.longitude);
    setState(() {
      savedWeather = w;
      wheaterStateIcon = Image.network(
          "http://openweathermap.org/img/w/${w.weatherIcon}.png",
          fit: BoxFit.cover);
      whether = "Weather description:${w.weatherMain}\n";
      whether += "more:${w.weatherDescription}\n";
      whether += "Weather code:${w.weatherConditionCode}\n";
      whether += "Temperature:${w.temperature}\n";
      whether += "Temp. min.:${w.tempMin}\n";
      whether += "Temp. max.:${w.tempMax}\n";
      whether += "Temp. feels like.:${w.tempFeelsLike}\n";
      whether +=
          "Wind:speed:${w.windSpeed},degree:${w.windDegree},gust:${w.windGust}\n";
      whether += "Humidity:${w.humidity} %\n";
      whether += "Presure:${w.pressure} Pascal \n";
      whether += "Chances of rain in next 3 h:${w.rainLast3Hours} mm\n";
      whether += "Chances of snow:${w.snowLast3Hours} mm\n";

      if (w.date!.isBefore(w.sunset!)) {
        whether += "Sunrise:${w.sunrise}\n";
      }
      whether += "Sunset:${w.sunset}\n";
    });
  }

  void generateNotification() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
          channelKey: "You are out of city",
          channelName: "channel_1",
          channelDescription: "empty not ",
          defaultColor: Colors.green,
          channelGroupKey: "basic_channel_group"),
      NotificationChannel(
          channelKey: "File Action",
          channelName: "channel_2",
          channelDescription: "channel for file actions ",
          defaultColor: Colors.green,
          channelGroupKey: "basic_channel_group"),
    ], channelGroups: [
      NotificationChannelGroup(
          channelGroupKey: "basic_channel_group",
          channelGroupName: "Basic group")
    ]);
    print("init done");
    await AwesomeNotifications().isNotificationAllowed().then(
      (value) async {
        if (!value) {
          await AwesomeNotifications().requestPermissionToSendNotifications();
        }
      },
    );
    AwesomeNotifications().setListeners(
        onNotificationCreatedMethod: (data) async {
      // print("created  $data");
    }, onNotificationDisplayedMethod: (data) async {
      // print("displayed  $data");
    }, onActionReceivedMethod: (event) async {
      // print("Event now:$event");
      useCamera();
    });

    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            channelKey: "You are out of city",
            id: -1,
            title: "Out of city, make a new memory",
            body: "You are now in the country $country" +
                " and  location $city, you changed your previous location, make a photo to capture the moment",
            actionType: ActionType.Default),
        actionButtons: [
          NotificationActionButton(key: "open", label: "Make a picture")
        ]);
  }

  void generateNotificationSimple() async {
    var adetail = AndroidNotificationDetails(
      "You are out of city",
      "channel_1",
      playSound: true,
      importance: Importance.high,
      priority: Priority.high,
    );
    var notd = NotificationDetails(
        android: adetail,
        iOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails());
    var plugin = FlutterLocalNotificationsPlugin();
    plugin.initialize(InitializationSettings(
        android: AndroidInitializationSettings('mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        linux:
            LinuxInitializationSettings(defaultActionName: "Make a picture")));
    plugin.show(
        0,
        "Out of city, make a new memory",
        "You are now in the country $country" +
            " and  location $city, you changed your previous location, make a photo to capture the moment",
        notd);
  }

  void useCamera() async {
    await initCamera();

    setState(() {
      useCamerabool = true;
    });
  }

  void changeCamera() async {
    setState(() {
      useBackCamera = !useBackCamera;
    });
    if (useBackCamera) {
      setState(() {
        camcon = CameraController(cameras[0], ResolutionPreset.max);
      });
      await initCamera();
      setState(() {});
    } else {
      setState(() {
        camcon = CameraController(cameras[1], ResolutionPreset.max);
      });
      await initCamera();
      setState(() {});
    }
  }

  void _incrementCounter() {
    setState(() {
      init = false;
    });
    getCurrentLocation();
  }

  void takePictureAndSave() async {
    XFile img = await camcon.takePicture();

    // print(img.path);
    int number = 1;
    String pathF = "storage/emulated/0/Download/$city-$number.jpg";
    while (File(pathF).existsSync()) {
      number += 1;
      pathF = "storage/emulated/0/Download/$city-$number.jpg";
    }

    img.saveTo(pathF);
    Image imgs = Image.memory(await img.readAsBytes(),
        semanticLabel: "$city-$number.jpg");

    setState(() {
      takenpictures.add(imgs);
      useCamerabool = false;
    });
  }

  String query = "";
  bool _SEARCH = false;
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
          // TRY THIS: Try changing the color here to a specific color (to
          // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
          // change color while the other colors stay the same.
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          leading: (_SEARCH != false)
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      _SEARCH = false;
                    });
                  },
                  icon: Icon(Icons.arrow_back))
              : null,
          title: (_SEARCH == false)
              ? Text(widget.title)
              : TextField(
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      query = value;
                    });
                  },
                  onEditingComplete: () {
                    _SEARCH = false;
                    init = false;
                    getCurrentLocation(queryP: query);
                  },
                ),
          actions: (_SEARCH == false)
              ? [
                  IconButton(
                      onPressed: () {
                        setState(() {
                          _SEARCH = true;
                        });
                      },
                      icon: Icon(Icons.search)),
                  PopupMenuButton(
                      child: const Icon(Icons.menu),
                      itemBuilder: (context) {
                        return [
                          PopupMenuItem(
                              child: IconButton(
                                  onPressed: useCamera,
                                  icon: Icon(Icons.camera_alt_rounded))),
                          PopupMenuItem(
                              child: IconButton.filled(
                                  onPressed: () {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (build) {
                                      //load history
                                      return const History();
                                    }));
                                  },
                                  icon: Icon(Icons.history))),
                          PopupMenuItem(
                              child: IconButton(
                                  onPressed: () async {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (builder) {
                                      return Favorites();
                                    }));
                                  },
                                  icon: Icon(Icons.star,
                                      color: const Color.fromARGB(
                                          255, 255, 208, 0)))),
                        ];
                      })
                ]
              : []),
      body: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              // Center is a layout widget. It takes a single child and positions it
              // in the middle of the parent.
              child: init
                  ? const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                          Text("Instructions", style: TextStyle(fontSize: 28)),
                          Text(
                              "The app provides the time , location and whether informations for geographical locations"),
                          Row(children: [
                            Text(
                                "To allow the app to show data about your current location push"),
                            Icon(Icons.add),
                            Text("found floating at bottom of screen")
                          ]),
                          Row(children: [
                            Text("To search a specific location press"),
                            Icon(Icons.search),
                            Text("found in app bar  and complete the text box")
                          ]),
                          Row(children: [
                            Text("To check more functionalities  press"),
                            Icon(Icons.menu),
                            Text("found in app bar")
                          ]),
                          Row(children: [
                            Text(
                                "To check the history of all the checked locations  with their times press:"),
                            Icon(Icons.history),
                            Text("found in menu"),
                            Icon(Icons.menu)
                          ]),
                          Row(children: [
                            Text(
                                "To check the selected favorite images press:"),
                            Icon(Icons.star, color: Colors.yellow),
                            Text("found in menu"),
                            Icon(Icons.menu)
                          ]),
                          Row(children: [
                            Text(
                                "To a photo as memory for the given location press:"),
                            Icon(Icons.camera_alt),
                            Text("found in menu"),
                            Icon(Icons.menu)
                          ]),
                          Row(children: [
                            Text(
                                "To add or remove image to or from favorites press:"),
                            Icon(Icons.star, color: Colors.yellow),
                            Text("or"),
                            Icon(Icons.star_border),
                            Text("found next to images"),
                          ]),
                          Row(children: [
                            Text(
                                "To completely delete image from device press:"),
                            Icon(Icons.close, color: Colors.red),
                            Text("found next to images"),
                          ]),
                          Row(children: [
                            Text(
                                "In history to see pictures press on the icon"),
                            Icon(Icons.image_not_supported),
                            Text(" and to disable press on"),
                            Icon(Icons.image),
                            Text("found in app bar"),
                          ]),
                        ])
                  : Column(
                      // Column is also a layout widget. It takes a list of children and
                      // arranges them vertically. By default, it sizes itself to fit its
                      // children horizontally, and tries to be as tall as its parent.
                      //
                      // Column has various properties to control how it sizes itself and
                      // how it positions its children. Here we use mainAxisAlignment to
                      // center the children vertically; the main axis here is the vertical
                      // axis because Columns are vertical (the cross axis would be
                      // horizontal).
                      //
                      // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
                      // action in the IDE, or press "p" in the console), to see the
                      // wireframe for each widget.
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                          useCamerabool != false
                              ? Container(
                                  height: MediaQuery.of(context).size.height /
                                      100 *
                                      60,
                                  width: MediaQuery.of(context).size.width /
                                      100 *
                                      80,
                                  child: CameraPreview(camcon))
                              : const SizedBox.shrink(),
                          Row(children: [
                            useCamerabool != false
                                ? ElevatedButton(
                                    onPressed: takePictureAndSave,
                                    child: Icon(Icons.camera))
                                : const SizedBox.shrink(),
                            useCamerabool != false
                                ? ElevatedButton(
                                    onPressed: changeCamera,
                                    child: useBackCamera
                                        ? (Icon(Icons.rotate_right_sharp))
                                        : Icon(Icons.rotate_left_sharp))
                                : const SizedBox.shrink()
                          ]),
                          const Text('Your locaion is :'),
                          Text('$_position'),
                          _position != null
                              ? SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  height:
                                      MediaQuery.of(context).size.height / 3,
                                  child: FlutterMap(
                                      mapController: mapcon,
                                      options: MapOptions(
                                          initialZoom: 11,
                                          initialCenter: latLng.LatLng(
                                              _position!.latitude,
                                              _position!.longitude)),
                                      children: [
                                        TileLayer(
                                          urlTemplate:
                                              "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                                          userAgentPackageName:
                                              'com.example.app',
                                        ),
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                                point: latLng.LatLng(
                                                    _position!.latitude,
                                                    _position!.longitude),
                                                height: 15,
                                                width: 15,
                                                child: Icon(Icons.circle,
                                                    color:
                                                        Colors.blue.shade400))
                                          ],
                                        ),
                                      ]))
                              : Text("no position provided"),
                          Text('Country $country'),
                          Text('City $city'),
                          Text('Time $time'),
                          wheaterStateIcon != null
                              ? SizedBox(
                                  width: MediaQuery.of(context).size.width / 2,
                                  height:
                                      2 / 3 * MediaQuery.of(context).size.width,
                                  child: wheaterStateIcon)
                              : SizedBox.shrink(),
                          Text("$whether"),
                          Column(
                              children: takenpictures.map((element) {
                            return Column(children: [
                              element.semanticLabel != null
                                  ? Text(element.semanticLabel!)
                                  : const Text("no name"),
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                80 /
                                                100,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                60 /
                                                100,
                                        child: element),
                                    Column(children: [
                                      IconButton(
                                          onPressed: () async {
                                            await showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: Text(
                                                        "DO you really want to delete file ${element.semanticLabel}"),
                                                    actions: [
                                                      ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: Text("No")),
                                                      ElevatedButton(
                                                          onPressed: () async {
                                                            String path =
                                                                "storage/emulated/0/Download/${element.semanticLabel}";
                                                            print(
                                                                "i do not know but try to delete");

                                                            if (await File(path)
                                                                .exists()) {
                                                              print(
                                                                  "FILE EXISTS");

                                                              await (await File(
                                                                          path)
                                                                      .create(
                                                                          recursive:
                                                                              true))
                                                                  .delete();

                                                              await AwesomeNotifications()
                                                                  .createNotification(
                                                                content:
                                                                    NotificationContent(
                                                                        channelKey:
                                                                            "File Action",
                                                                        id: 3,
                                                                        title:
                                                                            "A File was deleted from Downlods",
                                                                        body:
                                                                            '''The file with name ${element.semanticLabel} and path:
                                storage/emulated/0/Download/${element.semanticLabel} was succesfully deleted from device''',
                                                                        actionType:
                                                                            ActionType.Default),
                                                              );

                                                              setState(() {
                                                                takenpictures
                                                                    .remove(
                                                                        element);
                                                              });

                                                              Navigator.pop(
                                                                  context);
                                                            } else {
                                                              print(
                                                                  "file not found");
                                                              showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (builder) {
                                                                    return AlertDialog(
                                                                      title: Text(
                                                                          "File not found"),
                                                                      actions: [
                                                                        ElevatedButton(
                                                                            onPressed:
                                                                                () {
                                                                              Navigator.pop(context);
                                                                            },
                                                                            child:
                                                                                Text("close"))
                                                                      ],
                                                                    );
                                                                  });
                                                            }
                                                          },
                                                          child:
                                                              Text("Delete")),
                                                    ],
                                                  );
                                                });
                                          },
                                          icon: Icon(
                                            Icons.close,
                                            color: Colors.red,
                                          )),
                                      IconButton(
                                          onPressed: () {
                                            setState(() {
                                              if (favoritesImages.contains(
                                                  element.semanticLabel)) {
                                                favoritesImages.remove(
                                                    element.semanticLabel!);
                                                saveFavorites();
                                              } else {
                                                favoritesImages.add(
                                                    element.semanticLabel!);
                                                saveFavorites();
                                              }
                                            });
                                          },
                                          icon: favoritesImages.contains(
                                                  element.semanticLabel)
                                              ? Icon(Icons.star,
                                                  color: Colors.yellow)
                                              : Icon(Icons.star_border))
                                    ])
                                  ])
                            ]);
                          }).toList())
                        ]))),

      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
