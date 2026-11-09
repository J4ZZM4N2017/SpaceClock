# SpaceClock — A Little More Customizable

*A floating clock and countdown timer for macOS, with a few extra options.*

## Why this fork?

The [original SpaceClock](https://github.com/dsatyam09/SpaceClock) by [dsatyam09](https://github.com/dsatyam09) is a cute, simple little app. It does exactly what it promises: puts a clock or countdown timer on your Mac, keeps it visible across Spaces, and stays out of your way.

I liked that simplicity. I just needed a few things on top of it.

In particular, I wanted to decide **whether** the clock should stay above everything, make the digits much bigger when needed, choose a different font, and sometimes get rid of the background entirely. So I made a few small changes while trying to keep the original spirit intact.

This is a personal, slightly more customizable fork—not a redesign of the original app.

## What's different?

| Feature | Original SpaceClock | This fork |
| --- | --- | --- |
| Always on top | Always enabled | Optional toggle; enabled by default |
| Clock size | Small, Medium, Large, Huge | Adds Giant (100), Massive (140), and Custom Size (12–300) |
| Clock font | System Condensed | System Condensed, System Monospaced, System Rounded, or a custom font |
| Background | Always shown | Can be hidden |
| Border | Always shown | Can be hidden independently |
| Opacity | 100%, 85%, 60%, 40% | 10% to 100% in 10% steps |




### A cleaner floating clock

Turn off **Show Background** and **Show Border** to leave just the clock digits and controls floating over your desktop. The window shadow is also disabled when both are hidden.

Or keep either element enabled—background and border are independent settings.

### More control over the size and typeface

The original size presets are still there, plus **Giant**, **Massive**, and a custom size field for those occasions when a clock needs to be readable from across a room.

The **Font** menu offers three system font styles and a custom font picker.

### Optional always-on-top behavior

The original app is intentionally always on top. That makes perfect sense for its intended use, but I sometimes want a clock that behaves more like a regular floating window. **Always on Top** is now a switch, on by default.

### Finer opacity adjustment

Opacity can now be selected in **10% increments from 10% to 100%**, rather than the original four presets.

All these preferences are saved between launches.

## What hasn't changed?

The features that made the original useful are still here: the countdown timer, timer presets and custom durations, minute chimes, color-changing clock, optional date and seconds, 12/24-hour display, draggable position, Spaces support, and menu-bar controls.

It is still a small, native **Swift + AppKit** application, with no extra frameworks or web-based interface.

## Build

This fork uses the same single-file Swift approach as the original project. If you keep the original `build.sh` and project structure, replace `SpaceClock.swift` with the modified source and build using:

```sh
./build.sh
```

For installation details and the original usage guide, see the [upstream README](https://github.com/dsatyam09/SpaceClock#readme).

## Credits and license

**SpaceClock was created by [dsatyam09](https://github.com/dsatyam09/SpaceClock).** All credit for the original concept, design, and implementation goes to the original author.

This fork is based on that project and retains its **MIT License**. Keep the original copyright and license notice in redistributed copies.

Thanks for making such a neat little app open source.


## Install

You need **macOS 13 or later** and Apple's Command Line Tools, which provide the Swift compiler. If you don't have them, run this first:

```sh
xcode-select --install
```

Then:

```sh
git clone https://github.com/J4ZZM4N2017/SpaceClock.git
cd SpaceClock
./build.sh
open ~/Applications/SpaceClock.app
```

`build.sh` compiles the app and installs it to `~/Applications/SpaceClock.app`. Because you build it yourself on your own Mac, there's no "unidentified developer" warning.

After that, open it anytime from Spotlight (**⌘ Space**, type **SpaceClock**). To start it automatically, choose **Launch at Login** from its menu.

