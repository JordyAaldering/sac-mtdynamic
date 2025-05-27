SAC = sac2c
SAC_FLAGS = -Xc -Ofast
MT_FLAGS = -t mt_pth

bin/%_seq: src/%.sac host/seq/libBenchMod.so
	$(SAC) $(SAC_FLAGS) $< -o $@

bin/%_mt: src/%.sac host/mt-pth/libBenchMod.so
	$(SAC) ${MT_FLAGS} $(SAC_FLAGS) $< -o $@

bin/%_mtd: src/%.sac host/mt-pth/libBenchMod.so
	$(SAC) ${MT_FLAGS} -mt_dynamic $(SAC_FLAGS) $< -o $@

bin/nbody_mt: src/nbody.sac host/mt-pth/libBenchMod.so host/mt-pth/libVec3dMod.so
	$(SAC) ${MT_FLAGS} $(SAC_FLAGS) $< -o $@

bin/nbody_mtd: src/nbody.sac host/mt-pth/libBenchMod.so host/mt-pth/libVec3dMod.so
	$(SAC) ${MT_FLAGS} -mt_dynamic $(SAC_FLAGS) $< -o $@

host/mt-pth/lib%Mod.so: src/%.sac
	$(SAC) ${MT_FLAGS} $(SAC_FLAGS) $<

clean:
	$(RM) bin/*
	$(RM) -r host
	$(RM) -r tree
