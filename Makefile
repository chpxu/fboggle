FC      = gfortran
FFLAGS  = -g  -fcheck=all -fbacktrace -Wall -Wextra -pedantic -std=f2008 -fopenmp -fall-intrinsics
TARGET  = boggle
SRC     = boggle.f90
WORDS  ?= words_alpha.txt
PARAMS ?= examples/params.txt
.PHONY: all run clean
 
all: $(TARGET)
 
$(TARGET): $(SRC)
	$(FC) $(FFLAGS) -o $@ $<
 
run: $(TARGET)
	./$(TARGET) $(WORDS) $(PARAMS)
 
clean:
	rm -f $(TARGET) *.mod
 
