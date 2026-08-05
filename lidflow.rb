cask "lidflow" do
  version "1.0.0"
  sha256 "7e13338158e4711a685f8b3cf454dd63a400949ef37278db68d42aacbcac50c6"

  url "https://github.com/umairnawaz333/LidFlow/releases/download/v#{version}/LidFlow.zip"
  name "LidFlow"
  desc "MacBook Lid Hinge Angle Sensor Sound Utility"
  homepage "https://github.com/umairnawaz333/LidFlow"

  app "LidFlow.app"

  zap trash: [
    "~/.gemini/antigravity",
  ]
end
