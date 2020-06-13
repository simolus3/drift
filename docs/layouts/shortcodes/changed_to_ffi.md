<div class="alert alert-primary" role="alert">
<h4 class="alert-heading">Change to moor_ffi</h4>
Previous versions of this article recommended to use <code>moor_flutter</code>.
New users are recommended to use the <code>moor_ffi</code> package instead.
If you're already using <code>moor_flutter</code>, there's nothing to worry about!
The package is still maintained and will continue to work.
</div>

Some versions of the Flutter tool create a broken `settings.gradle` on Android, which can cause problems with `moor_ffi`.
If you get a "Failed to load dynamic library" exception, see [this comment](https://github.com/flutter/flutter/issues/55827#issuecomment-623779910).