# Using the Community LUADOC with This Skill

The [FS25 Community LUADOC](https://github.com/umbraprior/FS25-Community-LUADOC) by [@umbraprior](https://github.com/umbraprior) is the most complete API reference for FS25. This skill includes an index so Claude knows exactly where to point you.

---

## How It Works

This skill does **not** embed all 1,661 LUADOC pages (that would be too large). Instead, it contains:

1. A **complete categorized index** of all LUADOC pages
2. **Quick lookup entries** for the most commonly used classes
3. **Direct path references** so Claude can say "check `docs/script/GUI/Gui.md`"

When you ask Claude about an FS25 function, it will:
- Recall the correct class and function names from the index
- Tell you the exact LUADOC path to verify the signature
- Write code using the correct parameters

---

## Browsing the LUADOC Directly

**Online (easiest):**  
https://fs25-community-luadoc.pages.dev/

**Locally (for offline use):**
```bash
git clone https://github.com/umbraprior/FS25-Community-LUADOC
cd FS25-Community-LUADOC/website
npm install
npm start
# Open http://localhost:3000
```

---

## LUADOC Structure

```
docs/
├── engine/          ← Giants engine APIs (C++ bindings)
│   ├── Animation/
│   ├── Camera/
│   ├── Entity/
│   ├── I3D/
│   ├── Input/
│   ├── Math/
│   ├── Network/
│   ├── Node/
│   ├── Physics/
│   ├── Rendering/
│   ├── Sound/
│   ├── Terrain/
│   ├── XML/
│   └── ...
├── script/          ← Lua game script APIs
│   ├── AI/
│   ├── Animals/
│   ├── Economy/
│   ├── GUI/         ← Most mod-relevant
│   ├── Hud/
│   ├── Placeables/
│   ├── Specializations/
│   ├── Utils/
│   ├── Vehicles/
│   └── ...
└── foundation/      ← Core Lua extensions
```

---

## Most Used Pages (Bookmark These)

| What you're doing | LUADOC page |
|-------------------|-------------|
| Creating a custom dialog | `docs/script/GUI/Gui.md` + `docs/script/GUI/MessageDialog.md` |
| Adding buttons | `docs/script/GUI/ButtonElement.md` |
| Text display | `docs/script/GUI/TextElement.md` |
| Text input field | `docs/script/GUI/TextInputElement.md` |
| Dropdown selector | `docs/script/GUI/MultiTextOptionElement.md` |
| Layout containers | `docs/script/GUI/BoxLayoutElement.md` |
| Scrollable list | `docs/script/GUI/ListElement.md` |
| Overwriting/appending functions | `docs/script/Utils/Utils.md` |
| Farm money | `docs/script/Economy/FarmManager.md` |
| Reading/writing XML | `docs/engine/XML/` |
| Node positions | `docs/engine/Node/` |
| Sounds | `docs/engine/Sound/` |
| Physics | `docs/engine/Physics/` |
| Vehicle specializations | `docs/script/Specializations/` |
| HUD elements | `docs/script/Hud/` |
| Trigger zones | `docs/script/Triggers/` |

---

## Tips

- **Function not found?** Search the LUADOC website — it's full-text searchable
- **Confused about parameters?** The LUADOC shows the actual source code for each function
- **Finding a category?** Ask Claude "Where in the LUADOC do I find X?" — it will look up the index
- **Offline?** Clone the repo and run locally — it's a static Docusaurus site
