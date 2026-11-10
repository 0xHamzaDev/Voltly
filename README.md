<div align="center">
    <img src="assets/logo.svg" width="128" height="128" alt="Voltly logo">
    <h1>Voltly</h1>
    <p>A macOS menu bar app that limits how far your MacBook charges, so the battery is not held at 100% all day.</p>
</div>

## Why

Lithium batteries age faster when they sit at a full charge, and faster still when they are warm. A MacBook that lives on the charger spends most of its life in both conditions. Voltly keeps the charge at a level you choose and pauses charging when the battery gets hot.

## Features

| Feature | What it does |
| --- | --- |
| Charge Limiter | Stops charging at the percentage you choose, from 20% to 100%. |
| Sailing Mode | After reaching the limit, waits until the battery drops a few percent before charging again. |
| Heat Protection | Pauses charging while the battery is at or above a set temperature (default 35°C). |
| Top Up | Charges to 100% once, then returns to your limit. |
| Discharge | Runs on battery while plugged in until the charge is back at your limit. |
| Automatic Discharge | Does the same whenever the charge is above the limit. |
| Discharge in Clamshell Mode | Allows discharging with the lid closed. |
| Calibration Mode | Charges to 100%, drains to 15%, charges to 100%, holds for an hour, then returns to the limit. |
| Schedule | Runs Top Up, Discharge, Calibrate or a limit change on set days and times. |
| Stop Charging when Sleeping | Pauses charging as the Mac goes to sleep. |
| Sleep Control | Keeps the Mac awake until the limit is reached, on Macs where Voltly controls charging directly. |
| Control MagSafe LED | Green while holding, orange while charging, off while discharging. |
| Low Power Mode Control | Always on, always off, or only on battery. |
| Apple Shortcuts Support | Set Charge Limit, Top Up Battery, Discharge Battery to Limit, Start Battery Calibration, Return to Charge Limit. |
| Customizable Menu Bar Icons | Choose the icon and show the battery percentage next to it. |
| Customizable Popover | Hide the status line, the action buttons or the quick toggles. |

## Requirements

* macOS 13 or later
* Apple Silicon MacBook

## Install

1. Download `Voltly-2.0-alpha.dmg` from [Releases](https://github.com/0xHamzaDev/Voltly/releases/latest) and open it.
2. Drag Voltly into Applications and open it.
3. If macOS blocks it, open System Settings > Privacy & Security and click "Open Anyway". The build is signed with a development certificate and is not notarized.
4. Enter your admin password once. This installs the helper that controls charging.

## Use

Click the Voltly icon in the menu bar, then drag the slider to your charge limit. macOS can take a minute or more to react to a new limit.

Recommended setup for a Mac that stays plugged in:

| Setting | Value |
| --- | --- |
| Charge limit | 80% |
| Sailing Mode | On |
| Heat Protection | On |
| Launch at login | On |

Press Top Up before a trip to charge to 100% once.

Quitting Voltly restores normal charging and your original macOS charge limit within about 10 seconds.

## How it works

Voltly runs a small privileged helper, installed on first launch, that only accepts connections from the Voltly app.

* On macOS 27 the charge limit is set through the system's own charge limit, so macOS keeps enforcing it while the Mac sleeps.
* On earlier systems Voltly stops and resumes charging itself through the SMC.
* Discharge works by cutting wall power through the SMC while the charger stays plugged in.

## Build from source

Open `Voltly.xcodeproj` in Xcode, set your own development team on both targets, and update the team identifier in the three places that pin it: `Voltly/Info.plist`, `com.hamz4.Voltly.Helper/Helper-Info.plist` and `com.hamz4.Voltly.Helper/main.swift`. Then build the `Voltly` scheme.

Check the charging logic without touching hardware:

```sh
Voltly.app/Contents/MacOS/Voltly --self-check
```

## Known limits

* Discharge and Calibration Mode have not been tested end to end on real hardware.
* Top Up, Discharge and Calibration state is lost if the app quits.
* A scheduled task is skipped if the Mac is asleep at its time.
* English only.

## Credits and license

Voltly is based on the legacy open-source code of [AlDente](https://github.com/AppHouseKitchen/AlDente-Battery_Care_and_Monitoring) by AppHouseKitchen, whose terms are in [LICENSE](LICENSE). It also uses [SMCKit](https://github.com/beltex/SMCKit) by beltex (MIT).

Copyright © 2020–2026 AppHouseKitchen GmbH for the original code.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
