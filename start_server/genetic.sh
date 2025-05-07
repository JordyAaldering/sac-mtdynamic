if [ "$#" -ne 1 ]; then
    printf "Usage: %s <log-file>\n" "$0" >&2
    exit 1
fi

../mtdynamic/target/release/single \
    -c genetic -f energy -s 20 \
    --survival-rate 0.75 \
    --log-file $1
