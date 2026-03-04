---
description: Coding standards and guidelines for PowerShell scripts in this repository.
applyTo: "**/*.ps1" # Applies to all PowerShell script files in any folder
---

# PowerShell Coding Standards

## General Guidelines

- Use `Write-Output` for standard output and `Write-Error` for error messages.
- Always include a comment header with script purpose, author, and date.
- Use `param()` blocks for input parameters and validate them with `[ValidateNotNullOrEmpty()]` or other appropriate attributes.
- Prefer `Get-Help` compatible comment-based help for all functions and scripts.

## Naming Conventions

- Use PascalCase for function names (e.g., `Get-UserInfo`).
- Use camelCase for variable names (e.g., `$userName`).
- Prefix private/internal functions with an underscore (e.g., `_InitializeConfig`).

## Script Structure

- Group related functions together.
- Place all function definitions at the top, followed by script logic.
- Use regions (`#region`/`#endregion`) to organize code for readability.

## Error Handling

- Use `try/catch/finally` blocks for error handling.
- Log errors with sufficient context for troubleshooting.
- Avoid using `Write-Host` except for debugging.

## Formatting

- Indent with 4 spaces, no tabs.
- Limit line length to 120 characters.
- Use blank lines to separate logical sections.

## Security

- Avoid hardcoding credentials; use secure strings or environment variables.
- Validate all external input.
- Use `Set-StrictMode -Version Latest` at the top of scripts.

## Example Function
