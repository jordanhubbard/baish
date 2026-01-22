# baish
A version of bash that also knows what you were probably _trying_ to do.

## Repository Structure

```
├── bash-handbook-review/
│   └── REVIEW.md          # Comprehensive review of the bash-handbook
├── bash-source/
│   └── README.md          # Instructions for bash 5.3 source extraction
├── LICENSE
└── README.md             # This file
```

## Development Resources

### 1. Bash Handbook Review
Located in `bash-handbook-review/REVIEW.md`, this document provides:
- Overview of bash fundamentals from https://github.com/denysdovhan/bash-handbook
- Key concepts and features
- Common user mistakes to address
- Insights for implementing intelligent error correction
- Relevance to the baish project goals

### 2. Bash Source Code Reference
The `bash-source/` directory is prepared for the bash 5.3 source code. Having access to the actual bash implementation helps with:
- Understanding bash's internal behavior
- Ensuring compatibility
- Learning from established patterns
- Implementing similar features with enhancements

See `bash-source/README.md` for extraction instructions.

## Key Features to Implement

Based on the bash handbook review, baish could help with:
- Variable quoting mistakes
- Typos in command names
- Incorrect conditional syntax
- Misused exit codes
- Array handling errors
- Redirection mistakes
- Common scripting anti-patterns
