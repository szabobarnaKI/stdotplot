* stdotplot_test.do   18nov2026   test of stdotplot v0.8.0 (compete() codes that are also stset failures)
* Needs stdotplot.ado (+ stdotplot.sthlp) and ghlog.ado on the adopath.
* Puts the log and the graphs (PNG) in claude_communication/logs/stdotplot/

* ---------------- EDIT THIS LINE ----------------
local D "C:\Barna\PhD/ado development/stdotplot"
* ------------------------------------------------

clear all
discard
cd "`D'"
capture log close tlog
log using "stdotplot_test.log", text replace name(tlog)
di "stdotplot_test started `c(current_date)' `c(current_time)'"
which stdotplot
set more off
set scheme s2color

local repo szabobarnaKI/claude_communication
local pngs

* ---------------------------------------------------------------
* Simulated data: 40 subjects, delayed entry for some, recurrent
* events (status 1), death as competing event (status 2), censoring,
* and a time-varying categorical variable (dose) via stsplit
* ---------------------------------------------------------------
set seed 20261118
set obs 40
gen long id = _n
gen double t0e   = cond(runiform() < .25, .8*runiform(), 0)
gen double tcens = t0e + 1 + 4*runiform()
gen double tdth  = t0e + rexponential(6)
gen double tend  = min(tcens, tdth)
gen byte endst   = cond(tdth < tcens, 2, 0)
tempfile base
save `base'

expand 10
bysort id: gen double t = t0e + sum(rexponential(1.3))
keep if t < tend
gen byte status = 1
keep id t0e t status
append using `base'
replace t      = tend  if missing(status)
replace status = endst if missing(status)
keep id t0e t status
sort id t
by id: gen double t0 = cond(_n == 1, t0e, t[_n-1])

* a gap in follow-up for subject 3 (second record starts later)
by id: replace t0 = t0 + .3*(t - t0) if id == 3 & _n == 2

* misspecification: a "death" (status 2) on a subject's first record,
* with follow-up and records continuing after it
by id: gen int _nrec = _N
quietly su id if _nrec >= 3, meanonly
local badid = r(min)
by id: replace status = 2 if id == `badid' & _n == 1
di "subject with death before end of follow-up: id `badid'"
drop _nrec

label define stl 0 "censored" 1 "infection" 2 "death"
label values status stl
tab status

stset t, id(id) failure(status == 1) time0(t0) exit(time .)
stsplit period, at(1(1)6)
gen byte dose = mod(period + id, 3)
label define dl 0 "Low" 1 "Medium" 2 "High"
label values dose dl
decode dose, gen(dosestr)
* split-record times, for re-stsetting below
gen double tstart = _t0
gen double tstop  = _t
* time-varying weights (IPW-like), some missing
gen double ipw = exp(rnormal(0, .5))
replace ipw = . if runiform() < .05
su ipw
tab status, missing
stdescribe

* expected counts
quietly count if _d == 1
local exp_fail = r(N)
bysort id (_t): gen byte _lastrec = _n == _N
quietly count if _lastrec & status == 2 & _d == 0
local exp_comp = r(N)
quietly count if _lastrec & _d == 0 & status != 2
local exp_cens = r(N)
quietly count if !_lastrec & _d == 0 & status == 2
local exp_mid = r(N)
di "expected: fail `exp_fail', compete `exp_comp', censored `exp_cens', mid-FU compete `exp_mid'"

capture program drop _png
program define _png
    args name
    capture noisily graph export "`name'.png", replace width(1400)
end

