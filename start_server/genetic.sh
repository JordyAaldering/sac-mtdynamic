../mtdynamic/target/release/server \
    --once \
    --letterbox-size 20 \
    genetic \
        --score energy \
        --survival-rate 0.75 \
        --mutation-rate 0.10 \
        --immigration-rate 0.0
