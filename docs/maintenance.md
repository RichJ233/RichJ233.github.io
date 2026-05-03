# Maintaining CV Sections

This site keeps the original static HTML style, but the repetitive publication,
patent, and award entries can be generated from CSV files.

## Files

- `data/publications.csv`: papers and patents.
- `data/awards.csv`: award entries.
- `scripts/build_cv_sections.ps1`: updates the generated sections in `index.html` on Windows/PowerShell.
- `scripts/build_cv_sections.py`: optional Python version for machines with Python installed.

## Workflow

1. Open a CSV file in Excel or another spreadsheet editor.
2. Add, remove, or edit rows.
3. Save as CSV UTF-8.
4. Run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_cv_sections.ps1
```

5. Open `index.html` and check the result.

If Python is installed, this equivalent command is also available:

```powershell
python scripts\build_cv_sections.py
```

## Image Format

In `data/publications.csv`, the `images` column supports one or more image specs:

```text
assets/img/p/example.png|alt=Example|height=180
assets/img/p/a.png|alt=A|height=180;;assets/img/p/b.png|alt=B|height=180
```

For awards, use the `image` and `image_link` columns.

## HTML In Cells

Some cells intentionally allow small HTML fragments, such as `<B>Jiang R.</B>`,
`<sup>th</sup>`, or a patent link. Keep these fragments short and well-formed.
