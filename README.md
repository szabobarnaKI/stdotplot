# stdotplot: follow-up histories of st data as a dot plot

`stdotplot` draws each subject's follow-up from multiple-record, multiple-failure `stset` data as one horizontal line, with markers for events of interest, competing events, censoring and, optionally, entry.

- Each record is drawn from `_t0` to `_t`, so gaps in follow-up and delayed entry are visible.
- Competing events are the codes of the `stset` failure variable listed in `compete()`. They take precedence over `failure()`, so it doesn't matter whether `failure()` includes them.
- A competing code before the end of follow-up (e.g. follow-up continuing after a death) is always marked, so misspecified data are easy to spot.
- `colorby()` colours each follow-up segment by a time-varying categorical variable.
- Time-varying weights (e.g. inverse probability weights) can be shown as line width or colour intensity.
- Any `twoway` option can be added. The legend switches to one column automatically when it is placed at the side or inside the plot, or when the graph is narrow.

Requires Stata 15 or later. Line widths in points (`wstyle(width)`) need Stata 16; older versions use equivalent relative sizes.

## Install

```stata
net install stdotplot, from("https://raw.githubusercontent.com/szabobarnaKI/stdotplot/main/") replace
```

Or by hand: copy `stdotplot.ado` and `stdotplot.sthlp` into your PERSONAL ado folder (type `sysdir` in Stata to find it).

## Usage

```stata
stset t, id(id) failure(status==1) time0(t0) exit(time .)
stdotplot, compete(2)
stdotplot, compete(2) colorby(dose) colors(green orange red) legend(position(3))
stdotplot if id <= 20, compete(2) idlabel entry
```

Time-varying weights: `stset` does not allow pweights that vary within `id()`, so `stset` without `id()` and give the identifier to `stdotplot`:

```stata
stset t, failure(status==1) time0(t0)
stdotplot [pw=ipw], id(id) compete(2) colorby(dose) wstyle(intensity) wcuts(0.5 1 2)
```

| Option | Meaning |
|---|---|
| `id(varname)` | subject identifier, if not set (or to override) in `stset` |
| `compete(numlist)` | codes of the failure variable that are competing events |
| `entry`, `nocensor` | mark the start of follow-up; hide censoring markers |
| `colorby(varname)`, `colors()` | colour segments by a time-varying categorical variable |
| `wstyle(width\|intensity)`, `wbins(#)`, `wcuts()` | show weights as line width or colour intensity, in classes |
| `wminw(#)`, `wmaxw(#)` | thinnest and thickest line in points |
| `sortby(varlist)`, `descending` | order of subjects; default end of follow-up |
| `idlabel`, `idlsize()` | label the y axis with subject identifiers |
| `eventopts()`, `competeopts()`, `midcompeteopts()`, `censopts()`, `entryopts()` | marker options |
| `legend()`, *twoway_options* | added to the default legend and graph |

Stored results: `r(N_sub)`, `r(N_fail)`, `r(N_compete)`, `r(N_compete_mid)`, `r(N_cens)`, and `r(levels)`, `r(wcuts)`, `r(wstyle)`, `r(wexp)`, `r(legcols)` where relevant. See `help stdotplot` for details.

## Files

- `stdotplot.ado`, `stdotplot.sthlp`: the command and its help file
- `stdotplot.pkg`, `stata.toc`: package files for `net install`
- `stdotplot_test.do`: tests on simulated data (uses `ghlog` to upload the log; edit or remove those lines)

## AI disclosure

This command was developed using substantial work from Claude AI (Anthropic), with human supervision.

## Author

Barna Szabó-Söderberg, Karolinska Institutet, barna.szabo@ki.se
