if [ ! -d /tmp/spec/ ]; then \
    mkdir /tmp/spec
fi


#401 y y y -- bzip2 -- (done)
#429 y y y -- mcf -- (done)
#433 y y y -- milc -- (done)
#445 y y y -- gobmk -- (wierd rust panic)
#458 y y y -- sjeng -- (done)
#462 y y y -- libquantum -- (done)
#464 y y y -- h264ref -- (wierd rust panic)
#470 y y y -- lbm -- (done)

#401 bzip2 
cp sfi-spectre-spec/benchspec/CPU2006/401.bzip2/data/all/input/input.program  /tmp/spec/bzip2_input.program
cp sfi-spectre-spec/benchspec/CPU2006/401.bzip2/data/ref/input/text.html      /tmp/spec/bzip2_text.html
cp sfi-spectre-spec/benchspec/CPU2006/401.bzip2/data/all/input/input.combined /tmp/spec/bzip2_input.combined
cp sfi-spectre-spec/benchspec/CPU2006/401.bzip2/data/ref/input/chicken.jpg    /tmp/spec/bzip2_chicken.jpg
cp sfi-spectre-spec/benchspec/CPU2006/401.bzip2/data/ref/input/liberty.jpg    /tmp/spec/bzip2_liberty.jpg
cp sfi-spectre-spec/benchspec/CPU2006/401.bzip2/data/ref/input/input.source   /tmp/spec/bzip2_input.source
#429 mcf
cp sfi-spectre-spec/benchspec/CPU2006/429.mcf/data/ref/input/inp.in /tmp/spec/mcf_inp.in
#444 namd
cp sfi-spectre-spec/benchspec/CPU2006/444.namd/data/all/input/namd.input /tmp/spec/namd_namd.input
#445 gobmk 
cp sfi-spectre-spec/benchspec/CPU2006/445.gobmk/data/ref/input/13x13.tst /tmp/spec/gobmk_13x13.tst
cp sfi-spectre-spec/benchspec/CPU2006/445.gobmk/data/ref/input/nngs.tst /tmp/spec/gobmk_nngs.tst
cp sfi-spectre-spec/benchspec/CPU2006/445.gobmk/data/ref/input/score2.tst /tmp/spec/gobmk_score2.tst
cp sfi-spectre-spec/benchspec/CPU2006/445.gobmk/data/ref/input/trevorc.tst /tmp/spec/gobmk_trevorc.tst
cp sfi-spectre-spec/benchspec/CPU2006/445.gobmk/data/ref/input/trevord.tst /tmp/spec/gobmk_trevord.tst
cp -r sfi-spectre-spec/benchspec/CPU2006/445.gobmk/data/all/input/games /tmp/spec/gobmk_games

#450 soplex
cp sfi-spectre-spec/benchspec/CPU2006/450.soplex/data/ref/input/pds-50.mps /tmp/spec/soplex_pds-50.mps
cp sfi-spectre-spec/benchspec/CPU2006/450.soplex/data/ref/input/ref.mps /tmp/spec/soplex_ref.mps

#453 povray
cp sfi-spectre-spec/benchspec/CPU2006/453.povray/data/ref/input/SPEC-benchmark-ref.ini /tmp/spec/povray_SPEC-benchmark-ref.ini
cp sfi-spectre-spec/benchspec/CPU2006/453.povray/data/ref/input/SPEC-benchmark-ref.pov /tmp/spec/povray_SPEC-benchmark-ref.pov


#458 sjeng -- ref.txt
cp sfi-spectre-spec/benchspec/CPU2006/458.sjeng/data/ref/input/ref.txt /tmp/spec/sjeng_ref.txt
#464 h264ref  
cp sfi-spectre-spec/benchspec/CPU2006/464.h264ref/data/ref/input/foreman_ref_encoder_baseline.cfg /tmp/spec/h264ref_foreman_ref_encoder_baseline.cfg
cp sfi-spectre-spec/benchspec/CPU2006/464.h264ref/data/ref/input/foreman_ref_encoder_main.cfg /tmp/spec/h264ref_foreman_ref_encoder_main.cfg
cp sfi-spectre-spec/benchspec/CPU2006/464.h264ref/data/ref/input/sss.yuv /tmp/spec/h264ref_sss.yuv
cp sfi-spectre-spec/benchspec/CPU2006/464.h264ref/data/ref/input/sss_encoder_main.cfg /tmp/spec/h264ref_sss_encoder_main.cfg
cp sfi-spectre-spec/benchspec/CPU2006/464.h264ref/data/all/input/foreman_qcif.yuv /tmp/spec/h264ref_foreman_qcif.yuv
# foreman_qcif.yuv
#470 lbm reference.dat 100_100_130_ldc.of lbm.in
cp sfi-spectre-spec/benchspec/CPU2006/470.lbm/data/ref/input/100_100_130_ldc.of /tmp/spec/lbm_100_100_130_ldc.of

#473 astar
cp sfi-spectre-spec/benchspec/CPU2006/473.astar/data/ref/input/BigLakes2048.cfg /tmp/spec/astar_BigLakes2048.cfg
cp sfi-spectre-spec/benchspec/CPU2006/473.astar/data/ref/input/BigLakes2048.bin /tmp/spec/astar_BigLakes2048.bin
cp sfi-spectre-spec/benchspec/CPU2006/473.astar/data/ref/input/rivers.cfg /tmp/spec/astar_rivers.cfg
cp sfi-spectre-spec/benchspec/CPU2006/473.astar/data/ref/input/rivers.bin /tmp/spec/astar_rivers.bin

# 482.sphinx3
mkdir /tmp/spec/sphinx3
cp -r sfi-spectre-spec/benchspec/CPU2006/482.sphinx3/data/all/input/model /tmp/spec/sphinx3/model
cp -r sfi-spectre-spec/benchspec/CPU2006/482.sphinx3/data/ref/input /tmp/spec/sphinx3/input
