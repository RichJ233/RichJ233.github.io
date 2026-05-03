# Agent Notes for MyOnlineCV

## Purpose

This repository is **Ruiqi Jiang / JIANG Ruiqi's static academic CV site**.
It is intended to stay simple enough for GitHub Pages: plain HTML, CSS, local assets, and small helper scripts.

The live site is linked from `README.md` as:

```text
https://richj233.github.io/
```

The CV presents Ruiqi as a research postgraduate / Ph.D. candidate in Civil Engineering at **The University of Hong Kong**, affiliated with **CI3-Lab** under **Prof. LI Xiao**. The academic emphasis is construction robotics, modular integrated construction, robotic arms, embedded control, computer vision, autonomous robots, machine learning, and time-series research.

## Non-Negotiable Design Direction

The user likes the current original style. **Do not redesign the site unless explicitly asked.**

Preserve:

- BootstrapMade "Personal" template feel.
- Green accent color and dark fixed header.
- Section-switching navigation behavior.
- Existing profile/card/project/publication visual language.
- Image-heavy academic CV layout.
- Existing class names and CSS patterns.

Avoid:

- Replacing the page with a new design system.
- Converting it to a modern SPA/framework.
- Removing the section-switch behavior.
- Reworking the color palette, typography direction, or card style.
- Broadly "cleaning" legacy HTML in a way that changes rendering.

Good changes are conservative: maintenance tooling, small HTML correctness fixes, dependency reduction, and carefully scoped responsiveness improvements.

## Current Architecture

### Main Files

- `index.html`: main CV page and published homepage.
- `assets/css/style.css`: main stylesheet based on BootstrapMade "Personal", with local customizations.
- `assets/js/main.js`: lean interaction script for section navigation and mobile nav only.
- `assets/img/p/`: publication, patent, project, and award images.
- `assets/img/me/`: personal and activity photos.
- `assets/img/img/`: profile card image and icon.
- `assets/vendor/`: vendored libraries. Many are legacy and kept for old pages.
- `projects/`: legacy project detail pages. Many still contain original template/sample content.
- `data/publications.csv`: data source for publications and patents.
- `data/awards.csv`: data source for awards.
- `scripts/build_cv_sections.ps1`: primary generator for updating generated CV sections on Windows/PowerShell.
- `scripts/build_cv_sections.py`: optional Python generator for systems with Python installed.
- `docs/maintenance.md`: user-facing maintenance instructions.

### Runtime Dependencies for `index.html`

The homepage has been lightly optimized. It currently loads only these local/vendor files:

- `assets/vendor/bootstrap/css/bootstrap.min.css`
- `assets/vendor/icofont/icofont.min.css`
- `assets/vendor/jquery/jquery.min.js`
- `assets/css/style.css`
- `assets/js/main.js`

Do not reintroduce unused vendor dependencies unless the page actually uses them.

Removed from homepage loading because they were unused there:

- `remixicon`
- `boxicons`
- `owl.carousel`
- `venobox`
- `bootstrap.bundle`
- `jquery.easing`
- `php-email-form`
- `waypoints`
- `counterup`
- `isotope`
- `typed.js`

The files may still exist under `assets/vendor/` for legacy `projects/` pages. Do not delete vendor folders unless the user explicitly asks and you verify old pages.

## Main Page Map

`index.html` contains these sections:

- Header:
  - HKU and CI3 Lab logos.
  - Navigation links to `#publication`, `#award`, plus external GitHub, Google Scholar, and CI3-Lab.
- `#home`:
  - Profile image and identity block.
  - Education.
  - Memberships.
  - About Me masonry photos.
  - Related Source links.
- `#publication`:
  - Generated publications block.
  - Generated patents block.
  - Manually maintained Project Experience block.
- `#award`:
  - Manually maintained Social Service block.
  - Generated Awards block.
- `#contacts`:
  - Join us / recruitment note.

## Generated Sections

Publications, patents, and awards are now generated from CSV data. The generated blocks in `index.html` are marked:

```html
<!-- BEGIN GENERATED PUBLICATIONS: ... -->
...
<!-- END GENERATED PUBLICATIONS -->
```

```html
<!-- BEGIN GENERATED AWARDS: ... -->
...
<!-- END GENERATED AWARDS -->
```

Do not manually edit content inside those generated regions unless you also update the CSV. Manual edits inside generated blocks will be overwritten next time the generator runs.

### CSV Editing Workflow

Use this workflow for publication, patent, or award updates:

