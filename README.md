# Caveman Distillate

> Why use many token when few token do trick?

**Caveman Distillate** is a Claude Code skill that distills AI output to its core — cutting ~65% of output tokens while keeping full technical accuracy.

Inspired by [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman), distilled down to ~90 tokens of system prompt (vs ~450 in the original). Same effect, less overhead.

## What It Does

Strips articles, filler words, pleasantries, and hedging from Claude's responses. Code blocks, error messages, commits, and security warnings stay untouched.

**Before (69 tokens):**
> The reason your React component is re-rendering is likely because you're creating a new object reference on each render cycle. When you pass an inline object as a prop, React's shallow comparison sees it as a different object every time, which triggers a re-render. I'd recommend using useMemo to memoize the object.

**After (19 tokens):**
> New object ref each render. Inline object prop = new ref = re-render. Wrap in `useMemo`.

## Install

```bash
npx skills add dlepold/caveman-distillate
```

Or manually: copy `skills/caveman-distillate/SKILL.md` into your `.claude/skills/` directory.

## Usage

**Activate:** Say any of these:
- `caveman`, `terse`, `kurz`, `kurz&knapp`, `kurz bitte`, `less tokens`, `weniger text`

**Deactivate:**
- `normal`, `normal mode`, `verbose`, `ausführlich`

## Multilingual Triggers

Supports both English and German activation — because developers aren't all English-speaking.

| Language | ON | OFF |
|----------|-----|-----|
| English | terse, caveman, less tokens | normal, verbose |
| German | kurz, kurz&knapp, kurz bitte, weniger text | ausführlich, normal mode |

## How It Differs From the Original

| | [caveman](https://github.com/JuliusBrussee/caveman) | caveman-distillate |
|---|---|---|
| System prompt size | ~450 tokens | **~90 tokens** |
| Intensity levels | 3 (lite/full/ultra) | 1 (full — the useful one) |
| Multilingual triggers | English only | English + German |
| Plugin/marketplace files | Yes | No (just the skill) |
| Effect | Same | Same |

The three intensity levels are unnecessary complexity — "full" is what you want 95% of the time. If you need verbose output, just say "normal mode."

## Philosophy

The best compression is compressing the compressor itself. A 450-token prompt that tells you to be brief is ironic. This is the distillate — what remains after boiling away everything unnecessary.

## License

MIT
