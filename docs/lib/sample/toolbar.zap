<script>
  import 'database.dart';

  @prop
  Database database;

  TextInputElement? text;

  var currentFilter = database.currentFilter;

  void select(TodoListFilter filter) {
    currentFilter = filter;
    database.currentFilter = filter;
  }
</script>

<style>
  div {
    float: right;
  }

  a {
    margin: 0px 2px;
  }

  label {
    margin-top: 20px;
  }
</style>

{#await each entry from database.uncompletedItems}
  {#if entry.hasData}
    <strong>{entry.data} {entry.data == 1 ? 'item' : 'items'} left</strong>
  {/if}
{/await}

<div>
<a class={currentFilter == TodoListFilter.all ? '' : 'secondary'} on:click={() => select(TodoListFilter.all)}>All</a>
<a class={currentFilter == TodoListFilter.active ? '' : 'secondary'} on:click={() => select(TodoListFilter.active)}>Active</a>
<a class={currentFilter == TodoListFilter.completed ? '' : 'secondary'} on:click={() => select(TodoListFilter.completed)}>Completed</a>
</div>
