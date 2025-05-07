if [ "$#" -ne 1 ]; then
    printf "Usage: %s <log-file>\n" "$0" >&2
    exit 1
fi

../mtdynamic/target/release/single \
    -c corridor -f energy -s 10 \
    --log-file $1
