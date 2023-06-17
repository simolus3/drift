<script>
  import 'database.dart';

  import 'entry.zap';
  import 'toolbar.zap';

  var filter = TodoListFilter.all;
  var uncompleted = 0;

  final connFuture = connect();
  final dbFuture = connFuture.then((r) => Database(r.resolvedExecutor));
</script>
<style>
.ok {
  color: green;
}

.bad {
  color: red;
}

small {
  display: block;
}
</style>

<hgroup>
  <h1>Todo list</h1>
  <h2>This offline todo-list app is implemented with drift on the web.</h2>
</hgroup>

<article>
{#await database from dbFuture}
  {#if database.hasData}
    <header>
       <toolbar database={database.data} />
    </header>
    {#await each snapshot from database.data.items}
      {#if snapshot.hasData}
        {#for entry, i in snapshot.data}
          <entry entry={entry} database={database.data} />
          {#if i != snapshot.data.length - 1}
            <hr>
          {/if}
        {/for}
      {/if}
    {/await}
  {:else if database.hasError}
    Sorry, we could not open the database on this browser!
  {:else}
    <progress></progress>
  {/if}
{/await}
<footer>
  {#await connection from connFuture}
    {#if connection.hasData}
      Using implementation <span class={ connection.data.chosenImplementation.fullySupported ? 'ok' : 'bad' }>{ connection.data.chosenImplementation.name }</span>.

      {#if connection.data.chosenImplementation.fullySupported}
        Updates are transparently synchronized across tabs.
        <small>Want to try it out? Go ahead and open this website in <a href="#" target="_blank">a new tab</a>.</small>
      {:else}
        This implementation has known caveats and shouldn't be selected on recent browsers.
        More information is in the console and in <a href="https://drift.simonbinder.eu/web">the documentation</a>.
        <small>Please consider <a href="https://github.com/simolus3/drift/issues/new/choose">filing an issue</a>.</small>
      {/if}
    {/if}
  {/await}
</footer>
</article>

<footer>
  <small><a href="https://github.com/simolus3/drift/tree/develop/docs/lib/sample">Source code</a></small>
</footer>
