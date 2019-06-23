part of '../analysis.dart';

// https://www.sqlite.org/lang_corefunc.html
final abs = StaticTypeFunction(
    name: 'ABS', inputs: [NumericType()], output: NumericType());

final coreFunctions = [
  abs,
];
