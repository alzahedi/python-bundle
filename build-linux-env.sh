#!/bin/bash

CURRENT_DIR="$(pwd)"
BUNDLE_ROOT="$CURRENT_DIR/linux"
PYTHON_VERSION="3.11.14"  # Updated to latest 3.11.x
RELEASE_TAG="20251031"     # Latest release
PYTHON_DIR="$BUNDLE_ROOT/python3"

echo "Creating portable Python bundle in: $BUNDLE_ROOT"
echo "Python version: $PYTHON_VERSION"

# Step 1: Create folder
mkdir -p "$BUNDLE_ROOT"

# Step 2: Download standalone Python build
echo "Downloading Python standalone build..."
PYTHON_URL="https://github.com/astral-sh/python-build-standalone/releases/download/${RELEASE_TAG}/cpython-${PYTHON_VERSION}+${RELEASE_TAG}-x86_64-unknown-linux-gnu-install_only.tar.gz"
wget "$PYTHON_URL" -O python_standalone.tar.gz

# Step 3: Extract Python
echo "Extracting Python..."
mkdir -p "$PYTHON_DIR"
tar -xzf python_standalone.tar.gz -C "$PYTHON_DIR" --strip-components=1

# Step 4: Cleanup
rm python_standalone.tar.gz

# Step 5: Ensure pip is available
echo "Ensuring pip is available..."
"$PYTHON_DIR/bin/python3" -m ensurepip --upgrade

# Step 6: Install requirements
# if [ -f "$CURRENT_DIR/requirements.txt" ]; then
#     echo "Installing requirements..."
#     "$PYTHON_DIR/bin/pip3" install -r "$CURRENT_DIR/requirements.txt"
# fi

# # Step 7: Install scheduler wheel
# if [ -f "$CURRENT_DIR/scheduler-0.1.2-py3-none-any.whl" ]; then
#     echo "Installing scheduler wheel..."
#     "$PYTHON_DIR/bin/pip3" install "$CURRENT_DIR/scheduler-0.1.2-py3-none-any.whl"
# fi

# Step 8: Create activation script
cat > "$BUNDLE_ROOT/activate.sh" << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$SCRIPT_DIR/python3/bin:$PATH"
export LD_LIBRARY_PATH="$SCRIPT_DIR/python3/lib:$LD_LIBRARY_PATH"
EOF

chmod +x "$BUNDLE_ROOT/activate.sh"

echo ""
echo "Portable Python bundle created successfully!"
echo "Python version: $("$PYTHON_DIR/bin/python3" --version)"
echo "To activate: source $BUNDLE_ROOT/activate.sh"