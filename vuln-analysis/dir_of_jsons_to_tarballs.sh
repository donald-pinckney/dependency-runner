#!/bin/bash
jsons_dir=${1%/}
tarballs_dir=${2%/}

if [ -z "$jsons_dir" ]
then
    echo "Usage: dir_of_jsons_to_tarballs.sh [src dir of json files] [target dir to put tarballs (must exist)]"
    exit 1
fi

if [ -z "$tarballs_dir" ]
then
    echo "Usage: dir_of_jsons_to_tarballs.sh [src dir of json files] [target dir to put tarballs (must exist)]"
    exit 1
fi

echo "$jsons_dir"

for file in $jsons_dir/*.json; do
    tmp_name="${file//\.json/.tgz}"
    tarball_name=$(basename $tmp_name) 

    rm -rf "$jsons_dir/package"
    mkdir "$jsons_dir/package"
    cp "$file" "$jsons_dir/package/package.json"
    tar -czf "$tarballs_dir/$tarball_name" -C "$jsons_dir" package/
done

rm -rf "$jsons_dir/package"