import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CreateNewCarDialogue(),
          const SizedBox(
            height: 10,
          ),
          const DeleteAllCarsDialogue(),
        ],
      ),
    );
  }
}

class DeleteAllCarsDialogue extends StatelessWidget {
  const DeleteAllCarsDialogue({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                title: const Text("Are you sure you want to delete all cars?"),
                content: const Text("This action cannot be undone"),
                actions: [
                  TextButton(
                      onPressed: () => _deleteAllCars(),
                      child: const Text("Delete all cars"))
                ],
              )),
      child: const Icon(Icons.delete),
    );
  }
}

class CreateNewCarDialogue extends StatelessWidget {
  CreateNewCarDialogue({
    super.key,
  });

  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _milesController = TextEditingController();

  late String carMake;
  late String carModel;
  late int carMiles;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
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
                  hintText: "Total distance traveled bt the car in miles"),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () {
                  _makeController.dispose();
                  _modelController.dispose();
                  _milesController.dispose();
                  Navigator.pop(context);
                },
                child: const Text("Cancel")),
            TextButton(
                // TODO: Implement Car creation
                onPressed: () {
                  _addCar(carMake, carModel, carMiles);
                  _makeController.dispose();
                  _modelController.dispose();
                  _milesController.dispose();
                  Navigator.pop(context);
                },
                child: const Text("Save")),
          ],
        ),
      ),
      child: const Icon(Icons.add),
    );
  }
}

Future<void> _addCar(String make, String model, int miles) async {
  _realm.write(() {
    _realm.add(Car(ObjectId(), make: make, model: model, miles: miles));
  });
}

Future<List<Car>> _getAllCars() async {
  _realm.subscriptions.update((mutableSubscriptions) {});
  await _realm.subscriptions.waitForSynchronization();

  final cars = _realm.all<Car>().toList();

  return cars;
}

Future<void> _deleteAllCars() async {
  _realm.write(() {
    _realm.deleteAll<Car>();
  });
}
