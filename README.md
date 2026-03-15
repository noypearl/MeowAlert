

## 🚨 MeowAlert (macOS)
#### Mac App that turns disturbing Red Alerts into funny Meme sounds
MeowAlert is a native macOS menu bar app that keeps an eye on the Home Front Command (Oref) feed so you don't have to. It lives in your menu bar, watches your specific cities, and lets you know when it's time to head to the mamad—without the immediate soul-crushing panic of the standard siren.

### 🛡️ Why use this?
Meme-Grade Safety: Replace the heart-stopping "Siren" with a genZ meme sound or just your favorite 1-second meme MP3.

Menu Bar Stealth: It’s tiny, out of the way, and doesn’t hog your screen.

Fast as Lightning: Polls the official Pikud Haoref API every few seconds. If Pikud Haoref knows, you know.

Hyper-Local: Only get alerted for the cities you actually care about.

### 📖 Quick Start
1. Download `MeowAlert.app.zip` from Releases.
2. Unzip it and move `MeowAlert.app` to `Applications`.
3. First launch: right-click `MeowAlert.app` -> `Open` -> `Open`.
4. Click the menu bar icon, add your city, and choose a sound.

Custom Sounds: You can upload your own `.mp3` file for alerts from the app menu. Need ideas? Browse meme sounds on [MyInstants](https://www.myinstants.com/en/search/), download an `.mp3`, then select it inside MeowAlert.

### 🛠️ Build From Source
Prerequisites: `macOS 13+`, `Xcode 15+` (`XcodeGen` only if generating the project).

```bash
git clone https://github.com/noypearl/MeowAlert.git
cd MeowAlert
xcodegen generate   # only needed if .xcodeproj is not present
open MeowAlert.xcodeproj
```

In Xcode: select the `MeowAlert` scheme and press `Cmd + R`.

### [!TIP]
Why build from source? You can verify that we aren't sending your data anywhere and that the "Polling" interval is truly as aggressive as you want it to be.

### 🎮 Usage Tips
Watched Areas: Use the autocomplete! It's better than guessing how the API spells "Rishon LeTsiyon."

Sound Check: Use the Test Alert button in Dev Mode to make sure your custom MP3 isn't too loud (or too quiet).

Stay Monitoring: The app starts monitoring automatically on launch. If the icon is grayed out, check your connection.
