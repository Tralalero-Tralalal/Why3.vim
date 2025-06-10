# Makefile for building an OCaml project with ocamlbuild and ocamlfind

# Define the main executable you want to build
TARGET = main.native

# Define the ocamlbuild command with necessary flags
# -use-ocamlfind: Enables ocamlfind integration to locate packages
# -pkg why3: Links against the 'why3' OCaml package
# -tag thread: (Optional) If your project uses Lwt or other threading libraries,
#              you might need this. Remove if not applicable.
# -cflags -w -a: (Optional) Example compiler flags: '-w -a' for some warnings
# -lflags -linkall: (Optional) Example linker flags: '-linkall' might be needed for some libraries
OCAMLBUILD_CMD = ocamlbuild -use-ocamlfind -pkg why3

# .PHONY targets ensure that make doesn't confuse these with files named 'all' or 'clean'
.PHONY: all clean

# The 'all' target is the default. It builds our TARGET.
# It uses the defined OCAMLBUILD_CMD to build the specified TARGET.
all:
	@echo "Building $(TARGET)..."
	$(OCAMLBUILD_CMD) $(TARGET)
	@echo "Build complete. Executable: _build/$(TARGET)"

# The 'clean' target removes all generated build artifacts.
# ocamlbuild -clean removes the entire _build directory and other build files.
clean:
	@echo "Cleaning build artifacts..."
	$(OCAMLBUILD_CMD) -clean
	@echo "Clean complete."

# Optional: Add a 'run' target for convenience
.PHONY: run
run: all
	@echo "Running $(TARGET)..."
	./_build/$(TARGET)
