# Contributing to FS25 Claude Skill

First of all — thank you! This project is community-driven and every contribution makes it better for FS25 modders everywhere.

---

## Ways to Contribute

### 🐛 Report a Bug / Wrong Pattern
Found something that Claude says to do, but it crashes your game? Please open an issue!

**Good bug reports include:**
- What Claude suggested
- What actually happened (error message from game log)
- The correct approach if you found it
- Your FS25 version

### 📝 Add a New Pattern
Have a working pattern that's not documented? Add it!

1. Fork the repo
2. Edit the appropriate file in `skill/fs25-modding-skill/references/`
3. Follow the format: include validation status, code example, common pitfalls
4. Submit a PR with a description of what mod you validated it in

### 📖 Improve the LUADOC Index
The LUADOC index in `skill/fs25-modding-skill/references/luadoc-index/LUADOC-INDEX.md` is a manually maintained index. If you find categories or functions missing, add them.

### 🔧 Update for New FS25 Versions
When Giants releases updates that change APIs, open an issue or PR to update the affected patterns.

---

## Pattern Format

When adding a new pattern to the reference files, use this format:

```markdown
## Pattern Name

> ✅ **VALIDATED** — Tested in [ModName] v1.0.0
> OR
> ⚠️ **PARTIAL** — Core pattern works, edge cases untested
> OR
> 📚 **REFERENCE** — Extracted from community mod, not personally validated

Brief description of what this pattern does and when to use it.

### When to Use
- Use case 1
- Use case 2

### Code Example

```lua
-- Your complete, working example here
-- Include imports/requires at top if needed
-- Include error handling
```

### Common Pitfalls
- ❌ Don't do X because Y
- ❌ Don't forget Z

### Related
- `patterns/other-pattern.md`
- LUADOC: `docs/script/ClassName/Method.md`
```

---

## Validation Badges

| Badge | Meaning |
|-------|---------|
| ✅ **VALIDATED** | You've personally used this in a working, published or tested mod |
| ⚠️ **PARTIAL** | The pattern exists and mostly works, but you have caveats |
| 📚 **REFERENCE** | You extracted this from another mod's source code |

Please be honest about validation status — the whole value of this skill is that it doesn't feed Claude wrong info.

---

## PR Checklist

- [ ] Pattern follows the format above
- [ ] Validation status badge is accurate
- [ ] Code example is complete and runnable (not pseudocode)
- [ ] Common pitfalls section included if applicable
- [ ] No copy-pasted copyrighted Giants code (use your own examples)
- [ ] Updated table of contents if adding new sections

---

## Development Setup

```bash
git clone https://github.com/YOUR_USERNAME/fs25-claude-skill
cd fs25-claude-skill

# The skill itself lives in:
# skill/fs25-modding-skill/

# To package a new .skill file (requires Python):
cd skill
python package_skill.py fs25-modding-skill/
# Output: fs25-modding.skill
```

---

## Code of Conduct

Be kind. We're all just farmers trying to write better Lua. 🚜

---

## Questions?

Open a Discussion — not an Issue — for general questions about FS25 modding or how to use the skill.
