package eu.simonbinder.moor_ffi;

import io.flutter.embedding.engine.plugins.FlutterPlugin;

public class MoorFfiPlugin implements FlutterPlugin {

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        // Do nothing, we only need the native libraries.
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        // Again, nothing to do here.
    }

}