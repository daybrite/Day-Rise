# Day Rise

A small starting point for a Day app: a welcome page, a list with a detail editor, and settings,
rendered with native widgets from one Rust codebase.

This checkout is the reference app for `day new`. Run `scripts/scaffold-drift.sh --local`
to check it against the source template in the neighboring Day checkout.

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

Welcome and Items share adaptive navigation: the item list and editor appear side by side on a
wide window and stack on a phone. An item has just a name and a done flag. Start with an empty
list, add an item, and edit it through two-way bindings; changes are saved between launches.
Drag items to reorder them on platforms with native list reordering; the order is saved too.
The app also reopens on the section you last visited.

Creation, deletion, and reordering demonstrate `info!` console logging without logging item
contents. Failed saves produce a `warn!`; use `--env DAY_LOG=dayapp=debug` with `day launch`
to also see successful saves.

Settings provides theme and language preferences. It opens from the app menu on desktop and
appears as a navigation section on platforms without a menu bar. The app uses one main window.

<p align="center">
  <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/ios-uikit/iphone/default/welcome.png" width="200" alt="Welcome on iPhone"></kbd>
  <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/ios-uikit/iphone/default/list.png" width="200" alt="The list on iPhone"></kbd>
  <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/ios-uikit/iphone/default/editor.png" width="200" alt="The detail editor on iPhone"></kbd>
</p>

## The same code on every platform

These captures come from the app's own CI, which runs the smoke test on every target and
publishes the results to the [gallery](https://daybrite.dev/gallery/Day-Rise/).

| Windows · XAML | Linux · GTK | Linux · Qt |
|:---:|:---:|:---:|
| <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/windows-xaml/default/editor.png" width="300" alt="The editor on Windows"></kbd> | <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/linux-gtk/default/editor.png" width="300" alt="The editor on GTK"></kbd> | <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/linux-qt/default/editor.png" width="300" alt="The editor on Qt"></kbd> |

| Web · DOM | Android · Material | HarmonyOS · ArkUI |
|:---:|:---:|:---:|
| <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/web-dom/default/editor.png" width="300" alt="The editor in the browser"></kbd> | <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/android-mdc/phone/default/editor.png" width="150" alt="The editor on Android"></kbd> | <kbd><img src="https://daybrite.github.io/Day-Rise/gallery/harmony-arkui/phone/default/list.png" width="150" alt="The list on HarmonyOS"></kbd> |

## Build from a clone

Day compiles one toolkit backend per binary, so name a target when you build or launch. Every
target the app ships is listed in `Day.toml`.

```sh
day doctor                       # toolchains present and missing, with fixes
day launch -t macos-appkit       # build + run
day launch -t ios-uikit          # needs a booted Simulator
day launch -t android-mdc        # needs a JDK and a running emulator or device
day launch -t web-dom            # serves the WebAssembly build locally
```

A bare `cargo build` uses the crate's default `mock` backend, which is what lets rust-analyzer and
`cargo check` work with no flags. To pick a toolkit from plain cargo, turn the default off first:

```sh
cargo build --no-default-features --features appkit    # or gtk / qt / uikit / mdc / xaml / dom
```

`dayscript/demo.yaml` is a portable [dayscript](https://daybrite.dev/docs/dayscript) smoke test.
It opens Welcome, adds an item, edits its name and done flag, and deletes that same item. It
uses no platform-specific conditions, works with existing saved items, and captures Welcome,
the list, and the editor:

```sh
day launch -t macos-appkit --script dayscript/demo.yaml
```

## Inside the code

- `src/lib.rs` configures the app and builds the navigation and menus.
- `src/pages/mod.rs` declares the welcome, items, detail, and settings modules.
- `src/model.rs` holds the item model, selection, and JSON persistence, with unit tests at the end.
- `resource/locales/en/app.ftl` carries every user-facing string.
- `dayscript/demo.yaml` is the smoke test; `store/` and `website/` are the store-listing and
  site stubs every scaffold gets.
- `platform/` holds app-owned Apple host sources and any native resource customizations. Day generates the build projects under `build/`.

`day lint` checks routes, element ids, and locale coverage.


## Generated native projects

Use a Day CLI with automatic native project generation; Apple builds require **Xcode 27
or newer**. Xcode project documents, Android Gradle files, and HarmonyOS hvigor files are
created under `build/` by `day prepare`, `day build`, and `day launch`. Open the selected
project with `day open -t <target>`; edits to generated files are disposable. Apple Swift
sources, plists and `.xcconfig` files, and any Android resource overlays, remain app-owned
under `platform/`. For additional native configuration, use
`day project add-target <target> --persist-native-project` to create a persistent override.
