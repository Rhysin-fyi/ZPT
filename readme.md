# ZPT – Zig Plugin Toolkit for Offensive Security

**ZPT** is a high-performance, modular offensive security framework built in [Zig](https://ziglang.org/) with dynamic Lua-based plugins called ZPTScripts. Designed for speed, portability, and flexibility, ZPT enables offensive security professionals and researchers to write and run custom tools efficiently.

## Project Goals

- **Speed**: Zig provides memory safety and low-level performance ideal for networking and systems-level operations.
- **Extensibility**: Lua is used for defining plugin logic, making it easy to script new tools and behaviors in a ZPTScript file.
- **Modularity**: Separate core engine (Zig) from logic (ZPTScript) to allow clean integration and rapid development.
- **Embed-first Design**: ZPT does not depend on external interpreters or shells. Everything is controlled from within Zig.

---

## Architecture

ZPT consists of two core layers:

- **Zig Engine**:
  - Manages plugin loading, REPL commands, and exposes low-level APIs to Lua
  - Handles scanning, network sockets, encoders, and more
  - Uses [Ziglua](https://github.com/natecraddock/ziglua) to embed a Lua 5.* interpreter to created access to ZPTScripts

- **Lua Plugins**:
  - Scripted modules that declare options, run commands, or call into Zig
  - Executed in a controlled sandbox inside the Zig VM
  - Easy to create, modify, and reload

---

## Key Features

- Plugin loader with auto-discovery from `scripts/`
- Interactive REPL interface with commands:
  - `help`, `exit`, `list`, `load <plugin>`, `get`, `set`
- Lua-Zig function bindings (call Zig from ZPTScript and pass structured data back)
- Reads `options` from ZPTScript to populate state/config in Zig
- Support for writing scanner, encoder, or payload-style plugins
- Embeds Lua runtime via Zig (no external `lua` binary required)

---

## Example Lua Plugin

```lua
load("tcp")
load("os")

options = {
  { key = "RHOST", value = "192.168.1.1" },
  { key = "RPORT", value = "1337" },
}

tcp.connect(RHOST, RPORT)
tcp.sendBytes(0xdeadbeef)
tcp.sendCommand(os.ls())

print("Done.")

```

---

## Roadmap

- [x] Load plugins at runtime via REPL

- [X] Pass ZPT script options to Zig

- [ ] Bi-directional Zig-ZPT script integration

- [ ] Network utility layer (TCP, UDP, ICMP scanners)

- [ ] Shellcode encoder plugins

- [ ] Filesystem and process discovery modules

- [ ] Logging and reporting

- [ ] Scripting REPL + inline ZPT script eval

- [ ] Custom RAT named after ZIG's mascot ZERO