* ---------------------------------------------------------------
di _n "=== T1: default (no competing) ==="
capture noisily stdotplot, name(T1, replace) title("T1 default")
di "T1 rc = " _rc
if _rc == 0 {
    return list
    _png stdotplot_T1
    local pngs `pngs' stdotplot_T1
}

di _n "=== T2: compete(2), counts checked ==="
capture noisily stdotplot, compete(2) name(T2, replace) title("T2 compete(2)")
di "T2 rc = " _rc
if _rc == 0 {
    return list
    di "N_sub 40? "      (r(N_sub) == 40)
    di "N_fail ok? "     (r(N_fail) == `exp_fail')
    di "N_compete ok? "  (r(N_compete) == `exp_comp')
    di "N_cens ok? "     (r(N_cens) == `exp_cens')
    di "N_compete_mid ok? " (r(N_compete_mid) == `exp_mid')
    _png stdotplot_T2
    local pngs `pngs' stdotplot_T2
}

di _n "=== T3: colorby(dose) ==="
capture noisily stdotplot, compete(2) colorby(dose) name(T3, replace) ///
    title("T3 colorby(dose)")
di "T3 rc = " _rc
if _rc == 0 {
    return list
    _png stdotplot_T3
    local pngs `pngs' stdotplot_T3
}

di _n "=== T4: string colorby, colors(), entry, idlabel, subset ==="
capture noisily stdotplot if id <= 15, compete(2) colorby(dosestr) ///
    colors(green orange red) entry idlabel name(T4, replace) ///
    title("T4 string colorby, entry, idlabel, id<=15")
di "T4 rc = " _rc
if _rc == 0 {
    return list
    _png stdotplot_T4
    local pngs `pngs' stdotplot_T4
}

di _n "=== T5: missing colorby values ==="
gen byte dose2 = dose
replace dose2 = . if period == 0 & mod(id, 4) == 0
label values dose2 dl
capture noisily stdotplot, compete(2) colorby(dose2) name(T5, replace) ///
    title("T5 missing colorby values")
di "T5 rc = " _rc
if _rc == 0 {
    _png stdotplot_T5
    local pngs `pngs' stdotplot_T5
}

di _n "=== T6: sortby(t0e) descending, marker/legend/twoway options ==="
capture noisily stdotplot, compete(2) sortby(t0e) descending ///
    eventopts(mcolor(cranberry)) competeopts(mcolor(navy) msize(medium)) ///
    eventlabel("Infection") competelabel("Death") ///
    legend(rows(1) position(6)) xtitle("Years since randomisation") ///
    name(T6, replace) title("T6 sortby/descending/options")
di "T6 rc = " _rc
if _rc == 0 {
    _png stdotplot_T6
    local pngs `pngs' stdotplot_T6
}

di _n "=== T7: nocensor, lpattern(solid) lwidth(thin) ==="
capture noisily stdotplot in 1/60, compete(2) nocensor lpattern(solid) ///
    lwidth(thin) name(T7, replace) title("T7 nocensor, in 1/60")
di "T7 rc = " _rc
if _rc == 0 {
    _png stdotplot_T7
    local pngs `pngs' stdotplot_T7
}


di _n "=== T9: death before end of FU on id `badid' (always shown) ==="
capture noisily stdotplot, compete(2) idlabel name(T9, replace) ///
    title("T9 mid-FU competing event, id `badid'")
di "T9 rc = " _rc
if _rc == 0 {
    return list
    _png stdotplot_T9
    local pngs `pngs' stdotplot_T9
}

di _n "=== T27: compete codes also in stset failure() (expect same counts as T2 + note) ==="
preserve
stset tstop, id(id) failure(status == 1 2) time0(tstart) exit(time .)
capture noisily stdotplot, compete(2) name(T27, replace) ///
    title("T27 failure(status==1 2), compete(2)")
di "T27 rc = " _rc
if _rc == 0 {
    return list
    di "N_fail ok? "        (r(N_fail) == `exp_fail')
    di "N_compete ok? "     (r(N_compete) == `exp_comp')
    di "N_cens ok? "        (r(N_cens) == `exp_cens')
    di "N_compete_mid ok? " (r(N_compete_mid) == `exp_mid')
    _png stdotplot_T27
    local pngs `pngs' stdotplot_T27
}
restore

* time-varying weights: stset refuses them within id(), so stset
* without id() and pass the identifier to stdotplot with id().
* 0.3.0 log: stset [pw=ipw] drops the 9 missing-weight records (_st==0),
* so here stset WITHOUT weights and give [pw=ipw] to stdotplot; the
* missing-weight records are then drawn dotted ("Weight missing")
preserve
stset tstop, failure(status == 1) time0(tstart)

di _n "=== T10: [pw=ipw], id(id), wstyle(width) default, 5 bins ==="
capture noisily stdotplot [pw=ipw], id(id) compete(2) name(T10, replace) ///
    title("T10 pweight as width")
di "T10 rc = " _rc
if _rc == 0 {
    return list
    di "N_sub 40? "      (r(N_sub) == 40)
    di "N_fail ok? "     (r(N_fail) == `exp_fail')
    di "N_compete ok? "  (r(N_compete) == `exp_comp')
    di "N_cens ok? "     (r(N_cens) == `exp_cens')
    _png stdotplot_T10
    local pngs `pngs' stdotplot_T10
}

di _n "=== T11: colorby(dose), wstyle(intensity), wcuts(0.5 1 2) ==="
capture noisily stdotplot [pw=ipw], id(id) compete(2) colorby(dose) ///
    wstyle(intensity) wcuts(0.5 1 2) wformat(%3.1f) name(T11, replace) ///
    title("T11 colorby + pweight as intensity")
di "T11 rc = " _rc
if _rc == 0 {
    return list
    _png stdotplot_T11
    local pngs `pngs' stdotplot_T11
}

di _n "=== T12: colorby + width, 3 bins, subset with idlabel ==="
capture noisily stdotplot [pw=ipw] if id <= 15, id(id) compete(2) ///
    colorby(dose) wbins(3) idlabel entry name(T12, replace) ///
    title("T12 colorby + width, id<=15")
di "T12 rc = " _rc
if _rc == 0 {
    _png stdotplot_T12
    local pngs `pngs' stdotplot_T12
}

di _n "=== T17: wbins(9) width (top classes vvthin..vvthick) ==="
capture noisily stdotplot [pw=ipw], id(id) compete(2) wbins(9) ///
    name(T17, replace) title("T17 wbins(9) width")
di "T17 rc = " _rc
if _rc == 0 {
    _png stdotplot_T17
    local pngs `pngs' stdotplot_T17
}

di _n "=== T19: width, wminw(0.5) wmaxw(6), id<=15 ==="
capture noisily stdotplot [pw=ipw] if id <= 15, id(id) compete(2) ///
    wminw(0.5) wmaxw(6) idlabel name(T19, replace) ///
    title("T19 wminw(0.5) wmaxw(6)")
di "T19 rc = " _rc
if _rc == 0 {
    _png stdotplot_T19
    local pngs `pngs' stdotplot_T19
}

di _n "=== T20: pre-Stata-16 path forced (relwidth), compare with T10 ==="
* in Stata 16+ a plain size has scheme-dependent units, so this may
* differ from T10 even if the Stata 15 path is correct
capture noisily stdotplot [pw=ipw], id(id) compete(2) relwidth ///
    name(T20, replace) title("T20 relative widths (pre-16 path)")
di "T20 rc = " _rc
if _rc == 0 {
    _png stdotplot_T20
    local pngs `pngs' stdotplot_T20
}

di _n "=== T21: relwidth, xsize(4) ysize(6), id<=15 ==="
capture noisily stdotplot [pw=ipw] if id <= 15, id(id) compete(2) relwidth ///
    xsize(4) ysize(6) name(T21, replace) title("T21 relwidth, 4 x 6 in")
di "T21 rc = " _rc
if _rc == 0 {
    _png stdotplot_T21
    local pngs `pngs' stdotplot_T21
}

di _n "=== T22: legend(position(3)) -> one column (expect cols(1)) ==="
capture noisily stdotplot [pw=ipw], id(id) compete(2) colorby(dose) ///
    legend(position(3)) name(T22, replace) title("T22 legend right")
di "T22 rc = " _rc
if _rc == 0 {
    di "legcols: [" r(legcols) "]"
    _png stdotplot_T22
    local pngs `pngs' stdotplot_T22
}

di _n "=== T23: narrow graph xsize(4) ysize(6) -> one column (expect cols(1)) ==="
capture noisily stdotplot [pw=ipw] if id <= 15, id(id) compete(2) ///
    xsize(4) ysize(6) name(T23, replace) title("T23 narrow, auto 1 col")
di "T23 rc = " _rc
if _rc == 0 {
    di "legcols: [" r(legcols) "]"
    _png stdotplot_T23
    local pngs `pngs' stdotplot_T23
}

di _n "=== T24: position(3) with cols(2) kept (expect empty legcols) ==="
capture noisily stdotplot, id(id) compete(2) legend(position(3) cols(2)) ///
    name(T24, replace) title("T24 right, cols(2) kept")
di "T24 rc = " _rc
if _rc == 0 {
    di "legcols: [" r(legcols) "]"
    _png stdotplot_T24
    local pngs `pngs' stdotplot_T24
}

di _n "=== T25: legend inside, ring(0) pos(4) (expect cols(1)) ==="
capture noisily stdotplot, id(id) compete(2) legend(ring(0) pos(4)) ///
    name(T25, replace) title("T25 legend inside")
di "T25 rc = " _rc
if _rc == 0 {
    di "legcols: [" r(legcols) "]"
    _png stdotplot_T25
    local pngs `pngs' stdotplot_T25
}

di _n "=== T26: default 5.5 x 4 with weights (expect empty legcols) ==="
capture noisily stdotplot [pw=ipw], id(id) compete(2) name(T26, replace) ///
    title("T26 default legend")
di "T26 rc = " _rc
if _rc == 0 di "legcols: [" r(legcols) "]"

di _n "=== E9: wmaxw() < wminw() (expect rc 198) ==="
capture noisily stdotplot [pw=ipw], id(id) wminw(2) wmaxw(1)
di "E9 rc = " _rc

di _n "=== T14: id() without weights, stset has no id ==="
capture noisily stdotplot, id(id) compete(2) name(T14, replace) ///
    title("T14 id() option, stset without id")
di "T14 rc = " _rc
if _rc == 0 {
    return list
    di "N_sub 40? " (r(N_sub) == 40)
    _png stdotplot_T14
    local pngs `pngs' stdotplot_T14
}

* stset pweight: stset excludes the 9 missing-weight records, so
* N_sub may be < 40 and the counts differ from the expected ones
capture noisily stset tstop [pw=ipw], failure(status == 1) time0(tstart)
di "stset without id, time-varying pweight rc = " _rc
quietly count if _st == 0
di "records excluded by stset (missing weight): " r(N)

di _n "=== T13: stset pweight (no [pw=]) used via wstyle() ==="
capture noisily stdotplot, id(id) compete(2) wstyle(intensity) ///
    name(T13, replace) title("T13 stset pweight via wstyle()")
di "T13 rc = " _rc
if _rc == 0 {
    return list
    _png stdotplot_T13
    local pngs `pngs' stdotplot_T13
}
restore

di _n "=== T16: user marker colour overrides segment colour ==="
capture noisily stdotplot, compete(2) colorby(dose) eventopts(mcolor(red)) ///
    name(T16, replace) title("T16 eventopts(mcolor(red))")
di "T16 rc = " _rc
if _rc == 0 {
    _png stdotplot_T16
    local pngs `pngs' stdotplot_T16
}

di _n "=== T15: weights all equal (single class) ==="
gen byte one = 1
capture noisily stdotplot [pw=one], compete(2) name(T15, replace) ///
    title("T15 constant weight")
di "T15 rc = " _rc
if _rc == 0 {
    _png stdotplot_T15
    local pngs `pngs' stdotplot_T15
}

di _n "=== T18: idlabel idlsize(vsmall), ysize(8) ==="
capture noisily stdotplot, compete(2) idlabel idlsize(vsmall) ysize(8) ///
    name(T18, replace) title("T18 idlsize(vsmall) ysize(8)")
di "T18 rc = " _rc
if _rc == 0 {
    _png stdotplot_T18
    local pngs `pngs' stdotplot_T18
}

di _n "=== E8: idlsize() without idlabel (expect rc 198) ==="
capture noisily stdotplot, idlsize(tiny)
di "E8 rc = " _rc

di _n "=== E5: removed option compall (expect rc 198) ==="
capture noisily stdotplot, compete(2) compall
di "E5 rc = " _rc

di _n "=== E6: wstyle(bad) (expect rc 198) ==="
capture noisily stdotplot [pw=ipw], wstyle(bad)
di "E6 rc = " _rc

di _n "=== E7: wstyle() without any weights (expect rc 198) ==="
capture noisily stdotplot, wstyle(width)
di "E7 rc = " _rc

di _n "=== E1: non-integer colorby (expect rc 459) ==="
gen double xcont = runiform()
capture noisily stdotplot, colorby(xcont)
di "E1 rc = " _rc

di _n "=== E2: if selects nothing (expect rc 2000) ==="
capture noisily stdotplot if id > 1000
di "E2 rc = " _rc

di _n "=== E3: data not stset (expect rc 119) ==="
preserve
stset, clear
capture noisily stdotplot
di "E3 rc = " _rc
restore

di _n "=== E4: compete() without failure var (expect rc 198) ==="
preserve
* (0.3.0 log: stset with id() requires failure(), so stset without id)
stset tstop, time0(tstart)
capture noisily stdotplot, compete(2)
di "E4 rc = " _rc
restore

di _n "=== T8: single-record data without id (sysuse cancer) ==="
preserve
sysuse cancer, clear
stset studytime, failure(died)
capture noisily stdotplot, colorby(drug) name(T8, replace) ///
    title("T8 cancer, single record, colorby(drug)")
di "T8 rc = " _rc
if _rc == 0 {
    return list
    _png stdotplot_T8
    local pngs `pngs' stdotplot_T8
}
restore

di _n "=== data unchanged after calls? ==="
describe, short
stdescribe

di _n "stdotplot_test finished `c(current_date)' `c(current_time)'"
log close tlog

ghlog using "stdotplot_test.log", repo(`repo') path(logs/stdotplot/)
foreach p of local pngs {
    capture noisily ghlog using "`p'.png", repo(`repo') path(logs/stdotplot/)
}
