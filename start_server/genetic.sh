mtdynamic --once \
          --letterbox-size 20 \
          genetic --score energy \
                  --power-rate-min 0.1 \
                  --power-rate-max 0.5 \
                  --threads-rate-min 1 \
                  --survival-rate 0.2 \
                  --mutation-rate 0.3 \
                  --mutation-strength 0.05 \
                  --immigration-rate 0
