import 'dart:async';

import 'package:macros/macros.dart';
import 'package:drift_dev/src/utils/string_escaper.dart';

import 'analyzer/table.dart';
import 'model/table.dart';
import 'utils.dart';

macro class DriftTable implements ClassTypesMacro, ClassDeclarationsMacro {
  final String? sqlName;
  final bool withoutRowId;
  final bool strict;

  const DriftTable({
    this.sqlName,
    this.withoutRowId = false,
    this.strict = true,
  });

  @override
  Future<void> buildTypesForClass(
      ClassDeclaration clazz, ClassTypeBuilder builder) async {
    final driftImports = DriftImports(builder);
    final sqlName = _sqlTableName(clazz.identifier);
    final macroUri = Uri.parse('package:drift_macros/src/table.dart');

    Future<void> associatedTableConstructor(CodeBuilder b, String name) async {
      b
        // ignore: deprecated_member_use
        ..part(await builder.resolveIdentifier(macroUri, name))
        ..part(
            '(sqlName: ${asDartLiteral(sqlName)}, withoutRowId: $withoutRowId, strict: $strict,')
        ..line(
            'rowClassUri: ${asDartLiteral(clazz.library.uri.toString())}, rowClassName: ${asDartLiteral(clazz.identifier.name)})');
    }

    final tableName = TableAnalyzer.tableClassForRow(clazz.identifier);

    builder.declareType(
      tableName,
      await driftImports.buildCode(DeclarationCode.fromParts, (b) async {
        b.part('@');
        await associatedTableConstructor(b, 'GenerateTableClass');
        b.part('final class $tableName extends ');
        await b.driftImport('Table');
        b.part(' with ');
        await b.driftImport('TableInfo');
        b.part('<$tableName, ');
        b.part(clazz.identifier);
        b.line('> {');

        final string = await driftImports.fromDartCore('String');

        b.part('final ');
        await b.driftImport('GeneratedDatabase');
        b
          ..line(' attachedDatabase;')
          ..part('final ')
          ..part(string)
          ..line('? _alias;')
          ..line('$tableName(this.attachedDatabase, [this._alias]);')
          ..part(string)
          ..line(' get aliasedName => _alias ?? actualTableName;')
          ..part(string)
          ..line(' get actualTableName => \$name;')
          ..line('static const \$name = ${asDartLiteral(sqlName)};')
          ..part('$tableName createAlias(')
          ..part(string)
          ..line(' alias) => $tableName(attachedDatabase, alias);');

        if (withoutRowId) {
          b.line('get withoutRowId => true;');
        }
        if (strict) {
          b.line('get strict => true;');
        }

        // Defining these requires access to the resolved table model, which
        // we can only get in a later phase. So we declare them to be external
        // here and add an implementation later.
        // todo this should be a direct field but the CFE doesn't support
        // augmentations to fields.
        b.part('late final ');
        await b.dartCoreImport('List');
        b.part('<');
        await b.driftImport('GeneratedColumn');
        b.line('> \$columns = _createColumns();');
        b.part('external ');
        await b.dartCoreImport('List');
        b.part('<');
        await b.driftImport('GeneratedColumn');
        b.line('> _createColumns();');

        b..part('external ');
        await b.dartAsyncImport('Future');
        b
          ..part('<')
          ..part(clazz.identifier)
          ..line('> map(');
        await b.dartCoreImport('Map');
        b.part('<');
        await b.dartCoreImport('String');
        b.part(',');
        await b.dartCoreImport('Object');
        b.part('?> data, {');
        await b.dartCoreImport('String');
        b.line('? tablePrefix});');

        b.part('}');
      }),
    );

    final companionName = '${clazz.identifier.name}Companion';
    builder.declareType(
      companionName,
      await driftImports.buildCode(DeclarationCode.fromParts, (b) async {
        b.part('@');
        await associatedTableConstructor(b, 'GenerateCompanion');
        b.line('final class $companionName {');
        b.part('}');
      }),
    );
  }

  @override
  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final tableName = TableAnalyzer.tableClassForRow(clazz.identifier);
    final driftImports = DriftImports(builder);

    builder.declareInType(
      await driftImports.buildCode(DeclarationCode.fromParts, (b) async {
        b.part('static $tableName createTable(');
        await b.driftImport('GeneratedDatabase');
        b.part(' database) => $tableName(database);');
      }),
    );
  }

  String _sqlTableName(Identifier dataClassIdentifier) {
    return sqlName ?? dataClassIdentifier.name;
  }
}

class _AssociatedTableClass {
  final String sqlName;
  final bool withoutRowId;
  final bool strict;

  // todo: The macro design doc says we should be able to replace this with an
  // identifier, but that doesn't seem to be supported yet.
  final String rowClassUri;
  final String rowClassName;

