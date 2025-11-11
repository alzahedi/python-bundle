#!/bin/bash

# Check if config file is provided
if [ -z "$1" ]; then
    echo "Error: Config file required"
    echo "Usage: $0 <config-file>"
    exit 1
fi

CONFIG="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_EXE="$SCRIPT_DIR/linux/python3/bin/python3"
MAIN_SCRIPT="$SCRIPT_DIR/main.py"
ACTIVATE_SCRIPT="$SCRIPT_DIR/linux/activate.sh"

# Check if Python executable exists
if [ ! -f "$PYTHON_EXE" ]; then
    echo "Error: Bundled Python not found at: $PYTHON_EXE"
    exit 1
fi

# Check if main.py exists
if [ ! -f "$MAIN_SCRIPT" ]; then
    echo "Error: main.py not found at: $MAIN_SCRIPT"
    exit 1
fi

# Check if config file exists
if [ ! -f "$CONFIG" ]; then
    echo "Error: Config file not found at: $CONFIG"
    exit 1
fi

# Source activation script
if [ -f "$ACTIVATE_SCRIPT" ]; then
    source "$ACTIVATE_SCRIPT"
else
    echo "Warning: Activation script not found at: $ACTIVATE_SCRIPT"
    exit 1
fi

echo "Using Python: $PYTHON_EXE"
echo "Running: $MAIN_SCRIPT"
echo "Config: $CONFIG"
echo ""

# Run main.py with the config file
"$PYTHON_EXE" "$MAIN_SCRIPT" --config "$CONFIG"

# Exit with the same exit code as the Python script
exit $?