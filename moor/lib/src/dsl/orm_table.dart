// ignore_for_file: public_member_api_docs
part of 'dsl.dart';

@Target({TargetKind.classType})
class OrmTable {
  final String? name;
  final bool withoutRowId;
  final bool dontWriteConstraints;
  final List<String> customConstraints;
  final String? dbConstructor;

  const OrmTable({
    this.name,
    this.withoutRowId = false,
    this.dontWriteConstraints = false,
    this.customConstraints = const [],
    this.dbConstructor,
  });
}