  const _AssociatedTableClass({
    required this.sqlName,
    required this.withoutRowId,
    required this.strict,
    required this.rowClassUri,
    required this.rowClassName,
  });

  Future<ResolvedTable> resolveTable(
      DeclarationPhaseIntrospector introspector) async {
    final rowClassIdentifier =
        // ignore: deprecated_member_use
        await introspector.resolveIdentifier(
            Uri.parse(rowClassUri), rowClassName);
    final analyzer = TableAnalyzer(
      macro: DriftTable(
        sqlName: sqlName,
        withoutRowId: withoutRowId,
        strict: strict,
      ),
      rowClass: await introspector.typeDeclarationOf(rowClassIdentifier)
          as ClassDeclaration,
      introspector: introspector,
    );
    return await analyzer.resolve();
  }
}

macro class GenerateTableClass extends _AssociatedTableClass
    implements ClassDeclarationsMacro, ClassDefinitionMacro {
  const GenerateTableClass({
    required super.sqlName,
    required super.withoutRowId,
    required super.strict,
    required super.rowClassUri,
    required super.rowClassName,
  });

  @override
  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final resolvedTable = await resolveTable(builder);
    final driftImports = DriftImports(builder);

    for (final column in resolvedTable.columns) {
      builder.declareInType(
          await driftImports.buildCode(DeclarationCode.fromParts, (b) async {
        b.part('late final ');
        await b.driftImport('GeneratedColumn');
        b..part('<');
        await b.dartSqlType(column.sqlType);
        b.part('> ${column.nameInDart} = ');
        await b.driftImport('GeneratedColumn');
        b.part(
          '(${asDartLiteral(column.nameInSql)}, aliasedName, '
          '${column.nullable}, type: ',
        );
        await b.sqlTypeExpression(column.sqlType);
        b.part(
            ', requiredDuringInsert: ${resolvedTable.isColumnRequiredForInsert(column)},');
        b.part('\$customConstraints: ${asDartLiteral('')}');
        b.line(');');
      }));
    }
  }

  @override
  Future<void> buildDefinitionForClass(
      ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    // todo: We should not resolve the table again here. Once the macro API
    // supports it, we should instead add an annotation serializing the table
    // structure from the declaration phase and then look everything up from
    // there.
    final resolvedTable = await resolveTable(builder);

    final methods = await builder.methodsOf(clazz);
    await _createColumnsList(
        methods
            .singleWhere((e) => e.identifier.name == r'_createColumns')
            .identifier,
        builder,
        resolvedTable);
  }

  Future<void> _createColumnsList(Identifier identifier,
      TypeDefinitionBuilder builder, ResolvedTable table) async {
    final method = await builder.buildMethod(identifier);

    method.augment(FunctionBodyCode.fromParts([
      '=> ',
      '[',
      for (final column in table.columns) ...[column.nameInDart, ','],
      '];',
    ]));
  }
}

macro class GenerateCompanion extends _AssociatedTableClass
    implements ClassDeclarationsMacro {
  const GenerateCompanion({
    required super.sqlName,
    required super.withoutRowId,
    required super.strict,
    required super.rowClassUri,
    required super.rowClassName,
  });

  @override
  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final table = await resolveTable(builder);
    final imports = DriftImports(builder);

    for (final column in table.columns) {
      // Declare Value<> field for each column.
      builder.declareInType(
          await imports.buildCode(DeclarationCode.fromParts, (b) async {
        b.part('final ');
        await b.driftImport('Value');
        b.part('<');
        await b.dartType(column.sqlType);
        b.line('> ${column.nameInDart};');
      }));
    }

    // Add default constructor
    builder.declareInType(
        await imports.buildCode(DeclarationCode.fromParts, (b) async {
      b.part('const ${clazz.identifier.name}({');
      for (final column in table.columns) {
        b.part('this.${column.nameInDart} = const ');
        await b.driftImport('Value');
        b.line('.absent(),');
      }
      b.line('});');
    }));

    // Add .insert constructor for which only fields required for inserts are
    // required in Dart.
    builder.declareInType(
        await imports.buildCode(DeclarationCode.fromParts, (b) async {
      final requiredFields = <String>[];

      b.part('${clazz.identifier.name}.insert({');
      for (final column in table.columns) {
        if (table.isColumnRequiredForInsert(column)) {
          b.part('required ');
          await b.dartType(column.sqlType);
          b.line(' ${column.nameInDart},');
          requiredFields.add(column.nameInDart);
        } else {
          b.part('this.${column.nameInDart} = const ');
          await b.driftImport('Value');
          b.line('.absent(),');
        }
      }
      b.line('})');

      if (requiredFields.isNotEmpty) {
        b.part(': ');
        for (final (index, field) in requiredFields.indexed) {
          if (index != 0) b.part(', ');

          b.part('$field = ');
          await b.driftImport('Value');
          b.line('($field)');
        }
      }

      b.line(';');
    }));
  }
}
