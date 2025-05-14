SAC = sac2c
SAC_FLAGS = -Xc -Ofast
MT_FLAGS = -t mt_pth #-mt_dynamic

all: bin/matmul_mt bin/flash_mt bin/nbody_mt

bin/matmul_mt: src/matmul.sac
	$(SAC) ${MT_FLAGS} $(SAC_FLAGS) $< -o $@

bin/nbody_mt: src/nbody.sac host/mt-pth/libVec3dMod.so
	$(SAC) ${MT_FLAGS} $(SAC_FLAGS) $< -o $@

host/mt-pth/lib%Mod.so: src/%.sac
	$(SAC) ${MT_FLAGS} $(SAC_FLAGS) $<

clean:
	$(RM) bin/*
	$(RM) -r host
	$(RM) -r tree
