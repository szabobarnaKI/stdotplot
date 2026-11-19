{smcl}
{* *! version 0.8.1  19nov2026}{...}
{viewerjumpto "Syntax" "stdotplot##syntax"}{...}
{viewerjumpto "Description" "stdotplot##description"}{...}
{viewerjumpto "Examples" "stdotplot##examples"}{...}
{viewerjumpto "Stored results" "stdotplot##results"}{...}
{viewerjumpto "AI disclosure" "stdotplot##ai"}{...}
{title:Title}

{phang}
{bf:stdotplot} {hline 2} Individual follow-up histories of st data as a connected dot plot


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:stdotplot} {ifin} [{it:{help weight:pweight}}] [{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Subjects and events}
{synopt:{opth id(varname)}}subject identifier, if not set (or to override) in {cmd:stset}; needed with time-varying weights{p_end}
{synopt:{opth comp:ete(numlist)}}codes of the failure variable that are competing events{p_end}
{synopt:{opt entry}}mark the start of each subject's follow-up{p_end}
{synopt:{opt nocens:or}}do not draw censoring markers{p_end}

{syntab:Segments}
{synopt:{opth colorby(varname)}}colour each follow-up record by a time-varying categorical variable{p_end}
{synopt:{opt colors(colorlist)}}colours for the levels of {opt colorby()}, in sorted order of the levels{p_end}
{synopt:{opt lp:attern(linepattern)}}line pattern; default {cmd:dot} ({cmd:solid} with {opt colorby()}){p_end}
{synopt:{opt lw:idth(linewidth)}}line width; default {cmd:medthin} ({cmd:medthick} with {opt colorby()}){p_end}
{synopt:{opt lc:olor(color)}}line colour without {opt colorby()}; default {cmd:fg}{p_end}
{synopt:{opt lineop:ts(options)}}further options for the {cmd:pcspike} segments{p_end}

{syntab:Weights}
{synopt:{opt wst:yle(style)}}{cmd:width} (default) or {cmd:intensity}; with no {cmd:[pweight=]}, uses the {cmd:stset} pweight{p_end}
{synopt:{opt wb:ins(#)}}number of equal-width weight classes, 1-9; default 5{p_end}
{synopt:{opth wc:uts(numlist)}}cutpoints of the weight classes instead of {opt wbins()} (at most 8){p_end}
{synopt:{opt wmin:w(#)}}thinnest line in points with {cmd:wstyle(width)}; default 0.3{p_end}
{synopt:{opt wmax:w(#)}}thickest line in points; default depends on the number of subjects (0.8-4){p_end}
{synopt:{opt wf:ormat(%fmt)}}format of the weights in the legend; default {cmd:%9.3g}{p_end}
{synopt:{opt wmissl:abel(text)}}legend text for records with missing weight{p_end}

{syntab:Markers}
{synopt:{opt ms:ize(markersizestyle)}}marker size; default {cmd:small}{p_end}
{synopt:{opt eventop:ts(options)}}options for event-of-interest markers (default {cmd:msymbol(O)}){p_end}
{synopt:{opt competeop:ts(options)}}options for competing-event markers (default {cmd:msymbol(T)}){p_end}
{synopt:{opt midcompeteop:ts(options)}}options for competing codes before the end of follow-up (default {cmd:msymbol(D)}){p_end}
{synopt:{opt censop:ts(options)}}options for censoring markers (default {cmd:msymbol(Oh)}){p_end}
{synopt:{opt entryop:ts(options)}}options for entry markers (default {cmd:msymbol(pipe)}){p_end}

{syntab:Order and labels}
{synopt:{opth sort:by(varlist)}}order subjects by these variables (first record's values); default: end of follow-up{p_end}
{synopt:{opt des:cending}}reverse the order{p_end}
{synopt:{opt idl:abel}}label the y axis with subject identifiers{p_end}
{synopt:{opt idls:ize(textsizestyle)}}size of the {opt idlabel} labels; default depends on the number of subjects{p_end}
{synopt:{opt eventl:abel(text)}, {opt competel:abel(text)}, {opt midcompetel:abel(text)}, {opt censl:abel(text)}, {opt entryl:abel(text)}, {opt missl:abel(text)}}legend texts{p_end}
{synopt:{opt leg:end(options)}}legend options, added to the default legend; see {it:Legend} below{p_end}
{synopt:{it:twoway_options}}any other {helpb twoway_options}{p_end}
{synoptline}
{p 4 6 2}
You must {cmd:stset} your data before using {cmd:stdotplot}; see {manhelp stset ST}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:stdotplot} draws one horizontal line per subject from multiple-record,
multiple-failure {cmd:stset} data. Each record is drawn as a segment from
{cmd:_t0} to {cmd:_t}, so gaps in follow-up and delayed entry are visible.
Markers show events of interest ({cmd:_d==1}), competing events and censoring.
By default the segments are dotted lines in the foreground colour; with
{opt colorby()} each segment takes the colour of the level of a time-varying
variable on that record. Numeric {opt colorby()} variables must have integer
codes (value labels are used in the legend); string variables are encoded, so
their levels, and the colours in {opt colors()}, are in alphabetical order.
Records with a missing {opt colorby()} value are drawn dotted in the
foreground colour.

{pstd}
A competing event is the last record of a subject whose failure variable
(from {cmd:stset ..., failure()}) takes one of the codes in {opt compete()}.
{opt compete()} takes precedence over {cmd:failure()}: if the {cmd:failure()}
codes also include competing codes, those records ({cmd:_d==1}) are shown and
counted as competing events, not as events of interest, and a note is
displayed. An event of interest is a record with {cmd:_d==1} and no
{opt compete()} code. A subject is censored when the last record has neither
an event nor a competing event.

{pstd}
A {opt compete()} code on an earlier record is always marked, by
default as a filled diamond. This makes misspecified data easy to see, for
example follow-up or events of interest after a death.

{pstd}
{bf:Marker colours.} By default each marker has the {opt colorby()} colour of
the record that ends at it (the record of the event, competing event or
censoring; for {opt entry}, the first record), at full intensity: weight
classes change line width or intensity but never the markers. Without
{opt colorby()} markers have the line colour ({opt lcolor()}; {cmd:navy} with
{cmd:wstyle(intensity)}, otherwise the foreground colour). Use, e.g.,
{cmd:eventopts(mcolor(red))} to override. With several {opt colorby()} levels,
the legend shows the markers in the foreground colour.

{pstd}
The subject identifier is taken from {opt id()} or else from {cmd:stset}.
Without either, each observation is a subject.

{pstd}
{bf:Weights.} Time-varying weights (for example inverse probability weights)
are given as {cmd:[pweight=}{it:exp}{cmd:]}, which may vary between the records
of a subject. Because {cmd:stset} does not allow pweights that vary within
{cmd:id()}, {cmd:stset} such data without {cmd:id()} and give the identifier to
{cmd:stdotplot} with {opt id()}. With {opt wstyle()} and no
{cmd:[pweight=]}, the (subject-constant) {cmd:stset} pweight is used. The weights are grouped into classes ({opt wbins()} equal-width
classes between the smallest and largest weight, or {opt wcuts()}), and each
segment is drawn with a line width ({cmd:wstyle(width)}: linear in points
from {opt wminw()} to {opt wmaxw()}, where the default {opt wmaxw()} is about
60% of the spacing between subjects, between 0.8 and 4 points, taking
{cmd:ysize()} into account; before Stata 16, which has no point units, the
same widths are given as relative sizes computed from {cmd:xsize()} and
{cmd:ysize()}) or a
colour intensity ({cmd:wstyle(intensity)}: from 0.30 to 1.30 times the base
colour) that increases with the class. Records with missing {cmd:[pweight=]}
values are drawn as thin dotted lines. Note that {cmd:stset ... [pw=]}
itself excludes records with missing weights ({cmd:_st==0}), and such records
are not drawn at all; to show them, {cmd:stset} without weights and give the
weights to {cmd:stdotplot}. Weights are only used for display.

{pstd}
{bf:Subject labels.} With {opt idlabel}, the label size is {cmd:vsmall} for up
to 20 subjects, {cmd:tiny} up to 40, {cmd:half_tiny} up to 80 and
{cmd:third_tiny} above that; change it with {opt idlsize()} or make the graph
taller with {cmd:ysize()}.


{pstd}
{bf:Legend.} The default legend shows the markers, then the {opt colorby()}
levels, then the weight classes, in small text. Options in {opt legend()} are
added to it, so, e.g., {cmd:legend(position(3))} puts it on the right and
{cmd:legend(position(4) ring(0))} inside the plot. Unless you specify
{cmd:cols()} or {cmd:rows()}, the legend has one column when it is on the
left or right (positions 2-4 and 8-10), inside the plot ({cmd:ring(0)}), or
when two columns would be wider than the graph (estimated from the legend
texts and {cmd:xsize()}/{cmd:ysize()}). {cmd:legend(cols(2))} keeps two
columns.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. stset t, id(id) failure(status==1) time0(t0) exit(time .)}{p_end}
{phang2}{cmd:. stdotplot, compete(2)}{p_end}
{phang2}{cmd:. stdotplot, compete(2) colorby(dose) colors(green orange red)}{p_end}
{phang2}{cmd:. stdotplot if id <= 20, compete(2) idlabel entry}{p_end}
{phang2}{cmd:. stset t, failure(status==1) time0(t0)}{p_end}
{phang2}{cmd:. stdotplot [pw=ipw], id(id) compete(2) wstyle(width)}{p_end}
{phang2}{cmd:. stdotplot [pw=ipw], id(id) compete(2) colorby(dose) wstyle(intensity) wcuts(0.5 1 2)}{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 16 tabbed}{...}
{synopt:{cmd:r(N_sub)}}number of subjects{p_end}
{synopt:{cmd:r(N_fail)}}number of events of interest{p_end}
{synopt:{cmd:r(N_compete)}}number of competing events{p_end}
{synopt:{cmd:r(N_compete_mid)}}number of compete() codes before the end of follow-up{p_end}
{synopt:{cmd:r(N_cens)}}number of censored subjects{p_end}
{synopt:{cmd:r(levels)}}levels of {opt colorby()}{p_end}
{synopt:{cmd:r(wcuts)}}cutpoints of the weight classes{p_end}
{synopt:{cmd:r(wstyle)}}{cmd:width} or {cmd:intensity}{p_end}
{synopt:{cmd:r(wexp)}}weight expression{p_end}
{synopt:{cmd:r(legcols)}}{cmd:cols(1)} if the legend was switched to one column{p_end}


{marker ai}{...}
{title:AI disclosure}

{pstd}
This command was developed using substantial work from Claude AI (Anthropic), with human supervision.
{p_end}

{marker author}{...}
{title:Author}

{pstd}
Barna Szabó-Söderberg{break}
{it:Karolinska Institutet}{break}
{ul:barna.szabo@ki.se}
{p_end}
