#!/bin/bash

CURRENT_DIR="$(pwd)"
BUNDLE_ROOT="$CURRENT_DIR/linux"
PYTHON_VERSION="3.11.9"
PYTHON_MAJOR_MINOR="3.11"
PYTHON_DIR="$BUNDLE_ROOT/python3"

echo "Creating portable Python bundle in: $BUNDLE_ROOT"
echo "Python version: $PYTHON_VERSION"

# Check for required build tools
if ! command -v gcc &> /dev/null; then
    echo "Error: gcc not found. Please install build-essential:"
    echo "  sudo apt-get install build-essential libssl-dev zlib1g-dev libffi-dev"
    exit 1
fi

# Step 1: Create folder
mkdir -p "$BUNDLE_ROOT"

# Step 2: Download official Python (stable URL)
echo "Downloading Python from python.org..."
PYTHON_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz"
wget "$PYTHON_URL" -O python.tar.xz

# Step 3: Extract
echo "Extracting Python..."
tar -xf python.tar.xz
cd "Python-${PYTHON_VERSION}"

# Step 4: Configure for relocatable installation
echo "Configuring Python..."
./configure \
    --prefix="$PYTHON_DIR" \
    --enable-shared \
    --with-ensurepip=install \
    LDFLAGS="-Wl,-rpath,\$ORIGIN/../lib"

# Step 5: Build and install
echo "Building Python (this takes 3-5 minutes)..."
make -j$(nproc)
make install

cd "$CURRENT_DIR"

# Step 6: Cleanup
rm -rf "Python-${PYTHON_VERSION}"
rm python.tar.xz

# Step 7: Create symlinks for convenience
ln -sf "$PYTHON_DIR/bin/python3" "$PYTHON_DIR/bin/python"
ln -sf "$PYTHON_DIR/bin/pip3" "$PYTHON_DIR/bin/pip"

# Step 8: Install requirements
# if [ -f "$CURRENT_DIR/requirements.txt" ]; then
#     echo "Installing requirements..."
#     "$PYTHON_DIR/bin/pip" install -r "$CURRENT_DIR/requirements.txt"
# fi

# # Step 9: Install scheduler wheel
# if [ -f "$CURRENT_DIR/scheduler-0.1.2-py3-none-any.whl" ]; then
#     echo "Installing scheduler wheel..."
#     "$PYTHON_DIR/bin/pip" install "$CURRENT_DIR/scheduler-0.1.2-py3-none-any.whl"
# fi

# Step 10: Create activation script with deactivate support
cat > "$BUNDLE_ROOT/activate.sh" << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Save original environment if not already saved
if [ -z "$_PYTHON_BUNDLE_ACTIVE" ]; then
    export _ORIGINAL_PATH="$PATH"
    export _ORIGINAL_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
    export _PYTHON_BUNDLE_ACTIVE="1"
    export _PYTHON_BUNDLE_BIN="$SCRIPT_DIR/python3/bin"
fi

# Activate
export PATH="$SCRIPT_DIR/python3/bin:$PATH"
export LD_LIBRARY_PATH="$SCRIPT_DIR/python3/lib:$LD_LIBRARY_PATH"

# Create deactivate function
deactivate() {
    if [ -n "$_PYTHON_BUNDLE_ACTIVE" ]; then
        # Remove the bundle path from PATH
        export PATH="${PATH//$_PYTHON_BUNDLE_BIN:/}"
        export PATH="${PATH//$_PYTHON_BUNDLE_BIN/}"
        
        # Restore original LD_LIBRARY_PATH
        if [ -n "$_ORIGINAL_LD_LIBRARY_PATH" ]; then
            export LD_LIBRARY_PATH="$_ORIGINAL_LD_LIBRARY_PATH"
        else
            unset LD_LIBRARY_PATH
        fi
        
        # Clean up
        unset _PYTHON_BUNDLE_ACTIVE
        unset _PYTHON_BUNDLE_BIN
        unset _ORIGINAL_PATH
        unset _ORIGINAL_LD_LIBRARY_PATH
        unset -f deactivate
        
        echo "Python bundle deactivated"
    else
        echo "Python bundle is not active"
    fi
}

echo "Python bundle activated. Use 'deactivate' to restore environment."
EOF

chmod +x "$BUNDLE_ROOT/activate.sh"

echo ""
echo "Portable Python bundle created successfully!"
echo "Python version: $("$PYTHON_DIR/bin/python" --version)"
echo "Location: $PYTHON_DIR"
echo "To activate: source $BUNDLE_ROOT/activate.sh"