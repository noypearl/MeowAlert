## 🚨 MeowAlert (macOS)
Because the official siren gives us enough gray hair as it is.
MeowAlert is a native macOS menu bar app that keeps an eye on the Home Front Command (Oref) feed so you don't have to. It lives in your menu bar, watches your specific cities, and lets you know when it's time to head to the mamad—without the immediate soul-crushing panic of the standard siren.

### 🛡️ Why use this?
Meme-Grade Safety: Replace the heart-stopping "Siren" with a genZ meme sound or just your favorite 1-second meme MP3.

Menu Bar Stealth: It’s tiny, out of the way, and doesn’t hog your screen.

Fast as Lightning: Polls the official Pikud Haoref API every few seconds. If Pikud Haoref knows, you know.

Hyper-Local: Only get alerted for the cities you actually care about.

### 📖 How-To Guide
Option 1: The "I Just Want to Stay Safe" Way (Easy)
If you aren't a coder and just want the app to run:

Download: Go to the Releases page and download MeowAlert.app.zip.

Unzip: Double-click the file to reveal the MeowAlert.app.

Install: Drag the app into your Applications folder.

First Launch: * Since it's from a cool indie dev (you), macOS might be picky.

Right-click the app and select Open.

Click Open again on the pop-up.

Configure: Click the icon in your menu bar, add your city, and upload your funniest MP3.

Option 2: The "I’m a Hacker" Way (Building from Source)
For the senior researchers and devs who want to see under the hood:

### Prerequisites:

macOS 13+

Xcode 15+ (optional - optional - only for building app)

XcodeGen (If you don't have it: brew install xcodegen) (optional - only for building app)

### The Build Process:

Clone the repo:

Bash
git clone https://github.com/noypearl/MeowAlert.git
cd MeowAlert
Generate the project:
We use XcodeGen to keep the repo clean of messy .xcodeproj files. Run:

Bash
xcodegen generate
Build & Run:

Open the newly created MeowAlert.xcodeproj.

Select the MeowAlert scheme.

Hit Cmd + R to run it on your Mac.

### [!TIP]
Why build from source? You can verify that we aren't sending your data anywhere and that the "Polling" interval is truly as aggressive as you want it to be.

### 🎮 Usage Tips
Watched Areas: Use the autocomplete! It's better than guessing how the API spells "Rishon LeTsiyon."

Sound Check: Use the Test Alert button in Dev Mode to make sure your custom MP3 isn't too loud (or too quiet).

Stay Monitoring: The app starts monitoring automatically on launch. If the icon is grayed out, check your connection.
