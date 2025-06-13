TARGET = main.native

OCAMLBUILD_CMD = ocamlbuild -use-ocamlfind -pkg why3 -pkg lablgtk2

.PHONY: all clean

all:
	@echo "Building $(TARGET)..."
	$(OCAMLBUILD_CMD) $(TARGET)
	@echo "Build complete. Executable: _build/$(TARGET)"

clean:
	@echo "Cleaning build artifacts..."
	$(OCAMLBUILD_CMD) -clean
	@echo "Clean complete."

.PHONY: run
run: all
	@echo "Running $(TARGET)..."
	./_build/$(TARGET)
