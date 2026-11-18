*! version 0.8.1  19nov2026
*! stdotplot: individual follow-up histories of multiple-record,
*!            multiple-failure st data as a connected dot plot
*! 0.2.0: competing codes on any record, id(), time-varying
*!        pweights shown as line width or colour intensity
*! 0.3.0: markers coloured like the segment ending at them
*! 0.4.0: gentler width ladder, intensity 0.30-1.30, markers take the
*!        colorby() colour only (not weight width/intensity), idlabel
*!        label size scales with the number of subjects, idlsize()
*! 0.5.0: weight widths in points, linear between wminw() and wmaxw(),
*!        top width scaled to the row spacing (Stata 18+)
*! 0.6.0: point widths from Stata 16 (unit suffixes); before Stata 16 the
*!        same widths as relative sizes (100 = min(xsize, ysize))
*! 0.7.0: one-column legend when placed at the side, inside the plot,
*!        or when two columns would be wider than the graph
*! 0.8.0: compete() codes take precedence over failure(): a record with a
*!        compete() code is a competing event even if _d==1 (note shown)
*! 0.8.1: mid-follow-up competing marker msymbol(D) (was Th)

program define stdotplot, rclass
    version 15
    st_is 2 analysis

    syntax [if] [in] [pweight] [,                                    ///
        id(varname)                                                  ///
        COMPete(numlist missingokay)                                 ///
        colorby(varname)                                             ///
        colors(string asis)                                          ///
        WSTyle(string)                                               ///
        WBins(integer 5)                                             ///
        WCuts(numlist ascending)                                     ///
        WFormat(string)                                              ///
        WMINw(real 0.3)                                              ///
        WMAXw(real -1)                                               ///
        RELWIDTH                                                     ///
        SORTby(varlist)                                              ///
        DEScending                                                   ///
        IDLabel                                                      ///
        IDLSize(string)                                              ///
        ENTry                                                        ///
        NOCENSor                                                     ///
        LPattern(string)                                             ///
        LWidth(string)                                               ///
        LColor(string)                                               ///
        MSize(string)                                                ///
        EVENTOPts(string asis)                                       ///
        COMPETEOPts(string asis)                                     ///
        MIDCOMPETEOPts(string asis)                                  ///
        CENSOPts(string asis)                                        ///
        ENTRYOPts(string asis)                                       ///
        LINEOPts(string asis)                                        ///
        EVENTLabel(string)                                           ///
        COMPETELabel(string)                                         ///
        MIDCOMPETELabel(string)                                      ///
        CENSLabel(string)                                            ///
        ENTRYLabel(string)                                           ///
        MISSLabel(string)                                            ///
        WMISSLabel(string)                                           ///
        LEGend(string asis)                                          ///
        * ]

    * ---------------------------------------------------------------
    * 1. st information, id, weights
    * ---------------------------------------------------------------
    local stid : char _dta[st_id]
    local fvar : char _dta[st_bd]

    if "`id'" != "" {
        if "`stid'" != "" & "`stid'" != "`id'" {
            di as txt "(note: id(`id') overrides the stset id `stid')"
        }
    }
    else local id `stid'

    if "`compete'" != "" & "`fvar'" == "" {
        di as err "compete() requires that a failure variable was " ///
            "specified in {bf:stset ..., failure()}"
        exit 198
    }
    if "`compete'" != "" {
        capture confirm numeric variable `fvar'
        if _rc {
            di as err "compete() requires a numeric failure variable"
            exit 109
        }
    }

    * weights: [pweight=] here, or the stset pweight when wstyle() is given
    local wexp
    if "`weight'" != "" local wexp `"`exp'"'
    else if "`wstyle'" != "" {
        local stwt : char _dta[st_wt]
        local stwv : char _dta[st_wv]
        if "`stwt'" == "pweight" & "`stwv'" != "" local wexp `"= `stwv'"'
        else {
            di as err "wstyle() requires [pweight=] or pweights in stset"
            exit 198
        }
    }
    * records with missing weights are drawn, so keep weights out of marksample
    local weight
    local exp
    local hasw = (`"`wexp'"' != "")
    if `hasw' {
        if "`wstyle'" == "" local wstyle width
        if !inlist("`wstyle'", "width", "intensity") {
            di as err "wstyle() must be width or intensity"
            exit 198
        }
        if "`wcuts'" == "" & (`wbins' < 1 | `wbins' > 9) {
            di as err "wbins() must be between 1 and 9"
            exit 198
        }
        if "`wformat'" == "" local wformat %9.3g
    }
    else if "`wcuts'" != "" | "`wformat'" != "" {
        di as err "wcuts() and wformat() require weights"
        exit 198
    }

    marksample touse, novarlist
    quietly replace `touse' = 0 if _st != 1
    quietly count if `touse'
    if r(N) == 0 error 2000

    * ---------------------------------------------------------------
    * 2. defaults
    * ---------------------------------------------------------------
    local solidmode = ("`colorby'" != "" | `hasw')
    if "`lpattern'" == "" local lpattern = cond(`solidmode', "solid", "dot")
    if "`lwidth'"   == "" local lwidth   = cond(`solidmode', "medthick", "medthin")
    if "`lcolor'"   == "" {
        if `hasw' & "`wstyle'" == "intensity" local lcolor navy
        else local lcolor fg
    }
    if "`msize'" == "" local msize small
    if `"`eventlabel'"'      == "" local eventlabel      "Event of interest"
    if `"`competelabel'"'    == "" local competelabel    "Competing event"
    if `"`midcompetelabel'"' == "" local midcompetelabel "Competing event, not end of follow-up"
    if `"`censlabel'"'       == "" local censlabel       "Censored"
    if `"`entrylabel'"'      == "" local entrylabel      "Entry"
    if `"`misslabel'"'       == "" local misslabel       "Missing"
    if `"`wmisslabel'"'      == "" local wmisslabel      "Weight missing"

    * s2color p1-p15, explicit so that colour intensity can be applied
    if `"`colors'"' == "" {
        local colors navy maroon forest_green dkorange teal cranberry   ///
            lavender khaki sienna emidblue emerald brown erose gold bluishgray
    }
    local ncol : word count `colors'
    * vvvthick is far too thick for follow-up lines; vvthick only with 9 classes

    * ---------------------------------------------------------------
    * 3. work on a copy
    * ---------------------------------------------------------------
    preserve
    if `hasw' {
        tempvar w
        quietly gen double `w' `wexp'
    }
    quietly keep if `touse'

    tempvar idv comp mcomp last tag cens endt rank y cby wbin mis evt
    if "`id'" == "" {
        quietly gen long `idv' = _n
        local idisstr 0
    }
    else {
        quietly gen `: type `id'' `idv' = `id'
        capture confirm string variable `id'
        local idisstr = (_rc == 0)
    }

    sort `idv' _t _t0
    quietly by `idv': gen byte `last' = (_n == _N)
    quietly by `idv': gen byte `tag'  = (_n == 1)

    * competing code on the last record = competing event
    * competing code on an earlier record = possible misspecification
    *   (e.g. follow-up continues after death); always shown
    * compete() takes precedence over failure(): if stset's failure()
    * also includes the competing codes (_d==1), the record is still a
    * competing event and not an event of interest (0.7.0 counted them
    * as events of interest, seen on real data)
    quietly gen byte `comp'  = 0
    quietly gen byte `mcomp' = 0
    tempvar anyc
    quietly gen byte `anyc' = 0
    if "`compete'" != "" {
        foreach c of numlist `compete' {
            quietly replace `anyc' = 1 if `fvar' == `c'
        }
        quietly replace `comp'  = 1 if `anyc' & `last'
        quietly replace `mcomp' = 1 if `anyc' & !`last'
        quietly count if `anyc' & _d == 1
        if r(N) > 0 {
            di as txt "(note: `r(N)' record(s) with a compete() code are " ///
                "failures in {bf:stset}; shown as competing events, not " ///
                "as events of interest)"
        }
    }
    quietly count if `mcomp'
    local nmcomp = r(N)
    if `nmcomp' > 0 {
        di as txt "(note: `nmcomp' record(s) with a compete() code " ///
            "before the end of follow-up)"
    }

    quietly gen byte `cens' = `last' & _d == 0 & `comp' == 0
    quietly gen byte `evt'  = _d == 1 & !`anyc'
    quietly by `idv': egen double `endt' = max(_t)

    * ---------------------------------------------------------------
    * 4. vertical order of subjects
    * ---------------------------------------------------------------
    if "`sortby'" == "" local keys `endt'
    else                local keys `sortby'
    local gkeys
    foreach k of local keys {
        if "`descending'" != "" local gkeys `gkeys' -`k'
        else                    local gkeys `gkeys' `k'
    }
    * subject-level keys are taken from each subject's first record
    quietly gen long `rank' = .
    gsort -`tag' `gkeys' `idv'
    quietly replace `rank' = _n if `tag'
    sort `idv' `rank'
    quietly by `idv': replace `rank' = `rank'[1]
    quietly gen double `y' = `rank'
    quietly count if `tag'
    local nsub = r(N)

    * ---------------------------------------------------------------
    * 5. colour-coding variable
    * ---------------------------------------------------------------
    local levels
    local nmisscby 0
    if "`colorby'" != "" {
        capture confirm string variable `colorby'
        if _rc == 0 {
            quietly encode `colorby', gen(`cby')
        }
        else {
            capture assert `colorby' == int(`colorby') if !missing(`colorby')
            if _rc {
                di as err "colorby() must be a categorical variable " ///
                    "(integer codes or string)"
                di as err "  tip: {bf:egen newvar = group(`colorby')}"
                exit 459
            }
            quietly gen long `cby' = `colorby'
            local vl : value label `colorby'
            if "`vl'" != "" label values `cby' `vl'
        }
        quietly levelsof `cby' if !missing(`cby'), local(levels)
        local nlev : word count `levels'
        if `nlev' == 0 {
            di as err "colorby(): `colorby' is missing on all records"
            exit 2000
        }
        if `nlev' > `ncol' {
            di as txt "(note: `nlev' levels of `colorby' but `ncol' " ///
                "colours; colours repeat)"
        }
        quietly count if missing(`cby')
        local nmisscby = r(N)
    }

    * ---------------------------------------------------------------
    * 6. weight classes
    * ---------------------------------------------------------------
    local nwb 1
    local nmissw 0
    local cuts
    if `hasw' {
        quietly count if missing(`w')
        local nmissw = r(N)
        quietly su `w', meanonly
        if r(N) == 0 {
            di as err "weights are missing on all records"
            exit 2000
        }
        local wmin = r(min)
        local wmax = r(max)
        if "`wcuts'" != "" {
            local cuts `wcuts'
            local nwb : word count `cuts'
            local ++nwb
            if `nwb' > 9 {
                di as err "wcuts(): at most 8 cutpoints"
                exit 198
            }
        }
        else if `wmax' > `wmin' & `wbins' > 1 {
            local nwb = `wbins'
            forvalues b = 1/`=`nwb'-1' {
                local cuts `cuts' `=`wmin' + `b'*(`wmax'-`wmin')/`nwb''
            }
        }
        if "`cuts'" != "" {
            local cutsc : subinstr local cuts " " ",", all
            quietly gen byte `wbin' = irecode(`w', `cutsc') + 1 if !missing(`w')
        }
        else quietly gen byte `wbin' = 1 if !missing(`w')

        * widths: top width ~60% of the row spacing, 0.8-4pt; plot region
        * taken as ~55% of the graph height (ysize(), default 4in).
        * Stata 16+: unit suffix pt. Before Stata 16 a plain number is a
        * relative size, 100 = min(xsize, ysize) (default 5.5 x 4 in), so
        * the same point widths are converted. relwidth (undocumented)
        * forces the old path for testing.
        if "`wstyle'" == "width" {
            local usept = (c(stata_version) >= 16 & "`relwidth'" == "")
            local ys 4
            local xs 5.5
            if regexm(`"`options'"', "ysize\(([0-9.]+)\)") local ys = regexs(1)
            if regexm(`"`options'"', "xsize\(([0-9.]+)\)") local xs = regexs(1)
            local rowpt = `ys' * 72 * 0.55 / `nsub'
            local minpt = min(`xs', `ys') * 72
            if `wmaxw' < 0 local wmaxw = max(`wminw' + 0.5, min(4, max(0.8, 0.6 * `rowpt')))
            if `wminw' <= 0 | `wmaxw' <= `wminw' {
                di as err "wminw() and wmaxw() must satisfy 0 < wminw() < wmaxw()"
                exit 198
            }
        }

        * legend text and line attributes per class
        local smin = strtrim(string(`wmin', "`wformat'"))
        local smax = strtrim(string(`wmax', "`wformat'"))
        forvalues b = 1/`nwb' {
            if `b' > 1 {
                local lo_ : word `=`b'-1' of `cuts'
                local slo = strtrim(string(`lo_', "`wformat'"))
            }
            if `b' < `nwb' {
                local hi_ : word `b' of `cuts'
                local shi = strtrim(string(`hi_', "`wformat'"))
            }
            if `nwb' == 1 {
                if `wmax' > `wmin' local wl`b' "w `smin'-`smax'"
                else               local wl`b' "w = `smin'"
            }
            else if "`wcuts'" != "" {
                if      `b' == 1      local wl`b' "w ≤ `shi'"
                else if `b' == `nwb'  local wl`b' "w > `slo'"
                else                  local wl`b' "w `slo'-`shi'"
            }
            else {
                if      `b' == 1      local wl`b' "w `smin'-`shi'"
                else if `b' == `nwb'  local wl`b' "w `slo'-`smax'"
                else                  local wl`b' "w `slo'-`shi'"
            }
            * widths linear in points from wminw() to wmaxw()
            * (named widths grow unevenly: see handoff, v0.4.0)
            if "`wstyle'" == "width" {
                if `nwb' == 1 local wpt = min(1.2, `wmaxw')
                else local wpt = `wminw' + (`b' - 1) * (`wmaxw' - `wminw') / (`nwb' - 1)
                if `usept' local ww`b' = strtrim(string(`wpt', "%5.2f")) + "pt"
                else       local ww`b' = strtrim(string(100 * `wpt' / `minpt', "%6.3f"))
            }
            * intensities 0.30 (palest) to 1.30 (darker than the base colour)
            if `nwb' == 1 local wi`b' 1
            else local wi`b' = strtrim(string(0.3 + (`b' - 1) / (`nwb' - 1), "%4.2f"))
        }
    }

    * ---------------------------------------------------------------
    * 7. build the plot
    * ---------------------------------------------------------------
    local plots
    local order
    local np 0
    local seg pcspike `y' _t0 `y' _t
    quietly gen double `mis' = .
    local dummy pcspike `mis' `mis' `mis' `mis' in 1

    * segments: one plot per colorby level x weight class.
    * marker groups (mg*): one per colorby level (+ missing), so markers
    * take the colorby colour of the record ending at them, never the
    * weight width or intensity (pale markers were unreadable in 0.3.0)
    local ng 0
    if "`colorby'" == "" local levlist 1
    else                 local levlist `levels'
    local i 0
    foreach l of local levlist {
        local ++i
        if "`colorby'" == "" {
            local col `lcolor'
            local lc 1
        }
        else {
            local col : word `=mod(`i' - 1, `ncol') + 1' of `colors'
            local lc `cby' == `l'
        }
        local ++ng
        local gc`ng' `lc'
        local gk`ng' `col'
        if !`hasw' {
            local ++np
            local plots `plots' (`seg' if `lc', lcolor(`col')         ///
                lpattern(`lpattern') lwidth(`lwidth') `lineopts')
            if "`colorby'" != "" {
                local lab : label (`cby') `l'
                local order `order' `np' `"`lab'"'
            }
        }
        else {
            forvalues b = 1/`nwb' {
                quietly count if `wbin' == `b' & `lc'
                if r(N) == 0 continue
                if "`wstyle'" == "width" {
                    local att lcolor(`col') lwidth(`ww`b'')
                }
                else {
                    local att lcolor("`col'*`wi`b''") lwidth(`lwidth')
                }
                local ++np
                local plots `plots' (`seg' if `wbin' == `b' & `lc',   ///
                    `att' lpattern(`lpattern') `lineopts')
            }
            quietly count if missing(`wbin') & `lc'
            if r(N) > 0 {
                local ++np
                local plots `plots' (`seg' if missing(`wbin') & `lc', ///
                    lcolor(`col') lwidth(thin) lpattern(dot) `lineopts')
            }
        }
    }
    if `nmisscby' > 0 {
        local ++np
        local ++ng
        local gc`ng' missing(`cby')
        local gk`ng' fg
        local plots `plots' (`seg' if missing(`cby'),                ///
            lpattern(dot) lwidth(`lwidth') lcolor(fg) `lineopts')
        if !`hasw' local order `order' `np' `"`misslabel'"'
    }

    * legend keys with weights: dummy plots without data
    if `hasw' {
        if "`colorby'" != "" {
            local i 0
            foreach l of local levels {
                local ++i
                local col : word `=mod(`i' - 1, `ncol') + 1' of `colors'
                local ++np
                local plots `plots' (`dummy', lcolor(`col') lwidth(medthick))
                local lab : label (`cby') `l'
                local order `order' `np' `"`lab'"'
            }
            if `nmisscby' > 0 {
                local ++np
                local plots `plots' (`dummy', lcolor(fg) lpattern(dot) lwidth(medthick))
                local order `order' `np' `"`misslabel'"'
            }
            local kcol = cond("`wstyle'" == "intensity", "navy", "fg")
        }
        else local kcol `lcolor'
        forvalues b = 1/`nwb' {
            if "`wstyle'" == "width" local att lcolor(`kcol') lwidth(`ww`b'')
            else local att lcolor("`kcol'*`wi`b''") lwidth(`lwidth')
            local ++np
            local plots `plots' (`dummy', `att' lpattern(`lpattern'))
            local order `order' `np' `"`wl`b''"'
        }
        if `nmissw' > 0 {
            local ++np
            local plots `plots' (`dummy', lcolor(`kcol') lwidth(thin) lpattern(dot))
            local order `order' `np' `"`wmisslabel'"'
        }
    }

    * --- markers (drawn after the lines, so on top) ---
    * one scatter per marker type and colour group; with several groups
    * the legend key is a dummy marker in the foreground colour
    quietly count if `evt'
    local nfail = r(N)
    quietly count if `comp'
    local ncomp = r(N)
    quietly count if `cens'
    local ncens = r(N)

    local types
    if "`entry'" != ""     local types `types' entry
    local types `types' event comp mcomp
    if "`nocensor'" == ""  local types `types' cens

    local tc_entry  `tag'
    local tx_entry  _t0
    local ts_entry  msymbol(pipe)
    local to_entry  `"`entryopts'"'
    local tl_entry  `"`entrylabel'"'
    local tc_event  `evt'
    local tx_event  _t
    local ts_event  msymbol(O)
    local to_event  `"`eventopts'"'
    local tl_event  `"`eventlabel'"'
    local tc_comp   `comp'
    local tx_comp   _t
    local ts_comp   msymbol(T)
    local to_comp   `"`competeopts'"'
    local tl_comp   `"`competelabel'"'
    local tc_mcomp  `mcomp'
    local tx_mcomp  _t
    local ts_mcomp  msymbol(D)
    local to_mcomp  `"`midcompeteopts'"'
    local tl_mcomp  `"`midcompetelabel'"'
    local tc_cens   `cens'
    local tx_cens   _t
    local ts_cens   msymbol(Oh)
    local to_cens   `"`censopts'"'
    local tl_cens   `"`censlabel'"'

    local mord
    foreach t of local types {
        quietly count if `tc_`t''
        if r(N) == 0 continue
        local first
        forvalues g = 1/`ng' {
            quietly count if (`tc_`t'') & (`gc`g'')
            if r(N) == 0 continue
            local ++np
            if "`first'" == "" local first `np'
            local plots `plots' (scatter `y' `tx_`t'' if (`tc_`t'') & (`gc`g''), ///
                `ts_`t'' mcolor("`gk`g''") msize(`msize') `to_`t'')
        }
        if `ng' > 1 {
            local ++np
            local plots `plots' (scatter `mis' `mis' in 1,           ///
                `ts_`t'' mcolor(fg) msize(`msize') `to_`t'')
            local first `np'
        }
        local mord `mord' `first' `"`tl_`t''"'
    }
    local order `mord' `order'

    * --- y axis ---
    if "`idlabel'" != "" {
        tempname yl
        local vlid
        if "`id'" != "" & !`idisstr' local vlid : value label `id'
        * subjects' first records end up as the last nsub obs, in rank order
        sort `tag' `rank'
        local off = _N - `nsub'
        forvalues r = 1/`nsub' {
            local o = `off' + `r'
            if `idisstr' local idval = `idv'[`o']
            else if "`vlid'" != "" local idval : label `vlid' `=`idv'[`o']'
            else local idval = strtrim(string(`idv'[`o'], "%12.0g"))
            label define `yl' `r' `"`idval'"', modify
        }
        label values `y' `yl'
        * label size shrinks with the number of subjects (overlap at 40
        * subjects with vsmall in 0.3.0); idlsize() overrides
        if "`idlsize'" == "" {
            if      `nsub' <= 20 local idlsize vsmall
            else if `nsub' <= 40 local idlsize tiny
            else if `nsub' <= 80 local idlsize half_tiny
            else                 local idlsize third_tiny
        }
        local ylab ylabel(1(1)`nsub', valuelabel angle(0) ///
            labsize(`idlsize') nogrid)
        if `nsub' > 80 & "`idlsize'" == "third_tiny" {
            di as txt "(note: idlabel with `nsub' subjects; " ///
                "labels may overlap)"
        }
    }
    else {
        if "`idlsize'" != "" {
            di as err "idlsize() requires idlabel"
            exit 198
        }
        local ylab ylabel(none)
    }

    local lo = 0.5
    local hi = `nsub' + 0.5

    * one-column legend when needed, unless the user gives cols()/rows():
    * legend at the side (position 2-4, 8-10), inside (ring(0)), or two
    * columns wider than the graph. Width estimate from the v0.5.0 PNGs
    * (size(small), 5.5 x 4 in): key+gap ~0.67 in per column, ~0.05 in
    * per character, ~0.3 in margins; text scales with min(xsize, ysize)/4.
    * Items fill row-wise, so odd items are column 1, even items column 2.
    local legcols
    local lu `"`legend'"'
    if !ustrregexm(`"`lu'"', "\b(cols|rows)\(") & !ustrregexm(`"`lu'"', "\boff\b") {
        local onecol 0
        if ustrregexm(`"`lu'"', "\bpos[a-z]*\(\s*([0-9]+)\s*\)") {
            local lp = ustrregexs(1)
            if inlist(`lp', 2, 3, 4, 8, 9, 10) local onecol 1
        }
        if ustrregexm(`"`lu'"', "\bring\(\s*0\s*\)") local onecol 1
        if !`onecol' {
            local lxs 5.5
            local lys 4
            if ustrregexm(`"`options'"', "\bxsize\(\s*([0-9.]+)\s*\)") local lxs = ustrregexs(1)
            if ustrregexm(`"`options'"', "\bysize\(\s*([0-9.]+)\s*\)") local lys = ustrregexs(1)
            local mc1 0
            local mc2 0
            local k 0
            * order() is pairs of plot number and label text (a label
            * may itself be a number, e.g. unlabelled colorby levels)
            local istxt 0
            foreach tok of local order {
                if `istxt' {
                    local ++k
                    local c = 2 - mod(`k', 2)
                    local mc`c' = max(`mc`c'', ustrlen(`"`tok'"'))
                }
                local istxt = !`istxt'
            }
            local need = min(`lxs', `lys') / 4 * (2 * 0.67 + (`mc1' + `mc2') * 0.05 + 0.3)
            if `k' > 1 & `need' > `lxs' local onecol 1
        }
        if `onecol' local legcols cols(1)
    }
    local legopt legend(order(`order') size(small) `legcols')
    if `"`legend'"' != "" local legopt `legopt' legend(`legend')

    * ---------------------------------------------------------------
    * 8. draw
    * ---------------------------------------------------------------
    twoway `plots',                                                  ///
        `ylab' yscale(range(`lo' `hi')) ytitle("Subject")            ///
        xtitle("Analysis time")                                      ///
        `legopt'                                                     ///
        `options'

    * ---------------------------------------------------------------
    * 9. returns
    * ---------------------------------------------------------------
    return scalar N_sub         = `nsub'
    return scalar N_fail        = `nfail'
    return scalar N_compete     = `ncomp'
    return scalar N_compete_mid = `nmcomp'
    return scalar N_cens        = `ncens'
    if "`colorby'" != "" return local levels `"`levels'"'
    if `hasw' {
        return local wcuts  `"`cuts'"'
        return local wstyle `wstyle'
        return local wexp   `"`wexp'"'
    }
    return local legcols `"`legcols'"'
end
