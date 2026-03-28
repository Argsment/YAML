# YAML

A pure Swift YAML parser and emitter.

## Features

- Parse YAML 1.2 documents from strings or files
- Emit YAML with full control over formatting (block/flow style, quoting, indentation)
- Node-based API for reading, writing, and manipulating YAML data
- Multi-document support
- Anchor/alias support
- Base64 binary encoding/decoding
- UTF-8 with BOM detection
- No dependencies beyond Foundation (file I/O only)
- `Sendable`-conforming public types

## Requirements

- Swift 5.9+
- macOS, Linux, or any platform with Swift support

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Argsment/YAML.git", from: "1.0.0")
]
```

Then add `"YAML"` to your target's dependencies:

```swift
.target(name: "MyApp", dependencies: ["YAML"])
```

## Usage

### Parsing

```swift
import YAML

// From a string
let node = try load("name: John")
print(node["name"].scalar) // "John"

// From a file
let config = try loadFile("/path/to/config.yaml")

// Multiple documents
let docs = try loadAll("---\nfirst\n---\nsecond")
```

### Accessing values

```swift
let yaml = """
server:
  host: localhost
  port: 8080
  debug: true
tags:
  - swift
  - yaml
"""

let node = try load(yaml)

// Map access
node["server"]["host"].scalar  // "localhost"

// Type conversion
node["server"]["port"].as(Int.self)     // 8080
node["server"]["debug"].as(Bool.self)   // true

// Sequence access
node["tags"][0].scalar  // "swift"
node["tags"].size       // 2

// Type checking
node["server"].isMap       // true
node["tags"].isSequence    // true
```

### Building nodes

```swift
let root = Node()
root["name"].set("MyApp")
root["version"].set("1.0.0")

let dep = Node()
dep.data.setType(.sequence)
dep.append(try load("swift-log"))
root["dependencies"] = dep
```

### Emitting

```swift
let emitter = Emitter()

// Scalars
emitter.emit("hello")

// Sequences
emitter.emit(.beginSeq)
emitter.emit("one")
emitter.emit("two")
emitter.emit(.endSeq)

// Maps
emitter.emit(.beginMap)
emitter.emit("key")
emitter.emit("value")
emitter.emit(.endMap)

print(emitter.string)
```

### Dump and round-trip

```swift
let node = try load("name: John\nage: 30")
let yaml = dump(node)      // Serialize back to YAML string
let copy = clone(node)     // Deep copy a node
```

### Flow vs block style

```swift
let emitter = Emitter()

// Flow style: [1, 2, 3]
emitter.emit(.flow)
emitter.emit(.beginSeq)
emitter.emit("1"); emitter.emit("2"); emitter.emit("3")
emitter.emit(.endSeq)

// Block style (default):
// - 1
// - 2
// - 3
emitter.emit(.block)
emitter.emit(.beginSeq)
emitter.emit("1"); emitter.emit("2"); emitter.emit("3")
emitter.emit(.endSeq)
```

### Formatting options

```swift
let emitter = Emitter()
emitter.setIndent(4)
emitter.setStringFormat(.doubleQuoted)
emitter.setNullFormat(.lowerNull)      // "null" instead of "~"
emitter.setSeqFormat(.flow)            // Flow sequences globally
```

### Documents

```swift
let emitter = Emitter()
emitter.emit(.beginDoc)   // ---
emitter.emit("content")
emitter.emit(.endDoc)     // ...
```

### Comments, anchors, and tags

```swift
let emitter = Emitter()
emitter.emit(Comment("This is a comment"))
emitter.emit(AnchorManip("anchor1"))
emitter.emit("value")
emitter.emit(Alias("anchor1"))
emitter.emit(verbatimTag("tag:yaml.org,2002:str"))
emitter.emit("tagged")
```

## Architecture

| Layer | Files | Role |
|-------|-------|------|
| **Stream** | `Stream.swift` | UTF-8 byte stream with BOM detection and position tracking |
| **Scanner** | `Scanner.swift`, `Scanner+*.swift`, `ScalarScanner.swift`, `TagScanner.swift` | Tokenizer: converts byte stream into YAML tokens |
| **Patterns** | `PatternMatcher.swift`, `Patterns.swift` | Simple pattern matching engine for YAML syntax rules |
| **Parser** | `Parser.swift`, `SingleDocParser.swift` | Structures tokens into document events |
| **Node** | `Node.swift`, `NodeData.swift`, `NodeBuilder.swift` | Tree representation built from parse events |
| **Emitter** | `Emitter.swift`, `EmitterState.swift`, `EmitterUtils.swift` | Serializes nodes or manual calls back to YAML text |
| **Events** | `EventHandler.swift`, `EventEmitter.swift`, `NodeEvents.swift` | Event-based bridge between parsing and emitting |
