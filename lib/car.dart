import 'package:realm/realm.dart';
part 'car.g.dart';

@RealmModel()
class _Car {
  @PrimaryKey()
  @MapTo('_id')
  late ObjectId id;

  late String? make;
  late String? model;
  late int? miles;
}
