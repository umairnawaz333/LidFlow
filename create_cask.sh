#!/bin/bash
set -e

echo "=== Building LidFlow.app in Release Mode ==="
./build_app.sh

echo "=== Packaging LidFlow.app into LidFlow.zip ==="
rm -f LidFlow.zip
zip -q -r LidFlow.zip LidFlow.app

echo "=== Calculating SHA256 Checksum ==="
CHECKSUM=$(shasum -a 256 LidFlow.zip | awk '{print $1}')
echo "SHA256: $CHECKSUM"

echo "=== Generating lidflow.rb Cask Formula ==="
cat <<EOF > lidflow.rb
cask "lidflow" do
  version "1.0.0"
  sha256 "$CHECKSUM"

  url "https://github.com/umairnawaz333/LidFlow/releases/download/v#{version}/LidFlow.zip"
  name "LidFlow"
  desc "MacBook Lid Hinge Angle Sensor Sound Utility"
  homepage "https://github.com/umairnawaz333/LidFlow"

  app "LidFlow.app"

  postflight do
    system_command "xattr",
                   args: ["-rd", "com.apple.quarantine", "#{appdir}/LidFlow.app"],
                   sudo: false
  end

  zap trash: [
    "~/.gemini/antigravity",
  ]
end
EOF

echo ""
echo "========================================================="
echo " 🎉 Homebrew Cask 'lidflow.rb' generated successfully! "
echo "========================================================="
echo "Step 1: Create a GitHub Release in your repository (v1.0.0)"
echo "        Upload the 'LidFlow.zip' file as a release asset."
echo ""
echo "Step 2: Create a public GitHub repository named 'homebrew-tap'"
echo "        under your username: https://github.com/umairnawaz333/homebrew-tap"
echo ""
echo "Step 3: Commit and push 'lidflow.rb' to your 'homebrew-tap' repository"
echo "        in a folder named 'Casks/':"
echo "        Casks/lidflow.rb"
echo ""
echo "Once done, anyone can install your app by running:"
echo "  brew tap umairnawaz333/tap"
echo "  brew install --cask lidflow"
echo "========================================================="
