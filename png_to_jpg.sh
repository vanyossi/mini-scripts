#!/bin/sh
# Converts png to jpeg using cjpeg library
#   imagemagick cannot control jpeg smooth


## if no arguments, filename is date
if test $# -ne 0
then
    for f in ${@}
    do
        if test -e $f
        then
            printf -v FILE_ext ${f:(-3)}

            if test $FILE_ext = "png"
            then
                #get last /
                FILE_dir=${f%/*}
                echo $FILE_dir

                FILE_name="${f##*/}"
                echo $FILE_name

                printf -v DSC_pos `expr index "$FILE_name" DSC`
                if test $DSC_pos -gt 0
                then
                    DSC_pos=$(expr $DSC_pos + 3)
                    DSC_root=${FILE_name:${DSC_pos}:4}
                    DSC_name="DSC_${DSC_root}.JPG"
                    printf -v DSC_namedir "%s" $FILE_dir "/" $FILE_name
                fi

                # Assumes filename default from photivo: -new.JPG
                JPEG_namedir=${f::(-4)}.jpg
                JPEG_name=${JPEG_namedir##*/}

                echo "converting ${FILE_name}"
                pngtopnm $f | cjpeg -dct int -smooth 50 -quality 85 -optimize -outfile ${JPEG_namedir}

                if test -e $DSC_namedir
                then
                    echo "Cloning Exif from ${DSC_name} to ${JPEG_name}"
                    exiftool -overwrite_original -tagsfromfile ${DSC_namedir} -ColorSpace+=1 ${JPEG_namedir}
                fi
            fi
        else
            echo "File $f does not exist"
        fi
    done
else
    echo "No arguments, exiting..."
    exit
fi
