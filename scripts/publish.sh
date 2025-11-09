#!/bin/bash

# Single Version Publishing Script for SPAvatarKit Flutter Plugin
# This script publishes the production version with dynamic SPAvatarKit download

set -e

echo "🚀 Publishing Script for SPAvatarKit Plugin"
echo "=========================================="

# Configuration
PACKAGE_NAME="sp_character_plugin"

# Version management - Update this when you want to release new versions
VERSION="1.0.0-beta.42"

# You can also use command line arguments to override version
if [ "$1" = "version" ] && [ -n "$2" ]; then
    VERSION="$2"
    echo "Version set to: $VERSION"
    exit 0
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to update version in pubspec.yaml
update_version() {
    print_status "Updating version to $VERSION in pubspec.yaml..."
    sed -i '' "s/version: .*/version: $VERSION/" pubspec.yaml
    print_success "Version updated to $VERSION"
}

# Function to validate package
validate_package() {
    print_status "Validating package..."
    
    # Run dart pub publish --dry-run
    if dart pub publish --dry-run 2>&1 | grep -q "Package validation failed"; then
        print_error "Package validation failed"
        return 1
    else
        print_success "Package validation passed"
        return 0
    fi
}

# Function to publish package
publish_package() {
    print_status "Publishing package to pub.dev..."
    
    if dart pub publish --force; then
        print_success "Package published successfully!"
        print_success "Package URL: https://pub.dev/packages/$PACKAGE_NAME"
    else
        print_error "Failed to publish package"
        return 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [command] [version]"
    echo ""
    echo "Commands:"
    echo "  version <version>  - Set version number (e.g., 1.0.0)"
    echo "  validate          - Validate package without publishing"
    echo "  publish           - Publish package to pub.dev"
    echo "  update-version    - Update version in pubspec.yaml"
    echo "  help              - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 version 1.0.0"
    echo "  $0 validate"
    echo "  $0 publish"
    echo "  $0 update-version"
}

# Main execution
case "$1" in
    "version")
        if [ -n "$2" ]; then
            update_version
        else
            print_error "Please provide a version number"
            show_usage
            exit 1
        fi
        ;;
    "validate")
        validate_package
        ;;
    "publish")
        if validate_package; then
            publish_package
        else
            print_error "Validation failed, not publishing"
            exit 1
        fi
        ;;
    "update-version")
        update_version
        ;;
    "help"|"--help"|"-h")
        show_usage
        ;;
    "")
        # No command provided, show usage
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
