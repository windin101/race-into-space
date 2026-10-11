# Engine and language options for a cleanroom, high-resolution reimplementation of a 1993 turn-based space-race management game (state as of 2026-10-11)

Scope note: this survey covers open-source engines/frameworks and UI libraries for a 2D, turn-based, screen-and-menu-driven management sim with an illustrated base view, data-heavy UI screens, scripted mission playback (animation/video) and modest audio. Linux is the first-class target. The existing GPL "raceintospace" codebase was deliberately not consulted. All version numbers and dates were checked against primary pages in October 2026 where possible; where only secondary sources were available this is flagged.

## Key Question 1: Per-candidate profile (licence, language, 2D/HiDPI, UI toolkit, scaling, video, platforms, build/export, community cadence, shipped games, weaknesses)

### Takeaway
Of the roughly twenty candidates, only Godot 4.6, the TypeScript web stack (PixiJS 8 / Phaser 4 inside Electron or Tauri), Ren'Py 8.5, libGDX 1.14, and a hand-rolled SDL3 + RmlUi/Clay stack combine an OSI licence, an active 2026 release cadence, a usable data-heavy UI story and some form of video playback. Defold and Flax fail the open-source requirement outright; Bevy, LÖVE, raylib, Macroquad, Ebitengine and MonoGame/FNA are open and active but ship either no UI toolkit, no video playback, or both.

### Cited Findings

