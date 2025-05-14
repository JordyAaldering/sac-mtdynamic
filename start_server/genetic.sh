../mtdynamic/target/release/server \
    --single \
    --letterbox-size 20 \
    genetic \
        --score energy \
        --survival-rate 0.75 \
        --mutation-rate 0.25 \
        --immigration-rate 0.0
