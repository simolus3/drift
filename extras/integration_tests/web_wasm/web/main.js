(async () => {
    const thisScript = document.currentScript;
    const params = new URL(document.location.toString()).searchParams;
    const wasmOption = params.get("wasm");

    function relativeURL(ref) {
      const base = thisScript?.src ?? document.baseURI;
      return new URL(ref, base).toString();
    }

    if (wasmOption == "1") {
        let { compileStreaming } = await import("./main.mjs");

        let app = await compileStreaming(fetch(relativeURL("main.wasm")));
        let module = await app.instantiate({});
        module.invokeMain();
    } else {
        const scriptTag = document.createElement("script");
        scriptTag.type = "application/javascript";
        scriptTag.src = relativeURL("./main.dart2js.js");
        document.head.append(scriptTag);
    }
})();
