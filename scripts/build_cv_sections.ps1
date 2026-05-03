$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$IndexPath = Join-Path $Root "index.html"
$PublicationsPath = Join-Path $Root "data\publications.csv"
$AwardsPath = Join-Path $Root "data\awards.csv"

function Escape-Attr([string]$Value) {
  return [System.Net.WebUtility]::HtmlEncode($Value)
}

function Render-Images([string]$Spec, [string]$DefaultAlt) {
  if ([string]::IsNullOrWhiteSpace($Spec)) {
    return ""
  }

  $items = @()
  foreach ($rawItem in ($Spec -split ";;")) {
    $rawItem = $rawItem.Trim()
    if (-not $rawItem) { continue }

    $parts = @($rawItem -split "\|" | Where-Object { $_.Trim() })
    $src = $parts[0].Trim()
    $attrs = [ordered]@{
      src = $src
      alt = $DefaultAlt
    }

    foreach ($part in $parts[1..($parts.Count - 1)]) {
      if ($part -and $part.Contains("=")) {
        $key, $value = $part.Split("=", 2)
        $attrs[$key.Trim()] = $value.Trim()
      }
    }

    $attrText = ""
    foreach ($key in $attrs.Keys) {
      if ($attrs[$key]) {
        $attrText += " $key=`"$(Escape-Attr $attrs[$key])`""
      }
    }
    $items += "`t  <img$attrText>"
  }

  return ($items -join "`r`n")
}

function Render-Title($Row) {
  $title = [System.Net.WebUtility]::HtmlEncode($Row.title)
  if ($Row.title_url) {
    return "<a href=`"$(Escape-Attr $Row.title_url)`" target=`"_blank`" class=`"publication-title`">$title</a>"
  }
  return $title
}

function Render-Publication($Row) {
  $lead = ""
  if (@("yes", "true", "1") -contains $Row.lead_break.ToLowerInvariant()) {
    $lead = "<br>"
  }

  $prefix = ""
  if ($Row.prefix) {
    $prefix = "$($Row.prefix) "
  }

  $authors = ""
  if ($Row.authors_html) {
    $authors = "$($Row.authors_html), "
  }

  $venue = ""
  if ($Row.venue_html) {
    $venue = ", $($Row.venue_html)"
  }

  $extra = ""
  if ($Row.extra_html) {
    $extra = " $($Row.extra_html)"
  }

  $title = Render-Title $Row
  $images = Render-Images $Row.images $Row.title
  $imageBlock = ""
  if ($images) {
    $imageBlock = "`r`n$images"
  }

  return @"
        <div class="publication">
          <div class="publication-content">
            <p>
              $lead<b>($($Row.year))</b> $prefix$authors$title$venue$extra
            </p>
          </div>$imageBlock
        </div>
"@
}

function Render-Publications($Rows) {
  $papers = @($Rows | Where-Object { $_.kind.ToLowerInvariant() -eq "paper" })
  $patents = @($Rows | Where-Object { $_.kind.ToLowerInvariant() -eq "patent" })
  $paperHtml = (($papers | ForEach-Object { Render-Publication $_ }) -join "`r`n")
  $patentHtml = (($patents | ForEach-Object { Render-Publication $_ }) -join "`r`n")

  return @"
<!-- BEGIN GENERATED PUBLICATIONS: edit data/publications.csv, then run scripts/build_cv_sections.ps1 -->
      <div class="publication-list">

$paperHtml

      </div>

<!-- END OF PAPER---------------------------------------------------- -->
<!-- BEGIN OF PATENT------------------------------------------------- -->

$patentHtml

<!-- END GENERATED PUBLICATIONS -->
"@
}

function Render-Award($Row) {
  $imageHtml = ""
  if ($Row.image) {
    $img = "          <img src=`"$(Escape-Attr $Row.image)`" alt=`"Award Image`" class=`"project-image`" height=`"150`">"
    if ($Row.image_link) {
      $imageHtml = "          <a href=`"$(Escape-Attr $Row.image_link)`">`r`n$img`r`n          </a>`r`n"
    } else {
      $imageHtml = "$img`r`n"
    }
  }

  $titleHtml = ""
  if ($Row.year) {
    $titleHtml = "            <h3 class=`"project-title`"><b>($($Row.year))</b> </h3>`r`n"
  }

  $items = @($Row.items -split "\|\|" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
  $itemHtml = (($items | ForEach-Object { "            <p class=`"project-description`">$_</p>" }) -join "`r`n")

  return @"
        <div class="project-item">
$imageHtml          <div class="project-details">
$titleHtml$itemHtml
          </div>
        </div>
"@
}

function Render-Awards($Rows) {
  $awardsHtml = (($Rows | ForEach-Object { Render-Award $_ }) -join "`r`n")

  return @"
<!-- BEGIN GENERATED AWARDS: edit data/awards.csv, then run scripts/build_cv_sections.ps1 -->
      <div class="section-title">
      	<h2>Awards</h2>
      </div>

      <div class="projects-list">
$awardsHtml
      </div>
<!-- END GENERATED AWARDS -->
"@
}

function Replace-Once([string]$Text, [string]$Pattern, [string]$Replacement, [string]$Label) {
  $matches = [regex]::Matches($Text, $Pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
  if ($matches.Count -ne 1) {
    throw "Could not replace $Label; matched $($matches.Count) blocks."
  }
  return [regex]::Replace($Text, $Pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $Replacement }, [System.Text.RegularExpressions.RegexOptions]::Singleline)
}

$text = Get-Content -LiteralPath $IndexPath -Raw -Encoding UTF8

$publicationRows = Import-Csv -LiteralPath $PublicationsPath -Encoding UTF8
$publicationHtml = Render-Publications $publicationRows
if ($text.Contains("<!-- BEGIN GENERATED PUBLICATIONS:")) {
  $text = Replace-Once $text "<!-- BEGIN GENERATED PUBLICATIONS:.*?<!-- END GENERATED PUBLICATIONS -->" $publicationHtml "generated publications"
} else {
  $text = Replace-Once $text '<div class="publication-list">.*?<!-- END OF PATENT--------------------------------------------------- -->' $publicationHtml "initial publications"
}

$awardRows = Import-Csv -LiteralPath $AwardsPath -Encoding UTF8
$awardsHtml = Render-Awards $awardRows
if ($text.Contains("<!-- BEGIN GENERATED AWARDS:")) {
  $text = Replace-Once $text "<!-- BEGIN GENERATED AWARDS:.*?<!-- END GENERATED AWARDS -->" $awardsHtml "generated awards"
} else {
  $text = Replace-Once $text "<!-- awards----------------------------------------------------->.*?(?=`r?`n\s*</div>\s*`r?`n\s*</section>\s*`r?`n\s*<!-- End Award Section -->)" $awardsHtml "initial awards"
}

Set-Content -LiteralPath $IndexPath -Value $text -Encoding UTF8
