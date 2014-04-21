source "$progdir/termcode.sh"

prompt() {
  if [ -n "$prompt" ]
  then
    response=''
    while [ -z "$reponse" ]
    do
    echo -n "${_vt_RED} # \_ ${1} y|n|skip|quit|shell [${2}]: ${_vt_NORM}" 1>&2
    read response
    response="${response:-${2}}"
    case "$response"
    in
      [Yy]*)
        echo ""
        return 0
      ;;
      [Nn]*)
        echo "  # NO" 1>&2
        return 1
      ;;
      *sk*)
        echo "  # skipping..."  1>&2
        return 1
      ;;
      *sh*)
        echo "  # starting subshell..."  1>&2
        bash
        response=
      ;;
      *[Qq]*)
        echo "  # quit!"  1>&2
        exit 1
      ;;
      *)
        echo "  # What?" 1>&2
      ;;
    esac
    done
  else
    return 0
  fi
}

comment() {
  (set +xe; echo ""; echo " ${_vt_YELLOW}${_vt_UNDER}# ${_dryrun}$*${_vt_NORM}") 2>/dev/null
}

show_cmd() {
  if [ "$1" != 'comment' ]
  then
    (set +xe; echo "${_dryrun_c}${_vt_HI_GREEN} $ $*${_vt_NORM}") 2>/dev/null
  fi
}

ok() {
  show_cmd "$@"
  eval "$@"
  last_pid=$!
}

all() {
  show_cmd "$@"
  prompt "OK?" "y" &&
  $dryrun eval "$@"
  last_pid=$!
}

debian=
osx=
_dryrun=
_dryrun_c=
if [ -n "$dryrun" ]
then
  _dryrun="(Dry Run): "
  _dryrun_c=" # (Dry Run): "
fi

case "$(uname -a)-$(cat /etc/debian_version 2>/dev/null)"
in
  *Linux*-6*)
    debian=6
    comment 'Detected Debian 6 (squeeze)'
  ;;
  *Darwin*)
    osx=1
    comment 'Detected OS X.'
  ;;
  *)
    echo "Cannot continue"; exit 1
  ;;
esac

debian() {
  if [ -n "$debian" ]
  then
    show_cmd "$@"
    prompt "OK?" "y" &&
    $dryrun eval "$@"
    last_pid=$!
  fi
}

debian6() {
  if [ "$debian" = 6 ]
  then
    show_cmd "$@"
    prompt "OK?" "y" &&
    $dryrun eval "$@"
    last_pid=$!
  fi
}

osx() {
  if [ -n "$osx" ]
  then
    show_cmd "$@"
    prompt "OK?" "y" &&
    $dryrun eval "$@"
    last_pid=$!
  fi
}
