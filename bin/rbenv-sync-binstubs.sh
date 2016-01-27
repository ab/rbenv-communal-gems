#!/usr/bin/env bash
#
# Syncs Ruby binstubs for ruby-communal-gems.
# Run this everytime you install a new Ruby, or when you install a new gem
# with a bin/ command. (ie, when you typically do rbenv rehash)
#
# See: https://github.com/tpope/rbenv-communal-gems/issues/5
#

set -eu

shopt -s nullglob

log_debug() {
    if [ -n "$debug" ]; then
        echo >&2 "$@"
    fi
}

versions_path="$RBENV_ROOT/versions"
prefixes=(2.0.0- 2.1. 1.9. 2.2. 2.3.)

dry_run=
debug=

while [ $# -gt 0 ] && [[ $1 == -* ]]; do
    case "$1" in
        -h|--help)
            rbenv-help "$(basename "$0")" >&2
            exit 0
            ;;
        -d|--debug)
            debug=1
            log_debug 'debug mode enabled'
            ;;
        -n|--dry-run)
            dry_run=1
            echo >&2 'running in dry run mode'
            ;;
        *)
            rbenv-help "$(basename "$0")" >&2
            exit 1
            ;;
    esac
    shift
done

is_excluded_bin() {
    case "$1" in
        gem|ruby|irb|ri|rdoc|erb|testrb|rake)
            return 0
            ;;
    esac
    return 1
}

# Determine whether a shebang line is acceptable to sync across ruby point
# versions. Reject files without a shebang line, and reject files that depend
# on a specific ruby version (e.g. ~/.rbenv/versions/2.1.6/bin/ruby)
shebang_seems_ok() {
    shebang="$(head -1 "$1")"
    if [[ $shebang != '#!/'* ]]; then
        return 1
    fi

    # shebang must contain env, not a specific /bin/ruby version
    if [[ $shebang == */versions/*/bin/ruby* ]]; then
        return 1
    fi

    # OK
    return 0
}

sync_binary() {
    src="$1"
    dst="$2"

    if [ -n "$debug" ]; then
        opts='-v'
    else
        opts=''
    fi

    if [ -n "$dry_run" ]; then
        echo >&2 "(dry run) + $dst"
    else
        echo >&2 "+ $dst"
        cp -an $opts "$src" "$dst"
    fi
}

for prefix in "${prefixes[@]}"; do
    log_debug "prefix: $prefix*"

    bindirs=( "$versions_path/$prefix"*"/bin" )

    # no need to sync prefixes for which there are < 2 bin directories
    if [ ${#bindirs[@]} -le 1 ]; then
        log_debug "no sync needed for $prefix*"
        continue
    fi

    log_debug "found ${#bindirs[@]} bin directories: ${bindirs[@]}"

    for bindir in "${bindirs[@]}"; do
        log_debug "src: $bindir"
        ls -1 "$bindir" | while read binfile; do
            if is_excluded_bin "$binfile"; then
                # log_debug "-- skipping $binfile"
                continue
            fi
            if ! shebang_seems_ok "$bindir/$binfile"; then
                log_debug "-- skipping $binfile (bad shebang)"
                echo >&2 "- $bindir/$binfile has bad looking shebang line"
                continue
            fi

            for target_bindir in "${bindirs[@]}"; do
                if [ "$target_bindir" = "$bindir" ]; then
                    continue
                fi
                if [ -e "$target_bindir/$binfile" ]; then
                    # log_debug "-- $binfile already exists in $target_bindir"
                    continue
                fi
                log_debug "-- $binfile"
                sync_binary "$bindir/$binfile" "$target_bindir/$binfile"
            done
        done
    done
done

echo >&2 'All done!'
