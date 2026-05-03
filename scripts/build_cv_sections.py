from __future__ import annotations

import csv
import html
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
INDEX = ROOT / "index.html"
PUBLICATIONS = ROOT / "data" / "publications.csv"
AWARDS = ROOT / "data" / "awards.csv"


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as file:
        return [{key: (value or "").strip() for key, value in row.items()} for row in csv.DictReader(file)]


def attr_text(attrs: dict[str, str]) -> str:
    return "".join(f' {name}="{html.escape(value, quote=True)}"' for name, value in attrs.items() if value)


def render_images(spec: str, default_alt: str) -> str:
    if not spec:
        return ""

    output: list[str] = []
    for raw_item in spec.split(";;"):
        item = raw_item.strip()
        if not item:
            continue
        parts = [part.strip() for part in item.split("|") if part.strip()]
        src = parts[0]
        attrs = {"src": src, "alt": default_alt}
        for part in parts[1:]:
            if "=" in part:
                key, value = part.split("=", 1)
                attrs[key.strip()] = value.strip()
        output.append(f"\t  <img{attr_text(attrs)}>")
    return "\n".join(output)


def render_title(row: dict[str, str]) -> str:
    title = html.escape(row["title"])
    url = row["title_url"]
    if url:
        return f'<a href="{html.escape(url, quote=True)}" target="_blank" class="publication-title">{title}</a>'
    return title


def render_publication(row: dict[str, str]) -> str:
    lead = "<br>" if row["lead_break"].lower() in {"yes", "true", "1"} else ""
    prefix = f'{row["prefix"]} ' if row["prefix"] else ""
    authors = f'{row["authors_html"]}, ' if row["authors_html"] else ""
    title = render_title(row)
    venue = f', {row["venue_html"]}' if row["venue_html"] else ""
    extra = f' {row["extra_html"]}' if row["extra_html"] else ""
    images = render_images(row["images"], row["title"])
    image_block = f"\n{images}" if images else ""

    return f'''        <div class="publication">
          <div class="publication-content">
            <p>
              {lead}<b>({html.escape(row["year"])})</b> {prefix}{authors}{title}{venue}{extra}
            </p>
          </div>{image_block}
        </div>'''


def render_publications(rows: list[dict[str, str]]) -> str:
    papers = [row for row in rows if row["kind"].lower() == "paper"]
    patents = [row for row in rows if row["kind"].lower() == "patent"]

    paper_html = "\n\n".join(render_publication(row) for row in papers)
    patent_html = "\n\n".join(render_publication(row) for row in patents)

    return f'''<!-- BEGIN GENERATED PUBLICATIONS: edit data/publications.csv, then run scripts/build_cv_sections.py -->
      <div class="publication-list">

{paper_html}

      </div>

<!-- END OF PAPER---------------------------------------------------- -->
<!-- BEGIN OF PATENT------------------------------------------------- -->

{patent_html}

<!-- END GENERATED PUBLICATIONS -->'''


def render_award(row: dict[str, str]) -> str:
    year = row["year"]
    image = row["image"]
    image_link = row["image_link"]
    items = [item.strip() for item in row["items"].split("||") if item.strip()]

    image_html = ""
    if image:
        img = f'          <img src="{html.escape(image, quote=True)}" alt="Award Image" class="project-image" height="150">'
        if image_link:
            image_html = f'          <a href="{html.escape(image_link, quote=True)}">\n{img}\n          </a>\n'
        else:
            image_html = f"{img}\n"

    title_html = f'            <h3 class="project-title"><b>({html.escape(year)})</b> </h3>\n' if year else ""
    item_html = "\n".join(f'            <p class="project-description">{item}</p>' for item in items)

    return f'''        <div class="project-item">
{image_html}          <div class="project-details">
{title_html}{item_html}
          </div>
        </div>'''


def render_awards(rows: list[dict[str, str]]) -> str:
    awards_html = "\n\n".join(render_award(row) for row in rows)
    return f'''<!-- BEGIN GENERATED AWARDS: edit data/awards.csv, then run scripts/build_cv_sections.py -->
      <div class="section-title">
      	<h2>Awards</h2>
      </div>

      <div class="projects-list">
{awards_html}
      </div>
<!-- END GENERATED AWARDS -->'''


def replace_once(text: str, pattern: str, replacement: str, label: str) -> str:
    new_text, count = re.subn(pattern, replacement, text, count=1, flags=re.S)
    if count != 1:
        raise RuntimeError(f"Could not replace {label}; matched {count} blocks.")
    return new_text


def main() -> None:
    text = INDEX.read_text(encoding="utf-8")

    publications_html = render_publications(read_rows(PUBLICATIONS))
    if "<!-- BEGIN GENERATED PUBLICATIONS:" in text:
        text = replace_once(
            text,
            r"<!-- BEGIN GENERATED PUBLICATIONS:.*?<!-- END GENERATED PUBLICATIONS -->",
            publications_html,
            "generated publications",
        )
    else:
        text = replace_once(
            text,
            r'<div class="publication-list">.*?<!-- END OF PATENT--------------------------------------------------- -->',
            publications_html,
            "initial publications",
        )

    awards_html = render_awards(read_rows(AWARDS))
    if "<!-- BEGIN GENERATED AWARDS:" in text:
        text = replace_once(
            text,
            r"<!-- BEGIN GENERATED AWARDS:.*?<!-- END GENERATED AWARDS -->",
            awards_html,
            "generated awards",
        )
    else:
        text = replace_once(
            text,
            r"<!-- awards----------------------------------------------------->.*?(?=\n\s*</div>\s*\n\s*</section>\s*\n\s*<!-- End Award Section -->)",
            awards_html,
            "initial awards",
        )

    INDEX.write_text(text, encoding="utf-8")


if __name__ == "__main__":
    main()
