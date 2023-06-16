<script>
  import 'database.dart';

  @prop
  Database database;

  @prop
  TodoItem entry;

  void toggle() {
    database.toggleCompleted(entry);
  }
</script>

<label for="entry-{entry.id}">
  <input type="checkbox" id="entry-{entry.id}" checked={entry.completed} on:change={toggle}>
  {entry.description}
</label>
