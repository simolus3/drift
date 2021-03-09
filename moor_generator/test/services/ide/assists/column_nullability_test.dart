//@dart=2.9
import 'utils.dart';

void main() {
  testSourceEdit(
    'suggests making columns non-nullable',
    '''
CREATE TABLE bar (
  content ^TEXT
);''',
    '''
CREATE TABLE bar (
  content TEXT NOT NULL
);''',
    (s) => s.message.contains('NOT NULL'),
  );

  testSourceEdit(
    'suggests making columns nullable',
    '''
CREATE TABLE bar (
  content ^TEXT NOT NULL
);''',
    '''
CREATE TABLE bar (
  content TEXT 
);''',
    (s) => s.message.contains('nullable'),
  );
}
