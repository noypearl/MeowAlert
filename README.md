<img src="https://i.ibb.co/8hxM9LV/icon-512x512-2x.png" alt="icon-512x512-2x" border="0" height="150"/>

<a href="https://ibb.co/xr92Lrc"><img src="https://i.ibb.co/3P6TdP8/Screenshot-2026-03-15-at-4-32-41.png" alt="Screenshot-2026-03-15-at-4-32-41" border="0"></a>

# 🚨 MeowAlert (macOS)
### A Mac App that turns disturbing Red Alerts into funny Meme sounds
MeowAlert is a native macOS menu bar app that keeps an eye on the Home Front Command (Oref) feed so you don't have to. It lives in your menu bar, watches your specific cities, and lets you know when it's time to head to the mamad - without the immediate soul - crushing panic of the standard siren.
<br>
<br>
<img src="https://i.ibb.co/VYp9gVk7/Screenshot-2026-03-15-at-4-20-45.png" alt="Screenshot-2026-03-15-at-4-20-45" border="0" /><img src="https://i.ibb.co/cKWC0H92/Screenshot-2026-03-15-at-4-34-35.png" alt="Screenshot-2026-03-15-at-4-34-35" border="0">

### Developer Mode
<img src="https://i.ibb.co/67yZ0Jcm/Screenshot-2026-03-15-at-4-34-54.png" alt="Screenshot-2026-03-15-at-4-34-54" border="0" height="400">

### 🛡️ Why use this?
Meme - Grade Safety: Replace the heart-stopping "Siren" with a genZ meme sound or just your favorite 1-second meme MP3.

Menu Bar Stealth: It’s tiny, out of the way, and doesn’t hog your screen.

Fast as Lightning: Polls the official Pikud Haoref API every few seconds. If Pikud Haoref knows, you know.

Hyper-Local: Only get alerted for the cities you actually care about.

### 📖 Quick Start
1. Download [MeowAlert-mac.app.zip](https://github.com/noypearl/MeowAlert/releases/tag/1.0) from Releases.
2. Unzip it and move `MeowAlert.app` to `Applications`.
3. First launch: right-click `MeowAlert.app` -> `Open` -> `Open`.
4. Enable Notifications under Settings -> Notifications -> MeowAlert -> Allow Notifications
<img src="https://i.ibb.co/ksTpg1zB/Screenshot-2026-03-15-at-4-39-46.png" alt="Screenshot-2026-03-15-at-4-39-46" border="0" height="350">
5. Click the menu bar icon, add your city, and choose a sound.
6. Wait for the magic to happen. You can toggle Dev Tools to see & hear the custom notification sound


**If macOS blocks `MeowAlert.app`**
On some Macs, Gatekeeper may block the first launch with the following message:
<img src="https://i.ibb.co/Z1hYj7pD/Image-15-03-2026-at-23-31.jpg" alt="Image 15 03 2026 at 23 31" border="0">

If that happens, open `System Settings` -> `Privacy & Security`, scroll to the security warning for MeowAlert, click `Open Anyway`, then confirm by clicking `Open`.
<br><br>
<img src="https://i.ibb.co/Kz86G5S5/Image-15-03-2026-at-23-32.jpg" alt="Image-15-03-2026-at-23-32" border="0">

<br>
If installation is still blocked on your machine, you can run MeowAlert by building it directly from source!


### 🛠️ Build From Source
Prerequisites: `macOS 13+`, `Xcode 15+` `XcodeGen`.

Install [Xcode](https://developer.apple.com/xcode/)
Install [xcodegen](https://github.com/yonaskolb/xcodegen)
Run:
```bash
git clone https://github.com/noypearl/MeowAlert.git
cd MeowAlert
xcodegen generate   # only needed if .xcodeproj is not present
open MeowAlert.xcodeproj
```

In Xcode: select the `MeowAlert` scheme and press `Cmd + R`.

### Build a Standalone `.app` (No Xcode Run Needed)

If you want MeowAlert to run as a normal Mac app (persistent and independent of Xcode’s **Run** button), build a `Release` app bundle from Terminal:

```bash
xcodebuild -project MeowAlert.xcodeproj -scheme MeowAlert -configuration Release -derivedDataPath .xcode-derived build
```

After build completes, the app will be available at:
```bash
.xcode-derived/Build/Products/Release/MeowAlert.app
``` 
Move MeowAlert.app into your Applications folder and launch it like any regular macOS app.


### [!TIP]
Why build from source? You can verify that we aren't sending your data anywhere and that the "Polling" interval is truly as aggressive as you want it to be.



### Custom Sounds: You can upload your own `.mp3` file for alerts from the app menu. Need ideas? Browse meme sounds on [MyInstants](https://www.myinstants.com/en/search/), download an `.mp3`, then select it inside MeowAlert.

### How it works
MeowAlert runs quietly in your macOS menu bar and checks [the official Pikud HaOref](https://www.oref.org.il/warningMessages/alert/alerts.json) (Oref) alert feed every few seconds. When a new alert appears, it matches the alert locations against the cities you selected; if there is a match, it immediately plays your chosen sound (.mp3) and shows a notification so you can react fast. Everything happens locally on your Mac, and monitoring starts automatically when the app launches.


### 🎮 Usage Tips
Watched Areas: Use the autocomplete! It's better than guessing how the API spells "Rishon LeTsiyon."

Sound Check: Use the Test Alert button in Dev Mode to make sure your custom MP3 isn't too loud (or too quiet).

Stay Monitoring: The app starts monitoring automatically on launch. If the icon is grayed out, check your connection.


### Credits
Kudos to [this project](https://github.com/eladnava/pikud-haoref-api/tree/master) for publishing the cities.json file for quick city search
