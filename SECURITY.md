# Thought Circle security notes

## Protected data

Thought titles, details, plan text, step state, and thought status are stored in authenticated encrypted records.

The storage design uses:

- Argon2id password derivation with a random 16-byte salt, 64 MiB memory, three iterations, and one lane.
- A random 256-bit master key.
- AES-256-GCM to wrap the master key.
- HKDF-SHA-256 to derive an index key and independent record keys.
- HMAC-SHA-256 identifiers so logical record names are not written to SQLite.
- AES-256-GCM per record with associated data bound to the record identifier.
- A sentinel record that must authenticate after unlock.
- Atomic header replacement and restrictive file permissions where supported.

## Exposed metadata

This is not SQLite page encryption. An attacker with filesystem access can still see:

- the SQLite schema
- the number of encrypted rows
- ciphertext lengths
- update times
- the unencrypted vault header and password-derivation settings
- the local AI model file and model installation metadata

The header does not contain the startup password or plaintext master key.

## Password handling

Thought Circle never stores the startup password. The password exists in process memory while deriving the unlock key. The Dart code overwrites mutable password and key byte buffers when possible, but garbage-collected runtimes cannot guarantee that every historical copy is immediately removed from memory.

There is no password recovery path. A future recovery feature should be independently reviewed before release.

## Model boundary

The selected Gemma model is checked against the pinned SHA-256 digest before installation. User thought text is sent only to the local model API. The model file is not encrypted because it is public, large, and not user-created data.

Model output is untrusted input. The app:

- asks for a narrow JSON shape
- strips markdown wrappers
- limits returned field lengths and list sizes
- falls back to a deterministic starter plan when parsing fails
- does not execute model-provided tools, commands, links, or code

## Out of scope

The first build does not claim protection against:

- a compromised operating system
- screen capture or keyboard logging
- an attacker running code as the signed-in user while the vault is open
- memory inspection of the live process
- device backups made while files are accessible
- denial of service or deletion of app files

## Reporting

Do not post private thought data, passwords, keys, or model files in a public issue. Report reproducible security problems with redacted sample data.

## Read-only project mapper

The desktop project mapper is designed for structural inspection only.

- It never executes, imports, compiles, or launches repository code.
- It uses `Directory.list` with symbolic-link following disabled.
- It skips dependency, VCS, IDE, coverage, and build-output directories.
- It records relative file paths, file sizes, top-level entries, and extension-based language counts; it does not read source-file contents.
- It stops after 2,500 files or 64 MB of indexed file sizes.
- The generated map is placed into the Guide composer for user review before it is sent to the on-device model.
- The absolute selected path is not inserted into the guide prompt.

Treat unknown repositories as untrusted even though the mapper does not execute them. Do not manually run scripts or binaries from a repository unless you have reviewed and sandboxed them separately.
