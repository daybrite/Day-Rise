# Day Rise

A small starting point for a [Day](https://daybrite.dev) app: a welcome page, a list with a
detail editor, and settings, rendered with native widgets from one Rust codebase. It is exactly
what `day new app` creates, kept as a runnable reference.

<p align="center">
  <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/macos-appkit/default/welcome.png" width="720" alt="The welcome page on macOS"></kbd>
</p>

## Run it

Install the `day` CLI, then let it clone, build, and launch the app for your desktop:

```sh
cargo install day-cli
day launch --git https://github.com/daybrite/Day-Rise.git
```

`day doctor` lists what your platform's toolkit needs and how to install it. To start your own
app from the same template, run `day new app hello --toolkit macos-appkit --appid com.example.hello`.

From a clone, name a target when you build or launch; `Day.toml` lists them all:

```sh
day launch -t macos-appkit       # build + run
day launch -t ios-uikit          # needs a booted Simulator
day launch -t android-mdc        # needs a JDK and a running emulator or device
day launch -t web-dom            # serves the WebAssembly build locally
```

## What it does

Welcome and Items share adaptive navigation: the item list and editor sit side by side on a wide
window and stack on a phone. Give an item a name, a type and a color, and mark it done; every
change is saved as you make it, and Undo and Redo step back through them. Search narrows the
list, a swipe or the context menu marks an item done, dragging reorders it, and the Items tab
counts what is left to do. Settings holds the appearance, the language, and the app's own
setting for completed items; About shows the app's name and version. On desktop both open from
the app menu; on a phone, Settings is a section. The app reopens on the section you last visited.

<p align="center">
  <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/ios-uikit/iphone/default/welcome.png" width="200" alt="Welcome on iPhone"></kbd>
  <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/ios-uikit/iphone/default/list.png" width="200" alt="The list on iPhone"></kbd>
  <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/ios-uikit/iphone/default/editor.png" width="200" alt="The detail editor on iPhone"></kbd>
</p>

## The code

- `src/lib.rs` sets up the window, the routes, the navigation, and the menus.
- `src/model.rs` holds the items and the selection they share, with the unit tests.
- `src/pages.rs` builds the Welcome page, the item list, and the editor.
- `resource/locales/en/app.ftl` holds every string the app shows.
- `dayscript/demo.yaml` walks through the app on every target and takes the screenshots.

## Every platform

The app's CI runs `dayscript/demo.yaml` on every target and publishes the captures to the
[gallery](https://daybrite.dev/gallery/Day-Rise/).

| Windows · WinUI | Linux · GTK | Linux · Qt |
|:---:|:---:|:---:|
| <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/windows-winui/default/editor.png" width="300" alt="The editor on Windows"></kbd> | <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/linux-gtk/default/editor.png" width="300" alt="The editor on GTK"></kbd> | <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/linux-qt/default/editor.png" width="300" alt="The editor on Qt"></kbd> |

| Web · DOM | Android · Material | HarmonyOS · ArkUI |
|:---:|:---:|:---:|
| <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/web-dom/default/editor.png" width="300" alt="The editor in the browser"></kbd> | <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/android-mdc/phone/default/editor.png" width="150" alt="The editor on Android"></kbd> | <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/harmony-arkui/phone/default/list.png" width="150" alt="The list on HarmonyOS"></kbd> |

## Keeping it in step with `day new`

`scripts/scaffold-drift.sh --local` scaffolds a fresh app from the template in a neighboring
Day checkout and reports every file that differs from this one.