**Godot 4.x (GDScript, C#)**
- Licence: "Godot is released under the MIT License"; the only shipping obligation is to make the licence text available (credits screen, licences menu, accompanying file, etc.), and Godot recommends shipping its `COPYRIGHT.txt` for third-party components — [Godot docs: Complying with licenses](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html)
- Current release is Godot 4.6; the official release page lists Jolt as the default 3D physics engine for new projects, a new "Modern" editor theme, floating/dockable panels, LibGodot (embedding the engine as a library; initial release supports Linux, Windows and macOS), Direct3D 12 default on new Windows projects, Control-node changes (`pivot_offset_ratio`, separated mouse/keyboard focus) and delta-encoded patch PCKs — [godotengine.org/releases/4.6](https://godotengine.org/releases/4.6/)
- GameFromScratch's "Godot 4.6 Released" article carries a 26 January 2026 byline — [GameFromScratch](https://gamefromscratch.com/godot-4-6-released/); a secondary aggregator instead dates it to 27 February 2026 — [cinevva](https://app.cinevva.com/de/news/2026-02-27-godot-4-6-released). The late-January date from the primary-adjacent source is the more credible one.
- 2025 cadence: Godot 4.4 was released in March 2025 and Godot 4.5 in mid-September 2025 — [search summary citing GamingOnLinux/Godot forum](https://gamingonlinux.com/articles/category/Godot%20Engine/page=2)
- Resolution/DPI: Godot designs for a base size then scales; Stretch Mode is "Disabled", "Canvas Items" or "Viewport"; Stretch Aspect is Ignore/Keep/Keep Width/Keep Height/Expand; `content_scale_factor` ("Stretch Scale") is "a good candidate for a player-facing accessibility option"; Stretch Scale Mode (since 4.2) is "fractional" or "integer"; "Allow hiDPI" applies only on Windows and macOS; for a 4K base the docs say to raise Default Theme Scale to roughly 2.0–3.0 and to enable mipmaps on 2D textures or import SVGs as DPITexture; for ultrawide use Canvas Items + Expand with anchored Controls — [Godot docs: Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)
- SVG: "Godot uses the ThorVG library for SVG rendering", "SVG feature support is limited", "By default, SVGs are rasterized at import-time", and "SVG is the only image format that can be imported as DPITexture", which "allows for run-time rasterization to match the current oversampling factor" — [Godot docs: Importing images](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html)
- Fonts: MSDF "allows rendering fonts at any size, without having to re-rasterize them when their size changes", "will always look crisp, even at huge sizes", but "Fonts at small sizes will not look as clear as rasterized fonts, due to the lack of hinting" — [Godot docs: Using Fonts](https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_fonts.html)
- Video: "The only supported format in core is Ogg Theora"; "H.264 and H.265 cannot be supported in core Godot, as they are both encumbered by software patents"; "AV1 is royalty-free, but it remains slow to decode on the CPU"; WebM core support "was removed in 4.0"; streaming from URL is unsupported; extensions can add other formats — [Godot docs: Playing videos](https://docs.godotengine.org/en/stable/tutorials/animation/playing_videos.html)
- C#: "Since Godot 4.2, projects written in C# support all desktop platforms (Windows, Linux, and macOS)"; Android and iOS are "currently experimental"; "Currently, projects written in C# cannot be exported to the web platform" — [Godot docs: C# basics](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/index.html)
- Shipped UI-heavy games: Slay the Spire II was moved from Unity to Godot after Unity's 2023 runtime-fee policy, which required updating about two years of development; it launched in early access on 5 March 2026; Mega Crit is a Godot Gold Sponsor — [Game Developer](https://gamedeveloper.com/business/slay-the-spire-devs-followed-through-on-abandoning-unity); [80.lv](https://80.lv/articles/slay-the-spire-2-is-sticking-with-godot-leaving-unity-behind/); [Wikipedia](https://en.wikipedia.org/wiki/Slay_the_Spire_II)
- Shipped management sim: Hive Time (Cheeseness, December 2019, Windows/macOS/Linux) is a bee-colony management sim built in Godot; the developer said Godot let him assemble the core game quickly and its open-source nature let him modify the engine — [Godot showcase](https://godotengine.org/showcase/hive-time); [Godot showcase interview](https://godotengine.org/article/godot-showcase-cheeseness-hive-time); [itch.io](https://cheeseness.itch.io/hive-time)

**Bevy (Rust)**
- Licence: dual MIT / Apache 2.0; README warns "Bevy is still in the early stages of development. Important features are missing" and that breaking releases arrive "approximately once every 3 months" — [GitHub bevyengine/bevy](https://github.com/bevyengine/bevy)
- Cadence: 0.16 (24 Apr 2025), 0.17 (30 Sep 2025), 0.18 (13 Jan 2026), 0.19 (19 Jun 2026), 0.20 (8 Oct 2026, 227 contributors, 817 PRs) — [bevy.org/news](https://bevy.org/news/). (A secondary blog claiming 0.18 shipped in March 2026 is contradicted by the official page — [strayspark blog](https://www.strayspark.studio/blog/bevy-rust-game-engine-2026-indie-guide).)
- UI in 0.20: Feathers is "Bevy's opinionated editor-centric UI toolkit" with new Color Input, List View/Scrollbar, Dropdown, Lazy Menu and Number Input widgets and contextual theming; `bevy_ui_widgets` gains headless `TabList`/`Tab`; UI scaling is via `em`/`rem` units with a global `RemSize` resource; `InlineBox`/`InlineImage` for inline content in text; no dedicated editor section (a `.bsn` format "for tool-driven (read: editor) authoring" is upcoming); video playback is not mentioned — [Bevy 0.20 release notes](https://bevy.org/news/bevy-0-20/)
- Alternative UI: egui's README says it is "common to use `egui` from a game engine (using e.g. `bevy_egui`)" — [GitHub emilk/egui](https://github.com/emilk/egui)
- Shipped: Tiny Glade is reported (forum-level evidence only) to use Bevy for ECS with a custom Vulkan renderer; one commenter noted they could not find a developer statement confirming the shipped build uses Bevy — [Lemmy thread](https://lemmy.korz.dev/post/1328354/2037060); [Reddit mirror](https://red.127.pp.ua/r/rust/comments/1bcdjem/the_bevy_foundation/kuf85iz/?context=3)

**LÖVE / Love2D (Lua)**
- Licence: zlib; latest stable 11.5 released 3 December 2023; 12.0 ("Bestest Friend") is listed as "In development"; video support (OGV/Theora) was added in 0.10.0 (22 Dec 2015); notable games include Balatro (2024), Moonring (2023), Gravity Circuit (2023), Kingdom Rush (2011) — [Wikipedia: Löve](https://en.wikipedia.org/wiki/L%C3%B6ve_(game_framework))
- GitHub releases page still shows 11.5 as "Latest" (hotfixes through 8 April 2024); no 12.0 release is listed — [GitHub love2d/love releases](https://github.com/love2d/love/releases)
- In April 2025 a core developer said 12.0 would ship "when it's ready (but definitely this year)", with nightly desktop builds via GitHub Actions — [LÖVE forum](https://www.love2d.org/forums/viewtopic.php?p=262394). That 2025 target was not met per the releases page above.

**raylib (C, 70+ bindings)**
- Licence: zlib ("zlib/libpng" OSI-certified); latest stable v6.0 released 23 April 2026; bindings to more than 70 languages "though many of these ports are not stable"; raygui (immediate-mode GUI) moved to a separate repo in raylib 4.2 (Aug 2022) — [Wikipedia: Raylib](https://en.wikipedia.org/wiki/Raylib)
- 6.0 adds a CPU software renderer (`rlsw`), Memory/Win32/Emscripten platform backends, "Redesigned fullscreen and High-DPI scaling" (High-DPI is opt-in via `FLAG_WINDOW_HIGHDPI`), a new file-system API and a redesigned `config.h`; 5.5 added an SDL3 backend, RGFW backend, one-click WebAssembly builds and a project creator — [GitHub raysan5/raylib releases](https://github.com/raysan5/raylib/releases)

**SDL3 directly (C/C++, Rust and other bindings)**
- Licence: SDL 2.0 and newer use the zlib licence (SDL 1.2 and older were LGPL) — [libsdl.org/license.php](https://www.libsdl.org/license.php)
- Cadence: 3.4.0 "Major feature release" on 1 January, then stable bugfix releases roughly monthly (3.4.2 21 Feb … 3.4.16 2 Sep, 3.4.18 2 Oct) with 3.4.18 assets timestamped 2026; 3.4.0 added a new GPU-based 2D renderer and GPU device properties, and a hint for scaling cursors with the display scale; 3.4.4 covers Wayland window sizing and cursor scaling with pointer scale — [GitHub libsdl-org/SDL releases](https://github.com/libsdl-org/SDL/releases)
- Rust: the `sdl3` crate 0.20.0 lists SDL_ttf, SDL_image and SDL_mixer as supported; `sdl3-sys` 0.6.0 binds SDL 3.2.0–3.4.0; `sdl3-ttf-sys` binds SDL_ttf 3.2.0–3.2.2 — [docs.rs sdl3 0.20.0](https://docs.rs/crate/sdl3/0.20.0); [rust-digger sdl3-sys](https://rust-digger.code-maven.com/crates/sdl3-sys); [docs.rs sdl3-ttf-sys](https://docs.rs/docs.rs/sdl3-ttf-sys)
- Third-party 2D helper: SDL_gp, a single-header 2D painter on SDL_GPU, was announced July 2026 — [zeli.app story](https://zeli.app/story/49110655)

**Phaser 4 / PixiJS 8 / Excalibur with Electron or Tauri (TypeScript)**
- Phaser 4 versions: v4.0.0 "Caladan" 10 Apr 2026, v4.1.0 "Salusa" 30 Apr 2026, v4.2.0 "Giedi" 19 Jun 2026, v4.2.1 9 Jul 2026 — [phaser.io/download/phaser4](https://phaser.io/download/phaser4); the 4.0 launch "introduces a completely revamped WebGL-based renderer" — [GameDev.net](https://gamedev.net/news/2759-phaser-4-released/)
- PixiJS: MIT licence; "WebGL & WebGPU Renderers"; docs on the 8.x line — [GitHub pixijs/pixijs](https://github.com/pixijs/pixijs); PixiJS v8 launched March 2024 — [pixijs.com blog archive](https://pixijs.com/blog/archive)
- Excalibur: "licensed under the 2-clause BSD license", "a free game engine written in TypeScript", HTML5 canvas, "still in version 0.x" — [GitHub excaliburjs/Excalibur](https://github.com/excaliburjs/Excalibur)
- Tauri: MIT or MIT/Apache 2.0; webviews are WebView2 (Windows 7+), WKWebView (macOS 10.15+, iOS 9+), WebKitGTK (Linux; v2 needs webkit2gtk 4.1, e.g. Ubuntu 22.04), Android System WebView — [GitHub tauri-apps/tauri](https://github.com/tauri-apps/tauri)
- Tauri vs Electron for games: a developer packaging a JS game found it "wouldn't render the same across platforms since every operating system had a webview based on a different engine" and judged that "a deal breaker" versus Electron — [JSLegendDev Substack](https://jslegenddev.substack.com/p/the-struggle-of-wrapping-a-javascript); an itch.io commenter reported a Tauri demo "unplayable even on proton" because of a webview problem, and the developer planned a WebKitGTK Linux build instead — [itch.io post](https://itch.io/post/16353658); a small HTML5 game built with Tauri was "only 8 megabytes" versus an estimated 100 MB+ for Electron — [html5gamedevs](https://www.html5gamedevs.com/topic/47262-3-mb-native-html5-game-with-tauri/)

**Defold (Lua)**
- The Defold License is derived from Apache 2.0 with an added Section 4(a): you must not "sell or otherwise commercialise the Work or Derivative Works as a Game Engine Product"; the page never mentions OSI approval — [defold.com/license](https://defold.com/license/)
- The Defold Foundation acknowledged that "the Open Source Initiative defines the term Open Source to always allow Open Source software to be commercialised" and the project uses the term "source available" — [Defold blog, May 2020](https://defold.com/2020/05/20/Some-thoughts-on-the-open-source-discussion/); [Wikipedia: Defold](https://en.wikipedia.org/wiki/Defold)
- A forum user noted the licence's "Game Engine Product" definition covers both authoring software and runtime, leaving tools built on Defold in a grey area — [Defold forum](https://forum.defold.com/t/limitations-of-defolds-open-source-license/77600)
- Conclusion: does not meet the project's OSI-licence requirement.

**Flax Engine (C++/C#)**
- Sources are "licensed under Flax EULA"; commercial products owe a "4% royalty on earnings exceeding $250,000 per calendar quarter" (gross, per game); source and modifications may only be shared with other licensees of the same engine version; the page makes no open-source claim — [flaxengine.com/faq](https://flaxengine.com/faq/). (An older Phoronix piece cited a $25k threshold — [Phoronix](https://www.phoronix.com/news/Flax-Engine-1.2.6222) — the official FAQ figure of $250k is current.)
- Conclusion: royalty-bearing EULA; excluded.

**O3DE (C++, Lua/Python scripting)**
- Apache 2.0, Linux Foundation / Open 3D Foundation, originated from Amazon Lumberyard; 26.05.0 is listed as stable (27 May 2026) with a new particle system — [Wikipedia: Open 3D Engine](https://en.wikipedia.org/wiki/Open_3D_Engine); 25.05.0 was announced 18 June 2025 with "Enhanced Robotics Simulation" — [Linux Foundation blog](https://www.linuxfoundation.org/blog/open-3d-foundation-launches-o3de-25.05.0-release)

**Stride (C#)**
- MIT; the homepage says Stride 4.4 is "out now" and the engine is "fit for both 2D and 3D games", with highlights (photorealistic rendering, VR) that are 3D-oriented — [stride3d.net](https://www.stride3d.net/); 4.3 release notes dated 14 November 2025 (fully aligned with .NET 10, Bepu physics, Vulkan compute) — [Stride 4.3 release notes](https://doc.stride3d.net/latest/en/releasenotes/); samples for 4.4.0-beta8 were announced 19 Sep 2026 with a new 2D Platformer template — [GameDev.net](https://gamedev.net/news/5924-stride-samples441-released/)

**HaxeFlixel / OpenFL (Haxe)**
- MIT; "built on top of Haxe and OpenFL"; flixel-ui exists as an ecosystem add-on — [GitHub HaxeFlixel/flixel](https://github.com/HaxeFlixel/flixel); 6.1.0 changelog dated 28 April 2025, 6.2.0 ("Sound refactor, FlxMatrixSprite and tilemap ray methods") is the newest on Haxelib — [lib.haxe.org flixel versions](https://lib.haxe.org/p/flixel/versions/); [6.2.0 changelog](https://lib.haxe.org/p/flixel/6.2.0/changelog)

**MonoGame / FNA (C#)**
- MonoGame: Microsoft Public License (MS-PL) "except for a few portions"; desktop Windows 10 22H2+, Linux glibc 2.27+, macOS 13+; mobile Android 6+/iOS 12.2+; consoles for registered developers; 3.8.5 has Vulkan and DirectX 12 "in preview"; games include Stardew Valley, Celeste, Carrion, Streets of Rage 4 — [GitHub MonoGame/MonoGame](https://github.com/MonoGame/MonoGame)
- Cadence: 3.8.4 on 9 June 2025 — [MonoGame blog 3.8.4](https://monogame.net/blog/2025-06-09-monogame-384/); 3.8.5 on 15 July 2026 and 3.8.5.1 on 14 August 2026 — [MonoGame blog](https://monogame.net/blog)
- FNA: "released under the Microsoft Public License" (LzxDecoder dual MS-PL/LGPL 2.1; Mono.Xna code MIT) — [fna-xna.github.io/license](https://fna-xna.github.io/license/); primary targets Windows and GNU/Linux, plus macOS/iOS/tvOS, Xbox, Switch, PS5; "will not act as a gateway into proprietary products"; Ethan Lee has shipped "more than four dozen ports of XNA games" — [fna-xna.github.io](https://fna-xna.github.io/)
- FNA video: Theorafile "is a library for quickly and easily decoding Ogg Theora videos", zlib-licensed, "written for FNA's VideoPlayer" — [GitHub FNA-XNA/Theorafile](https://github.com/FNA-XNA/Theorafile)

**libGDX (Java/Kotlin)**
- Apache 2.0, community-maintained; 1.14.1 and 1.14.2 announced 28 May 2026; targets Windows, macOS, Linux (incl. Raspberry Pi), Android, iOS, HTML5; games listed include Pathway, Space Haven, Delver — [libgdx.com](https://libgdx.com/); 1.14.0 dated 20 Oct 2025 — [libgdx.com feed](https://libgdx.com/feed.xml); Wikipedia lists 1.14.2 as 5 June 2026 (one-week discrepancy with the site) — [Wikipedia: libGDX](https://en.wikipedia.org/wiki/LibGDX)
- gdx-video (Apache 2.0): desktop supports WebM VP8+Vorbis, WebM VP9+Opus and MKV AV1+Opus; MP4/H.264 is not supported on desktop by default ("more formats can be enabled by compiling gdx-video yourself"); Android/iOS/Web support varies by codec — [GitHub libgdx/gdx-video](https://github.com/libgdx/gdx-video)

**Qt / QML (Qt Quick)**
- Qt 6.12 licensing page: commercial, LGPL v3, or GPL v3; GPL-only modules include Qt Quick 3D, Qt Quick 3D Physics, Qt Quick Timeline, Qt Lottie Animation, Qt Graphs, Qt Virtual Keyboard, Qt Qml Compiler and others; docs under GFDL 1.3, examples under BSD-3 — [doc.qt.io licensing](https://doc.qt.io/qt-6/licensing.html)
- Cadence: Qt 6.11.1 (13 May 2026), Qt 6.11.2 (18 Aug 2026), Qt 6.12 LTS (30 Sep 2026); commercial-only LTS patch releases of 6.8 continue — [qt.io blog releases tag](https://www.qt.io/blog/tag/releases)
- Video: Qt Multimedia's FFmpeg backend "is the default on all platforms except WebAssembly and embedded Linux/Boot2Qt"; Windows Media Foundation deprecated since 6.10; bundled FFmpeg 9.0.1 is under LGPL v2.1+/BSD/ISC/MIT/MPL terms and the prebuilt libraries "include only features under the permissive licenses"; Qt Multimedia itself is LGPL v3 / GPL v2 / commercial — [doc.qt.io Qt Multimedia](https://doc.qt.io/qt-6/qtmultimedia-index.html)

**Ebitengine (Go)**
- v2.9.0 released 8 Oct 2025 with a new vector-graphics renderer, Go 1.24+ — [Ebitengine v2.9.0 blog](https://ebitengine.org/en/blog/v2.9.0.html); v2.10.0 released 8 Sep 2026: macOS and Linux/BSD builds no longer need Cgo so games "can now be built for all desktop platforms with Go alone", application-virtualization mode, experimental shader precompilation, `text/v2` colour emoji and bidi improvements, Go 1.25+ — [Ebitengine v2.10.0 blog](https://ebitengine.org/en/blog/v2.10.0.html)

**Ren'Py (Python)**
- Licence: "Most of Ren'Py" is MIT; parts derive from LGPL code and bundled deps include LGPL FFmpeg, Fribidi, libusb and part of Pygame_SDL2; games "must be distributed in a manner that satisfies the LGPL"; binaries also include AOM/Alliance for Open Media patent-licensed code — [renpy.org licence](https://www.renpy.org/doc/html/license.html)
- Cadence: 8.4 released 6 July 2025, 8.4.1 on 25 July 2025, 8.5 on 17 November 2025 — [renpytom Patreon sitemap](https://www.patreon.com/renpytom/sitemap)
- Video: codecs AV1, VP9, VP8, Theora, MPEG-4 part 2, MPEG-2, MPEG-1; audio Opus/Vorbis/MP3/MP2/FLAC/PCM; containers WebM, MKV, Ogg, AVI, MPEG streams; no alpha channel (use `side_mask`); on Web "the list of supported codecs differs from browser to browser" — [renpy.org Movie docs](https://www.renpy.org/doc/html/movie.html)
- Shipped management-adjacent game: Long Live the Queen (Hanako Games, 2 June 2012, Windows/Mac/Linux; later PS4/PS5/Switch/Xbox) is a raising/political sim on Ren'Py — [Wikipedia](https://en.wikipedia.org/wiki/Long_Live_the_Queen_(video_game))

**Macroquad (Rust)**
- Dual-licensed (LICENSE-APACHE and LICENSE-MIT files); docs badge 0.4.5; Windows/Linux/macOS, HTML5 (WASM), Android, iOS; "Immediate mode UI library included"; 752 commits, 262 open issues, 83 open PRs, ~4.7k stars — [GitHub not-fl3/macroquad](https://github.com/not-fl3/macroquad)
- egui bridge: egui-macroquad (Apache-2.0, ~122 stars as of April 2026) — [oosmetrics](https://oosmetrics.com/repo/optozorax/egui-macroquad); an early-2025 guide pairs egui 0.29 with macroquad 0.4 — [Rodney Lab](https://rodneylab.com/macroquad-egui-devtools/)

**UI libraries**
- Godot Control nodes/theming: see Godot entries above (Default Theme Scale, MSDF, DPITexture, `content_scale_factor`).
- egui: "MIT OR Apache-2.0"; "egui aims to be the best choice when you want a simple way to create a GUI" and for adding a GUI to a game engine; official `egui-wgpu` and `egui_glow` integrations; "All coordinates are in logical 'points' which may consist of many physical pixels"; production example is the Rerun Viewer (not a game) — [GitHub emilk/egui](https://github.com/emilk/egui); 0.34.0 switched font rendering to skrifa + vello_cpu (hinting, variable fonts) and reworks the entry point so `App::ui` replaces `App::update` — [newreleases egui 0.34.0](https://newreleases.io/project/github/emilk/egui/release/0.34.0); 0.33.2/0.33.3 are patch releases — [egui 0.33.3](https://newreleases.io/project/github/emilk/egui/release/0.33.3)
- Dear ImGui: MIT; designed to "empower programmers to create content creation tools and visualization / debug tools (as opposed to UI for the average end-user)"; 1.92.6 demo binaries dated 2026-02-25 — [GitHub ocornut/imgui](https://github.com/ocornut/imgui); the "Software using dear imgui" wiki lists Alan Wake 2, Control, Diablo IV, Doom: The Dark Ages, League of Legends, Rainbow Six Siege, S.T.A.L.K.E.R. 2 and others, but does not say whether use is player-facing or tooling — [ImGui wiki](https://github.com/ocornut/imgui/wiki/Software-using-dear-imgui); 1.92.9b hotfix (Drag/Slider ctrl-click flicker, table borders) — [GameDev.net](https://gamedev.net/news/4824-dear-imgui-v1929b-released/)
- Nuklear: "avaliable under either the MIT License or public domain"; ANSI C, no default render backend, demo backends for GLFW/SDL/X11/GDI/Direct3D/Vulkan; 250 open issues, 65 open PRs, no tagged releases — [GitHub Immediate-Mode-UI/Nuklear](https://github.com/Immediate-Mode-UI/Nuklear)
- RmlUi: HTML/CSS-like C++ UI (XHTML1/CSS2 with some HTML5/CSS3), "you bring your own renderer"; README says "We are moving towards the release of RmlUi 6.0" and that CMake scripts were rewritten — [RmlUi readme](https://github.com/mikke89/RmlUi/blob/master/readme.md); releases page lists 6.0 (26 Aug), 6.1 (20 Apr), 6.2 (11 Jan), 6.3 (22 Aug; years not shown on page); 6.3 scales form-control intrinsic sizes by dp-ratio and reworks the Lua data model, 6.2 adds an SVG cache and inline SVG in markup and fixes high-DPI mouse positions in SDL3 backends, 5.1 made the Lua plugin compatible with Lua 5.1+/LuaJIT, 6.3 adds GLFW DX11/DX12 backends — [GitHub mikke89/RmlUi releases](https://github.com/mikke89/RmlUi/releases)
- Clay: zlib; single-header C flexbox-style layout, renderer-agnostic (raylib example and HTML renderer in repo), text measurement via `Clay_SetMeasureTextFunction` with a cache that must be reset on "DPI changes" — [GitHub nicbarker/clay](https://github.com/nicbarker/clay); latest tag v0.14 (6 June 2025), v0.13 (12 Feb 2025) — [Clay tags](https://github.com/nicbarker/clay/tags)
- Web-tech UI (HTML/CSS inside Electron/Tauri): see Tauri/Electron findings above.

**Excluded non-open-source engines (one line each)**
- Unity: proprietary; its 2023 per-install "runtime fee" policy, later reversed, is what drove Mega Crit to Godot — [Game Developer](https://gamedeveloper.com/business/slay-the-spire-devs-followed-through-on-abandoning-unity). Unreal, GameMaker and Construct are proprietary/royalty- or subscription-based and excluded by the brief's OSI requirement (no further research done).

### Inferences
- Godot is the only candidate that bundles, under one MIT licence, a retained-mode UI toolkit with containers/theming, an explicit integer-scaling mode, SVG-as-DPITexture, MSDF fonts, a built-in video player and one-click exports to Linux/Windows/macOS/web/mobile.
- Bevy's Feathers is explicitly "editor-centric"; it is not yet positioned as a game-facing UI toolkit, and the quarterly breaking releases mean an indie project would spend real time on migrations.
- LÖVE's 12.0 has been "in development" with a missed 2025 target; 11.5 (Dec 2023) is stable but old. Balatro proves a UI-heavy card game ships on it, but the project must bring its own UI toolkit.
- raylib, Macroquad, Ebitengine and MonoGame/FNA have no built-in retained-mode UI suited to budget tables and rosters; they need Clay/raygui/egui/third-party layers.
- Defold and Flax are disqualified on licence; O3DE and Stride are 3D-first engines whose 2D/UI story is incidental.

### Gaps
- Ebitengine's licence (commonly listed as Apache 2.0) was not confirmed on any page fetched here.
- RmlUi's licence (MIT per general knowledge) was not stated on the fetched release page; the release years for 6.0–6.3 are not shown on the GitHub page.
- Phaser 4's licence was not on the download page fetched (phaser.io/download/license was not read).
- No source was found ranking FNA's release cadence or its SDL3/SDL_GPU backend status in 2026.
- No primary source was found for raylib's video playback story (none exists in core as far as this research found).
- No 2025–2026 Steam list of Godot management/strategy titles was found beyond Slay the Spire II and Hive Time.

## Key Question 2: Which candidates best suit a turn-based, mostly-UI management game? Ranking and justification

### Takeaway
Ranked on the brief's technical requirements: (1) Godot 4.6 with GDScript; (2) TypeScript web stack (PixiJS 8 or Phaser 4 + HTML/CSS UI) in Electron, with Tauri as a size-optimised but riskier alternative; (3) Ren'Py 8.5; (4) SDL3 + RmlUi (C++ or Rust) custom engine; (5) libGDX/Kotlin; then Bevy, LÖVE, raylib+Clay, MonoGame/FNA, Qt/QML, Macroquad, Ebitengine and HaxeFlixel as viable-but-weaker; Stride/O3DE unsuitable; Defold/Flax excluded.

### Cited Findings
- Godot's UI docs give explicit 4K/ultrawide guidance (Default Theme Scale 2.0–3.0, Canvas Items + Expand with anchored Controls) and a player-facing `content_scale_factor` accessibility knob — [Godot docs: Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)
- Godot's only core video codec is Theora; AV1/WebM/H.264 are not in core — [Godot docs: Playing videos](https://docs.godotengine.org/en/stable/tutorials/animation/playing_videos.html)
- Godot 4.6 adds LibGodot (embed engine as a library) on Linux/Windows/macOS first — [godotengine.org/releases/4.6](https://godotengine.org/releases/4.6/)
- A large UI-driven card game (Slay the Spire II) shipped on Godot in March 2026 after a two-year port — [80.lv](https://80.lv/articles/slay-the-spire-2-is-sticking-with-godot-leaving-unity-behind/)
- Ren'Py decodes AV1/VP9/VP8/Theora and more, the widest open-codec coverage of any candidate — [renpy.org Movie docs](https://www.renpy.org/doc/html/movie.html); Ren'Py's distribution obligations include satisfying the LGPL — [renpy.org licence](https://www.renpy.org/doc/html/license.html)
- Tauri's per-platform webviews (WebKitGTK/WebView2/WKWebView) caused cross-platform rendering differences that one JS-game developer called a "deal breaker" — [JSLegendDev Substack](https://jslegenddev.substack.com/p/the-struggle-of-wrapping-a-javascript); [GitHub tauri-apps/tauri](https://github.com/tauri-apps/tauri)
- RmlUi 6.x provides HTML/CSS-like layout with dp-ratio scaling, inline SVG and SDL3 backends — [RmlUi releases](https://github.com/mikke89/RmlUi/releases)
- SDL3 3.4.x ships monthly bugfix releases and a GPU 2D renderer — [SDL releases](https://github.com/libsdl-org/SDL/releases)
- libGDX has a direct precedent in Unciv (Civ V remake, Kotlin, MPL-2.0, desktop + Android) — [GitHub yairm210/Unciv](https://github.com/yairm210/Unciv); gdx-video plays WebM VP8/VP9 and MKV AV1 on desktop — [gdx-video](https://github.com/libgdx/gdx-video)
- Bevy's Feathers is "editor-centric" and video playback is absent from the 0.20 notes — [Bevy 0.20](https://bevy.org/news/bevy-0-20/)
- Dear ImGui is designed for tools "as opposed to UI for the average end-user" — [GitHub ocornut/imgui](https://github.com/ocornut/imgui)
- Qt Quick 3D, Qt Lottie, Qt Graphs and other modules are GPL-only, while core Qt Quick is LGPL v3 — [doc.qt.io licensing](https://doc.qt.io/qt-6/licensing.html)

### Inferences
1. **Godot 4.6 (GDScript; C# only for desktop)** — best overall: MIT, Linux-first builds, every export target, Control-node toolkit with theming/containers/nine-patch StyleBoxes, integer and fractional scaling modes, SVG DPITexture and MSDF fonts, built-in Theora playback that is adequate for short mission animations (or use image sequences/AnimatedSprite2D instead of video entirely). Weaknesses: Theora-only video in core, limited SVG feature support, C# cannot export to web.
2. **TypeScript web stack (PixiJS 8 for the base/mission scenes + HTML/CSS for data screens, packaged with Electron)** — the strongest data-heavy-UI technology available (HTML tables, flexbox/grid, CSS zoom for UI scale, browser video with WebM/AV1), and the best developer fit. Weaknesses: packaging (Electron size vs Tauri webview inconsistency, especially on Linux/Proton), no engine-level integer-scaling story (must be hand-written), and Steam/Linux distribution is less turnkey than Godot's export.
3. **Ren'Py 8.5** — the screen language is purpose-built for menu/screen-driven games with lots of text and stats, it has the widest video codec support, and Long Live the Queen proves a stats-driven raising sim ships on it. Weaknesses: visual-novel-oriented architecture, LGPL distribution obligations, Python performance for simulation code, and an isometric clickable base view is unidiomatic.
4. **SDL3 + RmlUi (+ Clay or egui) custom engine in C++ or Rust** — maximum control and tiny runtime; RmlUi gives CSS-style scaling and SVG; video via Theorafile or a WebM/AV1 decoder (dav1d) is extra work. Weaknesses: you build asset pipeline, scene management, exports, localisation and save-games yourself; this is how most historic remakes (OpenTTD, OpenRCT2, OpenRA) were done, but those projects had many contributors.
5. **libGDX / Kotlin** — Scene2D.ui is a mature retained-mode toolkit, gdx-video covers VP9/AV1 on desktop, and Unciv is a near-identical use case. Weaknesses: JVM packaging, no first-party editor, HiDPI handling is manual.
6. **Bevy** — attractive language and ecosystem, but UI is editor-centric and still moving, no video, quarterly breaking changes.
7. **LÖVE** — stable 11.5 but a stalled 12.0; no UI toolkit; Theora only.
8. **raylib + raygui/Clay** — simple and zlib-licensed, 6.0 improved HiDPI, but no retained UI, no video, raygui is tooling-grade.
9. **MonoGame/FNA** — Ms-PL (OSI-approved), Theora via FNA's Theorafile, no UI toolkit; C# with no web target.
10. **Qt/QML** — excellent desktop UI and FFmpeg video, LGPL v3 is fine for an open-source game, but it is a desktop-app framework: no game loop/scene tooling, large runtime, several useful modules are GPL-only.
11. **Macroquad / Ebitengine / HaxeFlixel** — all viable 2D renderers with thin UI stories; none has a video story found in this research.
12. **Stride, O3DE** — 3D-first; not a fit. **Defold, Flax** — excluded on licence.

### Gaps
- No head-to-head benchmark or 2025–2026 community comparison specifically about data-heavy UI in Godot vs web-tech vs RmlUi was found; the ranking is inferred from documentation and precedents.
- No shipped turn-based management title on Bevy, raylib, Macroquad or Ebitengine was identified.

## Key Question 3: Pixel-art-upscaled vs. true high-res/vector pipelines, and which engines handle each well

### Takeaway
Godot documents both pipelines explicitly (Viewport stretch + integer scale mode for pixel art; Canvas Items + DPITexture SVG + MSDF fonts + theme scale for high-res), making it the only candidate with first-party guidance for both. Web stacks get vector/high-res "for free" via CSS and SVG but must hand-roll integer scaling; RmlUi offers dp-ratio scaling and inline SVG for custom engines.

### Cited Findings
- Pixel art in Godot: use a small base such as 640×360 which "scales cleanly to 720p, 1080p, 1440p, and 4K with integer scaling", Viewport stretch mode, Stretch Scale Mode "integer" (since 4.2), and "Exclusive Fullscreen" to avoid a 1-pixel height reduction that breaks integer scaling — [Godot docs: Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)
- Godot texture filtering (nearest vs linear) is set per CanvasItem since 4.0 with a project-wide default; lossless compression is "the recommended setting for pixel art"; mipmaps cost "roughly 33%" more memory and are only recommended in 2D "if your project visibly benefits" — [Godot docs: Importing images](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html)
- High-res in Godot: SVGs rasterise at import with a `scale` option, or import as DPITexture for "run-time rasterization to match the current oversampling factor"; ThorVG "SVG feature support is limited" — [same](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html); MSDF fonts stay crisp at any size but lack hinting at small sizes; bitmap fonts must be used at integer multiples of their design size or "may look blurry" — [Godot docs: Using Fonts](https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_fonts.html)
- raylib 6.0: High-DPI is opt-in via `FLAG_WINDOW_HIGHDPI` with redesigned fullscreen handling — [raylib releases](https://github.com/raysan5/raylib/releases)
- RmlUi: 6.3 scales form-control intrinsic sizes by dp-ratio; 6.1 rounds element sizes to remove 1px gaps "most visible in DPI-scaled layouts"; 6.2 adds an SVG cache and inline SVG — [RmlUi releases](https://github.com/mikke89/RmlUi/releases)
- egui works in logical points that "may consist of many physical pixels"; 0.34 adds hinting and variable-font support via skrifa/vello_cpu — [GitHub emilk/egui](https://github.com/emilk/egui); [egui 0.34.0](https://newreleases.io/project/github/emilk/egui/release/0.34.0)
- Bevy 0.20 UI sizes scale via `rem` and a global `RemSize` resource — [Bevy 0.20](https://bevy.org/news/bevy-0-20/)
- Clay caches text measurements and requires `Clay_ResetMeasureTextCache` on DPI changes — [GitHub nicbarker/clay](https://github.com/nicbarker/clay)
- Ebitengine 2.9 added a vector-graphics renderer — [Ebitengine v2.9.0](https://ebitengine.org/en/blog/v2.9.0.html)
- PixiJS offers WebGL and WebGPU renderers — [GitHub pixijs/pixijs](https://github.com/pixijs/pixijs)

### Inferences
- A 1993 game's 320×200 art does not integer-scale to 16:9 or 4K cleanly; a cleanroom remake that chooses pixel art should pick a new base such as 640×360 (as Godot recommends) rather than the original resolution. True high-res/vector art avoids the problem but needs an SVG or large-PNG pipeline with mipmaps.
- For a hybrid (pixel-art base view, vector data screens), Godot's per-CanvasItem filter setting plus DPITexture/MSDF is the only documented single-engine path; web stacks achieve the same with `image-rendering: pixelated` on canvas plus CSS UI (inference from general web practice; not sourced here).
- Nine-patch panels: Godot has NinePatchRect/StyleBoxTexture and web has CSS `border-image` (general knowledge, not sourced in this research); no equivalent was confirmed for Clay or Nuklear.

### Gaps
- No source was found comparing scaling-quality outcomes (e.g. shimmer, text crispness at 150% UI scale) across engines.
- Nine-patch support in libGDX (NinePatch class) and LÖVE (none built-in) was not verified from primary pages here.

## Key Question 4: Asset licensing ecosystems and engine-specific pipeline notes

### Takeaway
Kenney (CC0, no attribution) and OpenGameArt (per-asset CC0/CC-BY/CC-BY-SA/OGA-BY/GPL) are the reliable sources for new art/audio; Google Fonts' licence page could not be read, so OFL claims rest on secondary sources. Engine-specific: Godot requires shipping its MIT text and third-party COPYRIGHT; Ren'Py requires LGPL-compliant distribution; FNA/MonoGame are Ms-PL; libGDX asks for (but does not require) credit for gdx-video.

### Cited Findings
- Kenney: "all game assets on the asset pages are public domain licensed (CC0)"; "Attribution is not required, but if you choose to give credit you can do so by mentioning 'Kenney'" — [kenney.nl/support](https://kenney.nl/support); a Defold asset listing counts "Over 30,000 game assets" under CC0 1.0 — [defold.com/assets/kenney](https://defold.com/assets/kenney)
- OpenGameArt accepts CC0, CC-BY 3.0/4.0, CC-BY-SA 3.0/4.0, OGA-BY 3.0/4.0 and GPL 2.0/3.0; CC-BY requires credit and indicating changes; CC-BY-SA requires derivatives under the same licence; OGA-BY is CC-BY without the DRM-platform restriction; "If an asset has multiple licenses, you follow only one of them" — [OpenGameArt FAQ](https://opengameart.org/content/faq)
- Game-icons.net is CC BY 3.0 (attribution required) per a 2026 asset round-up — [cinevva guide](https://app.cinevva.com/ko/guides/free-2d-sprites-tilesets)
- Unciv's own media use a mix of CC BY-SA, CC BY, CC0 and public-domain terms alongside MPL-2.0 code, a working example of a mixed-licence asset manifest — [GitHub yairm210/Unciv](https://github.com/yairm210/Unciv)
- Godot: ship the MIT text plus `COPYRIGHT.txt` (optionally renamed `GODOT_COPYRIGHT.txt`); `Engine.get_license_info` and `Engine.get_copyright_info` can generate a licences screen at runtime; Godot also recommends listing third-party notices for textures, sounds, music and fonts — [Godot docs: Complying with licenses](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html)
- Ren'Py games "must be distributed in a manner that satisfies the LGPL" and should include a licence notice and link — [renpy.org licence](https://www.renpy.org/doc/html/license.html)
- gdx-video "can be used free of charge in commercial and non-commercial projects" and asks for credit without requiring it — [gdx-video](https://github.com/libgdx/gdx-video)
- Qt's prebuilt FFmpeg "include[s] only features under the permissive licenses listed", relevant if shipping Qt Multimedia — [doc.qt.io Qt Multimedia](https://doc.qt.io/qt-6/qtmultimedia-index.html)
- Video encoding for Godot: convert source footage to Ogg Theora with FFmpeg (the docs give FFmpeg conversion examples) — [Godot docs: Playing videos](https://docs.godotengine.org/en/stable/tutorials/animation/playing_videos.html)

### Inferences
- A cleanroom project should keep an asset manifest with per-file licence from day one; CC-BY-SA art is a trap if the project's own art licence differs, so prefer CC0/CC-BY/OGA-BY.
- Because Godot core only plays Theora, mission "video" is better authored as image sequences or in-engine animation; this also sidesteps codec licensing entirely.

### Gaps
- The Google Fonts licensing page returned only its title; the claim that Google Fonts are OFL/Apache-licensed and embeddable in software is not sourced here.
- No primary page for freesound.org or other audio-specific CC sources was consulted.

## Key Question 5: Developer-fit note (TypeScript, Qt/QML, Lua, systems languages)

### Takeaway
The developer's TypeScript and Qt/QML experience maps directly onto the web stack and Qt options, and Lua onto LÖVE and the CorsixTH precedent; Godot's GDScript is a new but small language, while a systems-language SDL3/RmlUi build is the highest-effort path. Fit does not override the ranking: Godot still leads on the technical criteria.

### Cited Findings
- Qt Quick is LGPL v3 for core modules, with several Quick-adjacent modules GPL-only — [doc.qt.io licensing](https://doc.qt.io/qt-6/licensing.html)
- RmlUi's Lua plugin is compatible with Lua 5.1+ and LuaJIT, and 6.3 lets data models be defined in Lua — [RmlUi releases](https://github.com/mikke89/RmlUi/releases)
- CorsixTH's code base "is made up of Lua and C++" with most game logic in Lua — [GitHub CorsixTH/CorsixTH](https://github.com/CorsixTH/CorsixTH)
- Excalibur and PixiJS are TypeScript/JS; Tauri's host side is Rust with a TS front end — [Excalibur](https://github.com/excaliburjs/Excalibur); [PixiJS](https://github.com/pixijs/pixijs); [Tauri](https://github.com/tauri-apps/tauri)
- Godot C# supports all desktop platforms but not web export — [Godot docs: C#](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/index.html)
- Bevy ships breaking releases roughly every three months — [GitHub bevyengine/bevy](https://github.com/bevyengine/bevy)

### Inferences
- A C++ (systems) + Lua-scripted custom engine on SDL3 with RmlUi's Lua data models would reuse the developer's Lua and systems skills and mirrors CorsixTH's architecture, but it is the most labour-intensive option.
- The web-stack option is the lowest learning curve and the best UI toolkit, with the cost concentrated in packaging and Linux/Steam distribution.
- Godot GDScript is a modest learning cost relative to the time saved on UI, scaling and exports; C# in Godot is an option for desktop-only but forfeits web export.

### Gaps
- No source quantifies learning-curve differences; this section is inference.

## Key Question 6: Open-source turn-based strategy remakes/clones — what engines they chose and why

### Takeaway
Nearly every long-lived remake of a 1990s strategy/management game is a custom C++/C# engine on SDL plus OpenGL (OpenTTD, OpenRCT2, OpenRA, OpenXcom, CorsixTH), because they re-implement original binaries and need pixel-exact behaviour; the newer from-scratch remakes (Unciv, Shattered Pixel Dungeon) picked libGDX for Android+desktop reach. None of the surveyed projects documents its engine rationale in its README.

### Cited Findings
- OpenTTD: GPL v2; SDL (OpenGL and non-OpenGL) on Linux, Cocoa on macOS, Win32 GDI/OpenGL on Windows; guarantees "every revision of OpenTTD will be able to load savegames from every older revision" — [GitHub OpenTTD/OpenTTD](https://github.com/OpenTTD/OpenTTD)
- OpenRCT2: GPL v3 (or later); C++; SDL2 and OpenGL; Windows/macOS/Linux plus Flatpak, FreeBSD, an Emscripten directory; requires original RCT2 files — [GitHub OpenRCT2/OpenRCT2](https://github.com/OpenRCT2/OpenRCT2)
- OpenRA: GPL v3 (or later); "written in C# using SDL and OpenGL"; Windows, Linux, *BSD, macOS; supports Red Alert, Tiberian Dawn, Dune 2000 — [GitHub OpenRA/OpenRA](https://github.com/OpenRA/OpenRA)
- OpenXcom: GPL v3; C++; still lists SDL 1.2, SDL_mixer 1.2, SDL_gfx, SDL_image 1.2 and yaml-cpp as dependencies; Windows/macOS/Linux; requires original game resources — [GitHub OpenXcom/OpenXcom](https://github.com/OpenXcom/OpenXcom)
- CorsixTH: Lua + C++, "A reimplementation of the 1997 Bullfrog business sim Theme Hospital"; Windows/macOS/Linux/BSD with Flatpak/Snap/AppImage; needs original Theme Hospital data — [GitHub CorsixTH/CorsixTH](https://github.com/CorsixTH/CorsixTH)
- Unciv: "Open-source Android/Desktop remake of Civ V", "made with LibGDX", MPL-2.0 code, Kotlin DSL build files, desktop (Linux/Windows/macOS/Raspberry Pi) and Android, iOS "I'm not planning on it" — [GitHub yairm210/Unciv](https://github.com/yairm210/Unciv)
- Shattered Pixel Dungeon: Java, libGDX, GPL v3, "compiles for Android, iOS, and Desktop platforms" — [GitHub 00-Evan/shattered-pixel-dungeon](https://github.com/00-Evan/shattered-pixel-dungeon)
- Precedent for UI-heavy commercial games on lightweight frameworks: Balatro (2024) on LÖVE — [Wikipedia: Löve](https://en.wikipedia.org/wiki/L%C3%B6ve_(game_framework)); Stardew Valley and Celeste on MonoGame — [GitHub MonoGame/MonoGame](https://github.com/MonoGame/MonoGame); Slay the Spire II on Godot — [80.lv](https://80.lv/articles/slay-the-spire-2-is-sticking-with-godot-leaving-unity-behind/); Long Live the Queen on Ren'Py — [Wikipedia](https://en.wikipedia.org/wiki/Long_Live_the_Queen_(video_game))

### Inferences
- The SDL-custom-engine pattern among older remakes reflects their goal of binary-compatible re-implementation and their pre-Godot-4 start dates; a cleanroom remake that does not need save/behaviour compatibility with the original is free to use a full engine, as Unciv (libGDX) and Slay the Spire II (Godot) did.
- OpenXcom's continued dependence on SDL 1.2 shows the maintenance drag of a custom engine; SDL3 would be the modern choice if that route is taken.

### Gaps
- Open Fodder and FreeCiv were not researched (no fetch budget remained); their engine choices are not documented here.
- CorsixTH's licence is not stated on its README page (the LICENSE.txt was not read).
- No README gives an explicit rationale for its engine choice; the "why" above is inference.
