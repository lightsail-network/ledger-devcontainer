# Ledger Development Environment for VSCode

## What is this?

This is a [DevContainer](https://code.visualstudio.com/docs/remote/containers) environment for Visual Studio Code, allowing automatically installing [GNU Arm Embedded Toolchain](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm), [Clang](https://clang.llvm.org/), [Ledger Secure SDKs](https://github.com/LedgerHQ?q=secure-sdk) and [Speculos](https://github.com/LedgerHQ/speculos), and the necessary Visual Studio Code extensions to set up a Ledger app development environment with zero additional effort.

## How to use this?

Follow the [Getting Started](https://code.visualstudio.com/docs/remote/containers#_getting-started) instructions to configure your Visual Studio Code and Docker to use with DevContainers.

Place the `.devcontainer` directory in the root of your project, and the next time you load the project, Visual Studio Code will prompt to re-open the project in a container.
![Visual Studio Code prompt to re-open the project in a container.](./imgs/vscode.png)
**Note**: building the container might take a few minutes until all dependencies have finished downloading.

## How does it work?

Visual Studio Code supports [Developing inside a Container](https://code.visualstudio.com/docs/remote/containers) - using a Docker image as a development environment. It automates the process of creating the container image, as well as installing additional required extensions into the editor.

Pressing **Reopen in Container** will perform the automated steps to launch the container, and set up the environment.

For more information and setup, read the official documentation: https://code.visualstudio.com/docs/remote/containers

## What's in the box?

It contains the following:

1. `/opt/nanos-secure-sdk/` - [Nano S Secure SDK](https://github.com/LedgerHQ/nanos-secure-sdk)
2. `/opt/nanox-secure-sdk/` - [Nano X Secure SDK](https://github.com/LedgerHQ/ledger-secure-sdk)
3. `/opt/nanoplus-secure-sdk/` - [Nano S Plus Secure SDK](https://github.com/LedgerHQ/ledger-secure-sdk)
4. `/opt/stax-secure-sdk/` - [Stax Secure SDK](https://github.com/LedgerHQ/ledger-secure-sdk)
5. `/opt/flex-secure-sdk/` - [Flex Plus Secure SDK](https://github.com/LedgerHQ/ledger-secure-sdk)
6. `/opt/gcc-arm-none-eabi-10.3-2021.10/` - [GNU Arm Embedded Toolchain](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm)
7. `speculos` - [Speculos](https://github.com/LedgerHQ/speculos)

The `devcontainer.json` has some additional configuration for VSCode, you can customize it to your needs.

## Is the Speculos window not popping up correctly?

On macOS and Windows, make sure an X Window System server is installed and running (see [XQuartz](https://www.xquartz.org/) for mac and [VcXsrv](https://sourceforge.net/projec) for windows) otherwise, the window will not pop up correctly. **Make sure client connections are allowed**.

If you really don't want to use the graphical interface, you can run Speculos using the following command, and then you can control it in the browser:

```bash
speculos --display headless bin/app.elf
```

## Does it work on Apple Silicon?

**Yes.**
