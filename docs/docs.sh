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
    rm -r ./build/.dart_tool
    rm -r ./build/packages
    rm ./build/.build.manifest
    rm ./build/.packages
    
    build_container

    echo "Running MkDocs build..."
    docker run --rm  -v $(pwd):/docs --user $(id -u):$(id -g) mkdocs:latest build -f /docs/mkdocs/mkdocs.yml -d /docs/build/mkdocs
    if [ $? -ne 0 ]; then
        echo "Failed to build the MkDocs project"
        exit 1
    fi

    # Create a `deploy` folder with the MkDocs build and the compiled Dart code
    mkdir -p ./deploy
    # Move the contents of the MkDocs build to the `deploy` folder
    mv ./build/mkdocs/* ./deploy
    # Move the compiled Dart code to the `deploy` folder
    mv ./build/web/* ./deploy
    # Remove the `build` directory
    rm -r ./build

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



