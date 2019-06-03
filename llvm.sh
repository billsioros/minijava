#!/bin/bash

problematic=0

DIR="./examples/extra/positive"

OUT="./IR"

function test
{
    DIR="$(dirname "$1")"

    filename="$(basename "$1")"

    if [ "${filename##*.}" != "java" ]
    then
        return
    fi

    echo "Processing file '$1'"

    name="${filename%.*}"

    if java Main "$DIR"/"$name".java > "$OUT"/"$name".str
    then
        mv "$DIR"/"$name".ll "$OUT"/"$name".ll

        if clang -g -Wno-override-module -o "$OUT"/"$name".bin "$OUT"/"$name".ll
        then
            if ! "$OUT"/"$name".bin > "$OUT"/"$name".out
            then
                code -w "$OUT"/"$name".ll ./examples/llvm/"$name".llvm "$DIR"/"$name".java "$OUT"/"$name".str "$OUT"/"$name".out

                ((problematic++))
            else
                differences="$(diff <( tr -d "[:space:]" <"$OUT"/"$name".out ) <( tr -d "[:space:]" <"$DIR"/"$name".output))";

                if [ -n "$differences" ]
                then
                    code -w -r -d "$OUT"/"$name".out "$DIR"/"$name".output
                fi
            fi

            return
        fi
    fi

    read -n1 -r -p "Press any key to continue..."

    ((problematic++))
}

mkdir -p "$OUT"

./compile.sh --clean
./compile.sh

if [ ! "$#" -eq 0 ]
then
    for arguement in "$@"
    do
        if [ -f "$arguement" ]
        then
            test "$arguement"
        elif [ -d "$arguement" ]
        then
            for filename in $(ls "$arguement")
            do
                test "$arguement"/"$filename"
            done
        else
            exit 1
        fi
    done
else
    for filename in $(ls "$DIR")
    do
        test "$DIR"/"$filename"
    done
fi

if [ "$problematic" -eq 0 ]
then
    rm -rfv "$OUT"
fi

exit 0
