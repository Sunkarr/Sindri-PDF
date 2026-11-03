# Contributing to Sindri PDF

Thank you for your interest in contributing to Sindri PDF! This is an open-source project and community contributions are very welcome.

To maintain code quality and project stability, all contributions must go through **Pull Requests (PRs)**. Direct pushes to `main` are restricted.

---

## Getting Started

1. **Fork the repository** on GitHub.
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/<your-username>/Sindri-PDF.git
   cd Sindri-PDF
   ```
3. **Create a descriptive branch**:
   ```bash
   git checkout -b feature/my-cool-feature
   # or
   git checkout -b fix/issue-description
   ```

---

## Local Development & Building

Sindri PDF is built natively for macOS with Swift and PDFKit.

- **Build and run locally**:
  ```bash
  ./build.sh
  ```
- **Create DMG installer**:
  ```bash
  ./create_dmg.sh
  ```
- You can also open the project directly in Xcode or your preferred editor via Swift Package Manager (`Package.swift`).

---

## Guidelines

- **Simplicity first:** Sindri PDF aims to remain sleek, fast, and bloat-free. Avoid unnecessary heavy dependencies or complex menus.
- **Privacy by design:** No tracking, no telemetry, no subscriptions.
- **Code style:** Follow clean, idiomatic Swift guidelines. Keep UI components modular.
- **Test your changes:** Ensure the app builds without warnings and runs cleanly on recent macOS versions before submitting.

---

## Submitting a Pull Request

1. Push your branch to your fork:
   ```bash
   git push origin feature/my-cool-feature
   ```
2. Open a Pull Request targeting the `main` branch of `Sunkarr/Sindri-PDF`.
3. Fill out the PR template with a clear explanation of what changed and why.
4. The maintainer will review your PR, suggest adjustments if needed, and merge it once approved.

Thank you for helping make Sindri PDF better!
