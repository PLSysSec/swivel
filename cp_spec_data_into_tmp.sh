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
#445 gobmk 
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

