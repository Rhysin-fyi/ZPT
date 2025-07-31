# ZPT – Zig Plugin Toolkit for Offensive Security

**ZPT** is a high-performance, modular offensive security framework built in [Zig](https://ziglang.org/) with dynamic Lua-based plugins. Designed for speed, portability, and flexibility, ZPT enables offensive security professionals and researchers to write and run custom tools efficiently.

## Project Goals

- **Speed**: Zig provides memory safety and low-level performance ideal for networking and systems-level operations.
- **Extensibility**: Lua is used for defining plugin logic, making it easy to script new tools and behaviors.
- **Modularity**: Separate core engine (Zig) from logic (Lua) to allow clean integration and rapid development.
- **Embed-first Design**: ZPT does not depend on external interpreters or shells. Everything is controlled from within Zig.

---

## Architecture

ZPT consists of two core layers:

- **Zig Engine**:
  - Manages plugin loading, REPL commands, and exposes low-level APIs to Lua
  - Handles scanning, network sockets, encoders, and more
  - Uses [Ziglua](https://github.com/natecraddock/ziglua) to embed a Lua 5.1/5.2-compatible interpreter safely

- **Lua Plugins**:
  - Scripted modules that declare options, run commands, or call into Zig
  - Executed in a controlled sandbox inside the Zig VM
  - Easy to create, modify, and reload

---

## Key Features

- Plugin loader with auto-discovery from `scripts/`
- Interactive REPL interface with commands:
  - `help`, `exit`, `list`, `load <plugin>`
- Lua-Zig function bindings (call Zig from Lua and pass structured data back)
- Reads `options` from Lua to populate state/config in Zig
- Support for writing scanner, encoder, or payload-style plugins
- Embeds Lua runtime via Zig (no external `lua` binary required)

---

## Example Lua Plugin

```lua
print("Calling testLua from Lua...")

options = {
  { key = "RHOST", value = "192.168.1.1" },
  { key = "RPORT", value = "8080" },
}

testLua()
setLua()

print("Done.")
```


