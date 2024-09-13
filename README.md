# spark-install-macos
Apache-spark installation script for macOS. This script is customized for IEOR 4526 Analytics on the Cloud offered by Columbia University.

# macOS Spark Setup and Spylon Kernel Test Instructions

Follow these steps to set up Apache Spark on your macOS system and test the spylon kernel in Jupyter notebook.

**Note**: If you have Anaconda installed, please quit it before running this script, as it may prevent the script from editing the `~/.zshrc` file.   


## 1. Download and Run the Setup Script

Open Terminal and run the following commands:

```bash
# Download the script
curl -O https://raw.githubusercontent.com/x1linwang/spark-install-macos/main/macos_setup.sh

# Make the script executable
chmod +x macos_setup.sh

# Run the script
./macos_setup.sh
```
**Note**: This script installs Homebrew, which requires administrator privileges. You'll be prompted for your password. For security, the password field will remain blank as you type. Simply enter your password and press Return.  

## 2. Restart Terminal or Source .zshrc

After the script completes, either restart your Terminal or run:

```bash
source ~/.zshrc
```

This ensures all the new environment variables are loaded.

## 3. Launch Jupyter Notebook

Open a new Terminal window and run:

```bash
jupyter notebook
```

This will open Jupyter Notebook in your default web browser.

## 4. Create a New Notebook with Spylon Kernel

1. In the Jupyter interface, click on "New" in the top right corner.
2. Select "spylon-kernel" from the dropdown menu.

## 5. Test the Spylon Kernel

In the new notebook, you can test if everything is working correctly by running the following cells:

1. Test Scala:

   In the current spylon kernel, run the following command:
   ```
   val x = 1
   println(s"This is Scala. x = $x")
   ```

2. Test PySpark:

   Change to a python kernel and run the below command:
   ```
   %%python
   from pyspark.sql import SparkSession

   spark = SparkSession.builder.appName("test").getOrCreate()
   print(f"Spark version: {spark.version}")

   # Create a sample DataFrame
   df = spark.createDataFrame([(1, "a"), (2, "b"), (3, "c")], ["id", "letter"])
   df.show()
   ```

If both cells run without errors, congratulations! Your Spark environment with spylon kernel is set up correctly.

## Troubleshooting

- If you encounter any "command not found" errors, make sure you've restarted your Terminal or sourced your `.zshrc` file.
- If Jupyter can't find the spylon kernel, try running `python -m spylon_kernel install --user` manually.
- For any PySpark-related issues, verify that your `SPARK_HOME` and `PYSPARK_PYTHON` environment variables are set correctly by running `echo $SPARK_HOME` and `echo $PYSPARK_PYTHON` in the Terminal.
- Contact yout TA if you encountered any other errors.
