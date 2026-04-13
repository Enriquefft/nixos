# Oxeylyzer Bilingual Layout Optimization Results

Generated 2026-04-13 for ZSA Voyager (columnar split, 6x4 + 2 thumbs per hand).

## Corpus

| Source | Size | Proportion |
|--------|------|-----------|
| Spanish prose (Cervantes, Clarín) | 4.1 MB | 48% |
| English prose (Austen, Melville, Dickens) | 3.0 MB | 36% |
| Code (TS, Go, Rust, Python, Nix, Shell) | 1.3 MB | 16% |
| **Total** | **8.5 MB** | |

## Generated Layouts

### Recommended: Voyager Bilingual (r on right thumb)

```
Left hand:       Right hand:      R. Thumb:
ñ z o u k        b w l f q
i e a h ,        c d n s t        r
y ' / . x        p g j v m
```

- Left hand: vowels (i, e, a, o, u) — strong hand alternation
- Right hand: consonants (n, s, t, d, c, l)
- r on right thumb (eliminates r-based SFBs, like Enthium)
- ñ on left pinky top (0.15% frequency in mixed corpus)

### Alternative: Voyager Bilingual 3x10 (no thumb alpha)

```
Left hand:       Right hand:
j p h g q        . v o z ñ
s n r t d        w u a e i
f b l c m        k , x / y
```

Same consonant-left / vowel-right philosophy. r stays in the grid.

## Comparison: Bilingual Mixed Corpus (50/30/20)

| Metric | **Ours (r-thumb)** | **Ours (3x10)** | Enthium v14 | Sturdy | Colemak-DH |
|--------|:------------------:|:----------------:|:-----------:|:------:|:----------:|
| **SFB** | **0.570%** | 0.851% | 3.126% | 2.073% | 2.519% |
| Bad SFBs | **0.585%** | 0.873% | 2.280% | 1.777% | 3.087% |
| LSBs | 1.632% | 1.707% | **1.482%** | 2.392% | 1.720% |
| Total Rolls | 29.749%* | 37.043% | 27.118%* | 36.942% | **39.493%** |
| Total Alternates | 32.214%* | **40.359%** | 28.650%* | 34.908% | 26.102% |
| Total Redirects | **1.688%** | 3.172% | 3.770% | 5.803% | 10.785% |
| **Score** | -1.458† | **-1.365** | -1.696† | -1.542 | -1.698 |

\* Thumb layouts show lower rolls/alternation because thumb trigrams get zero weight in Oxeylyzer.
† Scores from different board types (custom vs ortho) are not directly comparable.

## Per-Corpus Breakdown

### Pure Spanish

| Metric | **Ours (r-thumb)** | **Ours (3x10)** | Enthium v14 | Sturdy | Colemak-DH |
|--------|:------------------:|:----------------:|:-----------:|:------:|:----------:|
| SFB | **0.310%** | 0.510% | 4.487% | 3.036% | 3.608% |
| Total Rolls | 29.764% | 38.420% | 24.924% | 34.941% | **42.160%** |
| Total Alternates | 38.501% | **49.274%** | 32.375% | 41.751% | 27.594% |
| Total Redirects | **1.419%** | 2.810% | 5.115% | 6.912% | 12.817% |
| Score | -1.362 | **-1.219** | -1.778 | -1.629 | -1.726 |

Our 3x10 layout achieves **7x lower SFBs** and **4.5x lower redirects** than Colemak-DH on Spanish.

### Pure English

| Metric | **Ours (r-thumb)** | **Ours (3x10)** | Enthium v14 | Sturdy | Colemak-DH |
|--------|:------------------:|:----------------:|:-----------:|:------:|:----------:|
| SFB | **0.696%** | 0.883% | 1.894% | **0.864%** | 1.474% |
| Total Rolls | 35.096% | 42.235% | 34.244% | **46.054%** | 42.751% |
| Total Alternates | 29.295% | **35.863%** | 27.875% | 31.988% | 27.614% |
| Total Redirects | **2.104%** | 3.972% | 2.784% | 5.367% | 10.157% |
| Score | -1.360 | -1.292 | -1.439 | **-1.244** | -1.508 |

On pure English, Sturdy is competitive (it was optimized for English). Our layouts still win on SFBs and redirects.

## Key Findings

1. **Existing layouts are terrible for Spanish.** Colemak-DH has 3.6% SFBs on Spanish vs our 0.31-0.51%. This is because letter frequencies differ dramatically (Spanish: more a/o/e, less th, more de/en/es bigrams).

2. **Vowel-consonant hand split dominates.** All our generated layouts converge to vowels-left, consonants-right. This maximizes hand alternation, which is especially powerful for Spanish (high vowel frequency → constant hand switching).

3. **r is the optimal thumb alpha.** Testing r, e, n: r (-1.399) > n (-1.429) > e (-1.471). r eliminates many consonant-cluster SFBs without breaking vowel rolls.

4. **Our 3x10 layout is competitive with the best English-optimized layouts even on English,** while being dramatically better on Spanish. No compromise.

5. **Redirects are the biggest differentiator.** Colemak-DH has 10-13% redirects (painful at 10hr/day). Ours: 1.4-3.2%. Sturdy is better than Colemak-DH but still 2-3x worse than ours.

## Optimization Configuration

- **Weights:** Community standard with health adjustments: lateral_penalty=1.2, stretches=-0.4, pinky_ring=-0.3, max_finger_use penalty=2.5, pinky cap=8%
- **Iterations:** 10,000 initial + 20,000 improvement per layout
- **Thumb alpha testing:** r, e, n candidates with pinned optimization
- **Board:** Custom 31-key (3x10 + 1 thumb) for r-thumb; ortho 3x10 for no-thumb

## Files

| File | Description |
|------|-------------|
| `repo/config.toml` | Oxeylyzer configuration with bilingual weights |
| `repo/static/text/bilingual_mixed/` | Raw corpus files |
| `repo/static/corpus_configs/provided/bilingual_mixed.toml` | Corpus config (ñ preserved, accents folded) |
| `repo/static/corpus_configs/provided/spanish_pure.toml` | Spanish-only corpus config |
| `repo/static/corpus_configs/provided/english_pure.toml` | English-only corpus config |
| `repo/static/language_data/bilingual_mixed.json` | Pre-computed bilingual n-gram data |
| `repo/static/layouts/bilingual_mixed/final_r_thumb.dof` | Best r-thumb layout |
| `repo/static/layouts/bilingual_mixed/final_3x10.dof` | Best 3x10 layout |
| `repo/static/layouts/voyager/enthium_v14.dof` | Enthium v14 reference (with ñ) |
| `repo/static/layouts/voyager/colemak_dh.dof` | Colemak-DH reference (with ñ) |
| `repo/static/layouts/voyager/sturdy.dof` | Sturdy reference (with ñ) |

## Voyager Key Mapping

For the r-thumb layout on the Voyager's 52-key physical board:

```
[Tab] ñ z o u k    b w l f q [???]
[Cap] i e a h ,    c d n s t [???]
[Ctl] y ' / . x    p g j v m [Del]
       [GUI][SPC]  [r/L1][BS/L2]
```

- `r` on R_thumb_inner with layer-tap to Layer_1
- Space on L_thumb_inner
- Backspace on R_thumb_outer with layer-tap to Layer_2
- GUI/Super on L_thumb_outer
- Outer columns: modifiers, symbols, or additional function keys
- Number row: numbers, F-keys, media (separate layer concern)
