#!/bin/bash

# Get the 1st argument passed to the script and convert it to lowercase
arg1=$(echo $1 | tr '[:upper:]' '[:lower:]')

# Build the MkDocs container which will be used to build/serve the MkDocs project
build_container () {
    echo "Building the container..."
    docker build -t mkdocs:latest ./mkdocs/
    if [ $? -ne 0 ]; then
        echo "Failed to build the container"
        exit 1
    fi
}

if [ $arg1 == "build" ]; then

    echo "Building the project..."

    # Remove the `build` directory if it already exists
    rm -r ./deploy
    rm -r ./build

    # Activate the webdev command
    dart pub global activate webdev

    # The below command will compile the dart code in `/web` to js & run build_runner
    webdev build -o web:build/web -- --delete-conflicting-outputs
    if [ $? -ne 0 ]; then
        echo "Failed to build the project"
        exit 1
    fi

    # Run the build_runner command to generate files in the `test` directory
    dart run build_runner build --delete-conflicting-outputs
    if [ $? -ne 0 ]; then
        echo "Failed to build the project"
        exit 1
    fi

    # Remove some files that are not needed
    rm -r ./build/web/.dart_tool
    rm -r ./build/web/packages
    rm ./build/web/.build.manifest
    rm ./build/web/.packages

    # Move the contents of `build` to `docs` without overwriting the `docs`
    mv -f ./build/web/* ./docs

    # Build the flutter web project
    cd ../examples/app
    flutter pub get
    if [ $? -ne 0 ]; then
        echo "Failed to build the example project"
        exit 1
    fi
    flutter build web --base-href "/examples/app/" --no-web-resources-cdn
    if [ $? -ne 0 ]; then
        echo "Failed to build the example project"
        exit 1
    fi
    mkdir -p ../../docs/docs/examples/app
    rm -r ../../docs/docs/examples/app/*
    mv -f ./build/web/* ../../docs/docs/examples/app
    cd -



    # Remove the `build` directory
    rm -r ./build

    build_container

    echo "Running MkDocs build..."
    docker run --rm  -v $(pwd):/docs --user $(id -u):$(id -g) mkdocs:latest build -f /docs/mkdocs/mkdocs.yml -d /docs/deploy
    if [ $? -ne 0 ]; then
        echo "Failed to build the MkDocs project"
        exit 1
    fi

    echo "Project built successfully"
    exit 0

elif [ $arg1 == "serve" ]; then
    echo "Serving the project..."

    # if `lib/versions.json` does not exist, create it
    if [ ! -f ./lib/versions.json ]; then
        dart run build_runner build --delete-conflicting-outputs
    fi

    build_container

    echo "Running MkDocs serve..."
    docker run --rm -p 9000:9000 -v $(pwd):/docs --user $(id -u):$(id -g) mkdocs:latest serve -f /docs/mkdocs/mkdocs.yml -a 0.0.0.0:9000 &
    dart run build_runner watch --delete-conflicting-outputs
    wait

else
    echo "Invalid argument. Please use 'build' or 'serve'"
    exit 1
fi



