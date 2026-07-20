# Agent tooling — gh + MCP (this machine / Grok)

> Setup for AI agents on the Sword Masters repo.  
> Last check: **2026-07-21**.

## GitHub CLI (`gh`)

- Installed: **GitHub CLI 2.96+** (`winget install GitHub.cli`).
- Auth: user env **`GH_TOKEN`** / **`GITHUB_PERSONAL_ACCESS_TOKEN`** (from Git Credential Manager, account typically `youtumba`).
- Scopes in use: `repo`, `gist`, `workflow`. Optional later: `gh auth login -w` for `read:org` if org APIs needed.
- Repo: https://github.com/haz33u/SwordMechyOnlinePizdec

```powershell
gh auth status
gh repo view haz33u/SwordMechyOnlinePizdec
gh pr list
```

## Grok MCP (`~/.grok/config.toml`)

| Server | Transport | Status (doctor) | Notes |
|--------|-----------|-----------------|-------|
| **github** | HTTP `https://api.githubcopilot.com/mcp/` | healthy, ~44 tools | Header `Authorization: Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}` |
| **Roblox_Studio** | stdio `cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat` | healthy, ~27 tools | Studio must be open + MCP enabled in Assistant |
| **figma** | HTTP `https://mcp.figma.com/mcp` | needs OAuth once | In Grok: `/mcps` → figma → **i** Authenticate → Allow |

```powershell
grok mcp list
grok mcp doctor
```

After editing MCP config: **new Grok session** or `/mcps` + **r** (refresh).

### Studio MCP (player steps)

1. Update Roblox Studio.
2. Open the game place (Team Create OK).
3. Assistant → **…** → **Manage MCP Servers** → enable **Enable Studio as MCP server**.
4. Green client indicator when Grok connects.

### Figma MCP (player steps)

1. `/mcps` in Grok TUI (or Ctrl+L → MCP Servers).
2. Select **figma** → **i** (authenticate) → browser Allow Access.
3. Tokens land in `~/.grok/mcp_credentials.json` (local, not git).

## Art / handoff (not MCP)

- Full brain: local `CONTEXT_MEPC.md` (gitignored) + Downloads mirror under `COOLICONFORDROK…`.
- Prefer **CONTEXT_MEPC** over older `CONTEXT_AI_HANDOFF.md`.
- Art bible §5: Tier A full badges only for Weapons-class tabs; Tier B candy wordmarks for HUD; avoid Imagine for production UI.

## Collab reminder

Always: `git pull` → `docs/MASTER_PLAN.md` → work → **commit + push** (unless user said not to).
