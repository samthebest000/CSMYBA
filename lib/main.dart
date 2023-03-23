import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'car.dart';

Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<List<Car>> _getAllCars() async {
    var app = App(AppConfiguration("yba-lmcvl"));
    var loggedInUser = await app.logIn(Credentials.anonymous());

    final config = Configuration.flexibleSync(loggedInUser, [Car.schema]);
    final realm = Realm(config);

    realm.subscriptions.update((mutableSubscriptions) {
      mutableSubscriptions.add(realm.query<Car>(r'model == $0', ["Model S"]));
    });
    await realm.subscriptions.waitForSynchronization();

    final cars = realm.all<Car>().toList();

    return cars;
  }

  Future<void> _deleteAllCars() async {
    var app = App(AppConfiguration("yba-lmcvl"));
    var loggedInUser = await app.logIn(Credentials.anonymous());

    final config = Configuration.flexibleSync(loggedInUser, [Car.schema]);
    final realm = Realm(config);

    realm.write(() {
      realm.deleteAll<Car>();
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<Car>>(
        future: _getAllCars(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.isEmpty) {
            return const Center(child: Text("No cars found!"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!;

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("ID: ${data[index].id}"),
                    Text("Make: ${data[index].make}"),
                    Text("model: ${data[index].model}"),
                    Text("miles: ${data[index].miles}"),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _deleteAllCars,
        child: const Icon(Icons.remove),
      ),
    );
  }
}
