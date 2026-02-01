#! /usr/bin/env zsh
# vim: filetype=zsh: tabstop=3: shifwidth=3: noexpandtab:

emulate zsh \
	+o bare_glob_qual   +o glob_assign      -o null_glob \
	+o case_glob        +o glob_dots        -o numeric_glob_sort \
	-o extended_glob    -o glob_star_short \
	-o glob             +o glob_subst


function () {
	zmodload -F zsh/zutil +b:zparseopts

	if (( $? != 0 )); then
		print -u2 - "Can't load the zparseopts command"
		exit 200
	fi
}


function _help () {
	cat - <<'eos'
mkiconapple:
  Creates an apple icon (icns) based on a list of images with different
    sizes.


# Adds the images manually

mkiconapple --out OUTPATH --workdir WD \
  --sizepath "S1:PATH1" --sizepath "S2:PATH2"

mkiconapple --out /my/out/icon --workdir /my/source/images \
  --sizepath "32:32x32/icon.png" --sizepath "1024:1024x1024/icon.png"


# Adds the images using a regex to get the size
# The regex is really a valid ZSH glob regex
# With the regex it's not necessary to indicate the size on each path
#   (as opposed to --sizepath "SIZE:PATH")

mkiconapple --out OUTPATH --workdir WD --regex REGEX --group 1 \
  --globpath GLOB1 --globpath GLOB2 --path PATH1 --path PATH2

mkiconapple --out /my/out/icon --workdir /my/source/images \
  --regex '([0-9]##)x' --group 1 \
  --globpath '*/icon.png' --path '1024x1024/icon.png'


DEFAULTS:
	workdir is the current folder by default
	group   is 1 by default


OPTIONS:

  -h // --help
    Shows this help.

  -o / --out PATH
    Output path (file should not have extension or have .icns)

  -s // --spath // --sizepath PATH
    Adds a sizepath. A sizepath has the format "SIZE:PATH". Not valid with
      regex.
  EX.: "1024:/path/to/my/img.png"

  -r / --rg / --regex REGEX
    Regular expresion to get the sizes from the dirs.
    If the regular expression doesn't have '(#b)' (capture groups)
      that will be prefixed.
    If the regular expression doesn't end in '*', that will be
      suffixed.
    If regex is set, the input files should be added with --globdir
      or --dir.
    If regex is set and the matching group that contains the size is
      different than 1, --group should be used.

  -g // --grp // --group NUMBER
    Match group that contains the size in the regex.

  -w // --wd // --workdir PATH
    Base directory for the input paths (globdirs, dirs and sizedirs). By
      default is the current dir.

  -g // --gpath // --globpath PATH
    Adds a glob input path (will use file generation). Only valid with
      regex.

  -p // --path // --plainpath PATH
    Adds a input path. Only valid with regex.


eos

	exit 0
}


function _remove_odd () {
	local -a arr
	local -i len index

	arr=( "${@}" )
	len=${#arr}

	if (( len > 0 )); then
		for (( index=len-1; index>0; index-=2 )); do
			arr=( ${arr[1,index-1]} ${arr[index+1,-1]} )
		done

		print - "${(pj.\0.)arr}"
	fi
}


function _parse_args () {
	typeset -g -A OPTS

	local    pth      basepth regex     basename ext
	local -a GLOBS    DIRS    SIZEDIRS
	local -A PARAMS
	local -a paramsarr
	local -i hasregex haswd
	local -r ptn1='*\(\#b\)*'
	local -r ptn2='*\*'

	PARAMS=() && paramsarr=()
	OPTS=()
	GLOBS=() && DIRS=() && SIZEDIRS=()
	hasregex=0 && haswd=0

	zparseopts -D -E -M -A PARAMS -a paramsarr - \
		-help h=-help \
		-out: o:=-out \
		-regex: r:=-regex -rg:=-regex \
		-group: -grp:=-group \
		-workdir: w:=-workdir -wd:=-workdir \
		-globpath+:=GLOBS g+:=-globpath -gpath+:=-globpath \
		-path+:=DIRS p+:=-path -plainpath+:=-path \
		-sizepath+:=SIZEDIRS s+:=-sizepath -spath+:=-sizepath


	## Check help
	if (( ${#paramsarr} == 0 || ${+PARAMS[--help]} == 1 )); then
		_help
	fi


	# check out path
	if (( ${+PARAMS[--out]} )); then
		pth=${PARAMS[--out]}
		pth=${pth:a}
		basepth=${pth:h}
		basename=${pth:t}
		ext=${basename:e}

		if [[ -z ${ext} ]]; then
			basename=${basename}.icns
			pth=${basepth}/${basename}

		else
			if [[ "${ext}" != 'icns' ]]; then
				print -u2 - \
					"The output file should not have a extension, or be '.icns'."
				
				exit 100
			fi
		fi

		if [[ ! -d "${basepth}" ]]; then
			print -u2 - \
				"The output folder ${(qq)${(D)basepth}} doesn't exists."
			exit 100
		fi

		if [[ -a "${pth}" ]]; then
			print -u2 - \
				"The output file ${(qq)${(D)pth}} already exists."
				exit 100
		fi

		OPTS[out]=${pth}
	else
		print -u2 - "Out path is needed"
		exit 100
	fi


	# check regex
	if (( ${+PARAMS[--regex]} )); then
		hasregex=1
		regex=${PARAMS[--regex]}

		[[ "${regex}" == ${~ptn1} ]] || regex='(#b)'${regex}
		[[ "${regex}" == ${~ptn2} ]] || regex=${regex}'*'
		OPTS[regex]=${regex}

		# regexgroup
		OPTS[rgroup]=${${OPTS[--group]}:-1}
	fi
	OPTS[hasregex]=${hasregex}


	# check workdir
	pth=${${PARAMS[--workdir]}:-.}
	pth=${pth:a}

	if [[ -d "${pth}" ]]; then
		OPTS[workdir]=${pth}
	else
		print -u2 - "The workdir ${(qq)${(D)pth}} doesn't exist."
		exit 100
	fi


	## check DIRS
	if (( hasregex )); then
		if (( ${#GLOBS} + ${#DIRS} == 0 )); then
			print -u2 - \
				"At least one --globdir or --dir is needed in REGEX mode"
			
			exit 100
		fi

		OPTS[gdirs]=$( _remove_odd "${(@)GLOBS}" )
		OPTS[pdirs]=$( _remove_odd "${(@)DIRS}" )

	## check SIZEDIRS
	else
		if (( ${#SIZEDIRS} == 0 )); then
			print -u2 - \
				"At least one --sizedir is needed in non REGEX mode"
			
			exit 100
		fi

		OPTS[sdirs]=$( _remove_odd "${(@)SIZEDIRS}" )
	fi
}


function _process_indirs () {
	typeset -g -A OPTS

	if (( ${${OPTS[hasregex]}:-0} )); then
		_process_regex_dirs
	else
		_process_size_dirs
	fi
}


function _process_regex_dirs () {
	typeset -g -A OPTS
	typeset -g -a match
	typeset -g    PWD

	typeset -a pdirs   gdirs
	typeset -A thedirs
	typeset -i index   len   rgroup  ok
	typeset    regex   size  pth     pthabs

	typeset -r ptn='[0-9]##'

	oldwd=${PWD}
	pdirs=() && gdirs=()
	regex=${OPTS[regex]}
	rgroup=${${OPTS[rgroup]}:-1}

	[[ -n ${OPTS[pdirs]} ]] && pdirs=( "${(@ps.\0.)${OPTS[pdirs]}}" )
	[[ -n ${OPTS[gdirs]} ]] && gdirs=( "${(@ps.\0.)${OPTS[gdirs]}}" )

	cd "${OPTS[workdir]}"

	gdirs=( ${~gdirs} )
	pdirs=( ${pdirs} ${gdirs} )
	pdirs=( ${(u)pdirs} )

	len=${#pdirs}
	for (( index=1; index<=len; index++ )); do
		pth=${pdirs[${index}]}
		pthabs=${pth:a}
		
		if [[ -f "${pthabs}" ]]; then
			ok=0

			if [[ "${pth}" == ${~regex} ]]; then
				size=${match[${rgroup}]}
				
				[[ "${size}" == ${~ptn} ]] && ok=1
			fi

			(( ok )) && thedirs[${size}]=${pthabs}
		fi
	done
	
	cd "${oldpw}"
	OPTS[icons]="${(pj.\0.)${(@kv)thedirs}}"
}


function _process_size_dirs () {
	typeset -g -A OPTS
	typeset -g -a match
	typeset -g    PWD

	local -a sdirs
	local -A thedirs
	local -i index len
	local -r ptn='(#b)([0-9]##):(?*)'
	local    oldwd

	oldwd=${PWD}
	sdirs=()
	thedirs=()

	[[ -n ${${OPTS[sdirs]}:-} ]] && sdirs=( ${(ps.\0.)${OPTS[sdirs]}} )

	cd "${OPTS[workdir]}"
	len=${#sdirs}
	for (( index=1; index<=len; index++ )); do
		if [[ "${sdirs[${index}]}" == ${~ptn} ]]; then
			thedirs[${match[1]}]=${${match[2]}:a}
		else
			print -u2 - \
				"The value ${(qq)${sdirs[${index}]}} should be 'size:path'"
			
			exit 100
		fi
	done

	cd "${oldwd}"
	OPTS[icons]="${(pj.\0.)${(@kv)thedirs}}"
}


function _check_images () {
	typeset -g -A OPTS

	local -A icons
	local -a keys
	local -i delete
	local    size   pth
	local    result

	local -r ptn='image/*'

	if [[ -z ${OPTS[icons]} ]]; then
		print -u2 - "There are no icons."
		exit 100
	fi
	
	icons=( "${(@ps.\0.)${OPTS[icons]}}" )
	keys=( "${(@k)icons}" )

	for size in "${(@)keys}"; do
		pth=${icons[${size}]}
		delete=1

		if [[ -f "${pth}" ]]; then
			result=$( file --brief --mime-type "${pth}" )

			[[ "${result}" == ${~ptn} ]] && delete=0
		fi

		(( delete )) && unset "icons[${size}]"
	done

	OPTS[icons]="${(pj.\0.)${(@kv)icons}}"
}


function _simplify_icons () {
	typeset -g -A OPTS

	local -A icons
	local -a iconsOut
	local -a validsizes  validsizesd
	local -a keys        keysOut
	local -a keysDouble  keysMixed
	local -i size        dsize
	local -i len         index

	keysOut=()  && keysDouble=()
	iconsOut=()

	if [[ -z ${OPTS[icons]} ]]; then
		print -u2 - "There are no icons."
		exit 100
	fi

	icons=( "${(@ps.\0.)${OPTS[icons]}}" )
	keys=( "${(@k)icons}" )
	keys=( ${(on)keys} )

	validsizes=(16 32 128 256 512)
	validsizesd=(32 64 256 512 1024)

	len=${#keys}
	for (( index=1; index<=len; index++ )); do
		size=${keys[${index}]}
		
		if (( ${+validsizes[(r)${size}]} == 1 )); then
			keysOut+=( ${size} )
		fi

		if (( ${+validsizesd[(r)${size}]} == 1 )); then
			keysDouble+=( ${size} )
		fi
	done

	# check minimums
	if (( ${#keysOut} == 0 )); then
		print -u2 - "There are no valid size icons (from 16 to 256)."
		exit 100
	fi

	# build keysMixed
	keysMixed=( ${keysOut} ${keysDouble} )
	keysMixed=( ${(onu)keysMixed} )

	# build iconsOut
	dsize=0
	for size in "${(@)keysMixed}"; do
		if (( ${+keysOut[(r)${size}]}  )); then
			iconsOut+=( "${size}x${size}:${icons[${size}]}" )
		fi
		
		if (( ${+keysDouble[(r)${size}]}  )); then
			(( dsize = size/2 ))
			iconsOut+=( "${dsize}x${dsize}@2x:${icons[${size}]}" )
		fi

	done
	OPTS[icons]="${(pj.\0.)iconsOut}"
}


function _build_icon () {
	typeset -g -A OPTS
	typeset -g -a match

	local -a icons   links
	local -i outcode
	local    value   size   pth
	local    output
	local    lpth
	local    tmpdir

	local -r ptn='(#b)([^:]##):(?*)'

	if [[ -z ${OPTS[icons]} ]]; then
		print -u2 - "There are no icons."
		exit 100
	fi

	links=()

	icons=( "${(@ps.\0.)${OPTS[icons]}}" )

	tmpdir=$( mktemp --directory )
	tmpdir=${tmpdir:a}

	OPTS[tmpdir]=${tmpdir}

	for value in "${(@)icons}"; do
		if [[ "${value}" == ${~ptn} ]]; then
			size=${match[1]}
			pth=${match[2]}

			lpth=${tmpdir}/${size}.${pth:e}
			lpth=${lpth:a}

			ln -s "${pth}" "${lpth}"
			links+=( ${lpth} )
		fi
	done

	## build the icon
	output=${OPTS[out]}
	icnsutil compose "${output}" "${(@)links}" --toc
	outcode=$?

	## deletes the temp folder
	rm -rf "${tmpdir}"

	## print error if needed
	if (( outcode != 0 )) {
		print -u2 - "The icon utility had an error."
		return ${outcode}
	}
}


function _run () {
	_parse_args "${@}"
	_process_indirs
	_check_images
	_simplify_icons
	_build_icon
}

_run "${@}"
