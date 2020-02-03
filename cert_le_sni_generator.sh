#!/bin/bash
# PoC for SNI certificates generation (via Let's Encrypt)
# This not finished/not working

set -eu

STATEDIR=/var/lib/rjsRedirector


function checkEnv() {
  if ! command -v comm &>/dev/null
  then
    echo "Missing comm command"
    exit 1
  fi
}

default_domain=""

while getopts "d:" o &>/dev/null
 do
    case "${o}" in
        d)	
						default_domain="${OPTARG}"
            ;;
        *)
            echo "Unknow option!"
						exit 1
            ;;
    esac
done
shift $((OPTIND-1))

if [[ -z "$1" ]]
then
  echo "$0 <file-name>"
  exit 1
fi

checkEnv

if [[ ! -d $STATEDIR ]]
then
  mkdir -p "${STATEDIR}"
fi

if [[ ! -d $STATEDIR ]]
then
  echo "Unable to create state directory $STATE"
  exit 1
fi

inFile="$1"

if [[ ! -f $inFile ]]
then
  echo "Missing input file: $inFile"
  exit 1
fi

declare -A  domains
if [[ -f ${STATEDIR}/domains.last ]]
then
  # This is not first run
  # find changes 
	# Normalize input file
	:>new.tmp
  while read domain
  do
    # skip empty lines
    if [[ -z $domain ]]
    then
      continue
    fi
    if [[ ! $domain =~ \. ]]
    then
			if [[ -z $default_domain ]]
			then
        echo "Skiping: $domain"
        continue
			fi
			domain="${domain}.${default_domain}"
    fi
		echo $domain >>new.tmp
  done <$inFile
	sort new.tmp >new
	rm new.tmp
	sort ${STATEDIR}/domains.last >old
  while read domain 
  do
    fc="${domain:0:1}"
    if [[ $fc == "@" ]] || [[ $fc == "-" ]]
    then
      key="${domain:1}"
      domain=$fc
    else
      key=$domain
      domain="+"
    fi
   domains[$key]=$domain
  done < <(comm new old  | sed -e "s/\t\t/@/g" "-e s/\t/-/g")
else
  while read domain
  do
    # skip empty lines
    if [[ -z $domain ]]
    then
      continue
    fi
    if [[ ! $domain =~ \. ]]
    then
			if [[ -z $default_domain ]]
			then
        echo "Skiping: $domain"
        continue
			fi
			domain="${domain}.${default_domain}"
    fi
    domains[$domain]="+"
  done <$inFile
fi
#SPLIT by count
MAX_NAMES_PER_CERT=4
count=0
:>"${STATEDIR}/domains.last"
for key in ${!domains[@]}
do
	((count++)) | true
  echo $key=${domains[$key]}
	echo $key >>"${STATEDIR}/domains.last"
done
# We have current state of all certificates (current, removed and added)
# Next step is to make them consistent
# vim: set tabstop=2 shiftwidth=2 expandtab autoindent indentexpr= nosmartindent background=dark :