# JEI submission checklist — Adaptation Buffer paper

Use this checklist when submitting to the [Journal of Emerging Investigators](https://emerginginvestigators.org/submissions/guidelines).

## Files in this folder

| File | Purpose |
|------|---------|
| `global_paper_JEI.docx` | JEI-formatted manuscript (Word) |
| `figures/Figure1.jpeg` | Vulnerability vs. undernourishment scatter plot |
| `figures/Figure2.jpeg` | Selected-country buffer bar chart |
| `figures/Figure3.jpeg` | Collapse-probability comparison |
| `scripts/build_jei_manuscript.py` | Regenerates the Word file and figures |

To rebuild after editing the script text:

```bash
cd "Global Research Paper"
python3 scripts/build_jei_manuscript.py
```

## Before you submit

### Required from JEI

- [ ] Download the **official JEI manuscript template** from [emerginginvestigators.org/documents](https://emerginginvestigators.org/documents)
- [ ] Copy the content from `global_paper_JEI.docx` into that template (JEI requires their template for pre-review)
- [ ] Fill in **author names** and **school affiliations** on the title page (mentor listed last)
- [ ] Confirm an **adult mentor** will submit on your behalf (students cannot submit directly)
- [ ] Pay the submission fee and save your **10-character confirmation code**
- [ ] Upload via **Editorial Manager** (not email)

### Formatting (already applied in `global_paper_JEI.docx`)

- [x] Section order: Title Page → Summary → Introduction → Results → Discussion → Materials and Methods → References → Acknowledgements
- [x] Times New Roman, 11 pt, 1.5 line spacing, 1-inch margins
- [x] Title ≤ 110 characters (current: 83)
- [x] Summary ≤ 250 words (current: ~197)
- [x] Numbered in-text citations (1), (2), … matching numbered reference list (JEI modified MLA)
- [x] 3 figures + 4 tables = 7 items (JEI allows 3–8)
- [ ] Body ≤ **10 pages** (excluding title page, references, figures/captions) — verify in Word after pasting into template

### Figures (upload separately)

- [ ] `Figure1.jpeg` — vulnerability vs. hunger
- [ ] `Figure2.jpeg` — buffer bar chart
- [ ] `Figure3.jpeg` — collapse simulation
- Name files with figure numbers (e.g. `Figure1.jpeg`) for editors

### Editorial Manager fields

- [ ] One-sentence **hypothesis** (e.g. *Countries with higher adaptive readiness will show larger positive adaptation buffers after accounting for climate vulnerability alone.*)
- [ ] How you heard about JEI
- [ ] Short answers: interest in the project, interesting findings, difficulties
- [ ] Institution name for each author

### Eligibility and policy

- [ ] Only **one** manuscript at a time at JEI
- [ ] Manuscript **not** submitted elsewhere (no SSRN/arXiv/competition journal with conflicting copyright)
- [ ] No human subjects or vertebrate animals (no approval forms needed for this study)
- [ ] All outside data and software cited (references 1–15)

## Section map (draft → JEI)

| Original draft section | JEI section |
|------------------------|-------------|
| Abstract | Summary |
| Introduction + Literature Review | Introduction (condensed) |
| Results (§4.1–4.7) | Results (Experiments 1–6 + robustness) |
| Discussion + Limitations + Conclusion | Discussion |
| Data and Methods (§3) | Materials and Methods |
| References | References (renumbered, MLA) |
| — | Acknowledgements |
| Appendix A (Bangladesh) | Omitted from main text (request appendix only if editors agree) |

## Citation style reminder

- In text: numbered at end of sentence, e.g. `(4).`
- Reference list: numbered 1, 2, 3… in order of first appearance
- Journal articles: no publisher name; include DOI when available
- Websites: include “Accessed [date]”

## After acceptance

JEI publishes online on a rolling basis. You will review the typeset PDF before it goes live.
