# Steal a City: tool setup checklist

Checked against official docs on 2026-10-01. Steps marked **(you)** need your
computer or your accounts; everything else is already done in
`steal-a-city.zip` next to this file.

## What's ready

`steal-a-city.zip` is a starter project laid out for Roblox Script Sync:

- `CLAUDE.md`: project rules Claude Code reads on every session (plan §9 rules,
  file layout, working loop, current milestone).
- `steal-a-city-gameplan.md`: the plan v3, so Claude Code on your computer has it.
- `ServerScriptService/Packages/ProfileStore.luau`: ProfileStore (MAD STUDIO,
  Apache 2.0, licence in `licenses/`).
- `ServerScriptService/Services/Data.luau`: the one module that writes saved
  data (coins, size, rebirths, plot slots, collection, offline time, funnel log).
- `ServerScriptService/Services/Scale.luau` + `StarterPlayerScripts/ScaleClient.client.luau`:
  server sets the `Scale` attribute from Size, every client runs `ScaleTo`.
- `ServerScriptService/Main.server.luau`: starts the services.
- `ReplicatedStorage/Shared/Config.luau`: all tunable numbers from the plan.
- `.gitignore`.

The scripts pass a Luau syntax check but have not run in Studio yet; step 6
below is the first real test.

## 1. Install Claude Code (you)

Needs a Claude Pro, Max, Team or Enterprise plan.

- Windows (PowerShell): `irm https://claude.ai/install.ps1 | iex`
  (also install Git for Windows: https://git-scm.com/downloads/win)
- macOS: `curl -fsSL https://claude.ai/install.sh | bash`

Open a new terminal, run `claude`, log in in the browser.
Or use the Claude desktop app's Code tab instead of a terminal.

## 2. Update Roblox Studio and create the place (you)

1. Update Studio to the latest version.
2. Create a new Baseplate place, name it **Steal a City**, and publish it
   (File > Publish to Roblox). Publishing gives it a place ID for data stores.
3. Game Settings > Security > turn on **Enable Studio Access to API Services**
   (otherwise saves only happen in memory during tests).

## 3. Turn on Studio's built-in MCP server (you)

1. Open the **Assistant** panel > ⋯ / Settings > **MCP Servers**.
2. Toggle **Enable Studio as MCP server**.
3. Under **Quick connect**, enable **Claude Code**.

Manual alternative if Quick connect doesn't list it (run in a terminal):

- Windows: `claude mcp add --scope user Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`
- macOS: `claude mcp add --scope user Roblox_Studio -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`

Studio must be open with the place loaded whenever Claude uses it.
Note: the old `Roblox/studio-rust-mcp-server` plugin is deprecated; don't install it.

## 4. Put the starter files on disk and sync them (you)

1. Download `steal-a-city.zip` from this project and unzip it somewhere
   permanent, e.g. `Documents/steal-a-city`. Keep the zip as a backup until
   step 6 works.
2. In Studio Explorer, right-click **ServerScriptService** > **Sync to…** and
   pick `steal-a-city/ServerScriptService`. Do the same for
   **ReplicatedStorage** → `steal-a-city/ReplicatedStorage` and
   **StarterPlayer > StarterPlayerScripts** → `steal-a-city/StarterPlayerScripts`.
3. Check Explorer now shows `Main`, `Services/Data`, `Packages/ProfileStore`,
   `Shared/Config` and `ScaleClient`. If a folder came through empty, copy the
   files back from the zip; Studio picks them up.

## 5. Git + GitHub (optional, recommended)

In the `steal-a-city` folder: `git init && git add . && git commit -m "Starter"`.
If you want a GitHub repo, tell me in this thread and I'll create a private
`Pixdls/steal-a-city` and give you the push command; then every thread in this
project can read and review the scripts. I haven't created anything yet.

## 6. First test (you, one prompt)

In a terminal: `cd` into `steal-a-city`, run `claude`, and paste:

> Use the Roblox Studio MCP: list the open Studio, start a playtest, read the
> console output and tell me whether "[Steal a City] server started" and a
> ProfileStore load appear without errors. Then stop the playtest.

If that works, the toolchain is done and week 1 can start.

## 7. Let this project's Claude work on your computer (you, optional)

With Claude Code installed, threads in this project can run on your computer
through **Remote Control** and use Studio directly. When we start week 1 I'll
post a card asking you to allow a session in your `steal-a-city` folder; you
approve it once.

## 8. Figma (optional, only for UI mockups)

On your computer:

1. `claude plugin install figma@claude-plugins-official`
   (or `claude mcp add --scope user --transport http figma https://mcp.figma.com/mcp`)
2. In Claude Code, run `/mcp`, pick **figma**, and log in with your Figma account.

In this cloud project the Figma connector fails because the environment's
network policy blocks `mcp.figma.com`. To fix: Project settings > Environment >
Network access, add `mcp.figma.com` to the allowed domains (or pick a broader
access level). Not needed for scripting; skip it until you design the shop/HUD.

## Sources

- Studio MCP server: https://create.roblox.com/docs/studio/mcp
- Coding harness guide: https://create.roblox.com/docs/ai/coding-harness
- Script Sync: https://create.roblox.com/docs/scripting/sync
- Claude Code install: https://code.claude.com/docs/en/setup
- Figma MCP remote server: https://developers.figma.com/docs/figma-mcp-server/remote-server-installation/
- ProfileStore: https://github.com/MadStudioRoblox/ProfileStore
