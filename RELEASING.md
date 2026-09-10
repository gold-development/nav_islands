# Releasing nav_islands

This package is developed inside the Stella monorepo and mirrored to its own
public repository. The monorepo is the source of truth: edit it here, where the
app consumes it through a `path:` dependency and every change is exercised by a
real app immediately.

Public repo: https://github.com/gold-development/nav_islands
Publisher: `gold-development.nl`

The directory is wired to that repo as a **git subtree**, so changes flow both
ways. Remotes live in `.git/config` rather than in the repository, so each
clone needs this once:

```bash
git remote add nav-islands https://github.com/gold-development/nav_islands.git
git fetch nav-islands
```

## Pulling changes made on GitHub

Edited the package upstream — on GitHub's web editor, from another machine, or
via a pull request? Bring it back from the monorepo root, on a clean tree:

```bash
git subtree pull --prefix=packages/nav_islands nav-islands main
```

Do this before starting local work on the package, so the two sides don't
diverge.

## Cutting a beta

1. Bump `version:` in `pubspec.yaml` and add the matching `CHANGELOG.md` entry.
   Stay on `-beta.N` while the API can still move — pub.dev keeps a prerelease
   out of the "latest stable" slot, so it only reaches people who ask for it by
   name (`nav_islands: ^0.1.0-beta.1`).

2. Check it from the package directory:

   ```bash
   flutter analyze && flutter test && flutter pub publish --dry-run
   ```

3. Mirror this directory to the public repo, from the monorepo root on a clean
   tree:

   ```bash
   git subtree push --prefix=packages/nav_islands nav-islands main
   ```

   Only this directory's commits go up, rewritten so the package sits at the
   repo root.

4. Tag and publish from a fresh clone of the public repo, so what goes to
   pub.dev is exactly what the repo shows:

   ```bash
   git clone git@github.com:gold-development/nav_islands.git
   cd nav_islands && flutter pub publish
   ```

The first published version number can never be reused, so let a beta sit in
the app for a while before promoting it.

## When to stop doing this

Once the API settles, flip the direction: make the public repo the source of
truth and consume it from Stella as a normal pub dependency. At that point this
file and the `path:` dependency in the app's `pubspec.yaml` both go away.
