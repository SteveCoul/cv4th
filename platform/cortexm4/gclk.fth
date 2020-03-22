
hex
40001C00 constant GCLK
80 constant PCHCTRL0
 4 constant EIC_GCLK_ID
decimal

: eic-gclk
  [ hex ] 42 [ decimal ] GCLK PCHCTRL0 + EIC_GCLK_ID cells + s>d d32!
;

