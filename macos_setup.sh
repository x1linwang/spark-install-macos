#!/bin/zsh

set -e  # Exit immediately if a command exits with a non-zero status.

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to add a line to a file if it doesn't exist
add_to_file() {
    grep -qF "$1" "$2" || echo "$1" >> "$2"
}

# Check if the shell is zsh; if not, prompt to switch
if [ "$SHELL" != "/bin/zsh" ]; then
    echo "Your current shell is not zsh. Switching to zsh is recommended."
    echo "Please upgrade your shell to zsh using the command: chsh -s /bin/zsh"
    exit 1
fi

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

# Check if conda is installed
if ! command_exists conda; then
    echo "Installing Anaconda..."
    brew install --cask anaconda
else
    echo "Anaconda is already installed."
fi

# Ensure the base conda environment uses Python 3.11
echo "Checking if the base conda environment uses Python 3.11..."
BASE_PYTHON_VERSION=$(conda run -n base python --version | grep "3.11")
if [[ -z "$BASE_PYTHON_VERSION" ]]; then
    echo "Updating base environment to Python 3.11..."
    conda run -n base conda install python=3.11 -y
else
    echo "Base environment is already running Python 3.11."
fi

# Install Apache Spark (this will also install OpenJDK and Scala as dependencies)
echo "Installing Apache Spark (along with OpenJDK and Scala)..."
brew install apache-spark

# Determine which openjdk Spark is using
echo "Determining which OpenJDK version Spark is using..."
JAVA_VERSION=$(brew info apache-spark | awk '/Required:/ && /openjdk/ {print $2}')

if [[ -z "$JAVA_VERSION" ]]; then
    echo "Error: Could not determine the OpenJDK version Spark is using."
    exit 1
else
    echo "OpenJDK version used by Spark: $JAVA_VERSION"
    echo "Homebrew suggests adding the following to your PATH: /opt/homebrew/opt/$JAVA_VERSION/bin:\$PATH"
    add_to_file "export PATH=\"/opt/homebrew/opt/$JAVA_VERSION/bin:\$PATH\"" ~/.zshrc
fi

# Get the installed path of the required OpenJDK version
JAVA_HOME=$(brew info "$JAVA_VERSION" | awk '/Installed/ {getline; print $1}')/libexec/openjdk.jdk/Contents/Home

if [[ -d "$JAVA_HOME" ]]; then
    echo "JAVA_HOME is set to $JAVA_HOME"
    add_to_file "export JAVA_HOME=$JAVA_HOME" ~/.zshrc
else
    echo "Error: Could not determine the installed path of $JAVA_VERSION."
    exit 1
fi

echo "Setting SPARK_HOME dynamically..."
SPARK_HOME=$(brew info apache-spark | awk '/Installed/ {getline; print $1}')/libexec

if [ -d "$SPARK_HOME" ]; then
    echo "SPARK_HOME is set to $SPARK_HOME"
    add_to_file "export SPARK_HOME=$SPARK_HOME" ~/.zshrc
else
    echo "Error: Could not determine SPARK_HOME."
    exit 1
fi

# Set PYSPARK_PYTHON to use the Anaconda Python
echo "Setting PYSPARK_PYTHON to Anaconda's Python..."
PYSPARK_PYTHON=$(conda run -n base which python)
add_to_file "export PYSPARK_PYTHON=$PYSPARK_PYTHON" ~/.zshrc

# Set PYTHONPATH for PySpark
echo "Setting PYTHONPATH for PySpark..."
PY4J_VERSION=$(ls $SPARK_HOME/python/lib | grep py4j | sed 's/py4j-\(.*\)-src.zip/\1/')
add_to_file "export PYTHONPATH=\"$SPARK_HOME/python/:$SPARK_HOME/python/lib/py4j-$PY4J_VERSION-src.zip:\$PYTHONPATH\"" ~/.zshrc

# Install spylon-kernel
echo "Installing spylon-kernel..."
$PYSPARK_PYTHON -m pip install spylon-kernel
$PYSPARK_PYTHON -m spylon_kernel install --user

echo "Setup complete! Please restart your terminal or run 'source ~/.zshrc' to apply the changes."
