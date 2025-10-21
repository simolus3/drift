import 'package:drift/drift.dart';

import 'aliases.drift.dart';

// #docregion tables
class GeoPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get latitude => text()();
  TextColumn get longitude => text()();
}

class Routes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  // contains the id for the start and destination geopoint.
  IntColumn get start => integer()();
  IntColumn get destination => integer()();
}

// #enddocregion tables

// #docregion query
class RouteWithPoints {
  final Route route;
  final GeoPoint start;
  final GeoPoint destination;

  RouteWithPoints({
    required this.route,
    required this.start,
    required this.destination,
  });
}

// #enddocregion query
extension FakeDatabase on GeneratedDatabase {
  $GeoPointsTable get geoPoints => throw '';
  $RoutesTable get routes => throw '';

  // #docregion query
  // inside the database class:
  Future<List<RouteWithPoints>> loadRoutes() async {
    // create aliases for the geoPoints table so that we can reference it twice
    final start = alias(geoPoints, 's');
    final destination = alias(geoPoints, 'd');

    final rows = await select(routes).join([
      innerJoin(start, start.id.equalsExp(routes.start)),
      innerJoin(destination, destination.id.equalsExp(routes.destination)),
    ]).get();

    return rows.map((resultRow) {
      return RouteWithPoints(
        route: resultRow.readTable(routes),
        start: resultRow.readTable(start),
        destination: resultRow.readTable(destination),
      );
    }).toList();
  }

  // #enddocregion query
}
