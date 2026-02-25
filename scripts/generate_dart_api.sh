# frontend-repo/scripts/generate_dart_api.sh
#!/bin/bash
set -e

echo "🔄 Generating Dart API client from local backend spec..."

# Path to backend repo (adjust if needed)
BACKEND_PATH="../../dance_analysis_server"
SPEC_PATH="$BACKEND_PATH/docs/openapi.json"
OUTPUT_PATH="../lib/generated/api"

# Check if backend repo exists
if [ ! -f "$SPEC_PATH" ]; then
    echo "❌ Error: Backend OpenAPI spec not found at $SPEC_PATH"
    echo "   Make sure backend-repo is in the same parent directory"
    exit 1
fi

# Check if swagger_parser is installed
if ! dart pub global list | grep -q swagger_parser; then
    echo "📦 Installing swagger_parser..."
    dart pub global activate swagger_parser
fi

# Check if spec is up to date (optional)
echo "📋 Using spec from: $SPEC_PATH"
echo "   Last modified: $(stat -f "%Sm" "$SPEC_PATH" 2>/dev/null || stat -c "%y" "$SPEC_PATH" 2>/dev/null)"

# Clean previous generation
rm -rf "$OUTPUT_PATH"
mkdir -p "$OUTPUT_PATH"

# Change to project root where swagger_parser.yaml is located
cd "$(dirname "$0")/.." || exit 1

# Generate Dart code using swagger_parser (uses swagger_parser.yaml config)
dart pub global run swagger_parser

echo "✅ Dart API client generated successfully!"
echo "   Location: lib/generated/api/"
