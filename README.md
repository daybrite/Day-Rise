# Day Rise

The app every Day project starts as. This repository is the output of `day new`, kept as a
regenerated copy so you can see what the scaffold gives you before you run it: a welcome page, a
list with a detail editor, adaptive layout across size classes, settings, and a second window on
the desktop, all in one Rust codebase and rendered with the platform's own widgets on twelve
targets.

<p align="center">
  <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/macos-appkit/default/welcome.png" width="720" alt="The welcome page on macOS"></kbd>
</p>

## Run it in one command

Install the `day` CLI, then let it clone, build, and launch the app for your desktop:

```sh
cargo install day-cli
day launch --git https://github.com/daybrite/Day-Rise.git
```

`day doctor` lists what your platform's toolkit needs and prints the install command for anything
missing. The launch prints where it put the checkout, so you can open the code and change it. To
start your own app from the same scaffold instead:

```sh
day new app hello --toolkit macos-appkit --appid com.example.hello
```

## What the scaffold gives you

Four sections in a typed-route sidebar on the desktop, a list that pushes each section on a phone,
and the same Rust behind both. The Navigate section is a list with a detail editor, so the
scaffold already shows a data-carrying route, two-way bindings, and a filter. Settings is a
native form with the theme and language pickers wired to persisted preferences.

<p align="center">
  <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/ios-uikit/iphone/default/welcome.png" width="200" alt="Welcome on iPhone"></kbd>
  <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/ios-uikit/iphone/default/list.png" width="200" alt="The list on iPhone"></kbd>
  <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/ios-uikit/iphone/default/editor.png" width="200" alt="The detail editor on iPhone"></kbd>
  <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/ios-uikit/iphone/default/settings.png" width="200" alt="Settings on iPhone"></kbd>
</p>

The layout follows the window. The walkthrough resizes it through the compact, medium, and
expanded size classes and captures each one, and on the desktop it opens a second window from the
File menu:

<p align="center">
  <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/macos-appkit/default/compact.png" width="360" alt="The compact size class on macOS"></kbd>
  <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/macos-appkit/default/expanded.png" width="360" alt="The expanded size class on macOS"></kbd>
</p>
<p align="center">
  <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/macos-appkit/default/after-new-window.png" width="720" alt="A second window on macOS"></kbd>
</p>

## The same code on every platform

These captures come from the app's own CI, which runs the walkthrough on every target and
publishes the results to the [gallery](https://daybrite.dev/gallery/Day-Rise/).

| Windows · XAML | Linux · GTK | Linux · Qt |
|:---:|:---:|:---:|
| <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/windows-xaml/default/editor.png" width="300" alt="The editor on Windows"></kbd> | <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/linux-gtk/default/editor.png" width="300" alt="The editor on GTK"></kbd> | <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/linux-qt/default/editor.png" width="300" alt="The editor on Qt"></kbd> |

| Web · DOM | Android · Material | HarmonyOS · ArkUI |
|:---:|:---:|:---:|
| <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/web-dom/default/editor.png" width="300" alt="The editor in the browser"></kbd> | <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/android-mdc/pixel-5/default/editor.png" width="150" alt="The editor on Android"></kbd> | <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/harmony-arkui/default/list.png" width="150" alt="The list on HarmonyOS"></kbd> |

## Build from a clone

Day compiles one toolkit backend per binary, so name a target when you build or launch. Every
target the app ships is listed in `Day.toml`.

```sh
day doctor                       # toolchains present and missing, with fixes
day launch -p macos-appkit       # build + run
day launch -p ios-uikit          # needs a booted Simulator
day launch -p android-mdc        # needs a JDK and a running emulator or device
day launch -p web-dom            # serves the WebAssembly build locally
```

A bare `cargo build` uses the crate's default `mock` backend, which is what lets rust-analyzer and
`cargo check` work with no flags. To pick a toolkit from plain cargo, turn the default off first:

```sh
cargo build --no-default-features --features appkit    # or gtk / qt / uikit / mdc / xaml / dom
```

`dayscript/demo.yaml` is a [dayscript](https://daybrite.dev/docs/dayscript) that drives every
feature the scaffold ships and doubles as its UI test:

```sh
day launch -p macos-appkit --script dayscript/demo.yaml
```

## Inside the code

- `src/lib.rs` sets the app up once and opens the first window; `window_shell` is one window's
  UI, shared by every platform and by File ▸ New Window.
- `src/pages/welcome.rs`, `navigate.rs`, `detail.rs`, and `settings.rs` are the sections, one
  module per destination.
- `src/model.rs` is the item model the list and the editor share.
- `resource/locales/en/app.ftl` carries every user-facing string.
- `dayscript/demo.yaml` is the walkthrough; `store/` and `website/` are the store-listing and
  site stubs every scaffold gets.
- `platform/` holds the thin native host projects the mobile targets build through.

`day lint` checks routes, element ids, and locale coverage.
