# Narko

Windows desktop scaffold for an OpenClaw-like node.

## What is included

- `src/Narko.Node.Desktop` — WPF desktop shell (`net8.0-windows`)
- Planned features panel directly in UI
- Auto-update service placeholder (`Services/AutoUpdateService.cs`)
- CI workflow to build and upload Windows artifacts (`.exe` + `.msi`)
- WiX source for MSI packaging (`installer/Product.wxs`)

## Planned feature roadmap

- Node registration + auth handshake
- Secure command execution sandbox
- Browser relay bridge
- Filesystem/task orchestration
- Notifications and telemetry
- **Auto-update pipeline (placeholder implemented, integration pending)**

## CI build artifacts

Workflow: `.github/workflows/windows-build.yml`

Uploaded artifacts:

- `Narko-Desktop-Exe` → `artifacts/publish/win-x64/Narko.Node.Desktop.exe`
- `Narko-Desktop-MSI` → `artifacts/installer/Narko.Node.Desktop.msi`

## Trigger build

- Push to any branch
- Or manual run: GitHub → Actions → **Build Windows Desktop Artifacts** → Run workflow
