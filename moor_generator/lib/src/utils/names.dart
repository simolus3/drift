//@dart=2.9
String dataClassNameForClassName(String tableName) {
  // This implementation is very primitive at the moment. The basic idea is
  // that, very often, table names are formed from the plural of the entity
  // they're storing (users, products, ...). We try to find the singular word
  // from the table name.

  // todo we might want to implement some edge cases according to
  // https://en.wikipedia.org/wiki/English_plurals

  if (tableName.endsWith('s')) {
    return tableName.substring(0, tableName.length - 1);
  }

  // Default behavior if the table name is not a valid plural.
  return '${tableName}Data';
}
