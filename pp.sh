#!/bin/sh

print_help() {
    printf "\t%-20s\t%s\n" "q" "Quit the editor" 
    printf "\t%-20s\t%s\n" "v [STARTLINE] [ENDLINE]" "View the file contents"
    printf "\t%-20s\t%s\n" "e [LINE]" "Edit (or append) a line"
    printf "\t%-20s\t%s\n" "r [LINE]" "Remove line"
    printf "\t%-20s\t%s\n" "h" "Show all available options"
}

print_usage_and_exit() {
    echo $(basename "$0"): POSIX Shell editor
    echo Usage: $(basename "$0") [OPTION] [FILE]
    if [ $# -gt 0 ]; then
        echo Error: "$1"
        exit 1
    else
        echo "Available commands:"
        print_help
        exit 0
    fi
}

line_number() {
    echo $(wc -l 2>/dev/null < "$file" || echo 0)
    return 0
}

case $# in
    0) print_usage_and_exit "No filename provided";;
    1) [ "$1" = "-h" ] && print_usage_and_exit;;
    *) print_usage_and_exit "Too many arguments";;
esac

file=$(dirname "$1")/$(basename "$1")
exit=0
while [ $exit -eq 0 ]; do
    printf "%s > " "$file"
    read -r input arg1 arg2
    case $input in
        v)      
            startline=${arg1:-1}
            endline=${arg2:-$(line_number)}
            [ -n "$arg1" ] && [ "$startline" -le 0 ] && echo ERR: Invalid STARTLINE && continue
            [ -n "$arg2" ] && [ "$endline" -le 0 ] && echo ERR: Invalid ENDLINE && continue
            if [ "$startline" -gt "$endline" ]; then
                tmp=$startline
                startline=$endline
                endline=$tmp
            fi

            echo "Line\tContent"
            echo "$(cat -n "$file" | head -"$endline" | tail +"$startline")"
            ;;
        e)
            linenum=${arg1:-$(( $(line_number) + 1 ))}
            [ -n "$arg1" ] && [ "$linenum" -le 0 ] && echo ERR: Invalid LINE && continue 

            printf "> "
            read -r line

            i=$(( $(line_number) + 1 )) && [ "$linenum" -gt $i ] && \
                while [ $i -lt "$linenum" ]; do echo "" >> "$file"; i=$(( i + 1 )); done

            [ ! -f "$file" ] && echo "$line" > "$file" || head -n $(( $linenum - 1)) "$file" > "$file".swp && \
                echo "$line" >> "$file".swp && \
                tail -n +$(($linenum + 1)) "$file" >> "$file".swp && \
                mv "$file".swp "$file"
            ;;
        r)
            linenum=${arg1:-$(line_number)}
            [ -n "$arg1" ] && [ "$linenum" -le 0 ] && echo ERR: Invalid LINE && continue

            head -n $(( $linenum - 1 )) "$file" > "$file".swp && \
                tail -n +$(( $linenum + 1 )) "$file" >> "$file".swp && \
                mv "$file".swp "$file"
            ;;
        h) print_help;;
        q) exit=1;;
        *) echo "ERR: Invalid command (h for help)";;
    esac
done
