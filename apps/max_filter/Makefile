include ../support/Makefile.inc
include ../support/autoscheduler.inc

HL_TARGET=host-cuda

GRADIENT_AUTOSCHED_BIN=../gradient_autoscheduler/bin
CXXFLAGS += -I../support/

FILTER_DEPS=$(BIN)/%/max_filter.a

ifndef NO_AUTO_SCHEDULE
	FILTER_DEPS += $(BIN)/%/max_filter_auto_schedule.a $(BIN)/%/max_filter_gradient_auto_schedule.a $(BIN)/%/runtime.a
else
	CXXFLAGS += -DNO_AUTO_SCHEDULE
endif

all: $(BIN)/test

$(GENERATOR_BIN)/max_filter.generator: max_filter_generator.cpp $(GENERATOR_DEPS)
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) -g $(filter-out %.h,$^) -o $@ $(LDFLAGS) $(HALIDE_SYSTEM_LIBS) $(USE_EXPORT_DYNAMIC)

$(BIN)/%/max_filter.a: $(GENERATOR_BIN)/max_filter.generator
	@mkdir -p $(@D)
	$< -g max_filter -e $(GENERATOR_OUTPUTS) -o $(@D) -f max_filter target=$* auto_schedule=false

$(BIN)/%/runtime.a: $(GENERATOR_BIN)/max_filter.generator
	@mkdir -p $(@D)
	$< -r runtime -o $(@D) target=$*

$(BIN)/%/max_filter_auto_schedule.a: $(GENERATOR_BIN)/max_filter.generator $(AUTOSCHED_BIN)/libauto_schedule.so
	@mkdir -p $(@D)
	HL_PERMIT_FAILED_UNROLL=1 \
	HL_WEIGHTS_DIR=$(AUTOSCHED_SRC)/gpu.weights \
	HL_DEBUG_CODEGEN=1 \
	HL_SHARED_MEMORY_LIMIT=48 \
	$< -g max_filter -f max_filter_auto_schedule -e $(GENERATOR_OUTPUTS) -o $(@D) target=$* auto_schedule=true -p $(AUTOSCHED_BIN)/libauto_schedule.so -s Adams2019 machine_params=$(HL_MACHINE_PARAMS) 2> stderr.txt > stdout.txt

$(BIN)/%/max_filter_gradient_auto_schedule.a: $(GENERATOR_BIN)/max_filter.generator
	@mkdir -p $(@D)
	$^ -g max_filter -e $(GENERATOR_OUTPUTS) -o $(@D) -f max_filter_gradient_auto_schedule target=$*-no_runtime auto_schedule=true -p $(GRADIENT_AUTOSCHED_BIN)/libgradient_autoscheduler.so -s Li2018

$(BIN)/%/filter: filter.cpp $(FILTER_DEPS)
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) -I$(BIN)/$* -Wall -O3 $^ -o $@ $(LDFLAGS) $(IMAGE_IO_FLAGS) $(CUDA_LDFLAGS) $(OPENCL_LDFLAGS) $(OPENGL_LDFLAGS)

clean:
	rm -rf $(BIN)

$(BIN)/%/out.png: $(BIN)/%/filter
	$< ../images/rgb.png $@

test: $(BIN)/$(HL_TARGET)/out.png

BATCH_ID ?= 0
TRAIN_ONLY ?= 0
SAMPLES_DIR ?= autotuned_samples
autotune: $(GENERATOR_BIN)/max_filter.generator $(AUTOSCHED_BIN)/featurization_to_sample $(AUTOSCHED_BIN)/retrain_cost_model $(AUTOSCHED_BIN)/libauto_schedule.so $(AUTOSCHED_SRC)/autotune_loop.sh
	HL_MACHINE_PARAMS=80,1,1 \
	SAMPLES_DIR=$(SAMPLES_DIR) \
	HL_PERMIT_FAILED_UNROLL=1 \
	HL_DEBUG_CODEGEN=1 \
	HL_SHARED_MEMORY_LIMIT=48 \
	bash $(AUTOSCHED_SRC)/autotune_loop.sh \
		$(GENERATOR_BIN)/max_filter.generator \
		max_filter \
		host-cuda \
		$(AUTOSCHED_SRC)/gpu.weights \
		$(AUTOSCHED_BIN) \
		$(BATCH_ID) \
		$(TRAIN_ONLY)
