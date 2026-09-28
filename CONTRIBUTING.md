How To Contribute
=================

We welcome your feedback and input in how to make Lime better!

If you are interested in discussing new features, the direction the project or how to integrate some change, please open an issue so we can talk about.

## Issue Reporting Guidelines

Please keep bug reports focused, reproducible and actionable. A good issue should describe one specific problem and include enough information for maintainers to reproduce it without guessing.

Before opening an issue:

 1. Search existing open and closed issues to avoid duplicates.

 2. Test with the latest stable release and, when possible, the current development branch.

 3. Reduce the problem to the smallest project or code sample that still reproduces it.

Bug reports should include:

 1. The exact Lime version, OpenFL version if applicable, Haxe version and target/runtime.

 2. The operating system, architecture and relevant hardware or driver details.

 3. A minimal project or code sample, including `project.xml` or `project.hxp`.

 4. Exact steps to reproduce the problem.

 5. The expected behavior and the actual behavior.

 6. Any relevant logs, console output, screenshots or videos.

Please do not combine multiple unrelated problems in one issue. Open one issue per behavior so each report can be reproduced, discussed and fixed independently.

Performance, timing and rendering reports need especially clear reproduction material. Include a minimal project, the exact frame rate/vsync/window settings, how the result was measured and whether the behavior reproduces across targets, machines or drivers.

Issues based only on broad observations, speculation, generated code that has not been verified, or project-specific behavior without a minimal reproduction may be closed until enough information is provided.

 1. Fork the repository
 
 2. Make the desired change
 
 3. Create a pull request


You may consider creating a branch specific to the fix or improvement you wish to make, in case you have more than one that has not been accepted into the project, or to allow for item-specific changes.

It is our goal to help Lime evolve as a clean, easy-to-use (but powerful) layer for cross-platform development. Thanks for being a part of making this possible!

## Versioning and Branching Guidelines

We follow Semantic Versioning (semver): MAJOR.MINOR.PATCH.

### Patch Updates (x.x.x)

All bug fixes should be submitted to the current stable development branch (e.g., develop).

These changes are released as patch versions (e.g., 8.2.3 → 8.2.4).

### Minor Updates (x.x.0)

All new features (non-breaking) should be submitted to the next minor development branch, named x.x.x-dev.

For example, if the current version is 8.2.2, features targeting 8.3.0 should go into 8.3.0-dev.

### Major Updates (x.0.0)

Any breaking changes or major version updates must be submitted to the next major development branch, named x.0.0-dev.

For example, breaking changes intended for 9.0.0 go into 9.0.0-dev.
