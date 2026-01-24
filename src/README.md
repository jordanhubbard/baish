# Bash 5.3 Source Code Directory

## Purpose
This directory is intended to contain the extracted contents of the Bash 5.3 source code from the GNU project.

## Source Location
The bash 5.3 source archive should be downloaded from:
- Primary: ftp://ftp.gnu.org/gnu/bash/bash-5.3.tar.gz
- Mirror: https://ftp.gnu.org/gnu/bash/bash-5.3.tar.gz
- Alternative: https://mirrors.kernel.org/gnu/bash/bash-5.3.tar.gz

## Extraction Instructions
Due to network restrictions in the current environment, manual extraction is required:

```bash
# Download the archive (run outside this environment if needed)
wget https://ftp.gnu.org/gnu/bash/bash-5.3.tar.gz

# Extract to this directory (--strip-components=1 removes the bash-5.3/ wrapper)
tar -xzf bash-5.3.tar.gz --strip-components=1 -C bash-source/
```

## Expected Contents
After extraction, this directory should contain:
- Bash 5.3 source code (C files)
- Build system files (configure, Makefile.in, etc.)
- Documentation (CHANGES, NEWS, README, etc.)
- Test suites
- Example scripts
- Library code (lib/ directory)
- Parser and lexer implementations
- Builtins implementation

## Relevance to baish Project
Having the bash 5.3 source code is valuable for:

1. **Understanding Implementation**: See how bash implements various features
2. **Error Handling**: Study how bash reports and handles errors
3. **Parser Logic**: Understand bash's parsing rules and syntax
4. **Command Execution**: Learn how bash executes commands and pipelines
5. **Builtin Commands**: Reference implementations of bash builtins
6. **Compatibility**: Ensure baish behaves consistently with bash

## Key Files to Study
Once extracted, important files include:
- `parse.y` - Bash grammar/parser
- `shell.c` - Main shell implementation
- `eval.c` - Command evaluation
- `execute_cmd.c` - Command execution
- `builtins/*.c` - Builtin command implementations
- `variables.c` - Variable handling
- `error.c` - Error handling and reporting

## Network Restrictions Note
The automated download failed due to network access restrictions in the build environment. The directory structure has been created and this documentation prepared to guide manual extraction when network access is available.
