SAC ?= sac2c
SAC_FLAGS = -maxwlur 9
MT_FLAGS = -t mt_pth

bin/%_mt: src/%.sac host/mt-pth/libBenchMod.so
	$(SAC) ${MT_FLAGS} $(SAC_FLAGS) $< -o $@

bin/%_mtd: src/%.sac host/mt-pth/libBenchMod.so
	$(SAC) -mt_dynamic ${MT_FLAGS} $(SAC_FLAGS) $< -o $@

host/mt-pth/lib%Mod.so: src/%.sac
	$(SAC) ${MT_FLAGS} $(SAC_FLAGS) $<

clean:
	$(RM) bin/*
	$(RM) -r host
	$(RM) -r tree
