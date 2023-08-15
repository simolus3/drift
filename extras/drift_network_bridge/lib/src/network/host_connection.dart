import 'dart:async';

import 'package:drift/backends.dart';
import 'package:drift/drift.dart';

abstract class HostConnection implements DatabaseDelegate{

  final DelegatedDatabase db;

  DatabaseDelegate get parentDelegate => db.delegate;

  HostConnection(this.db);

  @override
  FutureOr<bool> get isOpen => isConnect();

  FutureOr<bool> connect();

  bool isConnect();

  @override
  TransactionDelegate get transactionDelegate => const NoTransactionDelegate();

  // @override
  // Future<void> open(QueryExecutorUser user) async {
  //
  //   // TODO: implement open
  //   if(await connect()){
  //     print("Connected");
  //     return;
  //   }
  //   throw Exception("Failed to connect");
  // }

}