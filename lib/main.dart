import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:realm/realm.dart';
import 'car.dart';

late Realm _realm;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var app = App(AppConfiguration("yba-lmcvl"));
  var loggedInUser = await app.logIn(Credentials.anonymous());

  final config = Configuration.flexibleSync(loggedInUser, [Car.schema]);
  _realm = Realm(config);

  _realm.subscriptions.update((mutableSubscriptions) {
    mutableSubscriptions.add(_realm.query<Car>(r'miles > $0', [0]));
  });

  await _realm.subscriptions.waitForSynchronization();

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
  Future<void> _addCar(String make, String model, int miles) async {
    try {
      final car = Car(ObjectId(), make: make, model: model, miles: miles);

      await _realm.write(() {
        _realm.add(car);
      });

      await _realm.refreshAsync();

      print("added: ${car.make} model: ${car.model} miles: ${car.miles}");
    } catch (e) {
      print("failed to add car: $e");
    }
  }

  Future<List<Car>> _getAllCars() async {
    try {
      await _realm.syncSession.waitForDownload();

      final cars = _realm.all<Car>().toList();

      print("Getting all cars");
      return cars;
    } catch (e) {
      List<Car> result = List.empty();

      print("Getting cars failed");

      return result;
    }
  }

  Future<void> _deleteAllCars() async {
    try {
      await _realm.write(() {
        _realm.deleteAll<Car>();
      });

      await _realm.refreshAsync();
      print("Deleted all cars");
    } catch (e) {
      print("failed to delete cars: $e");
    }
  }

  Future<void> _refreshCars() async {
    await _realm.refresh();
    setState(() {});
    print("Refreshed all cars");
  }

  late String carMake;
  late String carModel;
  late int carMiles;

  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _milesController = TextEditingController();

  @override
  void dispose() {
    _realm.close();
    super.dispose();
  }

  // ACTUAL PAGE
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshCars(),
        child: FutureBuilder<List<Car>>(
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

                  try {
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
                  } catch (e) {
                    print("error drawing data: $e");
                    return const Text("");
                  }
                });
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => showDialog<String>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: const Text("Create new car"),
                content: Column(children: [
                  TextFormField(
                    controller: _makeController,
                    onChanged: (value) {
                      carMake = value.toString();
                    },
                    decoration: const InputDecoration(
                      labelText: "Maker",
                      hintText: "The company that made the car",
                    ),
                  ),
                  TextFormField(
                    controller: _modelController,
                    onChanged: (value) {
                      carModel = value.toString();
                    },
                    decoration: const InputDecoration(
                      labelText: "Model",
                      hintText: "The company assigned model of the car",
                    ),
                  ),
                  TextFormField(
                    controller: _milesController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      carMiles = int.parse(value);
                    },
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                        labelText: "Miles",
                        hintText:
                            "Total distance traveled bt the car in miles"),
                  ),
                ]),
                actions: [
                  TextButton(
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(context);
                      },
                      child: const Text("Cancel")),
                  TextButton(
                      onPressed: () async {
                        try {
                          await _addCar(carMake, carModel, carMiles);
                          await _refreshCars();
                          Navigator.pop(context);
                        } catch (e) {
                          print(e);
                        }
                      },
                      child: const Text("Save")),
                ],
              ),
            ),
            child: const Icon(Icons.add),
          ),
          const SizedBox(
            height: 10,
          ),
          FloatingActionButton(
            onPressed: () => showDialog<String>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                      title: const Text(
                          "Are you sure you want to delete all cars?"),
                      content: const Text("This action cannot be undone"),
                      actions: [
                        TextButton(
                            onPressed: () async {
                              await _deleteAllCars();
                              setState(() {});
                              await _refreshCars();
                              Navigator.pop(context);
                            },
                            child: const Text("Delete all cars"))
                      ],
                    )),
            child: const Icon(Icons.delete),
          )
        ],
      ),
    );
  }
}
