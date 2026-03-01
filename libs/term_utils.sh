#!/bin/bash

# Prevent re-sourcing if function already declared
if declare -F bach::term_utils::declare_colors &>/dev/null; then
    echo "bach::term_utils::declare_colors already declared, skipping re-source." >&2
    return 0
fi

bach::term_utils::declare_colors() {
    if [[ -z "${__BACH_TERM_COLORS}" ]]; then
        # echo "bach::term_utils::declare_colors declare __BACH_TERM_COLORS." >&2
        # TODO: Continue using bach::term_utils::colors_tput_demo output
        declare -gA __BACH_TERM_COLORS=(
            [reset]="$(tput sgr0)"
            [bold]="$(tput bold)"
            [underline]="$(tput smul)"
            [reverse]="$(tput rev)"
            [grey]="$(tput setaf 0)"
            [red]="$(tput setaf 1)"
            [green]="$(tput setaf 2)"
            [yellow]="$(tput setaf 3)"
            [blue]="$(tput setaf 4)"
            [magenta]="$(tput setaf 5)"
            [cyan]="$(tput setaf 6)"
            [white]="$(tput setaf 7)"
            [bright_grey]="$(tput setaf 8)"
            [bright_red]="$(tput setaf 9)"
            [bright_green]="$(tput setaf 10)"
            [bright_yellow]="$(tput setaf 11)"
            [bright_blue]="$(tput setaf 12)"
            [bright_magenta]="$(tput setaf 13)"
            [bright_cyan]="$(tput setaf 14)"
            [bright_white]="$(tput setaf 15)"
            [black]="$(tput setaf 16)"
        )
    # else
    #     echo "bach::term_utils::declare_colors __BACH_TERM_COLORS already declared, skipping." >&2
    fi
}

export -f bach::term_utils::declare_colors


# Source: https://unix.stackexchange.com/a/521120
bach::term_utils::colors_tput_demo() {
    for ((i=0; i<256; i++)) ;do
        echo -n '  '
        tput setab $i
        tput setaf $(( ( ( i > 231 && i < 244 ) || ( ( i < 17 ) && ( i % 8 < 2 ) )
                || ( i > 16 && i < 232 ) && ( ( i - 16 ) % 6 * 11 + ( i - 16 ) /
                6 % 6 * 14 + ( i - 16 ) / 36 * 10 ) < 58 ) ? 7 : 16 ))
        printf " C %3d " $i
        tput op
        (( ((i<16||i>231) && ((i+1)%8==0)) || ((i>16&&i<232)&& ((i-15)%6==0)) )) &&
            printf "\n"
    done
}

export -f bach::term_utils::colors_tput_demo