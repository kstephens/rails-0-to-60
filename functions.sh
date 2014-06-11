script_cmd_line="$0 $*"

source "$progdir/termcode.sh"

vm_ip="$(ifconfig -a | fgrep 'inet addr:192.168.' | cut -d: -f 2 | cut -d' ' -f 1)"
vm_ip="${remote_ip:-192.168.56.101}" # default vbox host-only IP
hostname="${hostname:-$vm_ip}"

prompt() {
  if [ -n "$prompt" ]
  then
    show_notes
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
  comment="$*"
  comment_c="${_vt_YELLOW}${_vt_UNDER}$comment${_vt_NORM}"
  show_comment
}
show_comment() {
  (set +xe; echo ""; echo " # ${_vt_YELLOW}${_dryrun}${_vt_NORM}$comment_c") 2>/dev/null
  (set +xe; show_notes) 2>/dev/null
}

set_cmd() {
  cmd="$ $*"
  cmd_c="${_vt_HI_GREEN}${cmd}${_vt_NORM}"
}
set_cmd "$script_cmd_line"

show_cmd() {
  set_cmd "$*"
  if [ "$1" != 'comment' ]
  then
    (set +xe; echo "${_dryrun_c}${cmd_c}") 2>/dev/null
    (set +xe; show_notes) 2>/dev/null
  fi
}

notes() {
  notes="${*:-$(cat -)}"
}
show_notes() {
  if [ -n "$NOTES_TTY" -a -n "$prompt" ]
  then
    cat <<EOF >"$NOTES_TTY"
${_vt_CLRSCR}${_vt_HOME}
  ===================================================

  comment | ${comment_c}
      cmd | ${cmd_c}

$notes

  ===================================================

EOF
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
    debian_name='squeeze'
  ;;
  *Darwin*)
    osx=1
    comment 'Detected OS X.'
  ;;
  *)
    echo "Cannot continue"; exit 1
  ;;
esac

case "$(cat /etc/issue 2>/dev/null)"
in
  *Ubuntu*12.04*)
    ubuntu=12.04
    debian=
    debian_name='precise'
    comment 'Detected Ubuntu 12.04 (precise pangolin)'
  ;;
esac

os_cmd() {
  show_cmd "$@"
  prompt "OK?" "y" &&
  $dryrun eval "$@"
  last_pid=$!
}

debian() {
  if [ -n "$debian" -o -n "$ubuntu" ]
  then
    os_cmd "$@"
  fi
}

debian6() {
  if [ "$debian" = 6 ]
  then
    os_cmd "$@"
  fi
}

ubuntu() {
  if [ "$ubuntu" ]
  then
    os_cmd "$@"
  fi
}

ubuntu1204() {
  if [ "$ubuntu" = 12.04 ]
  then
    os_cmd "$@"
  fi
}

osx() {
  if [ -n "$osx" ]
  then
    os_cmd "$@"
  fi
}

w3m="${w3m:-w3m}"
browse() {
  local url="$1" localhost_url
  # localhost_url="${url/$vm_ip/localhost}"
  echo -n "${_vt_INV}${_vt_LOW}"
  echo "  localhost_url=$localhost_url"
  echo "| $url |"
  echo "+----------------------------------------------------------------------"
  echo "|${_vt_NORM} "
  ${w3m} ${w3m_opts} -graph -o color=true -o display_link=true "$localhost_url" 2>/dev/null | sed -e "s@^@${_vt_INV}|${_vt_NORM}  @"
  echo -n "${_vt_INV}${_vt_LOW}"
  echo "-----------------------------------------------------------------------"
  echo -n "${_vt_NORM}"
}

server_pid=
stop_server() {
  if [ -n "$server_pid" ]
  then
    comment Stop server.
    all "kill -9 $server_pid"
  fi
  server_pid=
}

start_server() {
  comment Start rails server.
  all "$* > server.log 2>&1&"; sleep 2
  server_pid=$last_pid
  comment Server pid is $server_pid.
  echo ""
}

gem_check() {
  gem which "$@" >/dev/null 2>&1
}

trap true SIGINT
trap 'prompt=; stop_server' EXIT

