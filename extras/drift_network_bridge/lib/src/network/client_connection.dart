import 'dart:async';

import 'package:drift/backends.dart';

abstract class ClientConnection implements DatabaseDelegate{
  @override
  FutureOr<bool> get isOpen => isConnect();

  FutureOr<bool> connect();

  bool isConnect();

  @override
  TransactionDelegate get transactionDelegate => const NoTransactionDelegate();

  @override
  Future<void> open(QueryExecutorUser db) async {
    // TODO: implement open
    if(await connect()){
      print("Connected");
      return;
    }
    throw Exception("Failed to connect");
  }

}