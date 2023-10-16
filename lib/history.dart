import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import "main.dart";

class History extends StatefulWidget {
  const History({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<History> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<History> {
  bool showPictures = false;
  List<MapController> mapcon = <MapController>[];
  List<Image> pictures = <Image>[];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    showPictures = false;

    loadHistory();
  }

  void displayImages() async {
    List<String> uniqueCities = <String>[];
    for (Record record in historicRecord) {
      if (!uniqueCities.contains(record.location))
        uniqueCities.add(record.location);
    }

    for (String city in uniqueCities) {
      int index = 1;
      while (
          await File("storage/emulated/0/Download/$city-$index.jpg").exists()) {
        Image img = Image.memory(
          await File("storage/emulated/0/Download/$city-$index.jpg")
              .readAsBytes(),
          semanticLabel: "$city-$index.jpg",
          fit: BoxFit.cover,
        );
        setState(() {
          pictures.add(img);
        });

        index += 1;
      }
    }
    setState(() {
      showPictures = true;
    });
  }

  Future<void> loadHistory() async {
    File f = File(
        "storage/emulated/0/Download/geolocator_whether_and_time/history_geolocator.json");
    setState(() {
      historicRecord = [];
    });

    String json = await f.readAsString();

    List<dynamic> jsonEnc = jsonDecode(json);
    setState(() {
      historicRecord =
          List<Record>.from(jsonEnc.map((e) => Record.fromJson(e)).toList());
    });

    setState(() {
      for (Record _ in historicRecord) {
        mapcon.add(MapController());
      }
    });
  }

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

          title: Text("Your history page"),

          actions: [
            IconButton(
                onPressed: () {
                  if (showPictures == false) {
                    displayImages();
                  } else {
                    setState(() {
                      showPictures = false;
                    });
                  }
                },
                icon: showPictures
                    ? Icon(Icons.image)
                    : Icon(Icons.image_not_supported))
          ],
        ),
        body: SingleChildScrollView(

            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.

            child: Column(children: [
          Text("Number of events:${historicRecord.length}"),
          Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: historicRecord.map((e) {
                return Column(children: [
                  Text("City;${e.location}"),
                  Text("Country;${e.country}"),
                  Text("Lat.${e.lat},long.${e.long}"),
                  Text("Timestamp:${e.time}"),
                  Text("Weather:${e.weather}"),
                  Text("Temperature: ${e.temperature}"),
                  SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height / 3,
                      child: FlutterMap(
                          mapController: mapcon[historicRecord.indexOf(e)],
                          options: MapOptions(
                              initialZoom: 11,
                              initialCenter: LatLng(e.lat, e.long)),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                              userAgentPackageName: 'com.example.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                    point: LatLng(e.lat, e.long),
                                    height: 15,
                                    width: 15,
                                    child: Icon(Icons.circle,
                                        color: Colors.blue.shade400))
                              ],
                            ),
                          ]))
                ]);
              }).toList()),
          showPictures
              ? Column(
                  children: pictures.map((picture) {
                    return Column(
                        children: [Text(picture.semanticLabel!), picture]);
                  }).toList(),
                )
              : SizedBox.shrink()
        ])));
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
  }
}