1. Edit `data/publications.csv` or `data/awards.csv`.
2. Save as CSV UTF-8.
3. Run from the repo root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_cv_sections.ps1
```

4. Check `index.html`.
5. Verify the page still displays.

Python alternative, only if real Python is installed:

```powershell
python scripts\build_cv_sections.py
```

Important environment note: on this machine, `python.exe` may be the Microsoft Store placeholder, not real Python. Prefer the PowerShell script unless Python is confirmed available.

### `data/publications.csv`

This file drives both papers and patents.

Columns:

- `kind`: `paper` or `patent`.
- `year`: displayed inside `<b>(YEAR)</b>`.
- `lead_break`: `yes` to insert `<br>` before the year, otherwise `no`.
- `prefix`: optional text before the title, usually `(Patent)`.
- `authors_html`: author list; may contain small HTML such as `<B>Jiang R.</B>`.
- `title`: title text.
- `title_url`: optional URL. If present, title becomes a linked `.publication-title`.
- `venue_html`: venue or bibliographic details.
- `extra_html`: optional extra HTML, such as video or patent number links.
- `images`: optional image specs.

Image specs use this format:

```text
assets/img/p/example.png|alt=Example|height=180
```

Multiple images are separated with `;;`:

```text
assets/img/p/a.png|alt=A|height=180;;assets/img/p/b.png|alt=B|height=180
```

Notes:

- Keep short HTML fragments well-formed.
- If a title has no `title_url`, it renders as plain text.
- For patents, put patent-number links in `extra_html` when the title itself should not be the link.

### `data/awards.csv`

Columns:

- `year`: displayed as `(YEAR)`. Can be blank for the final note row.
- `items`: one or more award lines. Separate multiple lines with `||`.
- `image`: optional image path.
- `image_link`: optional link wrapping the image.

Award examples:

```csv
2025,"Outstanding Teaching Assistant Award 2024-2025, Department of Civil Engineering, The University of Hong Kong",,
2024,"Golden Medal...||23<sup>th</sup> RoboMaster...",assets/img/p/GoldenMedal.jpg,https://...
```

Because commas and quotes are common in awards, quote the whole `items` cell when needed.

## Manual Editing Guidance

For non-generated sections:

- `#home`, Related Source, Project Experience, Social Service, and Join Us are still manually edited in `index.html`.
- Preserve existing classes:
  - `section-title`
  - `publication`
  - `publication-content`
  - `projects-list`
  - `project-item`
  - `project-image`
  - `project-details`
  - `project-title`
  - `project-description`
- Put new publication/project/award images under `assets/img/p/` unless there is a strong reason to use another folder.
- Avoid deleting personal photos, project images, or legacy pages unless explicitly requested.
- Avoid broad encoding rewrites. Some legacy comments or old visible text may contain mojibake.

## JavaScript Notes

`assets/js/main.js` intentionally contains only:

- Navigation click handling for `.nav-menu a` and `.mobile-nav a`.
- Initial hash activation.
- Mobile nav cloning and toggle behavior.

Do not add back old unused plugin initialization unless the matching HTML and vendor dependency are also restored intentionally.

The old removed behaviors included:

- CounterUp.
- Waypoints skill animation.
- Owl Carousel testimonials.
- Isotope portfolio filtering.
- Venobox lightbox.
- Typed.js rotating text.

## Responsive Work Policy

Be careful with CSS changes. This template relies on absolute-positioned `section` elements and `section-show` to display only one section at a time.

Rules:

- Do not override base `section`, `section.section-show`, `#header.header-top`, or opacity/top/bottom behavior casually.
- Prefer small, targeted CSS at the end of `assets/css/style.css`.
- Test after each CSS change.
- Focus on overflow, image sizing, mobile nav readability, and project cards.
- Avoid changing visual identity.

Past issue to avoid: broad responsive overrides to `section` made the page appear blank except for the header.

## Verification Checklist

After any meaningful change, run or inspect:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_cv_sections.ps1
```

Then check:

- `index.html` opens and shows the home section.
- Navigation switches between `#home`, `#publication`, `#award`, and `#contacts`.
- Local image paths exist.
- No missing script dependencies.
- Long paper/project titles wrap acceptably.
- Generated block markers are still present.

Useful commands:

```powershell
Select-String -Path index.html -Pattern 'BEGIN GENERATED|END GENERATED'
```

```powershell
$missing = @(); Select-String -Path index.html -Pattern 'src="([^"]+)"' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $p = $_.Groups[1].Value; if ($p -notmatch '^https?://' -and -not (Test-Path -LiteralPath $p)) { $missing += $p } }; if ($missing.Count -eq 0) { 'All local image sources exist.' } else { $missing }
```

```powershell
$checks = 'section','p','script'; foreach ($tag in $checks) { $open = (Select-String -Path index.html -Pattern "<$tag(\s|>)" -AllMatches | ForEach-Object { $_.Matches.Count } | Measure-Object -Sum).Sum; $close = (Select-String -Path index.html -Pattern "</$tag>" -AllMatches | ForEach-Object { $_.Matches.Count } | Measure-Object -Sum).Sum; "$tag open=$open close=$close" }
```

## Git / Environment Notes

This repo may trigger Git's dubious ownership check. For read-only inspection, use:

```powershell
git -c safe.directory=D:/MyOnlineCV status --short
```

Do not change global Git config unless the user approves.

`README.md` is the tracked README path. The IDE may show `Readme.md` on Windows due to case-insensitive filesystem behavior.

