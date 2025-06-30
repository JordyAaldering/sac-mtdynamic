mtdynamic --once \
          --letterbox-size 20 \
          genetic --score energy \
                  --power-rate-min 0.05 \
                  --threads-rate-min 1 \
                  --survival-rate 0.25 \
                  --mutation-rate 0.30 \
                  --immigration-rate 0
