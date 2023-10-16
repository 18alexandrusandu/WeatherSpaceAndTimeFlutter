import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import "main.dart";

class Favorites extends StatefulWidget {
  const Favorites({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<Favorites> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<Favorites> {
  bool showPictures = false;
  List<MapController> mapcon = <MapController>[];
  List<Image> pictures = <Image>[];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //loadFavorites();
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

          title: Text("Your favorites page"),
        ),
        body: SingleChildScrollView(
            child: favoritesImages.length == 0
                ? Text("No favorites yet")
                : Column(
                    children: favoritesImages.map((elm) {
                    String name = elm;
                    File f = File("storage/emulated/0/Download/$elm");
                    Widget img = Image.file(f, errorBuilder: (a, b, c) {
                      return Icon(Icons.error, color: Colors.red);
                    });
                    return Column(
                      children: [
                        Row(
                          children: [
                            Text(name),
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    favoritesImages.remove(elm);
                                  });
                                  saveFavorites();
                                },
                                icon: const Icon(Icons.star))
                          ],
                        ),
                        img
                      ],
                    );
                  }).toList())
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.

            ));
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
