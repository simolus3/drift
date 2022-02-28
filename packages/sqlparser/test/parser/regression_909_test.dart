import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

// ignore_for_file: lines_longer_than_80_chars
void main() {
  const stmts = [
    'CREATE TABLE plots (owner_id VARCHAR NOT NULL, deleted INTEGER NOT NULL, last_synced INTEGER NULL, last_modified INTEGER NOT NULL, id VARCHAR NOT NULL, name VARCHAR NOT NULL, crop VARCHAR NOT NULL, crop_variety VARCHAR NOT NULL, planting_date INTEGER NOT NULL, is_outdoor_trial INTEGER NOT NULL CHECK (is_outdoor_trial in (0, 1)), uses_crop_blanket INTEGER NOT NULL CHECK (uses_crop_blanket in (0, 1)), is_raised_bed INTEGER NOT NULL CHECK (is_raised_bed in (0, 1)), plant_spacing REAL NOT NULL, row_spacing REAL NOT NULL, irrigation_type VARCHAR NOT NULL, rows_per_bed REAL NULL, bed_spacing REAL NULL, coordinates VARCHAR NOT NULL, PRIMARY KEY (id))',
    'CREATE TABLE lab_reports (owner_id VARCHAR NOT NULL, deleted INTEGER NOT NULL, last_synced INTEGER NULL, last_modified INTEGER NOT NULL, id VARCHAR NOT NULL, sample_date INTEGER NOT NULL, source VARCHAR NOT NULL, PRIMARY KEY (id))',
    'CREATE TABLE dissipated_active_ingredients (id VARCHAR NOT NULL, lab_report_id VARCHAR NOT NULL, active_ingredient_id VARCHAR NULL, name VARCHAR NULL, residue REAL NOT NULL, PRIMARY KEY (id))',
    'CREATE TABLE sprays (owner_id VARCHAR NOT NULL, deleted INTEGER NOT NULL, last_synced INTEGER NULL, last_modified INTEGER NOT NULL, id VARCHAR NOT NULL, create_date INTEGER NOT NULL, application_method VARCHAR NOT NULL, growth_stage VARCHAR NOT NULL, PRIMARY KEY (id))',
    'CREATE TABLE products (id VARCHAR NOT NULL, trade_name VARCHAR NOT NULL, type VARCHAR NOT NULL, owner_id VARCHAR NULL, PRIMARY KEY (id))',
    'CREATE TABLE markets (owner_id VARCHAR NOT NULL, deleted INTEGER NOT NULL, last_synced INTEGER NULL, last_modified INTEGER NOT NULL, id VARCHAR NOT NULL, name VARCHAR NOT NULL, mrl REAL NOT NULL, arfd REAL NOT NULL, adi REAL NOT NULL, total_active_ingredients INTEGER NOT NULL, PRIMARY KEY (id))',
  ];

  test('parses statements', () {
    final engine = SqlEngine();

    for (final stmt in stmts) {
      final result = engine.parse(stmt);
      expect(result.errors, isEmpty);
      expect(result.rootNode, isA<CreateTableStatement>());
    }
  });
}
