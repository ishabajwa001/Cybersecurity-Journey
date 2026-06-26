# Ping Version (`-V`)

## Command

```bash
ping -V
```

## Description

Displays the installed version of the `ping` utility and the features that were enabled when it was compiled.

## Example Output

```text
ping from iputils 20250605
libcap: yes, IDN: yes, NLS: no, error.h: yes, getrandom(): yes, __fpending(): yes
```

## Output Explanation

### `ping from iputils 20250605`

* **iputils** is the software package that provides the `ping` utility on most Linux distributions.
* **20250605** is the version (or release date) of the installed `iputils` package.

### `libcap: yes`

The program was built with Linux capabilities support. This allows `ping` to perform certain privileged operations without requiring the entire program to run as the root user.

### `IDN: yes`

The utility supports **Internationalized Domain Names (IDN)**, allowing it to resolve domain names that contain non-ASCII characters (for example, domain names written in languages such as Arabic, Chinese, or Japanese).

### `NLS: no`

**Native Language Support (NLS)** is disabled. This means the program displays messages only in its default language instead of providing translated output.

### `error.h: yes`

The program uses the `error.h` library for standardized error reporting. This is an internal implementation detail and does not affect normal usage.

### `getrandom(): yes`

The program supports the Linux `getrandom()` system call, which provides cryptographically secure random data when required by the application.

### `__fpending(): yes`

The program was compiled with support for checking whether output is still waiting in the output buffer before it is written to the terminal. This is another internal implementation detail.

## Purpose

* Verify the installed version of `ping`.
* Check which features are available in your installation.
* Compare different `ping` implementations across systems.
* Useful when troubleshooting or reporting bugs.
