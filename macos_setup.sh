#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to add a line to a file if it doesn't exist
add_to_file() {
    grep -qF "$1" "$2" || echo "$1" >> "$2"
}

# Install Homebrew if not already installed
if ! command_exists brew; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew is already installed."
fi

# Add Homebrew to PATH
if [[ ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
    echo "Adding Homebrew to PATH..."
    eval "$(/opt/homebrew/bin/brew shellenv)"
    add_to_file 'eval "$(/opt/homebrew/bin/brew shellenv)"' ~/.zshrc
fi

# Check for existing Python installation
if command_exists python3; then
    PYTHON_PATH=$(which python3)
    echo "Found Python installation at $PYTHON_PATH"
else
    echo "Python 3 not found. Installing Anaconda..."
    brew install --cask anaconda
    PYTHON_PATH="/opt/homebrew/anaconda3/bin/python"
    echo "Adding Anaconda to PATH..."
    add_to_file 'export PATH="/opt/homebrew/anaconda3/bin:$PATH"' ~/.zshrc
    source ~/.zshrc
fi

# Install Apache Spark (this will also install OpenJDK and Scala as dependencies)
echo "Installing Apache Spark (along with OpenJDK and Scala)..."
brew install apache-spark

# Set JAVA_HOME
# Get the installed version of openjdk and set JAVA_HOME dynamically
# Currently openjdk@17 is installed by default
# You might have to replace it with openjdk@xx based on brew prompt
JAVA_VERSION=$(brew info openjdk@17 | grep -o 'openjdk@[0-9.]*' | head -n 1)
JAVA_HOME=$(brew --prefix "$JAVA_VERSION")/libexec/openjdk.jdk/Contents/Home
echo "Setting JAVA_HOME..."
add_to_file "export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"" ~/.zshrc
add_to_file "export JAVA_HOME=$JAVA_HOME" ~/.zshrc

# Set SPARK_HOME with version number
SPARK_VERSION=$(brew info apache-spark --json | jq -r '.[0].installed[0].version')
SPARK_HOME="/opt/homebrew/Cellar/apache-spark/${SPARK_VERSION}/libexec"
echo "Setting SPARK_HOME..."
add_to_file "export SPARK_HOME=$SPARK_HOME" ~/.zshrc

# Set PYSPARK_PYTHON to use the detected Python
echo "Setting PYSPARK_PYTHON..."
add_to_file "export PYSPARK_PYTHON=$PYTHON_PATH" ~/.zshrc

# Set PYTHONPATH for PySpark
echo "Setting PYTHONPATH for PySpark..."
PY4J_VERSION=$(ls $SPARK_HOME/python/lib | grep py4j | sed 's/py4j-\(.*\)-src.zip/\1/')
add_to_file "export PYTHONPATH=\"$SPARK_HOME/python/:$SPARK_HOME/python/lib/py4j-$PY4J_VERSION-src.zip:\$PYTHONPATH\"" ~/.zshrc

# Install spylon-kernel
echo "Installing spylon-kernel..."
$PYTHON_PATH -m pip install spylon-kernel
$PYTHON_PATH -m spylon_kernel install

echo "Setup complete! Please restart your terminal or run 'source ~/.zshrc' to apply the changes."
