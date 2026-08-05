cask "lidflow" do
  version "1.0.0"
  sha256 "f333ac2b4b2bd1d8209c1d1b82f44d074fe7b03c1540925b89cd24e689dbe6ff"

  url "https://github.com/umairnawaz333/LidFlow/releases/download/v#{version}/LidFlow.zip"
  name "LidFlow"
  desc "MacBook Lid Hinge Angle Sensor Sound Utility"
  homepage "https://github.com/umairnawaz333/LidFlow"

  app "LidFlow.app"

  zap trash: [
    "~/.gemini/antigravity",
  ]
end
