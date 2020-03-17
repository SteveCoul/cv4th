
only forth definitions
forth-wordlist ext-wordlist internals 3 set-order definitions

S" AS3935_ADDRESS" environment? 0= [IF]
	cr .( AS3935_ADDRESS not in environment ) abort [THEN]
constant AS3935_ADDRESS

[UNDEFINED] Wire.begin [IF]
	cr .( No Wire implementation found ) abort
[THEN]

: as3935!
  AS3935_ADDRESS Wire.beginTransmission
  Wire.Write drop
  Wire.Write drop
  true Wire.endTransmission
;

: as3935@
  AS3935_ADDRESS Wire.beginTransmission
  Wire.Write drop
  false Wire.endTransmission
  AS3935_ADDRESS 1 true Wire.requestFrom if
    Wire.read exit
  then
  -1
;

: as3935-read: 	( address shift mask "cc" -- )
  create
	c,
	c,
	c,
  does>
	dup c@ swap		
	1+ dup c@ swap	
	1+ c@ 		( mask shift addr -- )
	as3935@ swap rshift and
;

: as3935-write:	( address shift mask "cc" -- )
  create
    c,
    c,
    c,
  does>		( new-value ^ -- )
	>r
	r@ 2 + c@ as3935@		( newdat regval -- : R: paramblock -- )
    r@ c@ 					( newdat regval mskv -- : R: paramblock -- )
	r@ 1+ c@ lshift			( newdat regval mask -- : R: paramblock -- )
	invert
	and						( newdat olddat -- : R: paramblock -- )
	swap r@ c@ and
	r@ 1+ c@ lshift		
	or
	r> 2 + c@ as3935!   
;

ext-wordlist set-current

0 0 1   as3935-read: as3935-pwd>
0 1 31  as3935-read: as3935-afe_gb>
1 0 15  as3935-read: as3935-wdth>
1 4 7   as3935-read: as3935-nf_lev>
2 0 15  as3935-read: as3935-srej>
2 4 3   as3935-read: as3935-min_num_ligh>
2 6 1	as3935-read: as3935-cl_stat>
3 0 15  as3935-read: as3935-int>
3 5 1   as3935-read: as3935-mask_dist>
3 6 3   as3935-read: as3935-lco_div>
4 0 255 as3935-read: as3935-s_sig_l>
5 0 255 as3935-read: as3935-s_sig_m>
6 0 31  as3935-read: as3935-s_sig_mm>
7 0 63  as3935-read: as3935-distance>
8 0 15	as3935-read: as3935-tun_cap>
8 5 1 	as3935-read: as3935-disp_trco>
8 6 1 	as3935-read: as3935-disp_srco>
8 7 1 	as3935-read: as3935-disp_lco>

0 0 1   as3935-write: >as3935-pwd
0 1 31  as3935-write: >as3935-afe_gb
1 0 15  as3935-write: >as3935-wdth
1 4 7   as3935-write: >as3935-nf_lev
2 0 15  as3935-write: >as3935-srej
2 4 3   as3935-write: >as3935-min_num_ligh
2 6 1	as3935-write: >as3935-cl_stat
3 0 15  as3935-write: >as3935-int
3 5 1   as3935-write: >as3935-mask_dist
3 6 3   as3935-write: >as3935-lco_div
4 0 255 as3935-write: >as3935-s_sig_l
5 0 255 as3935-write: >as3935-s_sig_m
6 0 31  as3935-write: >as3935-s_sig_mm
7 0 63  as3935-write: >as3935-distance
8 0 15	as3935-write: >as3935-tun_cap
8 5 1 	as3935-write: >as3935-disp_trco
8 6 1 	as3935-write: >as3935-disp_srco
8 7 1 	as3935-write: >as3935-disp_lco

: as3935-preset_default
  [ hex ] 96 3C [ decimal ] as3935! 
;

: as3935-calib_tco
  [ hex ] 96 3D [ decimal ] as3935! 
;

: as3935-dump
  base @ >r
  hex

  cr 9 0 ?do i as3935@ 0 <# # # #> type space loop

  as3935-pwd> 			cr ." PWD          " .
  as3935-afe_gb> 		cr ." AFE_GB       " .
  as3935-wdth> 			cr ." WDTH         " .
  as3935-nf_lev> 		cr ." NF_LEV       " .
  as3935-srej> 			cr ." SREJ         " .
  as3935-min_num_ligh> 	cr ." MIN_NUM_LIGH " .
  as3935-cl_stat> 		cr ." CL_STAT      " .
  as3935-int> 			cr ." INT          " .
  as3935-mask_dist> 	cr ." MASK_DIST    " .
  as3935-lco_div> 		cr ." LCO_DIV      " .
  as3935-s_sig_l> 		cr ." S_SIG_L      " .
  as3935-s_sig_m> 		cr ." S_SIG_M      " .
  as3935-s_sig_mm> 		cr ." S_SIG_MM     " .
  as3935-distance> 		cr ." DISTANCE     " .
  as3935-tun_cap> 		cr ." TUN_CAP      " .
  as3935-disp_trco> 	cr ." DISP_TRCO    " .
  as3935-disp_srco> 	cr ." DISP_SRCO    " .
  as3935-disp_lco> 		cr ." DISP_LCO     " .

  r> base !
;

[THEN]

only forth definitions

