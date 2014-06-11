#!/bin/sh
# $Id: termcode.sh,v 1.2 2006-12-21 21:54:24 stephens Exp $
# Author: ks@kurtstephens.com 2001/02/02
# Terminal codes for shell prompts.
#

# See:
#  http://www.icewalkers.com/Linux/ManPages/console_codes-4.html
#  man console_codes
#

# See bash man page for builtin echo -e escape sequences.
#_esc="\0033"
#_bel="\0007"
#_bs="\0010"
#_cr="\0015"
#_nl="\0012"
#_esc='\e' # OS X bash doesn't appear to understand \e in most cases.
_esc=''
#_bel='\a'
_bel=''
_bs='\b'
_cr='\r'
_nl='\n'
_bsl='\\'
_begc='\[' # Begin sequence of non-printing characters.
_endc='\]' # End sequence of non-printing characters.

_csi="${_esc}["

_vt_DECSC="${_esc}7"		# Save cursor
_vt_DECRC="${_esc}8"		# Restore cursor
_vt_HOME="${_csi};H"		# Home cursor
#_vt_EOL="${_csi}70;H"           # Move to End Of Line
_vt_CLREOL="${_csi}K"		# Clear to eol
_vt_CLRSCR="${_csi}2J"          # Clear screen and home

# Font modifiers
_vt_NORM="${_csi}0m"		# Normal text.
_vt_HI="${_csi}1m"              # Bold text.
_vt_LOW="${_csi}2m"             # half-bright.
_vt_UNDER="${_csi}4m"           # Underscored text.
_vt_BLINK="${_csi}5m"           # Blinking text.
_vt_INV="${_csi}7m"		# Inverse text.

# Colors: ANSI Terminal
_vt_BLACK="${_csi}30m"
_vt_RED="${_csi}31m"
_vt_GREEN="${_csi}32m"
_vt_YELLOW="${_csi}33m"
_vt_BLUE="${_csi}34m"
_vt_MAGENTA="${_csi}35m"
_vt_CYAN="${_csi}36m"
_vt_WHITE="${_csi}37m"

_vt_LOW_RED="${_csi}2;31m"
_vt_LOW_GREEN="${_csi}2;32m"
_vt_LOW_YELLOW="${_csi}2;33m"
_vt_LOW_BLUE="${_csi}2;34m"
_vt_LOW_MAGENTA="${_csi}2;35m"
_vt_LOW_CYAN="${_csi}2;36m"
_vt_LOW_WHITE="${_csi}2;37m"

_vt_HI_RED="${_csi}1;31m"
_vt_HI_GREEN="${_csi}1;32m"
_vt_HI_YELLOW="${_csi}1;33m"
_vt_HI_BLUE="${_csi}1;34m"
_vt_HI_MAGENTA="${_csi}1;35m"
_vt_HI_CYAN="${_csi}1;36m"
_vt_HI_WHITE="${_csi}1;37m"

#_vt_INV_BLACK="${_csi}36m"
_vt_INV_BLACK="${_csi}40m"
_vt_INV_RED="${_csi}41m"
_vt_INV_GREEN="${_csi}42m"
_vt_INV_YELLOW="${_csi}43m"
_vt_INV_BLUE="${_csi}44m"
_vt_INV_MAGENTA="${_csi}45m"
_vt_INV_CYAN="${_csi}46m"
_vt_INV_WHITE="${_csi}47m"

# VT Graphics?:
_vt_GR_SET="${_esc})"
_vt_GR_CLR="${_esc}("


# XTERM titles
_xt_WINICOTIT="${_esc}]0;" # Set window and icon title
_xt_ICOTIT="${_esc}]1;"    # Set window icon title
_xt_WINTIT="${_esc}]2;"    # Set window title
_xt_ENDTIT="${_bel}"       # End title string

# Windoze Cmd Window
# This actually works!
_wt_WINICOTIT="${_xt_WINICOTIT}" # Set window and icon title.
_wt_ICOTIT="${_xt_ICOTIT}"    # Set window and icon title.
_wt_WINTIT="${_xt_WINTIT}"    # Set windowtitle.
_wt_ENDTIT="${_xt_ENDTIT}"  # End title string.


# ECMA escape sequences.
_ecma_SC="${_csi}s"       # Save cursor location.
_ecma_RC="${_csi}u"       # Restore cursor location.
_ecma_HOME="${_vt_HOME}"  # Home cursor.


__set_window_title() {
  echo -ne "${_xt_WINTIT}$*${_xt_ENDTIT}"
}

__show_colors () {
i=0
while [ $i -lt 256 ]
do
  h="`printf %x $i`"
  h="$i"
  echo -e "${_esc}[${h}mNumber $i${_vt_NORM}"
  echo -e "${_vt_HI}${_esc}[${h}mHI: Number $i${_vt_NORM}"
  echo -e "${_vt_INV}${_esc}[${h}mINV: Number $i${_vt_NORM}"
  echo -e "${_vt_HI}${_vt_INV}${_esc}[${h}mHI-INV: Number $i${_vt_NORM}"
  echo "==="
  i=`expr $i + 1`
  if [ `expr $i % 5` -eq 0 ]
  then
    echo "Hit return"
    read x
  fi
done

}

__show_gr_chars() {
  i=0
  while [ $i -lt 256 ]
  do
    c="\\$(printf %o $i)"
    printf "%d = ${_vt_GR_SET}%b${_vt_GR_CLR}" "$i" "$c"
    i=`expr $i + 1`
  done
}
