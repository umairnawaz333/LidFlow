cask "lidflow" do
  version "1.0.0"
  sha256 "e8928de9562fba7cb8328bdcfb981ce204c51e0b9a0f4f36166bb57e08695dbb"

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
