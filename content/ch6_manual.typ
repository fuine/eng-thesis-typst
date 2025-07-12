#import "../utils.typ": code-listing-file

= User Manual
<user_manual>
== Installation
<installation>
_katome_ currently supports Linux, MacOS and Windows operating systems. Note that
internet connection is required to download and install necessary tools, as well as to
compile the application --- dependencies must be downloaded from `Crates.io`. For more
information refer to @dev_env. To install _katome_ on any of the above systems follow
these steps:

+ Install Git version control system from https://git-scm.com/

+ Install latest stable version of the Rust compiler and Cargo package manager.
  Recommended tool for this installation can be found at https://rustup.rs/
+ Clone _katome_ project and change working directory into the cloned repository.
  ```bash
    $ git clone https://github.com/fuine/katome
    $ cd katome
  ```
+ Compile application.
  ```bash
    $ cargo build --release
  ```
+ Built binary executable can be found in the `target/release` directory.

== Testing
<testing>
To run tests issue the following command in the repository:

```bash
  $ cargo test
```

== Configuration
<config_file>
Currently _katome_ is configured via two files, which should be placed at `config`
directory relative to the current working directory:

+ `settings.toml` --- configuration of the assembler

+ `log4rs.yaml` --- configuration of the logger

Both example files are provided to the user. To find more information about logging
configuration please refer to the following url https://docs.rs/log4rs/0.5.2/log4rs/.
Example `settings.toml` file is shown in the @example_config with comments describing
each field.

#code-listing-file(
  "settings.toml",
  caption: [Example `settings.toml` configuration file for _katome_ assembler],
)<example_config>

== Usage
<usage>
To use the assembler configure it to your use case and simply execute the binary file.
If your current working directory is within the repository for _katome_ you may also
issue following command to run the assembler:

```bash
  $ cargo run --release
```

In case of any issues or suggestions regarding katome please open an issue or file a
pull request at https://github.com/fuine/katome.
