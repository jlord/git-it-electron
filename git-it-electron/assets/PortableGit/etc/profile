# To the extent possible under law, the author(s) have dedicated all 
# copyright and related and neighboring rights to this software to the 
# public domain worldwide. This software is distributed without any warranty. 
# You should have received a copy of the CC0 Public Domain Dedication along 
# with this software. 
# If not, see <http://creativecommons.org/publicdomain/zero/1.0/>. 


# System-wide profile file

# Some resources...
# Customizing Your Shell: http://www.dsl.org/cookbook/cookbook_5.html#SEC69
# Consistent BackSpace and Delete Configuration:
#   http://www.ibb.net/~anne/keyboard.html
# The Linux Documentation Project: http://www.tldp.org/
# The Linux Cookbook: http://www.tldp.org/LDP/linuxcookbook/html/
# Greg's Wiki http://mywiki.wooledge.org/

# Setup some default paths. Note that this order will allow user installed
# software to override 'system' software.
# Modifying these default path settings can be done in different ways.
# To learn more about startup files, refer to your shell's man page.

MSYS2_PATH="/usr/local/bin:/usr/bin:/bin"
MANPATH="/usr/local/man:/usr/share/man:/usr/man:/share/man:${MANPATH}"
INFOPATH="/usr/local/info:/usr/share/info:/usr/info:/share/info:${INFOPATH}"
MINGW_MOUNT_POINT=
if [ -n "$MSYSTEM" ]
then
  case "$MSYSTEM" in
    MINGW32)
      MINGW_MOUNT_POINT=/mingw32
      PATH="${MINGW_MOUNT_POINT}/bin:${MSYS2_PATH}:${PATH}"
      PKG_CONFIG_PATH="${MINGW_MOUNT_POINT}/lib/pkgconfig:${MINGW_MOUNT_POINT}/share/pkgconfig"
      ACLOCAL_PATH="${MINGW_MOUNT_POINT}/share/aclocal:/usr/share/aclocal"
      MANPATH="${MINGW_MOUNT_POINT}/share/man:${MANPATH}"
    ;;
    MINGW64)
      MINGW_MOUNT_POINT=/mingw64
      PATH="${MINGW_MOUNT_POINT}/bin:${MSYS2_PATH}:${PATH}"
      PKG_CONFIG_PATH="${MINGW_MOUNT_POINT}/lib/pkgconfig:${MINGW_MOUNT_POINT}/share/pkgconfig"
      ACLOCAL_PATH="${MINGW_MOUNT_POINT}/share/aclocal:/usr/share/aclocal"
      MANPATH="${MINGW_MOUNT_POINT}/share/man:${MANPATH}"
    ;;
    MSYS)
      PATH="${MSYS2_PATH}:/opt/bin:${PATH}"
      PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/share/pkgconfig:/lib/pkgconfig"
    ;;
    *)
      PATH="${MSYS2_PATH}:${PATH}"
    ;;
  esac
else
  PATH="${MSYS2_PATH}:${PATH}"
fi

MAYBE_FIRST_START=false
SYSCONFDIR="${SYSCONFDIR:=/etc}"

# TMP and TEMP as defined in the Windows environment must be kept
# for windows apps, even if started from msys2. However, leaving
# them set to the default Windows temporary directory or unset
# can have unexpected consequences for msys2 apps, so we define 
# our own to match GNU/Linux behaviour.
ORIGINAL_TMP=$TMP
ORIGINAL_TEMP=$TEMP
#unset TMP TEMP
#tmp=$(cygpath -w "$ORIGINAL_TMP" 2> /dev/null)
#temp=$(cygpath -w "$ORIGINAL_TEMP" 2> /dev/null)
#TMP="/tmp"
#TEMP="/tmp"
case "$TMP" in *\\*) TMP="$(cygpath -m "$TMP")";; esac
case "$TEMP" in *\\*) TEMP="$(cygpath -m "$TEMP")";; esac
test -d "$TMPDIR" || test ! -d "$TMP" || {
  TMPDIR="$TMP"
  export TMPDIR
}


# Define default printer
p='/proc/registry/HKEY_CURRENT_USER/Software/Microsoft/Windows NT/CurrentVersion/Windows/Device'
if [ -e "${p}" ] ; then
  read -r PRINTER < "${p}" 
  PRINTER=${PRINTER%%,*}
fi
unset p

print_flags ()
{
  (( $1 & 0x0002 )) && echo -n "binary" || echo -n "text"
  (( $1 & 0x0010 )) && echo -n ",exec"
  (( $1 & 0x0040 )) && echo -n ",cygexec"
  (( $1 & 0x0100 )) && echo -n ",notexec"
}

# Shell dependent settings
profile_d ()
{
  local file=
  for file in $(export LC_COLLATE=C; echo /etc/profile.d/*.$1); do
    [ -e "${file}" ] && . "${file}"
  done
  
  if [ -n ${MINGW_MOUNT_POINT} ]; then
    for file in $(export LC_COLLATE=C; echo ${MINGW_MOUNT_POINT}/etc/profile.d/*.$1); do
      [ -e "${file}" ] && . "${file}"
    done
  fi
}

for postinst in $(export LC_COLLATE=C; echo /etc/post-install/*.post); do
  [ -e "${postinst}" ] && . "${postinst}"
done

if [ ! "x${BASH_VERSION}" = "x" ]; then
  HOSTNAME="$(/usr/bin/hostname)"
  profile_d sh
  [ -f "/etc/bash.bashrc" ] && . "/etc/bash.bashrc"
elif [ ! "x${KSH_VERSION}" = "x" ]; then
  typeset -l HOSTNAME="$(/usr/bin/hostname)"
  profile_d sh
  PS1=$(print '\033]0;${PWD}\n\033[32m${USER}@${HOSTNAME} \033[33m${PWD/${HOME}/~}\033[0m\n$ ')
elif [ ! "x${ZSH_VERSION}" = "x" ]; then
  HOSTNAME="$(/usr/bin/hostname)"
  profile_d zsh
  PS1='(%n@%m)[%h] %~ %% '
elif [ ! "x${POSH_VERSION}" = "x" ]; then
  HOSTNAME="$(/usr/bin/hostname)"
  PS1="$ "
else 
  HOSTNAME="$(/usr/bin/hostname)"
  profile_d sh
  PS1="$ "
fi

if [ -n "$ACLOCAL_PATH" ]
then
  export ACLOCAL_PATH
fi

export PATH MANPATH INFOPATH PKG_CONFIG_PATH USER TMP TEMP PRINTER HOSTNAME PS1 SHELL tmp temp
test -n "$TERM" || export TERM=xterm-256color

if [ "$MAYBE_FIRST_START" = "true" ]; then
  sh /usr/bin/regen-info.sh
  
  if [ -f "/usr/bin/update-ca-trust" ]
  then 
    sh /usr/bin/update-ca-trust
  fi

  clear
  echo
  echo
  echo "###################################################################"
  echo "#                                                                 #"
  echo "#                                                                 #"
  echo "#                   C   A   U   T   I   O   N                     #"
  echo "#                                                                 #"
  echo "#                  This is first start of MSYS2.                  #"
  echo "#       You MUST restart shell to apply necessary actions.        #"
  echo "#                                                                 #"
  echo "#                                                                 #"
  echo "###################################################################"
  echo
  echo
fi
unset MAYBE_FIRST_START
