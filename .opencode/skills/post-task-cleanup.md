# Post-Task Cleanup Workflow

## Description

After completing any implementation task in this repository, follow this mandatory cleanup workflow to ensure the repo stays clean and all changes are properly tracked.

## When to Use

This skill applies after:
- Any file modifications (edits, creates, deletes)
- Subagent task completion
- Plan execution finishing
- Any workflow that produces file changes

## Workflow Steps

### Step 1: Check Git Status

Always run `git status --short` first to see what changed.

**If there are uncommitted changes:**
- Review what changed (expected vs unexpected)
- Stage only the intended changes
- Do NOT stage `.omo/`, `.git/`, `node_modules/`, or other temporary directories
- Commit with a descriptive message

**If there are NO changes:**
- Verify the task actually completed (subagents may claim completion without changes)
- Check if changes were already committed

### Step 2: Identify and Remove Temporary Artifacts

Check for and remove these common temporary directories/files:

```bash
# Planning/workflow artifacts that should NOT be committed
rm -rf .omo/                    # Prometheus/Atlas planning artifacts
rm -rf .omo/drafts/             # Draft plans
rm -rf .omo/plans/              # Generated plans (optional - keep if useful)
rm -rf .omo/evidence/           # QA evidence files
rm -rf .omo/notepads/           # Session notepads
rm -f .omo/boulder.json         # Boulder state file
rm -f .omo/run-continuation/*.json  # Session continuation files

# Other common temporary files
rm -f *.tmp
rm -f *.bak
rm -f *.swp
rm -f *.log
```

### Step 3: Verify Clean State

After cleanup, run `git status --short` again:
- Should show only your intended committed changes
- No untracked `.omo/` or temporary files
- No unexpected modifications

### Step 4: Final Verification

If you made commits, verify:
- `git log --oneline -3` shows your commit
- The commit message describes what was done
- Only intended files are in the commit

## Commit Message Format

Use conventional commits:
```
<type>(<scope>): <description>

[optional body]
```

Examples:
- `fix(audio): correct PipeWire startup ordering`
- `feat(sway): add volume keybindings`
- `chore(cleanup): remove obsolete start-audio.sh`
- `docs(readme): update installation instructions`

## Anti-Patterns to Avoid

❌ **Never** leave `.omo/` directories in the repo after task completion  
❌ **Never** commit planning artifacts, draft files, or session logs  
❌ **Never** run `git add .` without reviewing what will be staged  
❌ **Never** claim a task is complete without verifying git status  
❌ **Never** ignore untracked files without checking what they are  

## Guardrails

- Always check `git status` before claiming completion
- Always remove `.omo/` after work is done
- Always commit meaningful changes
- Always verify the repo is clean before ending the session

## Example Session End

```
# After task completion:
$ git status --short
 M pipewire/.config/...     # expected changes
?? .omo/                    # temporary - REMOVE THIS

$ rm -rf .omo/
$ git add pipewire/.config/...
$ git commit -m "fix(audio): ..."
$ git status --short
# (empty - clean state)
```
